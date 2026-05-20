import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:photo_view/photo_view.dart';
import '../models/multimedia_models.dart';

/// Widget to display a single recipe step with media
class RecipeStepCard extends StatefulWidget {
  final RecipeStep step;
  final String langCode;
  final int stepIndex;
  final bool isExpanded;
  final VoidCallback? onToggleExpand;

  const RecipeStepCard({
    super.key,
    required this.step,
    required this.langCode,
    required this.stepIndex,
    this.isExpanded = true,
    this.onToggleExpand,
  });

  @override
  State<RecipeStepCard> createState() => _RecipeStepCardState();
}

class _RecipeStepCardState extends State<RecipeStepCard> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  int _currentMediaIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeMedia();
  }

  @override
  void didUpdateWidget(RecipeStepCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.step.id != widget.step.id) {
      _disposeVideo();
      _initializeMedia();
    }
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  void _disposeVideo() {
    _videoController?.dispose();
    _chewieController?.dispose();
    _videoController = null;
    _chewieController = null;
  }

  void _initializeMedia() {
    if (widget.step.media.isEmpty) return;

    final media = widget.step.media[_currentMediaIndex];
    if (media.mediaType.isVideo && media.mediaUrl.isNotEmpty) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(media.mediaUrl))
        ..initialize().then((_) {
          if (mounted) setState(() {});
        });
      
      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: false,
        looping: false,
        showControlsOnInitialize: true,
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final instruction = widget.step.getInstruction(widget.langCode);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Step header
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      '${widget.stepIndex}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Step $widget.stepIndex',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (widget.step.media.length > 1)
                  _buildMediaIndicator(),
              ],
            ),
          ),

          // Media section
          if (widget.step.media.isNotEmpty) ...[
            _buildMediaSection(),
          ],

          // Instruction text
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              instruction,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.6,
              ),
            ),
          ),

          // Duration badge if available
          if (widget.step.duration != null) ...[
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 16),
              child: Chip(
                avatar: const Icon(Icons.access_time, size: 18),
                label: Text(_formatDuration(widget.step.duration!)),
                backgroundColor: theme.colorScheme.surfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMediaSection() {
    if (widget.step.media.isEmpty) return const SizedBox.shrink();

    final media = widget.step.media[_currentMediaIndex];

    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: GestureDetector(
              onTap: media.mediaType.isImage
                  ? () => _showFullScreenImage(media.mediaUrl)
                  : null,
              child: _buildCurrentMedia(media),
            ),
          ),
        ),
        
        // Gradient overlay at bottom for better text readability
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.6),
                ],
              ),
            ),
          ),
        ),

        // Alt text or caption
        if (media.altText != null)
          Positioned(
            left: 16,
            right: 16,
            bottom: 12,
            child: Text(
              media.altText!,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
      ],
    );
  }

  Widget _buildCurrentMedia(RecipeStepMedia media) {
    if (media.mediaType.isVideo) {
      if (_chewieController == null) {
        return Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      return Chewie(controller: _chewieController!);
    } else {
      // Image
      return CachedNetworkImage(
        imageUrl: media.mediaUrl,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey.shade200,
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image, size: 64),
        ),
      );
    }
  }

  Widget _buildMediaIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        widget.step.media.length,
        (index) => Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: index == _currentMediaIndex
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }

  void _showFullScreenImage(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: PhotoView(
            imageProvider: CachedNetworkImageProvider(imageUrl),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
          ),
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inMinutes < 60) {
      return '${duration.inMinutes} min';
    } else {
      final hours = duration.inHours;
      final minutes = duration.inMinutes % 60;
      return minutes > 0 ? '$hours h $minutes min' : '$hours h';
    }
  }
}

/// Full recipe steps list widget
class RecipeStepsList extends StatelessWidget {
  final List<RecipeStep> steps;
  final String langCode;

  const RecipeStepsList({
    super.key,
    required this.steps,
    required this.langCode,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: steps.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        return RecipeStepCard(
          step: steps[index],
          langCode: langCode,
          stepIndex: index + 1,
        );
      },
    );
  }
}

/// Widget for uploading media to a recipe step (for recipe creators)
class StepMediaUploader extends StatefulWidget {
  final String stepId;
  final Function(String mediaUrl, MediaType type)? onUploadComplete;

  const StepMediaUploader({
    super.key,
    required this.stepId,
    this.onUploadComplete,
  });

  @override
  State<StepMediaUploader> createState() => _StepMediaUploaderState();
}

class _StepMediaUploaderState extends State<StepMediaUploader> {
  bool _isUploading = false;

  Future<void> _uploadMedia(MediaType mediaType) async {
    // This would integrate with MediaUploadService
    // Implementation depends on the actual service setup
    setState(() => _isUploading = true);
    
    // Placeholder - actual implementation in MediaUploadService
    await Future.delayed(const Duration(seconds: 2));
    
    setState(() => _isUploading = false);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload not yet implemented')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ElevatedButton.icon(
          onPressed: _isUploading ? null : () => _uploadMedia(MediaType.image),
          icon: const Icon(Icons.photo_camera),
          label: const Text('Add Photo'),
        ),
        const SizedBox(width: 12),
        ElevatedButton.icon(
          onPressed: _isUploading ? null : () => _uploadMedia(MediaType.video),
          icon: const Icon(Icons.videocam),
          label: const Text('Add Video'),
        ),
        if (_isUploading) ...[
          const SizedBox(width: 12),
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ],
      ],
    );
  }
}
