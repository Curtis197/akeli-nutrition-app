import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/logger.dart';
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../providers/meal_plan_provider.dart';
import '../../providers/user_profile_provider.dart';
import 'widgets/meal_planner_day_row.dart';

class MealPlannerPage extends ConsumerWidget {
  const MealPlannerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(activeMealPlanProvider);
    final profileAsync = ref.watch(userProfileProvider);

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
          // ── TOP NAVIGATION BAR ───────────────────────────────────────
          SliverAppBar(
            pinned: true,
            floating: true,
            expandedHeight: 0,
            toolbarHeight: 64,
            elevation: 0,
            backgroundColor: AkeliColors.surface,
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                const Icon(Icons.menu, color: AkeliColors.primaryContainer),
                const SizedBox(width: 16),
                Text(
                  profileAsync.when(
                    data: (p) => p?.displayName ?? 'Mon Plan',
                    loading: () => 'Mon Plan',
                    error: (_, __) => 'Mon Plan',
                  ),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 24),
                child: Center(
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AkeliColors.surfaceContainerHighest.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: profileAsync.when(
                      data: (p) => p?.avatarUrl != null
                          ? Image.network(p!.avatarUrl!, fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 20, color: AkeliColors.outline))
                          : const Icon(Icons.person, size: 20, color: AkeliColors.outline),
                      loading: () => const Icon(Icons.person, size: 20, color: AkeliColors.outline),
                      error: (_, __) => const Icon(Icons.person, size: 20, color: AkeliColors.outline),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
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
                    title: 'Batch Cooking',
                    onTap: () {
                      appLogger.userAction('Batch cooking card tapped', screen: 'MealPlannerPage');
                      context.push(AkeliRoutes.batchCooking);
                    },
                  ),
                ],
              ),
            ),
          ),

          // ── SNACK BLOCK ───────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
            sliver: SliverToBoxAdapter(
              child: _buildSnackSection(context),
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
                      onRecipeTap: (recipeId) {
                        appLogger.userAction('Meal plan recipe tapped', screen: 'MealPlannerPage', metadata: {'recipeId': recipeId});
                        context.push(AkeliRoutes.recipeDetailPath(recipeId));
                      },
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

  Widget _buildSnackSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AkeliColors.secondaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AkeliColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cookie, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Ajouter une collation',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AkeliColors.onSurface,
                    ),
                  ),
                  Text(
                    'Personnalisez votre plan',
                    style: TextStyle(
                      fontSize: 12,
                      color: AkeliColors.onSurfaceVariant.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ],
          ),
          ElevatedButton(
            onPressed: () {
              appLogger.userAction('Add snack tapped', screen: 'MealPlannerPage');
              HapticFeedback.lightImpact();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AkeliColors.primary,
              foregroundColor: Colors.white,
              elevation: 2,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AkeliRadius.pill),
              ),
            ),
            child: const Text(
              'Ajouter',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
        ],
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
