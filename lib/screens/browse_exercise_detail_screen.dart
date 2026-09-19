// lib/screens/browse_exercise_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../widgets/embedded_video_player.dart';
import '../widgets/step_image_carousel.dart';

const _difficultyLabels = {1: 'Beginner', 2: 'Intermediate', 3: 'Advanced', 4: 'Super Level'};
const _difficultyColors = {
  1: Color(0xFF16A085),
  2: Color(0xFFE0A100),
  3: Color(0xFFD9534F),
  4: Color(0xFF8E44AD),
};

/// View-only exercise detail for the browse library -- no mark-done,
/// feedback, or comment section, unlike the dashboard's prescribed-
/// exercise cards. A browsed exercise has no PrescriptionExercise row
/// (nothing was prescribed), so there's nothing for a physio to see even
/// if a patient did mark it done here -- keeping that action out
/// entirely avoids the false impression that it would go anywhere.
class BrowseExerciseDetailScreen extends StatefulWidget {
  final Map<String, dynamic> exercise;
  const BrowseExerciseDetailScreen({super.key, required this.exercise});

  @override
  State<BrowseExerciseDetailScreen> createState() => _BrowseExerciseDetailScreenState();
}

class _BrowseExerciseDetailScreenState extends State<BrowseExerciseDetailScreen> {
  bool _showEnglish = false; // false = Nepali-preferred default, matches the dashboard

  Future<void> _openYoutubeVideo(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open video link')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ex = widget.exercise;
    final screenWidth = MediaQuery.of(context).size.width;
    final visualHeight = screenWidth * 9 / 16;

    final hostedVideoUrl = (ex['hosted_video_url'] as String?)?.trim() ?? '';
    final youtubeUrl = (ex['youtube_url'] as String?)?.trim() ?? '';
    final stepImages = List<Map<String, dynamic>>.from(ex['step_images'] ?? []);
    final difficulty = ex['difficulty_level'] as int? ?? 1;

    final descriptionEn = (ex['description'] as String? ?? '').trim();
    final descriptionNp = (ex['description_nepali'] as String? ?? '').trim();
    final hasNepali = descriptionNp.isNotEmpty;
    final hasEnglish = descriptionEn.isNotEmpty;
    final showEnglish = _showEnglish || !hasNepali;
    final description = showEnglish ? descriptionEn : descriptionNp;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(ex['exercise_name'] ?? '', style: const TextStyle(color: Colors.black87, fontSize: 16), maxLines: 1, overflow: TextOverflow.ellipsis),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Same priority as the dashboard: hosted video, then step
            // slideshow, then a plain placeholder.
            if (hostedVideoUrl.isNotEmpty)
              EmbeddedVideoPlayer(url: hostedVideoUrl, height: visualHeight)
            else if (stepImages.isNotEmpty)
              StepImageCarousel(images: stepImages, height: visualHeight)
            else
              Container(
                width: double.infinity,
                height: visualHeight,
                color: Colors.grey[100],
                child: Icon(Icons.medical_services_outlined, color: Colors.grey[400], size: 48),
              ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ex['exercise_name'] ?? '',
                    style: const TextStyle(color: Colors.black87, fontSize: 19, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: (_difficultyColors[difficulty] ?? Colors.grey).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _difficultyLabels[difficulty] ?? 'Beginner',
                          style: TextStyle(color: _difficultyColors[difficulty] ?? Colors.grey, fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ),
                      // Redundant Video button hidden when a hosted video is
                      // already playing embedded above -- same reasoning as
                      // the dashboard.
                      if (youtubeUrl.isNotEmpty && hostedVideoUrl.isEmpty)
                        GestureDetector(
                          onTap: () => _openYoutubeVideo(youtubeUrl),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.red[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.play_circle_outline, size: 14, color: Colors.red[700]),
                                const SizedBox(width: 4),
                                Text('Video', style: TextStyle(color: Colors.red[700], fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  Text('Suggested', style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 16,
                    runSpacing: 6,
                    children: [
                      _doseChip('Sets', '${ex['default_sets'] ?? 3}'),
                      _doseChip('Reps', '${ex['default_reps'] ?? 10}'),
                      if ((ex['hold_time_sec'] as int? ?? 0) > 0) _doseChip('Hold', '${ex['hold_time_sec']}s'),
                      _doseChip('Rest', '${ex['default_rest_time_sec'] ?? 60}s'),
                    ],
                  ),
                  // A physio hasn't customized these for a specific person,
                  // so it's worth being explicit that these are starting
                  // points, not a prescription.
                  const SizedBox(height: 4),
                  Text(
                    'General starting point -- ask your physio before starting a new exercise if you\'re unsure it\'s right for you.',
                    style: TextStyle(color: Colors.grey[500], fontSize: 11, fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Instructions', style: TextStyle(color: Colors.grey[600], fontSize: 13, fontWeight: FontWeight.w600)),
                      if (hasNepali && hasEnglish)
                        TextButton.icon(
                          onPressed: () => setState(() => _showEnglish = !_showEnglish),
                          icon: const Icon(Icons.translate, size: 15),
                          label: Text(showEnglish ? 'नेपालीमा हेर्नुहोस्' : 'View in English'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFF0A6EBD),
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            textStyle: const TextStyle(fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description.isNotEmpty ? description : 'No instructions added for this exercise yet.',
                    style: TextStyle(
                      color: description.isNotEmpty ? Colors.black87 : Colors.grey[500],
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _doseChip(String label, String value) {
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(text: '$label: ', style: TextStyle(color: Colors.grey[600], fontSize: 13)),
          TextSpan(
            text: value,
            style: const TextStyle(color: Colors.black87, fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
