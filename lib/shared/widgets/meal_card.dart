import 'package:flutter/material.dart';
import 'package:akeli/core/theme.dart';

// ---------------------------------------------------------------------------
// AkeliMealCard - Digital Editorial Style
// ---------------------------------------------------------------------------
// Used in the Dashboard for "Vos repas du jour".
// Features high-fidelity imagery, a meal type badge, and metadata.
// ---------------------------------------------------------------------------

class AkeliMealCard extends StatelessWidget {
  final String title;
  final String mealType;
  final double calories;
  final double? protein;
  final double? carbs;
  final double? fat;
  final int? duration; // in minutes
  final String? imageUrl;
  final VoidCallback? onTap;

  const AkeliMealCard({
    super.key,
    required this.title,
    required this.mealType,
    required this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.duration,
    this.imageUrl,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280, // Match min-w-[280px] from mockup
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AkeliColors.surfaceContainerLowest, // Pure white
          borderRadius: BorderRadius.circular(24), // XL Radius
          border: Border.all(color: AkeliColors.outlineVariant.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── IMAGE AREA ───────────────────────────────────────────────────
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: imageUrl != null && imageUrl!.isNotEmpty
                      ? Image.network(
                          imageUrl!,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => const _PlaceholderImage(),
                        )
                      : const _PlaceholderImage(),
                ),
                // Meal Type Badge (Top-Right)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      mealType.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AkeliColors.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // ── CONTENT AREA ─────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AkeliColors.onSurface,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  // Macros Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _MacroItem(label: 'Prot', value: protein),
                      _MacroItem(label: 'Gluc', value: carbs),
                      _MacroItem(label: 'Lip', value: fat),
                      _MacroItem(label: 'Kcal', value: calories, isKcal: true),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Metadata Row
                  Row(
                    children: [
                      if (duration != null) ...[
                        const Icon(Icons.schedule_rounded, size: 14, color: AkeliColors.outline),
                        const SizedBox(width: 4),
                        Text(
                          '$duration min',
                          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AkeliColors.onSurfaceVariant,
                            fontSize: 11,
                          ),
                        ),
                        const SizedBox(width: 12),
                      ],
                      const Icon(Icons.local_fire_department_rounded, size: 14, color: AkeliColors.outline),
                      const SizedBox(width: 4),
                      Text(
                        '${calories.toInt()} kcal',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AkeliColors.onSurfaceVariant,
                          fontSize: 11,
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
    );
  }
}

class _MacroItem extends StatelessWidget {
  final String label;
  final double? value;
  final bool isKcal;

  const _MacroItem({required this.label, this.value, this.isKcal = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AkeliColors.outline,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value != null ? (isKcal ? value!.toInt().toString() : '${value!.toInt()}g') : '-',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: AkeliColors.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  const _PlaceholderImage();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      width: double.infinity,
      color: AkeliColors.surfaceContainerHigh,
      child: const Icon(Icons.restaurant_menu, color: AkeliColors.outline, size: 48),
    );
  }
}
