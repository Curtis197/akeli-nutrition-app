// ─────────────────────────────────────────────────────────────────────────────
// IMPORTS
// Flutter core & third-party packages needed by this file.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';               // Added for HapticFeedback
import 'package:flutter_riverpod/flutter_riverpod.dart'; // State management
import 'package:go_router/go_router.dart';               // Navigation (context.go)

import '../../core/theme.dart';                          // Design tokens: AkeliColors, AkeliRadius, AkeliShadows
import '../../providers/user_profile_provider.dart';     // userProfileProvider, healthProfileProvider
import '../../providers/nutrition_provider.dart';         // todayNutritionProvider
import '../../providers/meal_plan_provider.dart';         // activeMealPlanProvider
import '../../providers/recipe_provider.dart';            // feedProvider, FeedParams
import '../../shared/models/meal_plan.dart';              // Added for ShoppingItem
import '../../shared/widgets/progress_circle.dart';       // AkeliModernMetric widget
import '../../shared/widgets/meal_card.dart';             // AkeliMealCard widget
import '../../shared/widgets/shopping_row.dart';          // AkeliShoppingRow widget
import '../../shared/widgets/section_header.dart';        // AkeliSectionHeader widget
import '../../shared/widgets/akeli_recipe_card.dart';     // AkeliRecipeCard widget
import '../../shared/widgets/akeli_weight_stepper.dart';  // AkeliWeightStepper widget

// ─────────────────────────────────────────────────────────────────────────────
// WIDGET CLASS
//
// ConsumerStatefulWidget = a StatefulWidget that can READ Riverpod providers.
// Use this when the page needs both local state (setState) AND providers (ref.watch).
// ─────────────────────────────────────────────────────────────────────────────
class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

// ─────────────────────────────────────────────────────────────────────────────
// STATE CLASS
//
// All logic and build() live here. The leading underscore (_) means it is
// private to this file — Flutter convention for State classes.
// ─────────────────────────────────────────────────────────────────────────────
class _HomePageState extends ConsumerState<HomePage> {

  // ── LOCAL STATE ────────────────────────────────────────────────────────────
  // Shopping checkbox state is managed here for immediate interaction.
  // We mirror the persistent state from Supabase if needed, but for now 
  // it is local-only per session for simplicity.


  // ── LOCAL STATE FOR INTERACTION ─────────────────────────────────────────────
  double _currentWeight = 68.5;  // Local state for the stepper
  String _activeFilter  = 'tout'; // 'tout', 'acheter', 'pris'

