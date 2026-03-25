import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akeli/core/theme.dart';
import 'package:akeli/providers/meal_plan_provider.dart';
import 'package:akeli/shared/widgets/badge.dart';
import 'package:akeli/shared/widgets/section_header.dart';
import 'package:akeli/shared/widgets/shopping_row.dart';

class _Ingredient {
  final String quantity;
  final String name;
  const _Ingredient(this.quantity, this.name);
}

class MealDetailPage extends ConsumerWidget {
  final String mealId;

  const MealDetailPage({super.key, required this.mealId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(activeMealPlanProvider);

    return Scaffold(
      backgroundColor: AkeliColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(),
        title: const Text('Détail du repas'),
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
          final entry = plan?.entries.where((e) => e.id == mealId).firstOrNull;

          if (entry == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🍽️', style: TextStyle(fontSize: 48)),
                  const SizedBox(height: 16),
                  Text('Repas introuvable', style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: 8),
                  Text(
                    'Ce repas n’existe pas dans votre plan.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AkeliColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          final name = entry.recipeTitle ?? 'Repas';
          final mealType = entry.mealTypeLabel;
          final calories = (entry.calories ?? 0).toInt();
          final carbs = (entry.carbsG ?? 0).toInt();
          final protein = (entry.proteinG ?? 0).toInt();
          final fat = (entry.fatG ?? 0).toInt();

          const ingredients = [
            _Ingredient('200g', 'Poulet grillé'),
            _Ingredient('100g', 'Riz basmati'),
            _Ingredient('80g', 'Brocoli'),
            _Ingredient('1 c.s.', 'Huile d’olive'),
            _Ingredient('2 gousses', 'Ail'),
          ];

          const instructions =
              'Faites cuire le riz selon les instructions du paquet. '
              'Faites revenir le poulet dans l’huile d’olive avec l’ail '
              'pendant 8 minutes. Ajoutez le brocoli et faites sauter 3 minutes. '
              'Servez sur le riz chaud.';

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 220,
                  color: AkeliColors.primary.withValues(alpha: 0.08),
                  child: const Center(
                    child: Text('🍽️', style: TextStyle(fontSize: 64)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AkeliSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: AkeliSpacing.sm),
                      Row(children: [
                        AkeliBadge(label: mealType),
                        const SizedBox(width: AkeliSpacing.sm),
                        AkeliBadge(label: '$calories kcal', color: AkeliColors.secondary),
                      ]),
                      const SizedBox(height: AkeliSpacing.lg),
                      const AkeliSectionHeader(title: 'Macronutriments'),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: AkeliSpacing.sm,
                        runSpacing: AkeliSpacing.sm,
                        children: [
                          AkeliMacroBadge(label: 'Glucides', value: '${carbs}g', type: MacroType.carbs),
                          AkeliMacroBadge(label: 'Protéines', value: '${protein}g', type: MacroType.protein),
                          AkeliMacroBadge(label: 'Graisses', value: '${fat}g', type: MacroType.fat),
                          AkeliMacroBadge(label: 'Calories', value: '$calories', type: MacroType.kcal),
                        ],
                      ),
                      const SizedBox(height: AkeliSpacing.lg),
                      AkeliSectionHeader(
                        title: 'Ingrédients',
                        trailingLabel: 'Ajouter à la liste',
                        onTrailingTap: () => ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ajouté à la liste de courses')),
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...ingredients.map((i) => AkeliShoppingRow(
                        quantity: i.quantity,
                        ingredient: i.name,
                        checked: false,
                        onToggle: () {},
                      )),
                      const SizedBox(height: AkeliSpacing.lg),
                      const AkeliSectionHeader(title: 'Instructions'),
                      const SizedBox(height: 12),
                      Text(instructions, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AkeliColors.textSecondary)),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
