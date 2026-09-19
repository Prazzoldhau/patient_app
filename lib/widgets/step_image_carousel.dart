// lib/widgets/step_image_carousel.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

/// Slideshow of a physio's (or the library's) step-by-step exercise
/// photos -- swipe, prev/next buttons, and an auto-play button that plays
/// through once and stops on the last frame. Used on the dashboard's
/// prescribed-exercise cards and the exercise library's browse detail
/// screen, kept as one shared widget so both get the same experience.
///
/// Takes plain maps (`{'image_url': ..., 'label': ..., 'order': ...}`,
/// matching the API's own step_images shape) rather than a shared model
/// class, so this doesn't couple to either screen's own Exercise model --
/// deliberate, since the dashboard's prescribed-exercise ids and the
/// library's browse ids are different id spaces that shouldn't be mixed
/// through a shared type.
class StepImageCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> images;
  final double height;

  const StepImageCarousel({super.key, required this.images, required this.height});

  @override
  State<StepImageCarousel> createState() => _StepImageCarouselState();
}

class _StepImageCarouselState extends State<StepImageCarousel> {
  int _currentPage = 0;
  Timer? _autoPlayTimer;
  bool _isPlaying = false;
  bool _precached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Preload every step image up front so switching between them (via
    // swipe, buttons, or auto-play) always finds the image already
    // decoded and in cache. Without this, the image still has to fetch
    // over the network on first display, so by the time it's actually
    // ready to paint the fade-in animation has already finished and the
    // image just pops in instead of fading.
    if (!_precached) {
      _precached = true;
      for (final img in widget.images) {
        final url = img['image_url'] as String?;
        if (url != null && url.isNotEmpty) {
          precacheImage(CachedNetworkImageProvider(url), context);
        }
      }
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    super.dispose();
  }

  void _stopAutoPlay() {
    _autoPlayTimer?.cancel();
    _autoPlayTimer = null;
    if (_isPlaying) setState(() => _isPlaying = false);
  }

  void _togglePlay() {
    if (_isPlaying) {
      _stopAutoPlay();
      return;
    }
    setState(() {
      _isPlaying = true;
      // Restart from the beginning if Play is pressed while already on
      // the last frame, so there's something to actually play through.
      if (_currentPage >= widget.images.length - 1) _currentPage = 0;
    });
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      // Play through once and stop on the last frame instead of looping.
      if (_currentPage >= widget.images.length - 1) {
        _stopAutoPlay();
        return;
      }
      _advance(1);
    });
  }

  void _advance(int delta) {
    setState(() {
      _currentPage = (_currentPage + delta + widget.images.length) % widget.images.length;
    });
  }

  void _onManualNavigate(int delta) {
    _stopAutoPlay();
    _advance(delta);
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    final current = images[_currentPage];
    final currentUrl = current['image_url'] as String? ?? '';
    final currentLabel = current['label'] as String?;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: double.infinity,
            height: widget.height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: Colors.grey[100]),
                GestureDetector(
                  onHorizontalDragEnd: (details) {
                    final velocity = details.primaryVelocity ?? 0;
                    if (velocity < -200) {
                      _onManualNavigate(1); // swiped left -> next
                    } else if (velocity > 200) {
                      _onManualNavigate(-1); // swiped right -> previous
                    }
                  },
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    transitionBuilder: (child, animation) =>
                        FadeTransition(opacity: animation, child: child),
                    child: CachedNetworkImage(
                      imageUrl: currentUrl,
                      key: ValueKey(_currentPage),
                      fit: BoxFit.contain,
                      memCacheWidth: (MediaQuery.of(context).size.width * MediaQuery.of(context).devicePixelRatio).round(),
                      // The outer AnimatedSwitcher already cross-fades between
                      // step images, so skip this widget's own fade-in to
                      // avoid animating twice.
                      fadeInDuration: Duration.zero,
                      placeholder: (_, __) => Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.grey[400]),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Center(
                        child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 6,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _carouselButton(Icons.chevron_left, () => _onManualNavigate(-1)),
                  ),
                ),
                Positioned(
                  right: 6,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: _carouselButton(Icons.chevron_right, () => _onManualNavigate(1)),
                  ),
                ),
                Positioned(
                  right: 6,
                  bottom: 6,
                  child: _carouselButton(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    _togglePlay,
                    small: true,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),

        // Dot indicator + step label
        Row(
          children: [
            ...List.generate(images.length, (i) {
              final isActive = i == _currentPage;
              return Container(
                margin: const EdgeInsets.only(right: 4),
                width: isActive ? 8 : 6,
                height: isActive ? 8 : 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isActive ? Colors.green[700] : Colors.grey[300],
                ),
              );
            }),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Step ${_currentPage + 1} of ${images.length}'
                '${(currentLabel != null && currentLabel.trim().isNotEmpty) ? ' — $currentLabel' : ''}',
                style: TextStyle(color: Colors.grey[700], fontSize: 12),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _carouselButton(IconData icon, VoidCallback onTap, {bool small = false}) {
    // Deliberately still a dark scrim, unlike the rest of the app -- this
    // overlays directly on top of a photo of unpredictable content/color,
    // so it needs guaranteed contrast rather than following the light
    // theme (same reasoning as the QR scanner overlays).
    final size = small ? 30.0 : 36.0;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.45),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: small ? 18 : 22),
      ),
    );
  }
}
