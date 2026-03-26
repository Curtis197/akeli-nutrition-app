import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/core/router.dart';
import 'package:akeli/providers/meal_plan_provider.dart';
import 'package:akeli/shared/widgets/meal_card.dart';
import 'package:intl/intl.dart';

/// [Akeli] DietPlanPage - High-Fidelity Editorial Redesign
/// This page presents the weekly meal plan in a high-fidelity scrollable list of days.
/// Each day contains a horizontal snap list of meals, matching the "Digital Editorial" aesthetic.
class DietPlanPage extends ConsumerStatefulWidget {
  const DietPlanPage({super.key});

  @override
  ConsumerState<DietPlanPage> createState() => _DietPlanPageState();
}

class _DietPlanPageState extends ConsumerState<DietPlanPage> {
  @override
  Widget build(BuildContext context) {
    final planAsync = ref.watch(activeMealPlanProvider);

    return Scaffold(
      backgroundColor: AkeliColors.background,
      // Fixed sticky header with editorial blur
      appBar: AppBar(
        backgroundColor: AkeliColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        centerTitle: false,
        title: Text(
          'Akeli Victoire',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: AkeliColors.onSurface,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: AkeliColors.surfaceContainerHighest,
              backgroundImage: NetworkImage(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuBZp-6DEHw83vZ3znlhBFiNEDWo5PLlAfKX5oY6YR2wrBH9HyBeIuzo60H9m4vN9ZE0FruyJjub4iPtcF7l07HzLVePD4kS16e7dpPOclHJNmCKlHt361s6CQbcj823oCzBMNBpCfrwheID2tD2wt6QGydVwPEQDGTANtf5RLSzZDmwbd1aFhJkvZkD7OG1uejkB4Th7qbvgnWJnGW0fFxf0e9WUV8fc-uapul52TVLC2YQv_oKBF0jkoRT9ihI7ZX7LLjrF3el5Zc',
              ),
            ),
          ),
        ],
      ),
      body: planAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            'Erreur: $e',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AkeliColors.error),
          ),
        ),
        data: (plan) {
          final entries = plan?.entries ?? [];
          
          // Group entries by date
          final groupedMeals = <DateTime, List<dynamic>>{};
          for (final entry in entries) {
            final date = DateTime(
              entry.scheduledDate.year,
              entry.scheduledDate.month,
              entry.scheduledDate.day,
            );
            groupedMeals.putIfAbsent(date, () => []).add(entry);
          }

          // Generate date list for the week (starting today)
          final today = DateTime.now();
          final startOfWeek = DateTime(today.year, today.month, today.day);
          final weekDates = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));

          return ListView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            children: [
              // Header Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Vos repas de la semaine',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Navigation Shortcuts
                    _buildNavLink(
                      context,
                      icon: Icons.restaurant_menu,
                      label: 'Voir mon plan diététique',
                      onTap: () {},
                    ),
                    const SizedBox(height: 12),
                    _buildNavLink(
                      context,
                      icon: Icons.shopping_basket_outlined,
                      label: 'Voir ma liste de course',
                      onTap: () => context.go(AkeliRoutes.shoppingList),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Snacks Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _buildSnackBanner(context),
              ),
              const SizedBox(height: 32),

              // Weekly Planner Sections
              ...weekDates.map((date) {
                final meals = groupedMeals[date] ?? [];
                final dailyCals = meals.fold<double>(0, (sum, m) => sum + (m.calories ?? 0));
                
                return _buildDaySection(context, date, dailyCals, meals);
              }),

              const SizedBox(height: 100), // Space for FAB and BottomNav
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AkeliColors.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.auto_awesome, color: Colors.white),
      ),
    );
  }

  Widget _buildNavLink(BuildContext context, {required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AkeliColors.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AkeliColors.onSurface.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: AkeliColors.primary, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AkeliColors.onSurfaceVariant,
                ),
              ),
            ),
            const Icon(Icons.chevron_right, color: AkeliColors.outline, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSnackBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AkeliColors.secondaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: AkeliColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.cookie_outlined, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ajouter une collation',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Personnalisez votre plan',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AkeliColors.onSurfaceVariant),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: AkeliColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            ),
            child: const Text('Ajouter', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  Widget _buildDaySection(BuildContext context, DateTime date, double dailyCals, List<dynamic> meals) {
    final dateStr = DateFormat('EEEE d MMMM', 'fr_FR').format(date);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateStr,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AkeliColors.primary,
                ),
              ),
              Text(
                '${dailyCals.toInt()} kcal',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: AkeliColors.outline,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 300, 
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: meals.length,
            physics: const BouncingScrollPhysics(),
            itemBuilder: (context, index) {
              final m = meals[index];
              return Padding(
                padding: const EdgeInsets.only(right: 16),
                child: SizedBox(
                  width: 280,
                  child: AkeliMealCard(
                    title: m.recipeTitle ?? 'Repas',
                    mealType: m.mealTypeLabel,
                    calories: (m.calories ?? 0).toDouble(),
                    // Injecting mockup tags where available or using defaults
                    onTap: () => context.go(AkeliRoutes.mealDetailPath(m.id)),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
