// lib/features/settings/meal_schedule_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akeli/core/logger.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/features/nutrition_plan/widgets/meal_schedule_widget.dart';
import 'package:akeli/l10n/app_localizations.dart';
import 'package:akeli/providers/nutrition_plan_provider.dart';
import 'package:akeli/shared/models/nutrition_plan.dart';

class MealSchedulePage extends ConsumerStatefulWidget {
  const MealSchedulePage({super.key});

  @override
  ConsumerState<MealSchedulePage> createState() => _MealSchedulePageState();
}

class _MealSchedulePageState extends ConsumerState<MealSchedulePage> {
  final _logger = appLogger;
  List<MealDistribution>? _distributions;
  bool _isValid = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _logger.provider('MealSchedulePage initState');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    _logger.provider('MealSchedulePage build()');

    final planAsync = ref.watch(activeNutritionPlanProvider);

    return Scaffold(
      backgroundColor: AkeliColors.background,
      appBar: AppBar(
        title: Text(l10n.mealScheduleTitle),
        backgroundColor: AkeliColors.background,
        actions: [
          TextButton(
            onPressed: (_isValid && !_saving) ? _save : null,
            child: _saving
                ? const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : Text(l10n.mealScheduleSave),
          ),
        ],
      ),
      body: planAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text(e.toString())),
        data: (plan) {
          if (plan == null) {
            return Center(child: Text(l10n.mealScheduleSubtitle));
          }
          final initialDists = _distributions ??
              (plan.distributions ?? [
                MealDistribution(mealType: 'breakfast', sortOrder: 0, caloriePct: 30, calorieTarget: (plan.calorieGoal * 0.30)),
                MealDistribution(mealType: 'lunch',     sortOrder: 1, caloriePct: 35, calorieTarget: (plan.calorieGoal * 0.35)),
                MealDistribution(mealType: 'dinner',    sortOrder: 2, caloriePct: 35, calorieTarget: (plan.calorieGoal * 0.35)),
              ]);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.mealScheduleSubtitle,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AkeliColors.onSurfaceVariant)),
                const SizedBox(height: 16),
                MealScheduleWidget(
                  initialDistributions: initialDists,
                  totalCalorieGoal: plan.calorieGoal,
                  onChanged: (dists) => setState(() => _distributions = dists),
                  onSaveEnabled: (v) => setState(() => _isValid = v),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _save() async {
    _logger.userAction('MealSchedulePage save tapped');
    if (_distributions == null) return;

    setState(() => _saving = true);
    try {
      final plan = ref.read(activeNutritionPlanProvider).valueOrNull;
      if (plan == null) return;

      _logger.provider('MealSchedulePage → saving ${_distributions!.length} distributions');
      await ref.read(nutritionPlanNotifierProvider.notifier)
          .savePlan(plan, _distributions!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context).mealScheduleSave)),
        );
        Navigator.of(context).pop();
      }
    } catch (e, st) {
      _logger.provider('MealSchedulePage → save error | $e', error: e, stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AkeliColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
