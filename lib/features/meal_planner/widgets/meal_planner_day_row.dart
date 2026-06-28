import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/logger.dart';
import '../../../core/theme.dart';
import '../../../core/date_utils.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/meal_plan.dart';
import '../../../shared/widgets/meal_card.dart';

class MealPlannerDayRow extends StatelessWidget {
  final DateTime date;
  final List<MealPlanEntry> entries;
  final Function(String entryId)? onRecipeTap;
  final Function(String entryId)? onConsumedToggle;
  final VoidCallback? onAddSnack;

  const MealPlannerDayRow({
    super.key,
    required this.date,
    required this.entries,
    this.onRecipeTap,
    this.onConsumedToggle,
    this.onAddSnack,
  });

  double get _totalCalories {
    return entries.fold(0.0, (sum, e) => sum + e.calories);
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).languageCode;
    final formattedDate = DateFormat('EEEE d MMMM', locale).format(date);
    appLogger.provider('MealPlannerDayRow build() | date: $formattedDate | entries: ${entries.length}');
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
                  formattedDate,
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
          _buildMealList(context, locale),
          const SizedBox(height: 12),
          _buildAddSnackButton(context),
        ],
      ),
    );
  }

  Widget _buildAddSnackButton(BuildContext context) {
    final hasSnack = entries.any((e) => e.mealType == 'snack');
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: OutlinedButton.icon(
        onPressed: onAddSnack,
        icon: const Icon(Icons.add, size: 16),
        label: Text(hasSnack ? AppLocalizations.of(context).mealPlannerAddAnotherSnack : AppLocalizations.of(context).mealPlannerAddSnack),
        style: OutlinedButton.styleFrom(
          foregroundColor: AkeliColors.primary,
          side: BorderSide(color: AkeliColors.primary.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AkeliRadius.md)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildMealList(BuildContext context, String locale) {
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
          final isFuture = isFutureMeal(entry.scheduledDate);
          if (isFuture) {
            appLogger.provider('MealPlannerDayRow | future date guard | entryId: ${entry.id} | scheduledDate: ${entry.scheduledDate}');
          }
          return AkeliMealCard(
            title: entry.localizedTitle(locale) ?? entry.displayLabel(AppLocalizations.of(context)),
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


