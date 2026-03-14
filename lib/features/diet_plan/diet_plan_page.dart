import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/core/router.dart';
import 'package:akeli/providers/meal_plan_provider.dart';
import 'package:akeli/shared/widgets/section_header.dart';
import 'package:akeli/shared/widgets/progress_circle.dart';
import 'package:akeli/shared/widgets/tab_bar.dart';
import 'package:akeli/shared/widgets/meal_card.dart';

class DietPlanPage extends ConsumerStatefulWidget {
  const DietPlanPage({super.key});
  @override
  ConsumerState<DietPlanPage> createState() => _DietPlanPageState();
}

class _DietPlanPageState extends ConsumerState<DietPlanPage> {
  int _selectedDay = 0;
  static const _dayTabs = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
  @override
  Widget build(BuildContext context) {
    final planAsync = ref.watch(activeMealPlanProvider);
    return Scaffold(
      backgroundColor: AkeliColors.background,
      appBar: AppBar(backgroundColor: AkeliColors.background, elevation: 0, automaticallyImplyLeading: false, title: const Text('Mon plan alimentaire')),
      body: planAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AkeliColors.error))),
        data: (plan) {
          final entries = plan?.entries ?? [];
          final totalCals = entries.fold<double>(0, (s, e) => s + (e.calories ?? 0));
          final avgCals = entries.isEmpty ? 0 : (totalCals / 7).toInt();
          final calProgress = (avgCals / 2000).clamp(0.0, 1.0);
          final totalProt = entries.fold<double>(0, (s, e) => s + (e.proteinG ?? 0));
          final avgProt = entries.isEmpty ? 0 : (totalProt / 7).toInt();
          final today = DateTime.now();
          final startOfWeek = today.subtract(Duration(days: today.weekday - 1));
          final targetDay = startOfWeek.add(Duration(days: _selectedDay));
          final mealsForDay = entries.where((e) {
            final d = e.scheduledDate;
            return d.year == targetDay.year && d.month == targetDay.month && d.day == targetDay.day;
          }).toList();
          final totalIngr = entries.isEmpty ? 21 : entries.length * 3;
          return SingleChildScrollView(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const SizedBox(height: 16),
            Padding(padding: const EdgeInsets.symmetric(horizontal: AkeliSpacing.md), child: Container(
              padding: const EdgeInsets.all(AkeliSpacing.md),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [AkeliColors.primary, AkeliColors.primary.withValues(alpha: 0.7)]),
                borderRadius: BorderRadius.circular(AkeliRadius.lg),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Plan de la semaine', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: AkeliSpacing.sm),
                Row(children: [
                  AkeliProgressCircle(label: 'Calories', value: '$avgCals', unit: 'kcal', progress: calProgress, color: Colors.white),
                  const SizedBox(width: AkeliSpacing.lg),
                  AkeliProgressCircle(label: 'Protéines', value: '${avgProt}g', progress: 0.7, color: Colors.white),
                ]),
              ]),
            )),
            const SizedBox(height: AkeliSpacing.lg),
            SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: AkeliSpacing.md),
              child: AkeliTabBar(tabs: _dayTabs, selectedIndex: _selectedDay, onTabSelected: (i) => setState(() => _selectedDay = i))),
            const SizedBox(height: AkeliSpacing.md),
            const Padding(padding: EdgeInsets.symmetric(horizontal: AkeliSpacing.md), child: AkeliSectionHeader(title: 'Repas du jour')),
            const SizedBox(height: 12),
            if (mealsForDay.isEmpty && plan != null)
              Padding(padding: const EdgeInsets.symmetric(horizontal: AkeliSpacing.md),
                child: Text('Aucun repas planifié pour ce jour.', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AkeliColors.textSecondary)))
            else
              ...mealsForDay.map((m) => Padding(padding: const EdgeInsets.symmetric(horizontal: AkeliSpacing.md, vertical: 6),
                child: AkeliMealCard(title: m.recipeTitle ?? 'Repas', mealType: m.mealTypeLabel, calories: (m.calories ?? 0).toInt(), emoji: '🍽️', onTap: () => context.go(AkeliRoutes.mealDetailPath(m.id))))),
            if (plan == null) ...[
              Padding(padding: const EdgeInsets.symmetric(horizontal: AkeliSpacing.md, vertical: 6),
                child: AkeliMealCard(title: 'Petit-déjeuner: Omelette', mealType: 'Petit-déjeuner', calories: 320, emoji: '🍳', onTap: () {})),
              Padding(padding: const EdgeInsets.symmetric(horizontal: AkeliSpacing.md, vertical: 6),
                child: AkeliMealCard(title: 'Déjeuner: Salade de quinoa', mealType: 'Déjeuner', calories: 480, emoji: '🥗', onTap: () {})),
              Padding(padding: const EdgeInsets.symmetric(horizontal: AkeliSpacing.md, vertical: 6),
                child: AkeliMealCard(title: 'Dîner: Poulet grillé', mealType: 'Dîner', calories: 550, emoji: '🍗', onTap: () {})),
            ],
            const SizedBox(height: AkeliSpacing.lg),
            Padding(padding: const EdgeInsets.symmetric(horizontal: AkeliSpacing.md),
              child: AkeliSectionHeader(title: 'Courses nécessaires', trailingLabel: 'Voir la liste', onTrailingTap: () => context.go(AkeliRoutes.shoppingList))),
            const SizedBox(height: 12),
            Padding(padding: const EdgeInsets.symmetric(horizontal: AkeliSpacing.md),
              child: Text('$totalIngr ingrédients pour la semaine', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AkeliColors.textSecondary))),
            const SizedBox(height: 80),
          ]));
        },
      ),
    );
  }
}
