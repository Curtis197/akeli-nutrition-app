import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/date_utils.dart';
import '../../../core/logger.dart';
import '../../../core/theme.dart';
import '../../../l10n/app_localizations.dart';
import '../../../providers/meal_plan_provider.dart';
import '../../../providers/nutrition_plan_provider.dart';
import '../../../shared/models/meal_plan.dart';
import '../../../shared/widgets/meal_card.dart';
import '../meal_planner_actions.dart';
import 'meal_planner_day_recap_card.dart';
import 'meal_planner_day_selector.dart';

final _logger = appLogger;

class MealPlannerDayTabView extends ConsumerStatefulWidget {
  final MealPlan plan;
  final Function(String entryId)? onRecipeTap;

  const MealPlannerDayTabView({
    super.key,
    required this.plan,
    this.onRecipeTap,
  });

  @override
  ConsumerState<MealPlannerDayTabView> createState() => _MealPlannerDayTabViewState();
}

class _MealPlannerDayTabViewState extends ConsumerState<MealPlannerDayTabView> {
  DateTime? _selectedDate;

  List<DateTime> get _dayKeys => widget.plan.entriesByDay.keys.toList()..sort();

  @override
  Widget build(BuildContext context) {
    final dayKeys = _dayKeys;
    final selected = (_selectedDate != null && dayKeys.contains(_selectedDate))
        ? _selectedDate!
        : dayKeys.first;
    final entries = widget.plan.entriesByDay[selected] ?? [];
    final overrides = ref.watch(optimisticConsumptionProvider);
    final consumedKcal = entries.fold<double>(0.0, (sum, e) {
      final isConsumed = overrides[e.id] ?? e.isConsumed;
      return isConsumed ? sum + e.calories : sum;
    });
    final targetKcal =
        (ref.watch(activeNutritionPlanProvider).valueOrNull?.calorieGoal ?? 2000).toDouble();
    final locale = Localizations.localeOf(context).languageCode;

    _logger.provider('MealPlannerDayTabView build() | selected: ${selected.toIso8601String()} | '
        'entries: ${entries.length}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MealPlannerDaySelector(
          days: dayKeys,
          selected: selected,
          onSelect: (date) => setState(() => _selectedDate = date),
        ),
        const SizedBox(height: 16),
        MealPlannerDayRecapCard(
          date: selected,
          consumedKcal: consumedKcal,
          targetKcal: targetKcal,
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              for (final entry in entries) ...[
                Center(
                  child: AkeliMealCard(
                    title: entry.localizedTitle(locale) ??
                        entry.displayLabel(AppLocalizations.of(context)),
                    mealType: entry.mealType,
                    calories: entry.calories,
                    duration: entry.totalTimeMin,
                    imageUrl: entry.recipeThumbnail,
                    isPlanner: true,
                    isConsumed: overrides[entry.id] ?? entry.isConsumed,
                    onTap: () {
                      _logger.userAction('Meal plan entry tapped', screen: 'MealPlannerDayTabView',
                          metadata: {'entryId': entry.id});
                      widget.onRecipeTap?.call(entry.id);
                    },
                    onConsumedToggle: isFutureMeal(entry.scheduledDate)
                        ? null
                        : () {
                            final effectiveIsConsumed = overrides[entry.id] ?? entry.isConsumed;
                            _logger.userAction('Meal card consumed toggle',
                                screen: 'MealPlannerDayTabView',
                                metadata: {'entryId': entry.id, 'wasConsumed': effectiveIsConsumed});
                            toggleMealConsumption(
                              context,
                              ref,
                              entryId: entry.id,
                              isCurrentlyConsumed: effectiveIsConsumed,
                              screen: 'MealPlannerDayTabView',
                            );
                          },
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _buildAddSnackButton(context, selected, entries),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildAddSnackButton(BuildContext context, DateTime date, List<MealPlanEntry> entries) {
    final l10n = AppLocalizations.of(context);
    final hasSnack = entries.any((e) => e.mealType == 'snack');
    return OutlinedButton.icon(
      key: const Key('day-tab-add-snack'),
      onPressed: () => addSnackToDay(context, ref, widget.plan.id, date,
          screen: 'MealPlannerDayTabView'),
      icon: const Icon(Icons.add, size: 16),
      label: Text(hasSnack ? l10n.mealPlannerAddAnotherSnack : l10n.mealPlannerAddSnack),
      style: OutlinedButton.styleFrom(
        foregroundColor: AkeliColors.primary,
        side: BorderSide(color: AkeliColors.primary.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AkeliRadius.md)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      ),
    );
  }
}
