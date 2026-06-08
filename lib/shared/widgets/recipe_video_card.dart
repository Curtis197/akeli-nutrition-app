import 'package:akeli/core/logger.dart';
import 'package:akeli/core/theme.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class RecipeVideoCard extends StatefulWidget {
  final String videoUrl;
  final String? thumbnailUrl;

  const RecipeVideoCard({
    super.key,
    required this.videoUrl,
    this.thumbnailUrl,
  });

  @override
  State<RecipeVideoCard> createState() => _RecipeVideoCardState();
}

class _RecipeVideoCardState extends State<RecipeVideoCard> {
  final _logger = appLogger;
  late VideoPlayerController _videoController;
  ChewieController? _chewieController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _logger.provider(
        'RecipeVideoCard initState() | videoUrl: ${widget.videoUrl}');
    _initVideo();
  }

  Future<void> _initVideo() async {
    _videoController =
        VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    try {
      await _videoController.initialize();
      _chewieController = ChewieController(
        videoPlayerController: _videoController,
        autoPlay: false,
        looping: false,
        placeholder: widget.thumbnailUrl != null
            ? CachedNetworkImage(
                imageUrl: widget.thumbnailUrl!, fit: BoxFit.cover)
            : null,
      );
      _videoController.addListener(_onVideoEvent);
      if (mounted) {
        setState(() => _initialized = true);
        _logger.provider('RecipeVideoCard → initialized');
      }
    } catch (e, st) {
      _logger.edge('video-player', 'ERROR | init failed | ${widget.videoUrl}',
          error: e, stackTrace: st);
    }
  }

  void _onVideoEvent() {
    if (_videoController.value.isPlaying) {
      _logger.userAction('Recipe video playing', screen: 'RecipeVideoCard');
    }
  }

  @override
  void dispose() {
    _logger.provider('RecipeVideoCard disposed');
    _videoController.removeListener(_onVideoEvent);
    _chewieController?.dispose();
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    _logger.provider('RecipeVideoCard build()');
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AkeliColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AkeliRadius.xl),
          boxShadow: const [
            BoxShadow(
                color: Color(0x051B1C16),
                blurRadius: 12,
                offset: Offset(0, 4)),
          ],
        ),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: _initialized && _chewieController != null
              ? Chewie(controller: _chewieController!)
              : widget.thumbnailUrl != null
                  ? CachedNetworkImage(
                      imageUrl: widget.thumbnailUrl!,
                      fit: BoxFit.cover,
                      width: double.infinity,
                    )
                  : const Center(
                      child: CircularProgressIndicator(
                          color: AkeliColors.primary),
                    ),
        ),
      ),
    );
  }
}
