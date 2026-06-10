import 'package:flutter/material.dart';
import '../../../core/logger.dart';
import '../../../core/theme.dart';
import '../../../core/date_utils.dart';
import '../../../shared/models/meal_plan.dart';
import '../../../shared/widgets/meal_card.dart';

class MealPlannerDayRow extends StatelessWidget {
  final DateTime date;
  final List<MealPlanEntry> entries;
  final Function(String entryId)? onRecipeTap;
  final Function(String entryId)? onConsumedToggle;

  const MealPlannerDayRow({
    super.key,
    required this.date,
    required this.entries,
    this.onRecipeTap,
    this.onConsumedToggle,
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
          _buildMealList(context),
        ],
      ),
    );
  }

  Widget _buildMealList(BuildContext context) {
    final isFuture = isFutureMeal(date);
    if (isFuture) {
      appLogger.provider('MealPlannerDayRow | future date guard | date: $_formattedDate | toggle hidden');
    }
    return SizedBox(
      height: 270,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: entries.length,
        clipBehavior: Clip.none,
        itemBuilder: (context, index) {
          final entry = entries[index];
          return AkeliMealCard(
            title: entry.recipeTitle ?? '',
            mealType: entry.mealType,
            calories: entry.calories,
            duration: entry.totalTimeMin,
            imageUrl: entry.recipeThumbnail,
            isPlanner: true,
            isConsumed: entry.isConsumed,
            onTap: () {
              appLogger.userAction('Meal plan entry tapped', screen: 'MealPlannerDayRow', metadata: {'entryId': entry.id});
              onRecipeTap?.call(entry.id);
            },
            onConsumedToggle: isFuture
                ? null
                : () {
                    appLogger.userAction('Meal card consumed toggle', screen: 'MealPlannerDayRow', metadata: {'entryId': entry.id, 'wasConsumed': entry.isConsumed});
                    onConsumedToggle?.call(entry.id);
                  },
          );
        },
      ),
    );
  }
}


