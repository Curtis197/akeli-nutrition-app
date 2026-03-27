import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme.dart';
import '../../../shared/models/meal_plan.dart';
import '../../../shared/widgets/meal_card.dart';

class MealPlannerDayRow extends StatelessWidget {
  final DateTime date;
  final List<MealPlanEntry> entries;
  final Function(String entryId, bool isConsumed)? onConsumedToggle;
  final Function(String recipeId)? onRecipeTap;

  const MealPlannerDayRow({
    super.key,
    required this.date,
    required this.entries,
    this.onConsumedToggle,
    this.onRecipeTap,
  });

  static const _dayNames = [
    'Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'
  ];
  
  static const _monthNames = [
    '', 'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin', 
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
  ];

  String get _formattedDate {
    return '${_dayNames[date.weekday - 1]} ${date.day} ${_monthNames[date.month]}';
  }

  double get _totalCalories {
    return entries.fold(0.0, (sum, e) => sum + (e.calories ?? 0));
  }

  bool get _allConsumed {
    return entries.isNotEmpty && entries.every((e) => e.isConsumed);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formattedDate.toUpperCase(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AkeliColors.primary,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      '${_totalCalories.toInt()} kcal prévues',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AkeliColors.outline,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                _buildConsumptionToggle(context),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Horizontal Meal List
          SizedBox(
            height: 260, // Fixed height for the horizontal scroll
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                return AkeliMealCard(
                  title: entry.recipeTitle ?? 'Recette',
                  imageUrl: entry.recipeThumbnail,
                  mealType: entry.mealType,
                  calories: entry.calories ?? 0,
                  duration: 20,
                  isPlanner: true,
                  isConsumed: entry.isConsumed,
                  onTap: () => onRecipeTap?.call(entry.recipeId),
                  onConsumedToggle: () {
                    HapticFeedback.lightImpact();
                    onConsumedToggle?.call(entry.id, !entry.isConsumed);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsumptionToggle(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        // Logic to toggle all would go here or be passed down
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _allConsumed 
              ? AkeliColors.success.withValues(alpha: 0.1) 
              : AkeliColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AkeliRadius.pill),
          border: Border.all(
            color: _allConsumed ? AkeliColors.success : AkeliColors.outlineVariant,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _allConsumed ? Icons.check_circle : Icons.radio_button_unchecked,
              size: 16,
              color: _allConsumed ? AkeliColors.success : AkeliColors.outline,
            ),
            const SizedBox(width: 8),
            Text(
              'Tout consommé',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: _allConsumed ? AkeliColors.success : AkeliColors.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
