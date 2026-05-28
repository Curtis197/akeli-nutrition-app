import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/logger.dart';
import '../../core/theme.dart';
import '../../providers/food_region_provider.dart';
import '../../providers/meal_plan_provider.dart';
import '../../providers/nutrition_plan_provider.dart';
import '../../providers/nutrition_provider.dart';
import '../../providers/recipe_provider.dart';
import '../../providers/user_profile_provider.dart';
import '../../shared/models/meal_plan.dart';
import '../../shared/widgets/akeli_recipe_card.dart';
import '../../shared/widgets/akeli_weight_stepper.dart';
import '../../shared/widgets/meal_card.dart';
import '../../shared/widgets/progress_circle.dart';
import '../../shared/widgets/section_header.dart';
import '../../shared/widgets/shopping_row.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  double _currentWeight = 68.5;
  String _activeFilter = 'tout';
  final Set<String> _checkedShoppingIds = {};
  final _logger = appLogger;

  @override
  void initState() {
    super.initState();
    _logger.provider('_HomePageState initState | _currentWeight default: $_currentWeight kg (hardcoded)');
  }

  @override
  void dispose() {
    _logger.provider('_HomePageState disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final healthAsync = ref.watch(healthProfileProvider);
    final nutritionAsync = ref.watch(todayNutritionProvider);
    final nutritionPlanAsync = ref.watch(activeNutritionPlanProvider);
    final mealPlanAsync = ref.watch(activeMealPlanProvider);
    final shoppingAsync = ref.watch(shoppingListProvider);
    final recipesAsync = ref.watch(feedProvider(const FeedParams(limit: 10)));
    final weightAsync = ref.watch(weightLogProvider);
    final regionNames = ref.watch(foodRegionNamesProvider).valueOrNull ?? {};

    ref.listen(weightLogProvider, (_, next) {
      next.when(
        data: (entries) {
          _logger.provider('weightLogProvider listener | entries: ${entries.length}');
          if (entries.isNotEmpty) {
            _logger.provider('weightLogProvider listener | updating stepper: $_currentWeight → ${entries.first.weightKg} kg (from DB row[0])');
            setState(() => _currentWeight = entries.first.weightKg);
          } else {
            _logger.provider('weightLogProvider listener | 0 entries → stepper stays at hardcoded default: $_currentWeight kg');
          }
        },
        loading: () => _logger.provider('weightLogProvider listener | loading'),
        error: (e, st) => _logger.provider('weightLogProvider listener | error: $e'),
      );
    });

    _logger.provider(
        'HomePage build() | profileAsync.isLoading: ${profileAsync.isLoading} | mealPlanAsync.isLoading: ${mealPlanAsync.isLoading}');

    return Scaffold(
      backgroundColor: AkeliColors.background,
      body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: profileAsync.when(
                  data: (profile) {
                    final name =
                        profile?.displayName.split(' ').firstOrNull ?? 'Ami';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bonjour, $name!',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: AkeliColors.onSurface,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Heureux de vous revoir.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AkeliColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const SizedBox(height: 40),
                  error: (_, __) => Text(
                    'Bonjour!',
                    style: GoogleFonts.plusJakartaSans(
                        fontSize: 28, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: AkeliColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(AkeliRadius.xl),
                    boxShadow: const [AkeliShadows.sm],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        _logger.userAction('Nutrition card tapped', screen: 'HomePage');
                        context.go('/nutrition');
                      },
                      borderRadius: BorderRadius.circular(AkeliRadius.xl),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 32, horizontal: 24),
                        child: Column(
                          children: [
                            IntrinsicHeight(
                              child: Row(
                                children: [
                                  Expanded(
                                    child: weightAsync.maybeWhen(
                                      data: (entries) {
                                        final health = healthAsync.valueOrNull;
                                        _logger.provider('Weight graph data: | entries: ${entries.length} | healthProfile: ${health == null ? "null" : "loaded"} | targetWeightKg: ${health?.targetWeightKg}');
                                        for (var i = 0; i < entries.length; i++) {
                                          _logger.provider('  graph entry[$i] | date: ${entries[i].date} | weightKg: ${entries[i].weightKg}');
                                        }

                                        if (entries.isEmpty) {
                                          _logger.provider('Weight graph → data (no entries)');
                                          return const AkeliModernMetric(
                                            label: 'Poids actuel',
                                            subtitle: '--kg → --kg',
                                            value: '0',
                                            unit: '%',
                                            progress: 0,
                                            gradientColors: [
                                              AkeliColors.primary,
                                              AkeliColors.primaryContainer
                                            ],
                                          );
                                        }

                                        final currentWeight = entries.first.weightKg;
                                        final startingWeight = entries.last.weightKg;
                                        final targetWeight = health?.targetWeightKg;

                                        double progress = 0.0;
                                        if (targetWeight != null && startingWeight != targetWeight) {
                                          progress = (startingWeight - currentWeight) / (startingWeight - targetWeight);
                                        }
                                        progress = progress.clamp(0.0, 1.0);

                                        _logger.provider(
                                          'Weight graph → data | current: ${currentWeight}kg | target: ${targetWeight?.toStringAsFixed(1) ?? "--"}kg | progress: ${(progress * 100).toInt()}%');

                                        return AkeliModernMetric(
                                          label: 'Poids',
                                          subtitle: '${currentWeight.toStringAsFixed(1)}kg → ${targetWeight?.toStringAsFixed(1) ?? '--'}kg',
                                          value: '${(progress * 100).toInt()}',
                                          unit: '%',
                                          progress: progress,
                                          gradientColors: const [
                                            AkeliColors.primary,
                                            AkeliColors.primaryContainer
                                          ],
                                        );
                                      },
                                      orElse: () => const AkeliModernMetric(
                                        label: 'Poids actuel',
                                        subtitle: '--kg → --kg',
                                        value: '0',
                                        unit: '%',
                                        progress: 0,
                                        gradientColors: [
                                          AkeliColors.primary,
                                          AkeliColors.primaryContainer
                                        ],
                                      ),
                                    ),
                                  ),
                                  VerticalDivider(
                                    color: AkeliColors.outline.withValues(alpha: 0.1),
                                    thickness: 1,
                                    indent: 10,
                                    endIndent: 10,
                                  ),
                                  Expanded(
                                    child: nutritionAsync.when(
                                      data: (nutrition) {
                                        final consumed = nutrition?.calories.toInt() ?? 0;
                                        final target = (nutritionPlanAsync.valueOrNull?.calorieGoal ?? 2000).toDouble();
                                        final double rawProgress = consumed / target;
                                        final progress = rawProgress.clamp(0.0, 1.0);

                                        _logger.provider(
                                          'Calories graph → data | consumed: $consumed kcal | target: ${target.toInt()} kcal | progress: ${(progress * 100).toInt()}%');

                                        return AkeliModernMetric(
                                          label: 'Calories',
                                          subtitle: '$consumed → ${target.toInt()} kcal',
                                          value: '${(progress * 100).toInt()}',
                                          unit: '%',
                                          progress: progress,
                                          gradientColors: const [
                                            AkeliColors.secondary,
                                            AkeliColors.secondaryContainer
                                          ],
                                        );
                                      },
                                      loading: () => const Center(
                                          child: CircularProgressIndicator()),
                                      error: (_, __) =>
                                          const Icon(Icons.error_outline),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Text(
                                  'Voir mes progrès →',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AkeliColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AkeliWeightStepper(
                  weight: _currentWeight,
                  onChanged: (newWeight) {
                    HapticFeedback.lightImpact();
                    _logger.userAction('Weight stepper changed',
                        screen: 'HomePage',
                        metadata: {'newWeight': newWeight});
                    setState(() => _currentWeight = newWeight);
                    ref.read(weightLogNotifierProvider.notifier).addEntry(newWeight);
                  },
                ),
              ),
              const SizedBox(height: 32),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: AkeliSectionHeader(
                  title: 'Vos repas du jour',
                  color: AkeliColors.primary,
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                height: 310,
                child: mealPlanAsync.when(
                  data: (plan) {
                    final today = DateTime.now();
                    final todayEntries = plan?.entriesForDate(today) ?? [];
                    if (todayEntries.isEmpty) {
                      return Center(
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            "Aucun repas planifié pour aujourd'hui.",
                            style: GoogleFonts.inter(
                                color: AkeliColors.onSurfaceVariant),
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
                          key: ValueKey(entry.id),
                          title: entry.recipeTitle ?? 'Repas',
                          mealType: entry.mealTypeLabel,
                          calories: entry.calories,
                          protein: entry.proteinG,
                          carbs: entry.carbsG,
                          fat: entry.fatG,
                          imageUrl: entry.recipeThumbnail,
                          onTap: () {
                            _logger.userAction('Meal card tapped',
                                screen: 'HomePage',
                                metadata: {'mealId': entry.id});
                            context.go('/meal/${entry.id}');
                          },
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Erreur: $error',
                          style: GoogleFonts.inter(
                              color: AkeliColors.onSurfaceVariant)),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: AkeliSectionHeader(
                  title: 'Liste de courses',
                  trailingLabel: 'Voir tout',
                  onTrailingTap: () {
                    _logger.userAction('View all shopping tapped',
                        screen: 'HomePage');
                    context.go('/shopping-list');
                  },
                ),
              ),
              const SizedBox(height: 16),

              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _FilterChip(
                      label: 'Tout',
                      isActive: _activeFilter == 'tout',
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _logger.userAction('Shopping filter changed',
                            screen: 'HomePage',
                            metadata: {'filter': 'tout'});
                        setState(() => _activeFilter = 'tout');
                      },
                    ),
                    _FilterChip(
                      label: 'À acheter',
                      isActive: _activeFilter == 'acheter',
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _logger.userAction('Shopping filter changed',
                            screen: 'HomePage',
                            metadata: {'filter': 'acheter'});
                        setState(() => _activeFilter = 'acheter');
                      },
                    ),
                    _FilterChip(
                      label: 'Pris',
                      isActive: _activeFilter == 'pris',
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _logger.userAction('Shopping filter changed',
                            screen: 'HomePage',
                            metadata: {'filter': 'pris'});
                        setState(() => _activeFilter = 'pris');
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: shoppingAsync.when(
                  data: (items) {
                    final filtered = _filterShoppingItems(items);
                    if (filtered.isEmpty) {
                      return Container(
                        height: 100,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AkeliColors.surfaceContainerLowest,
                          borderRadius:
                              BorderRadius.circular(AkeliRadius.xl),
                          boxShadow: const [AkeliShadows.sm],
                        ),
                        child: Text(
                          'Aucun article trouvé',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AkeliColors.onSurfaceVariant
                                .withValues(alpha: 0.5),
                          ),
                        ),
                      );
                    }
                    return Container(
                      decoration: BoxDecoration(
                        color: AkeliColors.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(AkeliRadius.xl),
                        boxShadow: const [AkeliShadows.sm],
                      ),
                      child: Column(
                        children: List.generate(filtered.length, (index) {
                          final item = filtered[index];
                          final isChecked =
                              _checkedShoppingIds.contains(item.ingredientId);
                          return AkeliShoppingRow(
                            quantity: item.quantityDisplay,
                            ingredient: item.name,
                            checked: isChecked,
                            onToggle: () {
                              HapticFeedback.mediumImpact();
                              _logger.userAction('Shopping item toggled',
                                  screen: 'HomePage',
                                  metadata: {
                                    'itemId': item.ingredientId,
                                    'checked': !isChecked
                                  });
                              setState(() {
                                if (isChecked) {
                                  _checkedShoppingIds
                                      .remove(item.ingredientId);
                                } else {
                                  _checkedShoppingIds.add(item.ingredientId);
                                }
                              });
                            },
                          );
                        }),
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 24),

              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: AkeliSectionHeader(
                  title: 'Recettes recommandées',
                  color: AkeliColors.secondary,
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                height: 220,
                child: recipesAsync.when(
                  data: (recipes) {
                    if (recipes.isEmpty) {
                      return Center(
                        child: Padding(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'Aucune recette disponible.',
                            style: GoogleFonts.inter(
                                color: AkeliColors.onSurfaceVariant),
                          ),
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
                          key: ValueKey(recipe.id),
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
                              region: recipe.regionId != null ? regionNames[recipe.regionId!] ?? recipe.regionId : null,
                              imageUrl: recipe.thumbnailUrl,
                              hasImage: true,
                              isMinimalist: true,
                              onTap: () {
                                _logger.userAction('Recipe card tapped',
                                    screen: 'HomePage',
                                    metadata: {'recipeId': recipe.id});
                                context.go('/recipe/${recipe.id}');
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('Erreur: $error',
                          style: GoogleFonts.inter(
                              color: AkeliColors.onSurfaceVariant)),
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

  List<ShoppingItem> _filterShoppingItems(List<ShoppingItem> allItems) {
    List<ShoppingItem> filtered;
    if (_activeFilter == 'tout') {
      filtered = allItems;
    } else if (_activeFilter == 'acheter') {
      filtered = allItems
          .where((i) => !_checkedShoppingIds.contains(i.ingredientId))
          .toList();
    } else {
      filtered = allItems
          .where((i) => _checkedShoppingIds.contains(i.ingredientId))
          .toList();
    }
    _logger.provider(
        'HomePage: filtering shopping items | filter: $_activeFilter | total: ${allItems.length} | filtered: ${filtered.length}');
    return filtered.take(4).toList();
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isActive,
      label: label,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            color: isActive
                ? AkeliColors.primary
                : AkeliColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(AkeliRadius.pill),
            border: Border.all(
              color: isActive
                  ? AkeliColors.primary
                  : AkeliColors.outline.withValues(alpha: 0.2),
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AkeliColors.primary.withValues(alpha: 0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isActive
                  ? AkeliColors.onPrimary
                  : AkeliColors.onSurfaceVariant,
            ),
          ),
        ),
      ),
    );
  }
}
