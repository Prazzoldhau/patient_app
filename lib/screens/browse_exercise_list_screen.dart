// lib/screens/browse_exercise_list_screen.dart
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import 'browse_exercise_detail_screen.dart';

const _difficultyLabels = {1: 'Beginner', 2: 'Intermediate', 3: 'Advanced', 4: 'Super Level'};
const _difficultyColors = {
  1: Color(0xFF16A085),
  2: Color(0xFFE0A100),
  3: Color(0xFFD9534F),
  4: Color(0xFF8E44AD),
};

class BrowseExerciseListScreen extends StatefulWidget {
  final int subregionId;
  final String subregionName;
  const BrowseExerciseListScreen({super.key, required this.subregionId, required this.subregionName});

  @override
  State<BrowseExerciseListScreen> createState() => _BrowseExerciseListScreenState();
}

class _BrowseExerciseListScreenState extends State<BrowseExerciseListScreen> {
  List<Map<String, dynamic>> _exercises = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final exercises = await ApiService().getBrowseExercises(widget.subregionId);
      setState(() {
        _exercises = exercises;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.subregionName, style: const TextStyle(color: Colors.black87, fontSize: 16)),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _exercises.isEmpty
              ? Center(child: Text('No exercises found', style: TextStyle(color: Colors.grey[600])))
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: _exercises.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _exerciseRow(_exercises[i]),
                ),
    );
  }

  Widget _exerciseRow(Map<String, dynamic> ex) {
    final stepImages = List<Map<String, dynamic>>.from(ex['step_images'] ?? []);
    final thumbnailUrl = stepImages.isNotEmpty ? stepImages.first['image_url'] as String? : ex['exercise_url'] as String?;
    final difficulty = ex['difficulty_level'] as int? ?? 1;
    final hasVideo = ((ex['hosted_video_url'] ?? ex['youtube_url']) as String? ?? '').trim().isNotEmpty;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BrowseExerciseDetailScreen(exercise: ex))),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: thumbnailUrl != null
                      ? CachedNetworkImage(
                          imageUrl: thumbnailUrl,
                          fit: BoxFit.cover,
                          errorWidget: (_, __, ___) => _placeholder(),
                        )
                      : _placeholder(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ex['exercise_name'] ?? '',
                      style: const TextStyle(color: Colors.black87, fontSize: 14, fontWeight: FontWeight.w600),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (_difficultyColors[difficulty] ?? Colors.grey).withOpacity(0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            _difficultyLabels[difficulty] ?? 'Beginner',
                            style: TextStyle(color: _difficultyColors[difficulty] ?? Colors.grey, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (hasVideo) ...[
                          const SizedBox(width: 6),
                          Icon(Icons.play_circle_outline, size: 14, color: Colors.grey[400]),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: Colors.grey[100],
        child: Icon(Icons.medical_services_outlined, color: Colors.grey[400], size: 22),
      );
}
