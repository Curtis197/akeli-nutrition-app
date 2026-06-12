import 'package:flutter/material.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/shared/widgets/badge.dart';

// ---------------------------------------------------------------------------
// AkeliRecipeCard — two variants: image (default) and text-only
// ---------------------------------------------------------------------------

class AkeliRecipeCard extends StatelessWidget {
  final String title;
  final int? calories100g;
  final double rating;
  final int likes;
  final int comments;
  final int saves;
  final String? emoji;
  final String? region;
  final List<String> tags;
  final String? imageUrl;
  final bool hasImage;
  final bool isMinimalist;
  final bool horizontal;
  final VoidCallback? onTap;

  const AkeliRecipeCard({
    super.key,
    required this.title,
    this.calories100g,
    required this.rating,
    required this.likes,
    required this.comments,
    required this.saves,
    this.emoji,
    this.region,
    this.imageUrl,
    this.tags = const [],
    this.hasImage = true,
    this.isMinimalist = false,
    this.horizontal = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AkeliColors.surface, // Pure white
          borderRadius: BorderRadius.circular(AkeliRadius.xl), // organic radius (24px)
          border: Border.all(color: AkeliColors.outlineVariant.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: horizontal
            ? _HorizontalVariant(card: this)
            : hasImage
                ? _ImageVariant(card: this)
                : _TextVariant(card: this),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Image variant
// ---------------------------------------------------------------------------

class _ImageVariant extends StatelessWidget {
  final AkeliRecipeCard card;

  const _ImageVariant({required this.card});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Image area — expands to fill whatever height remains after the body
        Expanded(
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AkeliRadius.xl),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  color: AkeliColors.surfaceContainerHigh,
                  child: card.imageUrl != null
                      ? Image.network(card.imageUrl!, fit: BoxFit.cover)
                      : Center(
                          child: Text(
                            card.emoji ?? '🥘',
                            style: const TextStyle(fontSize: 40),
                          ),
                        ),
                ),
              if (!card.isMinimalist && card.tags.isNotEmpty)
                Positioned(
                  top: AkeliSpacing.sm,
                  left: AkeliSpacing.sm,
                  child: Wrap(
                    spacing: AkeliSpacing.xs,
                    children: card.tags
                        .take(2)
                        .map((tag) => AkeliBadge(
                              label: tag,
                              color: AkeliColors.primary,
                            ))
                        .toList(),
                  ),
                ),
            ],
          ),
        ),
        ),
        // Body
        Padding(
          padding: const EdgeInsets.all(AkeliSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                card.title,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AkeliColors.onSurface,
                  fontSize: card.isMinimalist ? 15 : 14,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (card.isMinimalist && card.calories100g != null) ...[
                const SizedBox(height: 4),
                Text(
                  '${card.calories100g} kcal/100g',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AkeliColors.onSurfaceVariant.withValues(alpha: 0.6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (!card.isMinimalist && card.region != null) ...[
                const SizedBox(height: 4),
                Text(
                  card.region!,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AkeliColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (!card.isMinimalist) ...[
                const SizedBox(height: 8),
                _StatsRow(card: card),
              ],
            ],
          ),
        ),
      ],
    );
  }
}


// ---------------------------------------------------------------------------
// Horizontal variant (single-column feed)
// ---------------------------------------------------------------------------

class _HorizontalVariant extends StatelessWidget {
  final AkeliRecipeCard card;

  const _HorizontalVariant({required this.card});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
              left: Radius.circular(AkeliRadius.xl),
            ),
            child: SizedBox(
              width: 120,
              child: card.imageUrl != null
                  ? Image.network(card.imageUrl!, fit: BoxFit.cover)
                  : Container(
                      color: AkeliColors.surfaceContainerHigh,
                      child: Center(
                        child: Text(
                          card.emoji ?? '🥘',
                          style: const TextStyle(fontSize: 36),
                        ),
                      ),
                    ),
            ),
          ),
          // Content
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AkeliSpacing.md,
                vertical: AkeliSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (card.region != null)
                    Text(
                      card.region!,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AkeliColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 4),
                  Text(
                    card.title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AkeliColors.onSurface,
                          fontSize: 14,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  _StatsRow(card: card),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Text-only variant
// ---------------------------------------------------------------------------

class _TextVariant extends StatelessWidget {
  final AkeliRecipeCard card;

  const _TextVariant({required this.card});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            card.title,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AkeliSpacing.sm),
          _StatsRow(card: card, centered: true),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Stats row (shared)
// ---------------------------------------------------------------------------

class _StatsRow extends StatelessWidget {
  final AkeliRecipeCard card;
  final bool centered;

  const _StatsRow({required this.card, this.centered = false});

  @override
  Widget build(BuildContext context) {
    final align = centered ? MainAxisAlignment.center : MainAxisAlignment.start;
    return Column(
      crossAxisAlignment:
          centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (card.calories100g != null) ...[
          Text(
            '${card.calories100g} kcal/100g',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AkeliColors.secondary,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: 4),
        ],
        Row(
          mainAxisAlignment: align,
          children: [
            const Icon(Icons.star_rounded, size: 12, color: AkeliColors.secondary),
            const SizedBox(width: 2),
            Text(
              card.rating.toStringAsFixed(1),
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(width: 8),
            const Icon(Icons.favorite_border, size: 14, color: AkeliColors.primary),
            const SizedBox(width: 2),
            Text(
              '${card.likes}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(width: AkeliSpacing.xs),
            const Icon(Icons.chat_bubble_outline, size: 14, color: AkeliColors.primary),
            const SizedBox(width: 2),
            Text(
              '${card.comments}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
            const SizedBox(width: AkeliSpacing.xs),
            const Icon(Icons.bookmark_border, size: 14, color: AkeliColors.primary),
            const SizedBox(width: 2),
            Text(
              '${card.saves}',
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ],
    );
  }
}
