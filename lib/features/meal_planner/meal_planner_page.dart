import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:akeli/features/nutrition_plan/widgets/meal_schedule_widget.dart';
import 'package:akeli/providers/nutrition_plan_provider.dart';
import 'package:akeli/providers/user_profile_provider.dart';
import 'package:akeli/shared/models/nutrition_plan.dart';
import '../../core/logger.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/meal_plan_provider.dart';
import '../../providers/mode_provider.dart';
import 'meal_planner_actions.dart';
import 'rating_bottom_sheet.dart';
import 'widgets/meal_planner_day_row.dart';
import 'widgets/meal_planner_day_tab_view.dart';
import 'widgets/meal_planner_view_toggle.dart';

import 'widgets/beauty_planner_view.dart';

class MealPlannerPage extends ConsumerWidget {
  const MealPlannerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final appMode = ref.watch(currentModeProvider);

    if (appMode == AppMode.beauty) {
      return Scaffold(
        backgroundColor: AkeliColors.surface,
        appBar: AppBar(
          title: Text(
            'Mon Plan de Routines',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  letterSpacing: -1.0,
                ),
          ),
          backgroundColor: AkeliColors.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: const BeautyPlannerView(),
      );
    }

    ref.listen(mealConsumptionProvider, (_, next) {
      if (next.hasError) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(next.error.toString()),
          backgroundColor: AkeliColors.error,
        ));
      } else if (next.valueOrNull != null) {
        final entryId = next.valueOrNull!;
        final plan = ref.read(activeMealPlanProvider).valueOrNull;
        final entry = plan?.entries.where((e) => e.id == entryId).firstOrNull;
        if (entry != null && !entry.isRated) {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            isDismissible: false,
            enableDrag: false,
            backgroundColor: Colors.transparent,
            builder: (_) => RatingBottomSheet(mealPlanEntryId: entryId),
          );
        }
      }
    });

    final planAsync = ref.watch(activeMealPlanProvider);

    return Scaffold(
      backgroundColor: AkeliColors.surface,
      body: planAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text(l10n.mealPlannerError(error.toString()), style: const TextStyle(color: AkeliColors.error))),
        data: (plan) {
          if (plan == null) {
            return _buildEmptyState(context, ref);
          }
          final viewMode = ref.watch(plannerViewModeProvider);
          final entriesByDay = plan.entriesByDay;
          final dayKeys = entriesByDay.keys.toList()..sort();

          appLogger.provider('MealPlannerPage build() | days: ${dayKeys.length} | viewMode: ${viewMode.name}');

          final appMode = ref.watch(currentModeProvider);
          final isBeauty = appMode == AppMode.beauty;
          final accentColor = getAppModeColor(appMode);
          final title = isBeauty ? 'Mon Plan de Routines' : l10n.mealPlannerTitle;

          return NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // ── HEADER ────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.w900,
                          height: 1.1,
                          letterSpacing: -1.0,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.tune_rounded),
                        tooltip: isBeauty ? 'Personnaliser la structure des soins' : l10n.mealScheduleCustomizeButton,
                        color: accentColor,
                        onPressed: () {
                          appLogger.userAction('Customize structure tapped', screen: 'MealPlannerPage');
                          _showCustomizeSheet(context, ref);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  MealPlannerViewToggle(
                    value: viewMode,
                    onChanged: (mode) {
                      appLogger.provider('plannerViewModeProvider → ${mode.name}');
                      ref.read(plannerViewModeProvider.notifier).state = mode;
                    },
                  ),
                ],
              ),
            ),
          ),

          // ── QUICK ACTIONS ───────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverToBoxAdapter(
              child: Column(
                children: [
                  _buildNavigationCard(
                    context,
                    icon: Icons.restaurant_menu,
                    title: l10n.mealPlannerViewDietPlan,
                    onTap: () {
                      appLogger.userAction('Diet plan card tapped', screen: 'MealPlannerPage');
                      context.push(AkeliRoutes.dietPlan);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildNavigationCard(
                    context,
                    icon: Icons.shopping_basket,
                    title: l10n.mealPlannerViewShoppingList,
                    onTap: () {
                      appLogger.userAction('Shopping list card tapped', screen: 'MealPlannerPage');
                      context.push(AkeliRoutes.shoppingList);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildNavigationCard(
                    context,
                    icon: Icons.soup_kitchen_outlined,
                    title: l10n.mealPlannerViewBatchCooking,
                    onTap: () {
                      appLogger.userAction('Batch cooking card tapped', screen: 'MealPlannerPage');
                      context.push(AkeliRoutes.batchCooking);
                    },
                  ),
                ],
              ),
            ),
          ),

        ],
        body: SafeArea(
          top: false,
          child: CustomScrollView(
            slivers: [
              // ── HINT BANNER ─────────────────────────────────────────────
              Consumer(builder: (context, ref, _) {
                final profileAsync = ref.watch(userProfileProvider);
                final profile = profileAsync.valueOrNull;
                if (profile == null || profile.hasDismissedMealScheduleHint) {
                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                }
                return SliverToBoxAdapter(
                  child: MaterialBanner(
                    content: Text(l10n.mealScheduleHintBanner),
                    actions: [
                      TextButton(
                        onPressed: () {
                          appLogger.userAction('Meal schedule hint dismissed', screen: 'MealPlannerPage');
                          ref.read(dismissMealScheduleHintProvider(profile.id));
                        },
                        child: Text(l10n.mealScheduleHintDismiss),
                      ),
                    ],
                  ),
                );
              }),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
              if (viewMode == PlannerViewMode.day) ...[
                // ── DAY TAB VIEW ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: MealPlannerDayTabView(
                    plan: plan,
                    onRecipeTap: (entryId) {
                      appLogger.userAction('Meal plan entry tapped', screen: 'MealPlannerPage', metadata: {'entryId': entryId});
                      context.push(AkeliRoutes.mealDetailPath(entryId));
                    },
                  ),
                ),
              ] else ...[
                // ── DAILY MEAL LIST (week view) ──────────────────────────
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final date = dayKeys[index];
                      final entries = entriesByDay[date]!;

                      return MealPlannerDayRow(
                        date: date,
                        entries: entries,
                        onRecipeTap: (entryId) {
                          appLogger.userAction('Meal plan entry tapped', screen: 'MealPlannerPage', metadata: {'entryId': entryId});
                          context.push(AkeliRoutes.mealDetailPath(entryId));
                        },
                        onConsumedToggle: (entryId) async {
                          appLogger.userAction('Meal consumed toggle', screen: 'MealPlannerPage', metadata: {'entryId': entryId});
                          final currentPlan = ref.read(activeMealPlanProvider).valueOrNull;
                          final dbIsConsumed = currentPlan?.entries.where((e) => e.id == entryId).firstOrNull?.isConsumed ?? false;
                          final overrides = ref.read(optimisticConsumptionProvider);
                          final effectiveIsConsumed = overrides[entryId] ?? dbIsConsumed;
                          await toggleMealConsumption(
                            context,
                            ref,
                            entryId: entryId,
                            isCurrentlyConsumed: effectiveIsConsumed,
                            screen: 'MealPlannerPage',
                          );
                        },
                        onAddSnack: () =>
                            addSnackToDay(context, ref, plan.id, date, screen: 'MealPlannerPage'),
                      );
                    },
                    childCount: dayKeys.length,
                  ),
                ),
              ],
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 48),
                  child: ElevatedButton.icon(
                    onPressed: () {
                      appLogger.userAction('Generate plan button tapped', screen: 'MealPlannerPage');
                      _generatePlan(context, ref);
                    },
                    icon: const Icon(Icons.auto_awesome),
                    label: Text(l10n.mealPlannerGenerate),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AkeliColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AkeliRadius.lg)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.restaurant_menu, size: 64, color: AkeliColors.outline),
          const SizedBox(height: 16),
          Text(
            l10n.mealPlannerEmpty,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.mealPlannerEmptySubtitle,
            style: const TextStyle(color: AkeliColors.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              appLogger.userAction('Generate plan FAB tapped from empty state', screen: 'MealPlannerPage');
              _generatePlan(context, ref);
            },
            icon: const Icon(Icons.auto_awesome),
            label: Text(l10n.mealPlannerGenerate),
            style: ElevatedButton.styleFrom(
              backgroundColor: AkeliColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationCard(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AkeliRadius.card),
          border: Border.all(color: AkeliColors.surfaceContainerHighest.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AkeliColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AkeliRadius.md),
              ),
              child: Icon(icon, color: AkeliColors.primary, size: 20),
            ),
            const SizedBox(width: 16),
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF3D4947),
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: AkeliColors.outline),
          ],
        ),
      ),
    );
  }

  Future<void> _showCustomizeSheet(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final nutritionPlan = ref.read(activeNutritionPlanProvider).valueOrNull;
    if (nutritionPlan == null) return;

    List<MealDistribution> pending = nutritionPlan.distributions ?? [
      MealDistribution(mealType: 'breakfast', sortOrder: 0, caloriePct: 30, calorieTarget: nutritionPlan.calorieGoal * 0.30),
      MealDistribution(mealType: 'lunch',     sortOrder: 1, caloriePct: 35, calorieTarget: nutritionPlan.calorieGoal * 0.35),
      MealDistribution(mealType: 'dinner',    sortOrder: 2, caloriePct: 35, calorieTarget: nutritionPlan.calorieGoal * 0.35),
    ];
    bool isValid = true;

    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          builder: (_, controller) => Container(
            decoration: const BoxDecoration(
              color: AkeliColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 8),
                const SizedBox(width: 40, height: 4,
                    child: DecoratedBox(decoration: BoxDecoration(
                      color: AkeliColors.outline,
                      borderRadius: BorderRadius.all(Radius.circular(2)),
                    ))),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    l10n.mealScheduleTitle,
                    style: Theme.of(ctx).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    controller: controller,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: MealScheduleWidget(
                      initialDistributions: pending,
                      totalCalorieGoal: nutritionPlan.calorieGoal,
                      onChanged: (dists) => setModalState(() => pending = dists),
                      onSaveEnabled: (v) => setModalState(() => isValid = v),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  child: ElevatedButton(
                    onPressed: isValid ? () => Navigator.of(ctx).pop(true) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AkeliColors.primary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AkeliRadius.lg),
                      ),
                    ),
                    child: Text(l10n.mealScheduleSave),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (confirmed != true || !context.mounted) return;

    // Save distributions
    await ref.read(nutritionPlanNotifierProvider.notifier)
        .savePlan(nutritionPlan, pending);

    if (!context.mounted) return;

    // Ask when to apply
    final applyNow = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.mealScheduleApplyDialogTitle),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n.mealScheduleApplyFromNextWeek),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AkeliColors.primary),
            child: Text(l10n.mealScheduleApplyFromToday),
          ),
        ],
      ),
    );

    if (applyNow == true && context.mounted) {
      try {
        await ref.read(mealPlanGeneratorProvider.notifier).generate();
      } catch (e) {
        appLogger.edge('generate-meal-plan', 'ERROR | $e', error: e);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppLocalizations.of(context).mealPlannerError(e.toString())),
              backgroundColor: AkeliColors.error,
            ),
          );
        }
      }
    }
  }

  Future<void> _generatePlan(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.commonLoading),
        backgroundColor: AkeliColors.primary,
      ),
    );

    try {
      await ref.read(mealPlanGeneratorProvider.notifier).generate();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).mealPlannerGenerate),
            backgroundColor: AkeliColors.primary,
          ),
        );
      }
    } catch (e) {
      appLogger.edge('generate-meal-plan', 'ERROR | $e', error: e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context).mealPlannerError(e.toString())),
            backgroundColor: AkeliColors.error,
          ),
        );
      }
    }
  }
}
