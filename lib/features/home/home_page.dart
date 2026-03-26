// ─────────────────────────────────────────────────────────────────────────────
// IMPORTS
// Flutter core & third-party packages needed by this file.
// ─────────────────────────────────────────────────────────────────────────────
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // State management
import 'package:go_router/go_router.dart';               // Navigation (context.go)

import '../../core/theme.dart';                          // Design tokens: AkeliColors, AkeliRadius, AkeliShadows
import '../../providers/user_profile_provider.dart';     // userProfileProvider, healthProfileProvider
import '../../providers/nutrition_provider.dart';         // todayNutritionProvider
import '../../providers/meal_plan_provider.dart';         // activeMealPlanProvider
import '../../providers/recipe_provider.dart';            // feedProvider, FeedParams
import '../../shared/widgets/progress_circle.dart';       // AkeliProgressCircle widget
import '../../shared/widgets/meal_card.dart';             // AkeliMealCard widget
import '../../shared/widgets/shopping_row.dart';          // AkeliShoppingRow widget
import '../../shared/widgets/section_header.dart';        // AkeliSectionHeader widget
import '../../shared/widgets/akeli_recipe_card.dart';     // AkeliRecipeCard widget

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
  // This list is hardcoded (placeholder data). It is NOT coming from Supabase yet.
  // It lives in the widget's local state so that toggling checkboxes causes a
  // rebuild via setState().
  final List<_ShoppingPreviewItem> _shoppingItems = [
    const _ShoppingPreviewItem(quantity: '500 g', ingredient: 'Tomates', checked: false),
    const _ShoppingPreviewItem(quantity: '1 kg',  ingredient: 'Riz blanc', checked: false),
    const _ShoppingPreviewItem(quantity: '200 g', ingredient: 'Poulet', checked: true),
    const _ShoppingPreviewItem(quantity: '3 pcs', ingredient: 'Oignons', checked: false),
  ];

  // ── LOCAL METHOD ───────────────────────────────────────────────────────────
  // Called when the user taps a checkbox in the shopping preview.
  // setState() tells Flutter to call build() again so the UI reflects the change.
  // copyWith() creates a new item with only `checked` changed (immutable pattern).
  void _toggleShoppingItem(int index) {
    setState(() {
      _shoppingItems[index] = _shoppingItems[index].copyWith(
        checked: !_shoppingItems[index].checked,
      );
    });
  }

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

      // ── STICKY APP BAR ─────────────────────────────────────────────────────
      // Consistent with "Digital Editorial" header:
      // - Leading: User Avatar
      // - Title: Bonjour, [Name] (Title Purple)
      // - Actions: Notifications & Settings
      // -----------------------------------------------------------------------
      appBar: AppBar(
        backgroundColor: AkeliColors.background,
        elevation: 0,
        centerTitle: false,
        leadingWidth: 72,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: CircleAvatar(
            backgroundColor: AkeliColors.surfaceContainerHigh,
            backgroundImage: profileAsync.whenOrNull(
              data: (p) => p?.avatarUrl != null ? NetworkImage(p!.avatarUrl!) : null,
            ),
            child: profileAsync.maybeWhen(
              data: (p) => p?.avatarUrl == null ? const Icon(Icons.person_outline, color: AkeliColors.outline) : null,
              orElse: () => const SizedBox.shrink(),
            ),
          ),
        ),
        title: profileAsync.when(
          data: (profile) {
            final name = profile?.displayName.split(' ').firstOrNull ?? 'Ami';
            return Text(
              'Bonjour, $name!',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AkeliColors.accentPurple,
                fontWeight: FontWeight.w700,
              ),
            );
          },
          loading: () => Text('Chargement...', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AkeliColors.accentPurple)),
          error: (_, __) => Text('Bonjour!', style: Theme.of(context).textTheme.titleLarge?.copyWith(color: AkeliColors.accentPurple)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none_rounded, color: AkeliColors.onSurface),
            onPressed: () => context.go('/notifications'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AkeliColors.onSurface),
            onPressed: () => context.push('/settings'),
          ),
          const SizedBox(width: 8),
        ],
      ),

      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),

            // ══════════════════════════════════════════════════════════════════
            // SECTION 1 — COMBINED METRICS & WEIGHT CONTAINER
            //
            // Design: SurfaceContainerLow card with XL (24px) corners.
            // Layout: Row containing Weight (Left) and Calories (Right).
            // This replaces the two separate circles with a unified journal entry look.
            // ══════════════════════════════════════════════════════════════════
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AkeliColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(24), // XL Corner radius
                ),
                child: Row(
                  children: [
                    // ── LEFT: Weight Circular Metric ────────────────────────
                    Expanded(
                      child: healthAsync.maybeWhen(
                        data: (health) {
                          final weight = health?.weightKg ?? 0.0;
                          final target = health?.targetWeightKg ?? 70.0;
                          return AkeliProgressCircle(
                            label: 'Poids actuel',
                            value: weight > 0 ? weight.toStringAsFixed(1) : '--',
                            unit: 'kg',
                            progress: (target > 0) ? (weight / target).clamp(0.0, 1.0) : 0.0,
                            color: AkeliColors.primary,
                          );
                        },
                        orElse: () => AkeliProgressCircle(
                          label: 'Poids actuel',
                          value: '--',
                          unit: 'kg',
                          progress: 0,
                          color: AkeliColors.outline.withValues(alpha: 0.3),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 32),
                    
                    // ── RIGHT: Calories Circle ───────────────────────────────
                    // Still using the custom circle but embedded within the main card
                    SizedBox(
                      width: 100,
                      height: 100,
                      child: nutritionAsync.when(
                        data: (nutrition) {
                          final consumed = nutrition?.calories.toInt() ?? 0;
                          const target = 2000.0;
                          return AkeliProgressCircle(
                            label: 'Calories', 
                            value: '$consumed', 
                            unit: 'kcal',
                            progress: (consumed / target).clamp(0.0, 1.0), 
                            color: AkeliColors.secondary,
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
            const SizedBox(height: 24),

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
            const SizedBox(height: 8),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color:        AkeliColors.surfaceContainerLow,       // High-fidelity background
                  borderRadius: BorderRadius.circular(AkeliRadius.lg), // 24px organic corners
                  boxShadow:    const [AkeliShadows.sm],                // subtle shadow
                ),
                // List.generate creates exactly N children.
                // .take(4) ensures we never show more than 4 rows even if _shoppingItems grows.
                child: Column(
                  children: List.generate(
                    _shoppingItems.take(4).length,
                    (index) {
                      final item = _shoppingItems[index];
                      return AkeliShoppingRow(
                        quantity:   item.quantity,
                        ingredient: item.ingredient,
                        checked:    item.checked,
                        onToggle:   () => _toggleShoppingItem(index), // calls setState above
                      );
                    },
                  ),
                ),
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
              height: 200, // fixed height for horizontal scroll area
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
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRIVATE DATA CLASS — _ShoppingPreviewItem
//
// A simple immutable value object used only within this file (private: underscore prefix).
// Holds a single row in the shopping preview section.
// Because it is immutable (const constructor), updates are done via copyWith().
// ─────────────────────────────────────────────────────────────────────────────
class _ShoppingPreviewItem {
  final String quantity;    // e.g. "500 g"
  final String ingredient;  // e.g. "Tomates"
  final bool   checked;     // whether the checkbox is ticked

  const _ShoppingPreviewItem({
    required this.quantity,
    required this.ingredient,
    required this.checked,
  });

  // copyWith: returns a new instance with only the specified field changed.
  // Common immutable pattern — avoids mutating the object directly.
  _ShoppingPreviewItem copyWith({bool? checked}) => _ShoppingPreviewItem(
        quantity:   quantity,
        ingredient: ingredient,
        checked:    checked ?? this.checked, // keep old value if not provided
      );
}
