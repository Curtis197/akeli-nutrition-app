import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme.dart';
import '../../providers/user_profile_provider.dart';
import '../../providers/nutrition_provider.dart';
import '../../providers/meal_plan_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../shared/widgets/progress_circle.dart';
import '../../shared/widgets/meal_card.dart';
import '../../shared/widgets/shopping_row.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/akeli_recipe_card.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  final List<_ShoppingPreviewItem> _shoppingItems = [
    const _ShoppingPreviewItem(quantity: '500 g', ingredient: 'Tomates', checked: false),
    const _ShoppingPreviewItem(quantity: '1 kg', ingredient: 'Riz blanc', checked: false),
    const _ShoppingPreviewItem(quantity: '200 g', ingredient: 'Poulet', checked: true),
    const _ShoppingPreviewItem(quantity: '3 pcs', ingredient: 'Oignons', checked: false),
  ];

  void _toggleShoppingItem(int index) {
    setState(() {
      _shoppingItems[index] = _shoppingItems[index].copyWith(
        checked: !_shoppingItems[index].checked,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final healthAsync = ref.watch(healthProfileProvider);
    final nutritionAsync = ref.watch(todayNutritionProvider);
    final mealPlanAsync = ref.watch(activeMealPlanProvider);
    final recipesAsync = ref.watch(feedProvider(const FeedParams(limit: 10)));

    return Scaffold(
      backgroundColor: AkeliColors.background,
      appBar: AppBar(
        backgroundColor: AkeliColors.background,
        elevation: 0,
        title: profileAsync.when(
          data: (profile) {
            final name = profile?.displayName?.split(' ').first ?? '';
            return Text(
              name.isEmpty ? 'Bonjour!' : 'Bonjour, $name!',
              style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: AkeliColors.tertiary,
                  ),
            );
          },
          loading: () => Text('Bonjour!',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AkeliColors.tertiary,
                ),
          ),
          error: (_, __) => Text('Bonjour!',
            style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AkeliColors.tertiary,
                ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_outlined,
              color: AkeliColors.tertiary,
            ),
            onPressed: () => context.go('/notifications'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),

            // 1. METRICS ROW
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Center(
                      child: healthAsync.when(
                        data: (health) {
                          final weight = health?.weightKg;
                          final targetWeight = health?.targetWeightKg;
                          final weightStr = weight != null ? weight.toStringAsFixed(1) : '--';
                          double progress = 0.7;
                          if (weight != null && targetWeight != null && targetWeight > 0) {
                            progress = (weight / targetWeight).clamp(0.0, 1.0);
                          }
                          return AkeliProgressCircle(
                            label: 'Poids', value: weightStr, unit: 'kg',
                            progress: progress, color: AkeliColors.primary,
                            onTap: () => context.go('/nutrition'),
                          );
                        },
                        loading: () => AkeliProgressCircle(
                          label: 'Poids', value: '--', unit: 'kg',
                          progress: 0.7, color: AkeliColors.primary,
                          onTap: () => context.go('/nutrition'),
                        ),
                        error: (_, __) => AkeliProgressCircle(
                          label: 'Poids', value: '--', unit: 'kg',
                          progress: 0.0, color: AkeliColors.primary,
                          onTap: () => context.go('/nutrition'),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Center(
                      child: nutritionAsync.when(
                        data: (nutrition) {
                          final consumed = nutrition?.calories.toInt() ?? 0;
                          const target = 2000.0;
                          final progress = (consumed / target).clamp(0.0, 1.0);
                          return AkeliProgressCircle(
                            label: 'Calories', value: '$consumed', unit: 'kcal',
                            progress: progress, color: AkeliColors.secondary,
                            onTap: () => context.go('/nutrition'),
                          );
                        },
                        loading: () => AkeliProgressCircle(
                          label: 'Calories', value: '--', unit: 'kcal',
                          progress: 0.5, color: AkeliColors.secondary,
                          onTap: () => context.go('/nutrition'),
                        ),
                        error: (_, __) => AkeliProgressCircle(
                          label: 'Calories', value: '--', unit: 'kcal',
                          progress: 0.0, color: AkeliColors.secondary,
                          onTap: () => context.go('/nutrition'),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // 2. MEALS OF THE DAY
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AkeliSectionHeader(
                title: 'Mes repas du jour',
                color: AkeliColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 160,
              child: mealPlanAsync.when(
                data: (plan) {
                  final today = DateTime.now();
                  final todayEntries = plan?.entriesForDate(today) ?? [];
                  if (todayEntries.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "Aucun repas planifié pour aujourd'hui.",
                          style: TextStyle(color: AkeliColors.textSecondary),
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: todayEntries.length,
                    itemBuilder: (context, index) {
                      final entry = todayEntries[index];
                      return AkeliMealCard(
                        title: entry.recipeTitle ?? 'Repas',
                        mealType: entry.mealTypeLabel,
                        calories: entry.calories?.toInt() ?? 0,
                        onTap: () => context.go('/meal/${entry.id}'),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Erreur: $error',
                      style: const TextStyle(color: AkeliColors.textSecondary)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 3. SHOPPING LIST PREVIEW
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AkeliSectionHeader(
                title: 'Liste de courses',
                trailingLabel: 'Voir tout',
                onTrailingTap: () => context.go('/shopping-list'),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AkeliRadius.lg),
                  boxShadow: const [AkeliShadows.sm],
                ),
                child: Column(
                  children: List.generate(
                    _shoppingItems.take(4).length,
                    (index) {
                      final item = _shoppingItems[index];
                      return AkeliShoppingRow(
                        quantity: item.quantity,
                        ingredient: item.ingredient,
                        checked: item.checked,
                        onToggle: () => _toggleShoppingItem(index),
                      );
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // 4. RECOMMENDED RECIPES
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AkeliSectionHeader(
                title: 'Recettes recommandées',
                color: AkeliColors.primary,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: recipesAsync.when(
                data: (recipes) {
                  if (recipes.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Aucune recette disponible.',
                          style: TextStyle(color: AkeliColors.textSecondary)),
                      ),
                    );
                  }
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: recipes.length,
                    itemBuilder: (context, index) {
                      final recipe = recipes[index];
                      return SizedBox(
                        width: 160,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: AkeliRecipeCard(
                            title: recipe.title,
                            calories: recipe.calories?.toInt() ?? 0,
                            rating: recipe.averageRating,
                            likes: recipe.likeCount,
                            comments: recipe.ratingCount,
                            saves: 0,
                            region: recipe.regionId,
                            hasImage: true,
                            onTap: () => context.go('/recipe/${recipe.id}'),
                          ),
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text('Erreur: $error',
                      style: const TextStyle(color: AkeliColors.textSecondary)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _ShoppingPreviewItem {
  final String quantity;
  final String ingredient;
  final bool checked;

  const _ShoppingPreviewItem({
    required this.quantity,
    required this.ingredient,
    required this.checked,
  });

  _ShoppingPreviewItem copyWith({bool? checked}) => _ShoppingPreviewItem(
        quantity: quantity,
        ingredient: ingredient,
        checked: checked ?? this.checked,
      );
}