  // ── LOCAL METHOD (Removed placeholder logic) ──────────────────────────────

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD METHOD
  //
  // Called every time setState() or a watched provider changes.
  // Returns the widget tree that Flutter renders on screen.
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {

    // ── PROVIDER SUBSCRIPTIONS ──────────────────────────────────────────────
    // ref.watch() subscribes to a provider. When provider data changes,
    // Flutter automatically calls build() again with the new value.
    //
    // Each provider returns an AsyncValue<T> with three states:
    //   .when(data: ..., loading: ..., error: ...)
    // -----------------------------------------------------------------------
    final profileAsync   = ref.watch(userProfileProvider);   // → AsyncValue<UserProfile?>
    final healthAsync    = ref.watch(healthProfileProvider);  // → AsyncValue<HealthProfile?>
    final nutritionAsync = ref.watch(todayNutritionProvider); // → AsyncValue<DailyNutrition?>
    final mealPlanAsync  = ref.watch(activeMealPlanProvider); // → AsyncValue<MealPlan?>
    final shoppingAsync  = ref.watch(shoppingListProvider);   // → AsyncValue<List<ShoppingItem>>
    final recipesAsync   = ref.watch(feedProvider(          // → AsyncValue<List<Recipe>>
      const FeedParams(limit: 10),                          //   FeedParams is the filter/param object
    ));

    // ─────────────────────────────────────────────────────────────────────────
    // ROOT WIDGET: Scaffold
    //
    // Scaffold provides the standard page structure:
    //   - backgroundColor: sets the page background
    //   - appBar: top bar
    //   - body: scrollable content
    // ─────────────────────────────────────────────────────────────────────────
    return Scaffold(
      backgroundColor: AkeliColors.background,

      body: NestedScrollView(
        floatHeaderSlivers: true,
        headerSliverBuilder: (context, innerBoxIsScrolled) => [
          SliverAppBar(
            pinned: false,
            floating: true,
            snap: false,
            backgroundColor: AkeliColors.background,
            automaticallyImplyLeading: false,
            elevation: 0,
            scrolledUnderElevation: 0,
            leadingWidth: 72,
            leading: Padding(
              padding: const EdgeInsets.only(left: 16),
              child: profileAsync.when(
                data: (profile) => Center(
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AkeliColors.primary.withValues(alpha: 0.1),
                        width: 1.5,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 20,
                      backgroundColor: AkeliColors.surfaceContainerHigh,
                      backgroundImage: profile?.avatarUrl != null 
                          ? NetworkImage(profile!.avatarUrl!) 
                          : null,
                      child: profile?.avatarUrl == null 
                          ? const Icon(Icons.person_outline, color: AkeliColors.outline, size: 20) 
                          : null,
                    ),
                  ),
                ),
                loading: () => const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                error: (_, __) => const CircleAvatar(radius: 20, child: Icon(Icons.person)),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: AkeliColors.secondary, size: 26),
                onPressed: () => context.go('/notifications'),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: const Icon(Icons.settings_outlined, color: AkeliColors.secondary, size: 26),
                  onPressed: () => context.go('/profile'),
                ),
              ),
            ],
          ),
        ],
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── WELCOME HEADER ───────────────────────────────────────────────────
              // Moved from AppBar to Body to match FlutterFlow layout
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: profileAsync.when(
                  data: (profile) {
                    final name = profile?.displayName.split(' ').firstOrNull ?? 'Ami';
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bonjour, $name!',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AkeliColors.onSurface,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Heureux de vous revoir.', // Subtitle or date can go here
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AkeliColors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const SizedBox(height: 40),
                  error: (_, __) => const Text('Bonjour!'),
                ),
              ),
              const SizedBox(height: 24),

            // SECTION 1 — COMBINED METRICS
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.02),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: IntrinsicHeight(
                  child: Row(
                    children: [
                      // ── LEFT: Weight Goal ────────────────────────
                      Expanded(
                        child: healthAsync.maybeWhen(
                          data: (health) {
                            final weight = health?.weightKg ?? _currentWeight;
                            final target = health?.targetWeightKg ?? 70.0;
                            return AkeliModernMetric(
                              label: 'Poids actuel',
                              value: weight > 0 ? weight.toStringAsFixed(1) : '--',
                              unit: 'kg',
                              progress: (target > 0) ? (target / weight).clamp(0.0, 1.0) : 0.7,
                              gradientColors: const [AkeliColors.primary, AkeliColors.primaryContainer],
                            );
                          },
                          orElse: () => const AkeliModernMetric(
                            label: 'Poids actuel',
                            value: '--',
                            unit: 'kg',
                            progress: 0,
                          ),
                        ),
                      ),
                      
                      VerticalDivider(
                        color: AkeliColors.outline.withValues(alpha: 0.1),
                        thickness: 1,
                        indent: 10,
                        endIndent: 10,
                      ),
                      
                      // ── RIGHT: Calories Progress ───────────────────────────────
                      Expanded(
                        child: nutritionAsync.when(
                          data: (nutrition) {
                            final consumed = nutrition?.calories.toInt() ?? 0;
                            const target = 2000.0;
                            return AkeliModernMetric(
                              label: 'Calories', 
                              value: '$consumed', 
                              unit: 'kcal',
                              progress: (consumed / target).clamp(0.0, 1.0), 
                              gradientColors: const [AkeliColors.secondary, AkeliColors.secondaryContainer],
                              onTap: () => context.go('/nutrition'),
                            );
                          },
                          loading: () => const Center(child: CircularProgressIndicator()),
                          error: (_, __) => const Icon(Icons.error_outline),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // ── NEW: WEIGHT STEPPER ──────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AkeliWeightStepper(
                weight: _currentWeight,
                onChanged: (newWeight) {
                  HapticFeedback.lightImpact();
                  setState(() => _currentWeight = newWeight);
                },
              ),
            ),
            const SizedBox(height: 32),

            // ══════════════════════════════════════════════════════════════════
            // SECTION 2 — MEALS OF THE DAY
            //
            // Data source: activeMealPlanProvider → MealPlan
            // Filters today's entries from the active plan using entriesForDate().
            // Renders as a HORIZONTAL scrollable list of AkeliMealCard widgets.
            // Height is increased to 310 px to fit images, macros, and metadata.
            // ══════════════════════════════════════════════════════════════════
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: AkeliSectionHeader(
                title: 'Vos repas du jour',
                color: AkeliColors.primary,
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 310, // Height increased for high-fidelity content
              child: mealPlanAsync.when(
                data: (plan) {
                  // Filter the meal plan entries to only today's date
                  final today       = DateTime.now();
                  final todayEntries = plan?.entriesForDate(today) ?? [];

                  // Empty state: show a message if no meals are planned today
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

                  // Horizontal list of high-fidelity meal cards
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,          // scroll left ↔ right
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: todayEntries.length,
                    itemBuilder: (context, index) {
                      final entry = todayEntries[index];
                      // Each card now displays full nutritional metadata
                      return AkeliMealCard(
                        title:    entry.recipeTitle ?? 'Repas',
                        mealType: entry.mealTypeLabel,         // e.g. "Déjeuner"
                        calories: entry.calories ?? 0,
                        protein:  entry.proteinG,
                        carbs:    entry.carbsG,
                        fat:      entry.fatG,
                        imageUrl: entry.recipeThumbnail,
                        onTap:    () => context.go('/meal/${entry.id}'),
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

            // ══════════════════════════════════════════════════════════════════
            // SECTION 3 — SHOPPING LIST PREVIEW
            //
            // ⚠️  Data source: LOCAL STATE (_shoppingItems), NOT Supabase.
            // This is placeholder data. The real shopping list is at /shopping-list
            // which reads from the shoppingListProvider (Supabase RPC).
            //
            // Layout:
            //   - SectionHeader with "Voir tout" → navigates to /shopping-list
            //   - SurfaceContainerLow rounded card containing up to 4 preview items.
            // ══════════════════════════════════════════════════════════════════
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: AkeliSectionHeader(
                title:          'Liste de courses',
                trailingLabel:  'Voir tout',
                onTrailingTap:  () => context.go('/shopping-list'), // navigate to full list
              ),
            ),
            const SizedBox(height: 16),

            // ── SHOPPING FILTERS ─────────────────────────────────────────────
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
                      setState(() => _activeFilter = 'tout');
                    },
                  ),
                  _FilterChip(
                    label: 'À acheter',
                    isActive: _activeFilter == 'acheter',
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _activeFilter = 'acheter');
                    },
                  ),
                  _FilterChip(
                    label: 'Pris',
                    isActive: _activeFilter == 'pris',
                    onTap: () {
                      HapticFeedback.selectionClick();
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
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: const [AkeliShadows.sm],
                      ),
                      child: Text(
                        'Aucun article trouvé',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AkeliColors.onSurfaceVariant.withValues(alpha: 0.5),
                        ),
                      ),
                    );
                  }
                  return Container(
                    decoration: BoxDecoration(
                      color:        Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      boxShadow:    const [AkeliShadows.sm],
                    ),
                    child: Column(
                      children: List.generate(
                        filtered.length,
                        (index) {
                          final item = filtered[index];
                          final isChecked = _checkedShoppingIds.contains(item.ingredientId);
                          return AkeliShoppingRow(
                            quantity:   item.quantityDisplay,
                            ingredient: item.name,
                            checked:    isChecked,
                            onToggle:   () {
                              HapticFeedback.mediumImpact();
                              setState(() {
                                if (isChecked) {
                                  _checkedShoppingIds.remove(item.ingredientId);
                                } else {
                                  _checkedShoppingIds.add(item.ingredientId);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
            const SizedBox(height: 24),

            // ══════════════════════════════════════════════════════════════════
            // SECTION 4 — RECOMMENDED RECIPES
            //
            // Data source: feedProvider (Supabase RPC `recommend_recipes`)
            // Fetches up to 10 personalized recipes via FeedParams(limit: 10).
            // Renders as a HORIZONTAL scrollable list of AkeliRecipeCard widgets.
            // These cards provide inspiration based on the user's nutritional profile.
            // ══════════════════════════════════════════════════════════════════
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: AkeliSectionHeader(
                title: 'Recettes recommandées',
                color: AkeliColors.secondary, // Differentiated branding color
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 220, // slightly taller for minimalist card
              child: recipesAsync.when(
                data: (recipes) {
                  // Empty state: show info message if no recommendations found
                  if (recipes.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16),
                        child: Text('Aucune recette disponible.',
                          style: TextStyle(color: AkeliColors.textSecondary)),
                      ),
                    );
                  }

                  // Horizontal list of personalized recipe cards
                  return ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: recipes.length,
                    itemBuilder: (context, index) {
                      final recipe = recipes[index];
                      // Each card is fixed-width (160) for consistent horizontal flow
                      return SizedBox(
                        width: 160, 
                        child: Padding(
                          padding: const EdgeInsets.only(right: 12), // gap between cards
                            child: AkeliRecipeCard(
                              title:    recipe.title,
                              calories: recipe.calories?.toInt() ?? 0,
                              rating:   recipe.averageRating,
                              likes:    recipe.likeCount,
                              comments: recipe.ratingCount,
                              saves:    0,              // not tracked yet
                              region:   recipe.regionId,
                              imageUrl: recipe.thumbnailUrl,
                              hasImage: true,
                              isMinimalist: true,       // DIGITAL EDITORIAL aesthetic
                              onTap:    () => context.go('/recipe/${recipe.id}'),
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

            // Bottom padding so the last section is not hidden behind the bottom nav bar
            const SizedBox(height: 80),
          ],
        ),
      ),
    ),
  );
}

  // ── HELPER METHODS ──────────────────────────────────────────────────────────
  final Set<String> _checkedShoppingIds = {};

  List<ShoppingItem> _filterShoppingItems(List<ShoppingItem> allItems) {
    List<ShoppingItem> filtered = [];
    if (_activeFilter == 'tout') {
      filtered = allItems;
    } else if (_activeFilter == 'acheter') {
      filtered = allItems.where((i) => !_checkedShoppingIds.contains(i.ingredientId)).toList();
    } else {
      filtered = allItems.where((i) => _checkedShoppingIds.contains(i.ingredientId)).toList();
    }
    return filtered.take(4).toList();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRIVATE DATA CLASSES (UNUSED - REMOVED PLACEHOLDERS)
// ─────────────────────────────────────────────────────────────────────────────

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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isActive ? AkeliColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(40),
          border: Border.all(
            color: isActive ? AkeliColors.primary : AkeliColors.outline.withValues(alpha: 0.2),
          ),
          boxShadow: isActive ? [
            BoxShadow(
              color: AkeliColors.primary.withValues(alpha: 0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ] : null,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: isActive ? Colors.white : AkeliColors.onSurfaceVariant,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

