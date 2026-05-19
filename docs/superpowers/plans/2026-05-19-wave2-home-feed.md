# Wave 2 — Home Dashboard & Feed Page Redesign

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Bring `home_page.dart` and `feed_page.dart` into full Organic Editorial compliance — replace `Colors.white` with `surfaceContainerLowest`, strip multi-line comment banners, fix field placement, add `dispose()` with log, align typography to PlusJakartaSans/Inter, and ensure all logging is complete per CLAUDE.md.

**Architecture:** `home_page.dart` is a full file rewrite (scattered changes throughout). `feed_page.dart` is a targeted typography and header pass — structure stays. Both files already have full logging from prior retrofit work; this plan verifies and preserves it.

**Tech Stack:** Flutter 3, Riverpod 2, GoRouter 14, `google_fonts`, AkeliColors / AkeliRadius / AkeliSpacing / AkeliShadows from `lib/core/theme.dart`, `AkeliGradientButton` from `lib/shared/widgets/akeli_gradient_button.dart`.

---

## File Map

**Modified:**
- `lib/features/home/home_page.dart` — full Organic Editorial redesign
- `lib/features/recipes/feed_page.dart` — header typography + greeting alignment

**Not touched:**
- All providers (already fully logged)
- `lib/core/theme.dart` (tokens already correct from Wave 1)
- Widget files (`meal_card.dart`, `akeli_recipe_card.dart`, etc.)

---

## Task 1: Redesign home_page.dart

**Files:**
- Modify: `lib/features/home/home_page.dart`

### What changes and why

| Issue | Location | Fix |
|-------|----------|-----|
| `Colors.white` — hardcoded, breaks dark-mode readiness | metric card, shopping card, empty state, `_FilterChip` | `AkeliColors.surfaceContainerLowest` |
| Multi-line comment banners (`// ═══`, `// ───`, explanatory blocks) | Throughout file | Remove — violates CLAUDE.md "no multi-line comment blocks" |
| `_checkedShoppingIds` declared mid-file after `}` of build | Line 571 | Move to class-level with other fields |
| Missing `dispose()` | `_HomePageState` | Add with `_logger.provider('_HomePageState disposed')` |
| `AkeliColors.textSecondary` direct reference | error/empty text | Replace with `AkeliColors.onSurfaceVariant` (canonical token) |
| Welcome greeting uses `Theme.of(context).textTheme.headlineMedium` | Greeting | Replace with explicit `GoogleFonts.plusJakartaSans(fontSize: 28, fontWeight: FontWeight.w800)` |
| `_FilterChip` inactive background `Colors.white` | `_FilterChip.build` | `AkeliColors.surfaceContainerLowest`, wrap in `Semantics(button: true, selected: isActive)` |
| Unused import `akeli_gradient_button.dart` | imports | Remove |

