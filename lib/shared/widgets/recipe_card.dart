import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/theme.dart';
import '../../shared/models/recipe.dart';
import '../../features/recipes/domain/entities/recipe_tracking.dart';
import '../../features/recipes/presentation/providers/recipe_tracking_provider.dart';

class RecipeCard extends ConsumerStatefulWidget {
  final Recipe recipe;
  final VoidCallback? onTap;
  final VoidCallback? onLike;
  final bool compact;
  final TrackingSource source;

  const RecipeCard({
    super.key,
    required this.recipe,
    this.onTap,
    this.onLike,
    this.compact = false,
    this.source = TrackingSource.feed,
  });

  @override
  ConsumerState<RecipeCard> createState() => _RecipeCardState();
}

class _RecipeCardState extends ConsumerState<RecipeCard> {
  bool _impressionLogged = false;
  Timer? _visibilityTimer;

  @override
  void dispose() {
    _visibilityTimer?.cancel();
    super.dispose();
  }

  void _onVisibilityChanged(VisibilityInfo info) {
    if (info.visibleFraction >= 0.5 && !_impressionLogged) {
      _visibilityTimer ??= Timer(const Duration(seconds: 1), () {
        if (!_impressionLogged && mounted) {
          _impressionLogged = true;
          ref.read(recipeTrackingRepositoryProvider).trackImpression(
                recipeId: widget.recipe.id,
                source: widget.source,
              );
        }
      });
    } else if (info.visibleFraction < 0.5) {
      _visibilityTimer?.cancel();
      _visibilityTimer = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return VisibilityDetector(
      key: Key('recipe-card-${widget.recipe.id}'),
      onVisibilityChanged: _onVisibilityChanged,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              AspectRatio(
                aspectRatio: widget.compact ? 16 / 9 : 4 / 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (widget.recipe.thumbnailUrl != null)
                      CachedNetworkImage(
                        imageUrl: widget.recipe.thumbnailUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Container(color: Colors.white),
                        ),
                        errorWidget: (_, __, ___) => _PlaceholderImage(),
                      )
                    else
                      _PlaceholderImage(),
                    // Like button
                    Positioned(
                      top: AkeliSpacing.sm,
                      right: AkeliSpacing.sm,
                      child: _LikeButton(
                        isLiked: widget.recipe.isLiked,
                        onTap: widget.onLike,
                      ),
                    ),
                    // Duration badge
                    Positioned(
                      bottom: AkeliSpacing.sm,
                      left: AkeliSpacing.sm,
                      child: _DurationBadge(minutes: widget.recipe.totalTimeMin),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(AkeliSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.recipe.title,
                      style: textTheme.titleMedium,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!widget.compact) ...[
                      const SizedBox(height: AkeliSpacing.xs),
                      Row(
                        children: [
                          if (widget.recipe.calories != null) ...[
                            _MacroBadge(
                              label: '${widget.recipe.calories!.toInt()} kcal',
                              color: AkeliColors.secondary,
                            ),
                            const SizedBox(width: AkeliSpacing.xs),
                          ],
                          if (widget.recipe.proteinG != null)
                            _MacroBadge(
                              label: '${widget.recipe.proteinG!.toInt()}g prot.',
                              color: AkeliColors.primary,
                            ),
                          const Spacer(),
                          _DifficultyChip(difficulty: widget.recipe.difficulty),
                        ],
                      ),
                    ],
                    const SizedBox(height: AkeliSpacing.xs),
                    Row(
                      children: [
                        const Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: AkeliColors.secondary,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          widget.recipe.averageRating.toStringAsFixed(1),
                          style: textTheme.labelSmall,
                        ),
                        const SizedBox(width: AkeliSpacing.xs),
                        Text(
                          '(${widget.recipe.ratingCount})',
                          style: textTheme.labelSmall?.copyWith(
                            color: AkeliColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        color: AkeliColors.background,
        child: const Center(
          child: Icon(Icons.restaurant_rounded, size: 40, color: AkeliColors.primary),
        ),
      );
}

class _LikeButton extends StatelessWidget {
  final bool isLiked;
  final VoidCallback? onTap;

  const _LikeButton({required this.isLiked, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
        ),
        child: Icon(
          isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          size: 18,
          color: isLiked ? Colors.red : AkeliColors.textSecondary,
        ),
      ),
    );
  }
}

class _DurationBadge extends StatelessWidget {
  final int minutes;

  const _DurationBadge({required this.minutes});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AkeliSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(AkeliRadius.full),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, size: 12, color: Colors.white),
          const SizedBox(width: 2),
          Text(
            minutes >= 60
                ? '${minutes ~/ 60}h${minutes % 60 > 0 ? '${minutes % 60}min' : ''}'
                : '${minutes}min',
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _MacroBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AkeliRadius.full),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _DifficultyChip extends StatelessWidget {
  final String difficulty;

  const _DifficultyChip({required this.difficulty});

  Color get _color {
    switch (difficulty) {
      case 'easy':
        return AkeliColors.success;
      case 'medium':
        return AkeliColors.secondary;
      case 'hard':
        return AkeliColors.error;
      default:
        return AkeliColors.textSecondary;
    }
  }

  String get _label {
    switch (difficulty) {
      case 'easy':
        return 'Facile';
      case 'medium':
        return 'Moyen';
      case 'hard':
        return 'Difficile';
      default:
        return difficulty;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AkeliRadius.full),
      ),
      child: Text(
        _label,
        style: TextStyle(
          fontSize: 11,
          color: _color,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Skeleton loader for RecipeCard
// ---------------------------------------------------------------------------

class RecipeCardSkeleton extends StatelessWidget {
  const RecipeCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Card(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 4 / 3,
              child: Container(color: Colors.white),
            ),
            Padding(
              padding: const EdgeInsets.all(AkeliSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 12,
                    width: 120,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
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
}
