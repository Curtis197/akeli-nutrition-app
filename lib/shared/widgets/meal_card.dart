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
  final bool isPlanner;
  final bool isConsumed;
  final VoidCallback? onTap;
  final VoidCallback? onConsumedToggle;

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
    this.isPlanner = false,
    this.isConsumed = false,
    this.onTap,
    this.onConsumedToggle,
  });

  String get _mealTypeEmoji {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return '☀️';
      case 'lunch':
        return '🍔';
      case 'dinner':
        return '🌙';
      case 'snack':
        return '🍎';
      default:
        return '🍴';
    }
  }

  String get _mealTypeLabel {
    switch (mealType.toLowerCase()) {
      case 'breakfast':
        return 'Petit-Déjeuner';
      case 'lunch':
        return 'Déjeuner';
      case 'dinner':
        return 'Dîner';
      case 'snack':
        return 'Collation';
      default:
        return mealType;
    }
  }

  Widget _buildPlaceholderImage(double height) {
    return Container(
      height: height,
      width: double.infinity,
      color: AkeliColors.surfaceContainerHigh,
      child: const Icon(Icons.restaurant_menu, color: AkeliColors.outline, size: 48),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isPlanner) {
      return _buildPlannerCard(context);
    } else {
      return _buildDashboardCard(context);
    }
  }

  Widget _buildPlannerCard(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AkeliRadius.xl),
          border: Border.all(
            color: AkeliColors.outlineVariant.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AkeliRadius.xl)),
                  child: imageUrl != null && imageUrl!.isNotEmpty
                      ? Image.network(
                          imageUrl!,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholderImage(160),
                        )
                      : _buildPlaceholderImage(160),
                ),
                // Meal Type Badge
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(AkeliRadius.md),
                    ),
                    child: Text(
                      _mealTypeLabel.toUpperCase(),
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AkeliColors.primary,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                // Consumption Checkbox
                Positioned(
                  top: 12,
                  left: 12,
                  child: GestureDetector(
                    onTap: onConsumedToggle,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isConsumed ? AkeliColors.success : Colors.white.withValues(alpha: 0.8),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: isConsumed
                          ? const Icon(Icons.check, size: 18, color: Colors.white)
                          : null,
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AkeliColors.onSurface,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 16, color: AkeliColors.outline),
                      const SizedBox(width: 4),
                      Text(
                        '${duration ?? 20} min',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AkeliColors.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(Icons.local_fire_department, size: 16, color: AkeliColors.outline),
                      const SizedBox(width: 4),
                      Text(
                        '${calories.toInt()} kcal',
                        style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: AkeliColors.onSurfaceVariant,
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

  Widget _buildDashboardCard(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
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
                          errorBuilder: (_, __, ___) => _buildPlaceholderImage(160),
                        )
                      : _buildPlaceholderImage(160),
                ),
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
                      _mealTypeLabel.toUpperCase(),
                      style: const TextStyle(
                        color: AkeliColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: AkeliColors.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _MacroItem(label: 'Prot', value: protein),
                      _MacroItem(label: 'Gluc', value: carbs),
                      _MacroItem(label: 'Lip', value: fat),
                      _MacroItem(label: 'Kcal', value: calories, isKcal: true),
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
          style: const TextStyle(
            color: AkeliColors.outline,
            fontSize: 9,
            fontWeight: FontWeight.w600,
          ),
        ),
        Text(
          value != null ? (isKcal ? value!.toInt().toString() : '${value!.toInt()}g') : '-',
          style: const TextStyle(
            color: AkeliColors.onSurface,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
