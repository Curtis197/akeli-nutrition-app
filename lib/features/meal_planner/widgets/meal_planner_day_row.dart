import 'package:flutter/material.dart';
import '../../../core/logger.dart';
import '../../../core/theme.dart';
import '../../../shared/models/meal_plan.dart';

class MealPlannerDayRow extends StatelessWidget {
  final DateTime date;
  final List<MealPlanEntry> entries;
  final Function(String recipeId)? onRecipeTap;

  const MealPlannerDayRow({
    super.key,
    required this.date,
    required this.entries,
    this.onRecipeTap,
  });

  static const _dayNames = [
    'lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi', 'dimanche'
  ];
  
  static const _monthNames = [
    '', 'janvier', 'février', 'mars', 'avril', 'mai', 'juin', 
    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'
  ];

  String get _formattedDate {
    return '${_dayNames[date.weekday - 1]} ${date.day} ${_monthNames[date.month]}';
  }

  double get _totalCalories {
    return entries.fold(0.0, (sum, e) => sum + e.calories);
  }

  @override
  Widget build(BuildContext context) {
    appLogger.provider('MealPlannerDayRow build() | date: $_formattedDate | entries: ${entries.length}');
    return Padding(
      padding: const EdgeInsets.only(bottom: 40.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  _formattedDate,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: AkeliColors.accentAmber,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${_totalCalories.toInt()} kcal',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AkeliColors.accentAmber,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Horizontal Meal List
          SizedBox(
            height: 260,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: entries.length,
              clipBehavior: Clip.none,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return _PlannerMealCard(
                  entry: entry,
                  onTap: () {
                    if (entry.recipeId != null) {
                      appLogger.userAction('Meal plan recipe tapped', screen: 'MealPlannerDayRow', metadata: {'recipeId': entry.recipeId});
                      onRecipeTap?.call(entry.recipeId!);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PlannerMealCard extends StatelessWidget {
  final MealPlanEntry entry;
  final VoidCallback onTap;

  const _PlannerMealCard({required this.entry, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 280,
        margin: const EdgeInsets.only(right: 16),
        decoration: BoxDecoration(
          color: AkeliColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AkeliColors.outlineVariant.withValues(alpha: 0.2)),
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
            SizedBox(
              height: 160,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: entry.recipeThumbnail != null
                        ? Image.network(entry.recipeThumbnail!, fit: BoxFit.cover)
                        : Container(color: AkeliColors.surfaceContainerHigh),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        (entry.mealType == 'breakfast' ? 'PETIT DÉJEUNER' : 'DÉJEUNER').toUpperCase(),
                        style: const TextStyle(
                          color: AkeliColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.recipeTitle ?? '',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 18,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.schedule, size: 16, color: AkeliColors.onSurfaceVariant),
                      const SizedBox(width: 4),
                      const Text('20 min', style: TextStyle(fontSize: 12, color: AkeliColors.onSurfaceVariant)),
                      const SizedBox(width: 16),
                      const Icon(Icons.local_fire_department, size: 16, color: AkeliColors.accentAmber),
                      const SizedBox(width: 4),
                      Text('${entry.calories.toInt()} kcal', style: const TextStyle(fontSize: 12, color: AkeliColors.onSurfaceVariant)),
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

