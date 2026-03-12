import 'package:flutter/material.dart';
import 'package:akeli/core/theme.dart';

// ---------------------------------------------------------------------------
// AkeliMealCard
// ---------------------------------------------------------------------------

class AkeliMealCard extends StatelessWidget {
  final String title;
  final String mealType;
  final int calories;
  final String? emoji;
  final VoidCallback? onTap;

  const AkeliMealCard({
    super.key,
    required this.title,
    required this.mealType,
    required this.calories,
    this.emoji,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        margin: const EdgeInsets.symmetric(horizontal: AkeliSpacing.sm),
        decoration: BoxDecoration(
          color: AkeliColors.surface,
          borderRadius: BorderRadius.circular(AkeliRadius.lg),
          boxShadow: const [AkeliShadows.sm],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Emoji/image area
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AkeliRadius.lg),
              ),
              child: Container(
                height: 80,
                width: double.infinity,
                color: const Color(0xFFF0F0F0),
                child: Center(
                  child: Text(
                    emoji ?? '',
                    style: const TextStyle(fontSize: 36),
                  ),
                ),
              ),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AkeliColors.textPrimary,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AkeliSpacing.xs),
                  Text(
                    '$calories kcal',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AkeliColors.secondary,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    mealType,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AkeliColors.tertiary,
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
