import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../core/logger.dart';
import '../../models/multimedia_models.dart';

final _logger = appLogger;

/// Widget to display a single recipe step with optional media
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
  @override
  Widget build(BuildContext context) {
    final instruction = widget.step.getInstruction(widget.langCode);
    final primaryMedia = widget.step.getPrimaryMedia();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: () {
          _logger.userAction('Step ${widget.stepIndex + 1} tapped', screen: 'RecipeStepCard');
          widget.onToggleExpand?.call();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 14,
                    child: Text('${widget.stepIndex + 1}', style: const TextStyle(fontSize: 12)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      instruction,
                      maxLines: widget.isExpanded ? null : 2,
                      overflow: widget.isExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
                    ),
                  ),
                  if (widget.step.duration != null)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Text(
                        '${widget.step.duration!.inMinutes}min',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
              if (widget.isExpanded && primaryMedia != null) ...[
                const SizedBox(height: 12),
                _buildMedia(primaryMedia),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedia(RecipeStepMedia media) {
    if (media.mediaType.isVideo) {
      // Video playback is not yet implemented — show placeholder
      return Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.black87,
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.play_circle_outline, color: Colors.white, size: 48),
              SizedBox(height: 8),
              Text('Vidéo', style: TextStyle(color: Colors.white70, fontSize: 13)),
            ],
          ),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: CachedNetworkImage(
        imageUrl: media.thumbnailUrl ?? media.mediaUrl,
        height: 180,
        width: double.infinity,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          height: 180,
          color: Colors.grey.shade200,
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (_, __, ___) => Container(
          height: 180,
          color: Colors.grey.shade200,
          child: const Icon(Icons.image_not_supported, color: Colors.grey),
        ),
      ),
    );
  }
}

/// Scrollable list of recipe steps
class RecipeStepsList extends StatefulWidget {
  final List<RecipeStep> steps;
  final String langCode;

  const RecipeStepsList({
    super.key,
    required this.steps,
    required this.langCode,
  });

  @override
  State<RecipeStepsList> createState() => _RecipeStepsListState();
}

class _RecipeStepsListState extends State<RecipeStepsList> {
  final Set<int> _expandedIndices = {0};

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: widget.steps.length,
      itemBuilder: (context, index) {
        return RecipeStepCard(
          step: widget.steps[index],
          langCode: widget.langCode,
          stepIndex: index,
          isExpanded: _expandedIndices.contains(index),
          onToggleExpand: () {
            setState(() {
              if (_expandedIndices.contains(index)) {
                _expandedIndices.remove(index);
              } else {
                _expandedIndices.add(index);
              }
            });
          },
        );
      },
    );
  }
}
