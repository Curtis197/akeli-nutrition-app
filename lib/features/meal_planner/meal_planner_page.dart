import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:percent_indicator/percent_indicator.dart' as import_percent;
import '../../core/router.dart';
import '../../core/theme.dart';
import '../../providers/meal_plan_provider.dart';
import '../../shared/mocks/mock_meal_plan.dart';
import '../../shared/widgets/empty_state.dart';
import 'widgets/meal_planner_day_row.dart';

class MealPlannerPage extends ConsumerWidget {
  const MealPlannerPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // For the current UI refactor, we use MockMealPlan
    // In production, we would use: final planAsync = ref.watch(activeMealPlanProvider);
    final mockPlan = MockMealPlan.sevenDayPlan();
    final entriesByDay = mockPlan.entriesByDay;
    final dayKeys = entriesByDay.keys.toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFCFAEF),
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          // ── TOP NAVIGATION BAR ───────────────────────────────────────
          SliverAppBar(
            pinned: true,
            floating: true,
            expandedHeight: 0,
            toolbarHeight: 64,
            elevation: 0,
            backgroundColor: const Color(0xFFFCFAEF),
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                const Icon(Icons.menu, color: Color(0xFF4DB6AC)),
                const SizedBox(width: 16),
                Text(
                  'Akeli Victoire',
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
                    child: const Icon(Icons.person, size: 20, color: AkeliColors.outline),
                  ),
                ),
              ),
            ],
          ),
          
          // ── HEADER & PROGRESS ────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            sliver: SliverToBoxAdapter(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Vos repas ${dayKeys.length > 3 ? 'de la semaine' : 'des prochains jours'}',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            fontWeight: FontWeight.w900,
                            height: 1.1,
                            letterSpacing: -1.0,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Découvrez votre programme nutritionnel personnalisé pour les ${dayKeys.length} prochains jours.',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AkeliColors.outline,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Progress Indicator aligned with FF
                  import_percent.CircularPercentIndicator(
                    radius: 38.0,
                    lineWidth: 8.0,
                    percent: 0.72,
                    animation: true,
                    progressColor: AkeliColors.primary,
                    backgroundColor: AkeliColors.surfaceContainerHighest.withValues(alpha: 0.3),
                    center: Text(
                      "72%",
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AkeliColors.primary,
                      ),
                    ),
                    circularStrokeCap: import_percent.CircularStrokeCap.round,
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
                    title: 'Voir mon plan diététique',
                    onTap: () => context.push(AkeliRoutes.dietPlan),
                  ),
                  const SizedBox(height: 12),
                  _buildNavigationCard(
                    context,
                    icon: Icons.shopping_basket,
                    title: 'Voir ma liste de course',
                    onTap: () => context.push(AkeliRoutes.shoppingList),
                  ),
                ],
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
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
                    
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        MealPlannerDayRow(
                          date: date,
                          entries: entries,
                          onRecipeTap: (recipeId) => context.push(AkeliRoutes.recipeDetailPath(recipeId)),
                          onConsumedToggle: (entryId, isConsumed) {
                            HapticFeedback.mediumImpact();
                          },
                        ),
                        // Snack button per day
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 48),
                          child: _buildSnackSection(context),
                        ),
                      ],
                    );
                  },
                  childCount: dayKeys.length,
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _generatePlan(context, ref),
        backgroundColor: AkeliColors.primary,
        elevation: 4,
        child: const Icon(Icons.auto_awesome, color: Colors.white),
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
                borderRadius: BorderRadius.circular(AkeliRadius.m),
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
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        // Implement add snack action
      },
      borderRadius: BorderRadius.circular(AkeliRadius.card),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFE4F5F2), // Light teal background matching FF
          borderRadius: BorderRadius.circular(AkeliRadius.card),
          border: Border.all(color: const Color(0xFFB2DFDB).withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_circle_outline, color: Color(0xFF00796B), size: 20),
            const SizedBox(width: 12),
            Text(
              'Ajouter une collation',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: const Color(0xFF00796B),
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
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
    
    // Simulating generation logic
    await Future.delayed(const Duration(seconds: 2));
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plan généré avec succès !'),
          backgroundColor: AkeliColors.primary,
        ),
      );
    }
  }
}
