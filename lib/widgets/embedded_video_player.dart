// lib/widgets/embedded_video_player.dart
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

/// Plays a hosted video file (e.g. a Supabase Storage URL) embedded
/// in-app. Used both on the dashboard's prescribed-exercise cards (in
/// place of the step-image slideshow) and the exercise library's browse
/// detail screen -- kept as one shared widget so a fix/tweak here covers
/// both instead of two copies drifting apart.
class EmbeddedVideoPlayer extends StatefulWidget {
  final String url;
  final double height;
  const EmbeddedVideoPlayer({super.key, required this.url, required this.height});

  @override
  State<EmbeddedVideoPlayer> createState() => _EmbeddedVideoPlayerState();
}

class _EmbeddedVideoPlayerState extends State<EmbeddedVideoPlayer> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final controller = VideoPlayerController.networkUrl(Uri.parse(widget.url));
    try {
      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }
      setState(() {
        _videoController = controller;
        _chewieController = ChewieController(
          videoPlayerController: controller,
          // Never autoplay -- a patient scrolling/browsing shouldn't get
          // sound/data usage they didn't ask for.
          autoPlay: false,
          looping: false,
          aspectRatio: controller.value.aspectRatio,
          materialProgressColors: ChewieProgressColors(
            playedColor: const Color(0xFF0A6EBD),
            handleColor: const Color(0xFF0A6EBD),
            bufferedColor: Colors.grey[300]!,
            backgroundColor: Colors.grey[200]!,
          ),
          placeholder: Container(color: Colors.grey[100]),
          errorBuilder: (_, __) => _errorPlaceholder(),
        );
        _loading = false;
      });
    } catch (_) {
      controller.dispose();
      if (mounted) {
        setState(() {
          _loading = false;
          _failed = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  Widget _errorPlaceholder() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: Colors.grey[400], size: 32),
            const SizedBox(height: 6),
            Text('Could not load video', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: double.infinity,
        height: widget.height,
        child: _loading
            ? Container(color: Colors.grey[100], child: const Center(child: CircularProgressIndicator(strokeWidth: 2)))
            : (_failed || _chewieController == null)
                ? _errorPlaceholder()
                : Chewie(controller: _chewieController!),
      ),
    );
  }
}
