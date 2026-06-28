import 'package:flutter/material.dart';
import 'package:akeli/core/logger.dart';
import 'package:akeli/core/meal_type_l10n.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// AkeliMealCard - Digital Editorial Style
// ---------------------------------------------------------------------------
// Used in the Dashboard for "Vos repas du jour".
// Features high-fidelity imagery, a meal type badge, and metadata.
// ---------------------------------------------------------------------------

final _logger = appLogger;

class AkeliMealCard extends StatelessWidget {
  final String title;
  final String mealType;
  final double calories;
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
    this.duration,
    this.imageUrl,
    this.isPlanner = false,
    this.isConsumed = false,
    this.onTap,
    this.onConsumedToggle,
  });


  Color get _mealTypeColor {
    switch (mealType.toLowerCase()) {
      case 'breakfast': return const Color(0xFFF59E0B);
      case 'lunch':     return const Color(0xFF22C55E);
      case 'dinner':    return const Color(0xFF6366F1);
      case 'snack':     return const Color(0xFFA855F7);
      default:          return AkeliColors.primary;
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
    _logger.provider(
      'AkeliMealCard build() | title: "$title" | mealType: $mealType | '
      'calories: ${calories.toInt()} | isConsumed: $isConsumed | variant: ${isPlanner ? "planner" : "dashboard"}',
    );
    if (isPlanner) {
      return _buildPlannerCard(context);
    } else {
      return _buildDashboardCard(context);
    }
  }

  Widget _buildPlannerCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: onTap == null ? null : () {
        _logger.userAction('Meal card tapped', screen: 'AkeliMealCard',
            metadata: {'title': title, 'mealType': mealType, 'variant': 'planner'});
        onTap!();
      },
      child: Container(
        width: 300,
        height: 300,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              // Full-bleed Image
              imageUrl != null && imageUrl!.isNotEmpty
                  ? Image.network(
                      imageUrl!,
                      height: 300,
                      width: 300,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _buildPlaceholderImage(300),
                    )
                  : _buildPlaceholderImage(300),

              // Gradient Overlay for better text readability
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.1),
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.7),
                      ],
                      stops: const [0.0, 0.5, 1.0],
                    ),
                  ),
                ),
              ),

              // Top Badges
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Consumption Toggle
                    if (onConsumedToggle != null)
                      GestureDetector(
                        onTap: () {
                          _logger.userAction('Consumed toggle tapped', screen: 'AkeliMealCard',
                              metadata: {'title': title, 'wasConsumed': isConsumed, 'variant': 'planner'});
                          onConsumedToggle!();
                        },
                        child: Container(
                          key: const Key('consumed-toggle'),
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: isConsumed ? AkeliColors.success : Colors.white.withValues(alpha: 0.8),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: isConsumed
                              ? const Icon(Icons.check, size: 20, color: Colors.white)
                              : null,
                        ),
                      )
                    else
                      const SizedBox(width: 32, height: 32),
                    // Meal Type Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _mealTypeColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        mealTypeLabel(l10n, mealType).toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 10,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Content
              Positioned(
                bottom: 16,
                left: 16,
                right: 16,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontFamily: 'Outfit',
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.local_fire_department, size: 16, color: Color(0xFFEBA14D)),
                        const SizedBox(width: 4),
                        Text(
                          '${calories.toInt()} kcal',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.schedule, size: 16, color: Colors.white70),
                        const SizedBox(width: 4),
                        Text(
                          '${duration ?? 20} min',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
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

  Widget _buildDashboardCard(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return GestureDetector(
      onTap: onTap == null ? null : () {
        _logger.userAction('Meal card tapped', screen: 'AkeliMealCard',
            metadata: {'title': title, 'mealType': mealType, 'variant': 'dashboard'});
        onTap!();
      },
      child: Container(
        width: 300,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: isConsumed
              ? AkeliColors.surfaceContainerLowest
              : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isConsumed
                ? AkeliColors.success.withValues(alpha: 0.4)
                : AkeliColors.outlineVariant.withValues(alpha: 0.3),
          ),
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
                  child: ColorFiltered(
                    colorFilter: isConsumed
                        ? const ColorFilter.matrix([
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0,      0,      0,      1, 0,
                          ])
                        : const ColorFilter.mode(Colors.transparent, BlendMode.dst),
                    child: imageUrl != null && imageUrl!.isNotEmpty
                        ? Image.network(
                            imageUrl!,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholderImage(200),
                          )
                        : _buildPlaceholderImage(200),
                  ),
                ),
                // Meal type badge — top right
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: _mealTypeColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      mealTypeLabel(l10n, mealType).toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 10,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
                // Consumption toggle — top left
                Positioned(
                  top: 12,
                  left: 12,
                  child: GestureDetector(
                    onTap: onConsumedToggle == null ? null : () {
                      _logger.userAction('Consumed toggle tapped', screen: 'AkeliMealCard',
                          metadata: {'title': title, 'wasConsumed': isConsumed, 'variant': 'dashboard'});
                      onConsumedToggle!();
                    },
                    child: Container(
                      key: const Key('consumed-toggle-dashboard'),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isConsumed
                            ? AkeliColors.success
                            : Colors.white.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isConsumed
                              ? AkeliColors.success
                              : Colors.white,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.12),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
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
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      color: isConsumed
                          ? AkeliColors.onSurfaceVariant
                          : AkeliColors.onSurface,
                      decoration: isConsumed ? TextDecoration.lineThrough : null,
                      decorationColor: AkeliColors.onSurfaceVariant,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.local_fire_department,
                        size: 14,
                        color: isConsumed
                            ? AkeliColors.onSurfaceVariant.withValues(alpha: 0.5)
                            : const Color(0xFFEBA14D),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${calories.toInt()} kcal',
                        style: TextStyle(
                          color: isConsumed
                              ? AkeliColors.onSurfaceVariant.withValues(alpha: 0.5)
                              : AkeliColors.textSecondary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (isConsumed) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AkeliColors.success.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            l10n.nutritionConsumed,
                            style: const TextStyle(
                              color: AkeliColors.success,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
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

