import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/logger.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../providers/meal_plan_provider.dart';
import 'rating_bottom_sheet.dart';
import 'widgets/meal_planner_day_row.dart';
import 'widgets/snack_picker_sheet.dart';

class MealPlannerPage extends ConsumerWidget {
  const MealPlannerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        error: (error, _) => Center(child: Text('Erreur: $error', style: const TextStyle(color: AkeliColors.error))),
        data: (plan) {
          if (plan == null) {
            return _buildEmptyState(context, ref);
          }
          final entriesByDay = plan.entriesByDay;
          final dayKeys = entriesByDay.keys.toList()..sort();

          appLogger.provider('MealPlannerPage build() | days: ${dayKeys.length}');

          return NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // ── HEADER ────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
            sliver: SliverToBoxAdapter(
              child: Text(
                'Vos repas ${dayKeys.length > 3 ? 'de la semaine' : 'des prochains jours'}',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                  letterSpacing: -1.0,
                ),
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
                    title: 'Voir mon plan diététique',
                    onTap: () {
                      appLogger.userAction('Diet plan card tapped', screen: 'MealPlannerPage');
                      context.push(AkeliRoutes.dietPlan);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildNavigationCard(
                    context,
                    icon: Icons.shopping_basket,
                    title: 'Voir ma liste de course',
                    onTap: () {
                      appLogger.userAction('Shopping list card tapped', screen: 'MealPlannerPage');
                      context.push(AkeliRoutes.shoppingList);
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildNavigationCard(
                    context,
                    icon: Icons.soup_kitchen_outlined,
                    title: 'Session de cuisine',
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
              // ── DAILY MEAL LIST ─────────────────────────────────────────
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
                      onConsumedToggle: (entryId) {
                        appLogger.userAction('Meal consumed toggle', screen: 'MealPlannerPage', metadata: {'entryId': entryId});
                        final plan = ref.read(activeMealPlanProvider).valueOrNull;
                        final isConsumed = plan?.entries.where((e) => e.id == entryId).firstOrNull?.isConsumed ?? false;
                        ref.read(mealConsumptionProvider.notifier).toggleConsumption(entryId, isCurrentlyConsumed: isConsumed);
                      },
                      onAddSnack: () => _addSnack(context, ref, plan.id, date),
                    );
                  },
                  childCount: dayKeys.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          appLogger.userAction('Generate plan FAB tapped', screen: 'MealPlannerPage');
          _generatePlan(context, ref);
        },
        backgroundColor: AkeliColors.primary,
        elevation: 4,
        child: const Icon(Icons.auto_awesome, color: Colors.white),
      ),
    );
  }

  Future<void> _addSnack(BuildContext context, WidgetRef ref, String mealPlanId, DateTime date) async {
    appLogger.userAction('Add snack tapped', screen: 'MealPlannerPage', metadata: {'date': date.toIso8601String()});
    final recipeId = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SnackPickerSheet(),
    );
    if (recipeId == null || !context.mounted) return;
    try {
      await ref.read(snackEntryProvider.notifier).addSnack(
        mealPlanId: mealPlanId,
        recipeId: recipeId,
        scheduledDate: date,
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Collation ajoutée !'),
            backgroundColor: AkeliColors.primary,
          ),
        );
      }
    } catch (e) {
      appLogger.edge('add-snack', 'ERROR | $e', error: e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AkeliColors.error,
          ),
        );
      }
    }
  }

  Widget _buildEmptyState(BuildContext context, WidgetRef ref) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.restaurant_menu, size: 64, color: AkeliColors.outline),
          const SizedBox(height: 16),
          Text(
            'Aucun plan alimentaire',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Générez votre premier plan pour commencer',
            style: TextStyle(color: AkeliColors.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              appLogger.userAction('Generate plan FAB tapped from empty state', screen: 'MealPlannerPage');
              _generatePlan(context, ref);
            },
            icon: const Icon(Icons.auto_awesome),
            label: const Text('Générer un plan'),
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

  Future<void> _generatePlan(BuildContext context, WidgetRef ref) async {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Génération de votre nouveau plan...'),
        backgroundColor: AkeliColors.primary,
      ),
    );

    try {
      await ref.read(mealPlanGeneratorProvider.notifier).generate();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Plan généré avec succès !'),
            backgroundColor: AkeliColors.primary,
          ),
        );
      }
    } catch (e) {
      appLogger.edge('generate-meal-plan', 'ERROR | $e', error: e);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la génération : $e'),
            backgroundColor: AkeliColors.error,
          ),
        );
      }
    }
  }
}