- [ ] **Step 1: Replace lib/features/home/home_page.dart with the Organic Editorial version**

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/logger.dart';
import '../../core/theme.dart';
import '../../providers/meal_plan_provider.dart';
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
  void dispose() {
    _logger.provider('_HomePageState disposed');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(userProfileProvider);
    final healthAsync = ref.watch(healthProfileProvider);
    final nutritionAsync = ref.watch(todayNutritionProvider);
    final mealPlanAsync = ref.watch(activeMealPlanProvider);
    final shoppingAsync = ref.watch(shoppingListProvider);
    final recipesAsync = ref.watch(feedProvider(const FeedParams(limit: 10)));

    _logger.provider(
        'HomePage build() | profileAsync.isLoading: ${profileAsync.isLoading} | mealPlanAsync.isLoading: ${mealPlanAsync.isLoading}');

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
                          ? const Icon(Icons.person_outline,
                              color: AkeliColors.outline, size: 20)
                          : null,
                    ),
                  ),
                ),
                loading: () => const Center(
                    child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))),
                error: (_, __) =>
                    const CircleAvatar(radius: 20, child: Icon(Icons.person)),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded,
                    color: AkeliColors.secondary, size: 26),
                onPressed: () {
                  _logger.userAction('Notifications button tapped',
                      screen: 'HomePage');
                  context.go('/notifications');
                },
              ),
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: IconButton(
                  icon: const Icon(Icons.settings_outlined,
                      color: AkeliColors.secondary, size: 26),
                  onPressed: () {
                    _logger.userAction('Settings button tapped',
                        screen: 'HomePage');
                    context.go('/profile');
                  },
                ),
              ),
            ],
          ),
        ],
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome header
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

              // Daily metrics
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      vertical: 32, horizontal: 24),
                  decoration: BoxDecoration(
                    color: AkeliColors.surfaceContainerLowest,
                    borderRadius: BorderRadius.circular(AkeliRadius.xl),
                    boxShadow: const [AkeliShadows.sm],
                  ),
                  child: IntrinsicHeight(
                    child: Row(
                      children: [
                        Expanded(
                          child: healthAsync.maybeWhen(
                            data: (health) {
                              final weight = health?.weightKg ?? _currentWeight;
                              final target = health?.targetWeightKg ?? 70.0;
                              return AkeliModernMetric(
                                label: 'Poids actuel',
                                value: weight > 0
                                    ? weight.toStringAsFixed(1)
                                    : '--',
                                unit: 'kg',
                                progress: (target > 0)
                                    ? (target / weight).clamp(0.0, 1.0)
                                    : 0.7,
                                gradientColors: const [
                                  AkeliColors.primary,
                                  AkeliColors.primaryContainer
                                ],
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
                                gradientColors: const [
                                  AkeliColors.secondary,
                                  AkeliColors.secondaryContainer
                                ],
                                onTap: () {
                                  _logger.userAction('Nutrition metric tapped',
                                      screen: 'HomePage');
                                  context.go('/nutrition');
                                },
                              );
                            },
                            loading: () =>
                                const Center(child: CircularProgressIndicator()),
                            error: (_, __) => const Icon(Icons.error_outline),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Weight stepper
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
                  },
                ),
              ),
              const SizedBox(height: 32),

              // Meals of the day
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
                          title: entry.recipeTitle ?? 'Repas',
                          mealType: entry.mealTypeLabel,
                          calories: entry.calories ?? 0,
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

              // Shopping list preview
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

              // Recommended recipes
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
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
    _logger.d(
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
```

- [ ] **Step 2: Run analyze on home_page.dart**

```
flutter analyze lib/features/home/home_page.dart
```

Expected: No issues found.

- [ ] **Step 3: Commit**

```bash
git add lib/features/home/home_page.dart
git commit -m "feat(design): wave 2 — home_page Organic Editorial redesign (tokens, fields, dispose, comments)"
```

---

## Task 2: Redesign feed_page.dart

**Files:**
- Modify: `lib/features/recipes/feed_page.dart`

### What changes and why

| Issue | Fix |
|-------|-----|
| Greeting uses `Theme.of(context).textTheme.titleMedium` (Inter body) | Replace with `GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w700)` |
| `SearchBar` elevation=1 uses system default fill (grey) | Wrap in `Theme(data: Theme.of(context).copyWith(searchBarTheme: SearchBarThemeData(backgroundColor: WidgetStatePropertyAll(AkeliColors.surfaceContainerLow))))` |
| `AkeliColors.primary` as default CircleAvatar background color | Already correct — keep |
| Missing `google_fonts` import | Add if not present |

- [ ] **Step 1: Add google_fonts import if missing, fix greeting typography**

Read the top of `lib/features/recipes/feed_page.dart`. If `google_fonts` is not imported, add it after the existing imports.

Replace the greeting `Text` widget inside `SliverAppBar` title:

**Find (lines ~88–97):**
```dart
              Expanded(
                child: Text(
                  profileAsync.when(
                    data: (p) => p?.displayName != null
                        ? 'Bonjour, ${p!.displayName} 👋'
                        : 'Bienvenue sur Akeli',
                    loading: () => 'Bienvenue sur Akeli',
                    error: (_, __) => 'Bienvenue sur Akeli',
                  ),
                  style: Theme.of(context).textTheme.titleMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
```

**Replace with:**
```dart
              Expanded(
                child: Text(
                  profileAsync.when(
                    data: (p) => p?.displayName != null
                        ? 'Bonjour, ${p!.displayName} 👋'
                        : 'Bienvenue sur Akeli',
                    loading: () => 'Bienvenue sur Akeli',
                    error: (_, __) => 'Bienvenue sur Akeli',
                  ),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AkeliColors.onSurface,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
```

- [ ] **Step 2: Wrap SearchBar in Theme to apply surfaceContainerLow fill**

**Find (lines ~112–140 — the SearchBar `bottom:` section):**
```dart
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AkeliSpacing.md, 0, AkeliSpacing.md, AkeliSpacing.sm),
              child: SearchBar(
```

**Replace with:**
```dart
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                  AkeliSpacing.md, 0, AkeliSpacing.md, AkeliSpacing.sm),
              child: Theme(
                data: Theme.of(context).copyWith(
                  searchBarTheme: const SearchBarThemeData(
                    backgroundColor:
                        WidgetStatePropertyAll(AkeliColors.surfaceContainerLow),
                  ),
                ),
                child: SearchBar(
```

Then close the extra `Theme(` widget — find the closing `)` of the `SearchBar(...)` widget and add one more `)` to close `Theme(`. Concretely, the full `SearchBar` block ends with `),` — change that closing `)` sequence to:

```dart
              ),  // SearchBar
            ),    // Theme
          ),      // Padding
```

- [ ] **Step 3: Run analyze on feed_page.dart**

```
flutter analyze lib/features/recipes/feed_page.dart
```

Expected: No issues found.

- [ ] **Step 4: Commit**

```bash
git add lib/features/recipes/feed_page.dart
git commit -m "feat(design): wave 2 — feed_page greeting typography + search bar fill token"
```

---

## Task 3: Final verify

**Files:** None (read-only verification)

- [ ] **Step 1: Run full analyze on both files together**

```
flutter analyze lib/features/home/home_page.dart lib/features/recipes/feed_page.dart
```

Expected: `No issues found.`

- [ ] **Step 2: Verify logging is present in both files**

Run these greps — each must produce output:

```bash
grep "_logger.provider" lib/features/home/home_page.dart
grep "_logger.userAction" lib/features/home/home_page.dart
grep "_logger.provider" lib/features/recipes/feed_page.dart
grep "_logger.userAction" lib/features/recipes/feed_page.dart
```

Expected: At least one match per command.

- [ ] **Step 3: Verify Colors.white is gone from home_page.dart**

```bash
grep "Colors.white" lib/features/home/home_page.dart
```

Expected: No output (zero matches).

- [ ] **Step 4: Commit Wave 2 plan file**

```bash
git add docs/superpowers/plans/2026-05-19-wave2-home-feed.md
git commit -m "docs: add Wave 2 home+feed redesign implementation plan"
```
