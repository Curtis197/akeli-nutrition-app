import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akeli/core/logger.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/features/nutrition_plan/widgets/meal_schedule_widget.dart';
import 'package:akeli/l10n/app_localizations.dart';
import 'package:akeli/providers/nutrition_plan_provider.dart';
import 'package:akeli/shared/models/nutrition_plan.dart';

class MealScheduleOnboardingStep extends ConsumerStatefulWidget {
  final VoidCallback onCompleted;
  final VoidCallback onSkipped;

  const MealScheduleOnboardingStep({
    super.key,
    required this.onCompleted,
    required this.onSkipped,
  });

  @override
  ConsumerState<MealScheduleOnboardingStep> createState() =>
      _MealScheduleOnboardingStepState();
}

class _MealScheduleOnboardingStepState
    extends ConsumerState<MealScheduleOnboardingStep> {
  final _logger = appLogger;
  List<MealDistribution>? _distributions;
  bool _isValid = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _logger.provider('MealScheduleOnboardingStep initState');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    _logger.provider('MealScheduleOnboardingStep build()');

    final planAsync = ref.watch(activeNutritionPlanProvider);

    return Scaffold(
      backgroundColor: AkeliColors.background,
      body: SafeArea(
        child: planAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(e.toString())),
          data: (plan) {
            if (plan == null) {
              // No plan yet — skip silently
              WidgetsBinding.instance
                  .addPostFrameCallback((_) => widget.onSkipped());
              return const SizedBox.shrink();
            }
            final initialDists = _distributions ??
                [
                  MealDistribution(
                      mealType: 'breakfast',
                      sortOrder: 0,
                      caloriePct: 30,
                      calorieTarget: plan.calorieGoal * 0.30),
                  MealDistribution(
                      mealType: 'lunch',
                      sortOrder: 1,
                      caloriePct: 35,
                      calorieTarget: plan.calorieGoal * 0.35),
                  MealDistribution(
                      mealType: 'dinner',
                      sortOrder: 2,
                      caloriePct: 35,
                      calorieTarget: plan.calorieGoal * 0.35),
                ];

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.mealScheduleOnboardingTitle,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.mealScheduleOnboardingSubtitle,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(
                                  color: AkeliColors.onSurfaceVariant),
                        ),
                        const SizedBox(height: 24),
                        MealScheduleWidget(
                          initialDistributions: initialDists,
                          totalCalorieGoal: plan.calorieGoal,
                          onChanged: (dists) =>
                              setState(() => _distributions = dists),
                          onSaveEnabled: (v) =>
                              setState(() => _isValid = v),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    children: [
                      ElevatedButton(
                        onPressed: (_isValid && !_saving) ? _save : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AkeliColors.primary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(AkeliRadius.lg)),
                        ),
                        child: _saving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : Text(l10n.mealScheduleSave),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: widget.onSkipped,
                        child: Text(
                          l10n.mealScheduleOnboardingSkip,
                          style: const TextStyle(
                              color: AkeliColors.onSurfaceVariant),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _save() async {
    _logger.userAction('MealScheduleOnboardingStep save tapped');
    if (_distributions == null) return;
    setState(() => _saving = true);
    try {
      final plan = ref.read(activeNutritionPlanProvider).valueOrNull;
      if (plan == null) {
        widget.onSkipped();
        return;
      }
      await ref
          .read(nutritionPlanNotifierProvider.notifier)
          .savePlan(plan, _distributions!);
      _logger.provider('MealScheduleOnboardingStep → save success');
      if (mounted) widget.onCompleted();
    } catch (e, st) {
      _logger.provider(
          'MealScheduleOnboardingStep → save error | $e',
          error: e,
          stackTrace: st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.toString()),
              backgroundColor: AkeliColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
