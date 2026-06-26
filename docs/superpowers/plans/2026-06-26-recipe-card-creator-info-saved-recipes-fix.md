# Recipe Card Creator Info + Saved Recipes Fix — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Show creator name + avatar on every recipe card in the feed, and fix the blank saved-recipes page that results from a `recipe_macro` type-cast bug.

**Architecture:** Task 1 fixes `Recipe.fromJson` so the Saved Recipes page stops throwing a silent type error. Task 2 adds an `_AkeliCreatorRow` ConsumerWidget inside `AkeliRecipeCard` (the only production recipe card widget) that fetches creator data from the existing `creatorByIdProvider`, then updates all five call sites to pass `creatorId`.

**Tech Stack:** Flutter/Dart 3, Riverpod (flutter_riverpod), Supabase (supabase_flutter), go_router, flutter_test.

## Global Constraints

- Every Dart file written or modified MUST import `package:akeli/core/logger.dart` and log user actions (`_logger.userAction(...)`) for every tap/navigation. Providers must log lifecycle events.
- Use `appLogger` (singleton) — never instantiate a new logger.
- Never log passwords, tokens, or full UUIDs in public context.
- Logging is NEVER conditional on `kDebugMode` in source code — it controls runtime visibility only.
- Do NOT run `dart run build_runner build` — no new `@riverpod` providers are introduced.
- Reuse the existing `creatorByIdProvider` from `lib/providers/creator_provider.dart`.
- `AkeliColors`, `AkeliSpacing`, `AkeliRadius` are from `lib/core/theme.dart`.

---

## File Map

| File | Action | Reason |
|------|--------|--------|
| `lib/shared/models/recipe.dart` | Modify | Defensive `recipe_macro` parsing (List → Map) |
| `lib/shared/widgets/akeli_recipe_card.dart` | Modify | Add `creatorId` param + `_AkeliCreatorRow` ConsumerWidget |
| `lib/features/recipes/saved_recipes_page.dart` | Modify | Pass `creatorId`; add logger; fix visible error state |
| `lib/features/settings/saved_recipes_eligibility_page.dart` | Modify | Pass `creatorId` to `AkeliRecipeCard` |
| `lib/features/home/home_page.dart` | Modify | Pass `creatorId` to `AkeliRecipeCard` |
| `lib/features/recipes/feed_page.dart` | Modify | Pass `creatorId` to `AkeliRecipeCard` |
| `test/shared/models/recipe_macro_test.dart` | Create | Unit tests for defensive `recipe_macro` parsing |
| `test/shared/widgets/akeli_recipe_card_creator_test.dart` | Create | Widget test for `_AkeliCreatorRow` rendering |

> **Note:** `creator_detail_page.dart` intentionally skipped — its cards already belong to one creator; a per-card row would be redundant.
> **Note:** `lib/shared/widgets/recipe_card.dart` (`RecipeCard`) is not imported by any production code — skip.

---

## Task 1: Fix `Recipe.fromJson` — defensive `recipe_macro` parsing

**Files:**
- Modify: `lib/shared/models/recipe.dart:92-144`
- Create: `test/shared/models/recipe_macro_test.dart`

**Context:** When `userSavedRecipesProvider` fetches recipes via a direct Supabase `.select('*, recipe_macro(...)')` query, PostgREST returns the related `recipe_macro` row as a `List<dynamic>` (has-many shape), not a bare `Map<String, dynamic>`. The existing cast `json['recipe_macro'] as Map<String, dynamic>?` throws a `TypeError`, the provider enters error state, and the page appears blank (error text uses `AkeliColors.outline` which is nearly invisible on `AkeliColors.background`). The RPC-based feed works because RPCs return flattened JSON.

**Interfaces:**
- No new public API — this is an internal fix to `Recipe.fromJson`.

---

- [ ] **Step 1: Write failing tests**

Create `test/shared/models/recipe_macro_test.dart`:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/shared/models/recipe.dart';

Map<String, dynamic> _baseJson({dynamic recipeMacro}) => {
  'id': 'r-1',
  'creator_id': 'c-1',
  'title': 'Thiéboudienne',
  'prep_time_min': 30,
  'cook_time_min': 60,
  'servings': 4,
  'difficulty': 'medium',
  'average_rating': 4.5,
  'average_rating_taste': 4.5,
  'average_rating_ease': 4.0,
  'average_rating_satiety': 4.5,
  'rating_count': 10,
  'comment_count': 5,
  'like_count': 20,
  'save_count': 8,
  'is_saved': false,
  'is_liked': false,
  'is_published': true,
  'ingredients': [],
  'steps': [],
  'tag_ids': [],
  'created_at': '2026-01-01T00:00:00.000Z',
  'recipe_macro': recipeMacro,
};

void main() {
  group('Recipe.fromJson — recipe_macro', () {
    test('parses recipe_macro when it is a bare Map (RPC shape)', () {
      final json = _baseJson(recipeMacro: {
        'calories': 250.0,
        'protein_g': 20.0,
        'carbs_g': 30.0,
        'fat_g': 5.0,
        'fiber_g': 3.0,
        'calories_per_100g': 120.0,
        'protein_per_100g': 10.0,
        'carbs_per_100g': 15.0,
        'fat_per_100g': 2.5,
      });
      final recipe = Recipe.fromJson(json);
      expect(recipe.calories100g, closeTo(120.0, 0.001));
      expect(recipe.protein100g, closeTo(10.0, 0.001));
    });

    test('parses recipe_macro when it is a List with one item (direct query shape)', () {
      final json = _baseJson(recipeMacro: [
        {
          'calories': 250.0,
          'protein_g': 20.0,
          'carbs_g': 30.0,
          'fat_g': 5.0,
          'fiber_g': 3.0,
          'calories_per_100g': 120.0,
          'protein_per_100g': 10.0,
          'carbs_per_100g': 15.0,
          'fat_per_100g': 2.5,
        }
      ]);
      final recipe = Recipe.fromJson(json);
      expect(recipe.calories100g, closeTo(120.0, 0.001));
      expect(recipe.protein100g, closeTo(10.0, 0.001));
    });

    test('returns null macro fields when recipe_macro is an empty List', () {
      final json = _baseJson(recipeMacro: <dynamic>[]);
      final recipe = Recipe.fromJson(json);
      expect(recipe.calories100g, isNull);
      expect(recipe.protein100g, isNull);
    });

    test('returns null macro fields when recipe_macro is null', () {
      final json = _baseJson(recipeMacro: null);
      final recipe = Recipe.fromJson(json);
      expect(recipe.calories100g, isNull);
      expect(recipe.protein100g, isNull);
    });
  });
}
```

- [ ] **Step 2: Run tests to verify they fail**

```
flutter test test/shared/models/recipe_macro_test.dart -v
```

Expected: 3 of 4 tests fail — the list and empty-list cases throw a `TypeError`.

- [ ] **Step 3: Fix `Recipe.fromJson` in `lib/shared/models/recipe.dart`**

Replace this single line inside `Recipe.fromJson` (currently line 94):

```dart
// BEFORE
final macro = json['recipe_macro'] as Map<String, dynamic>?;
```

```dart
// AFTER — handles both RPC shape (Map) and direct-query shape (List)
final macroRaw = json['recipe_macro'];
final macro = macroRaw is Map<String, dynamic>
    ? macroRaw
    : (macroRaw is List && (macroRaw as List).isNotEmpty)
        ? (macroRaw as List).first as Map<String, dynamic>
        : null;
```

The rest of `Recipe.fromJson` stays unchanged — `macro` is already used correctly below.

- [ ] **Step 4: Run tests to verify they pass**

```
flutter test test/shared/models/recipe_macro_test.dart -v
```

Expected: All 4 tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/models/recipe.dart test/shared/models/recipe_macro_test.dart
git commit -m "fix(recipe): handle recipe_macro as List from direct Supabase query"
```

---

## Task 2: Add `_AkeliCreatorRow` to `AkeliRecipeCard`

**Files:**
- Modify: `lib/shared/widgets/akeli_recipe_card.dart`

**Context:** `AkeliRecipeCard` is a `StatelessWidget`. Adding a new optional `String? creatorId` parameter is non-breaking (all existing callers default to null → no row shown). The `_AkeliCreatorRow` is a `ConsumerWidget` child — Flutter allows ConsumerWidgets inside StatelessWidget trees without issue.

**Interfaces:**
- Consumes: `creatorByIdProvider(creatorId)` from `lib/providers/creator_provider.dart` — returns `AsyncValue<Creator?>` where `Creator` has `.displayName` (String) and `.avatarUrl` (String?).
- Produces: `AkeliRecipeCard` gains `String? creatorId` parameter. If null, no creator row is rendered.

---

- [ ] **Step 1: Write failing widget test**

Create `test/shared/widgets/akeli_recipe_card_creator_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/shared/widgets/akeli_recipe_card.dart';
import 'package:akeli/providers/creator_provider.dart';
import 'package:akeli/shared/models/creator.dart';

Creator _fakeCreator() => const Creator(
  id: 'c-1',
  userId: 'u-1',
  displayName: 'Amara Diallo',
  avatarUrl: null,
  specialties: [],
  recipeCount: 5,
  fanCount: 2,
  isFanEligible: false,
  isMyFanCreator: false,
  averageRating: 4.2,
);

Widget _wrap(Widget child, {Creator? creator}) {
  return ProviderScope(
    overrides: [
      if (creator != null)
        creatorByIdProvider('c-1').overrideWith(
          (ref) async => creator,
        ),
    ],
    child: MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 300,
          height: 300,
          child: child,
        ),
      ),
    ),
  );
}

void main() {
  group('AkeliRecipeCard creator row', () {
    testWidgets('shows nothing when creatorId is null', (tester) async {
      await tester.pumpWidget(_wrap(
        const AkeliRecipeCard(
          title: 'Mafé',
          rating: 4.0,
          likes: 5,
          comments: 2,
          saves: 1,
        ),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Amara Diallo'), findsNothing);
    });

    testWidgets('shows creator name when creatorId is provided', (tester) async {
      await tester.pumpWidget(_wrap(
        const AkeliRecipeCard(
          title: 'Mafé',
          rating: 4.0,
          likes: 5,
          comments: 2,
          saves: 1,
          creatorId: 'c-1',
        ),
        creator: _fakeCreator(),
      ));
      await tester.pumpAndSettle();
      expect(find.text('Amara Diallo'), findsOneWidget);
    });
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

```
flutter test test/shared/widgets/akeli_recipe_card_creator_test.dart -v
```

Expected: Compilation error — `AkeliRecipeCard` has no `creatorId` parameter yet.

- [ ] **Step 3: Update `AkeliRecipeCard` — add `creatorId` param and `_AkeliCreatorRow` widget**

Open `lib/shared/widgets/akeli_recipe_card.dart`. Make the following changes:

**3a — Add imports at the top of the file** (after the existing imports):

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:akeli/core/logger.dart';
import 'package:akeli/core/router.dart';
import 'package:akeli/providers/creator_provider.dart';
import 'package:go_router/go_router.dart';
```

**3b — Add `creatorId` to the `AkeliRecipeCard` class** — replace the constructor and field list:

```dart
class AkeliRecipeCard extends StatelessWidget {
  final String title;
  final int? calories100g;
  final double rating;
  final int likes;
  final int comments;
  final int saves;
  final String? emoji;
  final String? region;
  final List<String> tags;
  final String? imageUrl;
  final bool hasImage;
  final bool isMinimalist;
  final bool horizontal;
  final String? creatorId;          // NEW
  final VoidCallback? onTap;

  const AkeliRecipeCard({
    super.key,
    required this.title,
    this.calories100g,
    required this.rating,
    required this.likes,
    required this.comments,
    required this.saves,
    this.emoji,
    this.region,
    this.imageUrl,
    this.tags = const [],
    this.hasImage = true,
    this.isMinimalist = false,
    this.horizontal = false,
    this.creatorId,                 // NEW
    this.onTap,
  });
  // ... rest unchanged
```

**3c — Add `_AkeliCreatorRow` after the `_StatsRow` class at the bottom of the file:**

```dart
// ---------------------------------------------------------------------------
// Creator row — shown below title when creatorId is provided
// ---------------------------------------------------------------------------

class _AkeliCreatorRow extends ConsumerWidget {
  final String creatorId;

  const _AkeliCreatorRow({required this.creatorId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final creatorAsync = ref.watch(creatorByIdProvider(creatorId));

    return creatorAsync.when(
      loading: () => const SizedBox(height: 18),
      error: (_, __) => const SizedBox.shrink(),
      data: (creator) {
        if (creator == null) return const SizedBox.shrink();
        return GestureDetector(
          onTap: () {
            appLogger.userAction(
              'Creator row tapped',
              screen: 'AkeliRecipeCard',
              metadata: {'creatorId': creatorId},
            );
            context.push(AkeliRoutes.creatorDetailPath(creatorId));
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 10,
                backgroundImage: creator.avatarUrl != null
                    ? NetworkImage(creator.avatarUrl!)
                    : null,
                backgroundColor: AkeliColors.primary.withValues(alpha: 0.15),
                child: creator.avatarUrl == null
                    ? Text(
                        creator.displayName.isNotEmpty
                            ? creator.displayName[0].toUpperCase()
                            : 'C',
                        style: const TextStyle(
                          fontSize: 9,
                          color: AkeliColors.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  creator.displayName,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AkeliColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

**3d — Insert `_AkeliCreatorRow` into `_ImageVariant.build()`**

In the `Padding → Column → children` of `_ImageVariant`, after the title `Text` widget and before the `if (card.isMinimalist && card.calories100g != null)` block:

```dart
// BEFORE (existing code in _ImageVariant):
Text(
  card.title,
  style: Theme.of(context).textTheme.titleSmall?.copyWith(
    fontWeight: FontWeight.w700,
    color: AkeliColors.onSurface,
    fontSize: card.isMinimalist ? 15 : 14,
  ),
  maxLines: 2,
  overflow: TextOverflow.ellipsis,
),
if (card.isMinimalist && card.calories100g != null) ...[
```

```dart
// AFTER:
Text(
  card.title,
  style: Theme.of(context).textTheme.titleSmall?.copyWith(
    fontWeight: FontWeight.w700,
    color: AkeliColors.onSurface,
    fontSize: card.isMinimalist ? 15 : 14,
  ),
  maxLines: 2,
  overflow: TextOverflow.ellipsis,
),
if (!card.isMinimalist && card.creatorId != null) ...[
  const SizedBox(height: 4),
  _AkeliCreatorRow(creatorId: card.creatorId!),
],
if (card.isMinimalist && card.calories100g != null) ...[
```

**3e — Insert `_AkeliCreatorRow` into `_HorizontalVariant.build()`**

In `_HorizontalVariant`, in the `Column → children`, after the title `Text` and before `const SizedBox(height: 8)`:

```dart
// BEFORE (existing code in _HorizontalVariant Column):
Text(
  card.title,
  style: Theme.of(context).textTheme.titleSmall?.copyWith(
    fontWeight: FontWeight.w700,
    color: AkeliColors.onSurface,
    fontSize: 14,
  ),
  maxLines: 2,
  overflow: TextOverflow.ellipsis,
),
const SizedBox(height: 8),
_StatsRow(card: card),
```

```dart
// AFTER:
Text(
  card.title,
  style: Theme.of(context).textTheme.titleSmall?.copyWith(
    fontWeight: FontWeight.w700,
    color: AkeliColors.onSurface,
    fontSize: 14,
  ),
  maxLines: 2,
  overflow: TextOverflow.ellipsis,
),
if (card.creatorId != null) ...[
  const SizedBox(height: 4),
  _AkeliCreatorRow(creatorId: card.creatorId!),
],
const SizedBox(height: 8),
_StatsRow(card: card),
```

- [ ] **Step 4: Run the widget test**

```
flutter test test/shared/widgets/akeli_recipe_card_creator_test.dart -v
```

Expected: Both tests PASS.

- [ ] **Step 5: Commit**

```bash
git add lib/shared/widgets/akeli_recipe_card.dart test/shared/widgets/akeli_recipe_card_creator_test.dart
git commit -m "feat(recipe-card): add creator name and avatar row to AkeliRecipeCard"
```

---

## Task 3: Update call sites to pass `creatorId`

**Files:**
- Modify: `lib/features/recipes/saved_recipes_page.dart`
- Modify: `lib/features/settings/saved_recipes_eligibility_page.dart`
- Modify: `lib/features/home/home_page.dart`
- Modify: `lib/features/recipes/feed_page.dart`

**Context:** `creatorId` is optional on `AkeliRecipeCard` — existing callers compile without change, but the creator row only appears when `creatorId` is passed. All four call sites have a `Recipe` object in scope whose `.creatorId` field is the correct value to pass. `creator_detail_page.dart` is intentionally excluded (creator is already shown on the page).

---

### 3a — `lib/features/recipes/saved_recipes_page.dart`

This file also needs: (a) a logger import + user-action log on recipe tap, (b) a more visible error state color.

- [ ] **Step 1: Edit `saved_recipes_page.dart`**

Add import at the top (after existing imports):

```dart
import 'package:akeli/core/logger.dart';
```

Fix the error state widget (currently uses invisible `AkeliColors.outline`):

```dart
// BEFORE:
error: (err, _) => Center(child: Text('Erreur: $err', style: const TextStyle(color: AkeliColors.outline))),
```

```dart
// AFTER:
error: (err, _) => Center(
  child: Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      const Icon(Icons.error_outline_rounded, size: 40, color: AkeliColors.error),
      const SizedBox(height: 8),
      Text('Erreur: $err',
          style: const TextStyle(color: AkeliColors.onSurface),
          textAlign: TextAlign.center),
    ],
  ),
),
```

Update `AkeliRecipeCard` call in the `itemBuilder` to pass `creatorId` and add logging:

```dart
// BEFORE:
return AkeliRecipeCard(
  title: recipe.title,
  calories100g: recipe.calories100g?.round(),
  rating: recipe.averageRating,
  likes: recipe.likeCount,
  comments: recipe.commentCount,
  saves: recipe.saveCount,
  imageUrl: recipe.thumbnailUrl,
  onTap: () {
    context.push(
      AkeliRoutes.recipeDetailPath(recipe.id),
      extra: TrackingSource.feed,
    );
  },
);
```

```dart
// AFTER:
return AkeliRecipeCard(
  title: recipe.title,
  calories100g: recipe.calories100g?.round(),
  rating: recipe.averageRating,
  likes: recipe.likeCount,
  comments: recipe.commentCount,
  saves: recipe.saveCount,
  imageUrl: recipe.thumbnailUrl,
  creatorId: recipe.creatorId,      // NEW
  onTap: () {
    appLogger.userAction('Saved recipe tapped',
        screen: 'SavedRecipesPage',
        metadata: {'recipeId': recipe.id});
    context.push(
      AkeliRoutes.recipeDetailPath(recipe.id),
      extra: TrackingSource.feed,
    );
  },
);
```

- [ ] **Step 2: Run app and verify Saved Recipes page no longer blank**

Hot-restart the app, navigate Settings → Recettes Sauvegardées. Expected: page shows saved recipes (or visible empty state if none saved). The blank/invisible error is gone.

- [ ] **Step 3: Commit**

```bash
git add lib/features/recipes/saved_recipes_page.dart
git commit -m "fix(saved-recipes): pass creatorId, add logger, fix invisible error state"
```

---

### 3b — `lib/features/settings/saved_recipes_eligibility_page.dart`

The horizontal recipe carousels inside this page use `AkeliRecipeCard` with `isMinimalist: true`. The creator row is hidden for minimalist cards (guarded in Step 3d of Task 2), so passing `creatorId` here is forward-compatible and harmless.

- [ ] **Step 1: Edit the `AkeliRecipeCard` call inside `saved_recipes_eligibility_page.dart` (around line 192)**

```dart
// BEFORE:
child: AkeliRecipeCard(
  title: recipe.title,
  calories100g: recipe.calories100g?.round(),
  rating: recipe.averageRating,
  likes: recipe.likeCount,
  comments: recipe.commentCount,
  saves: recipe.saveCount,
  imageUrl: recipe.thumbnailUrl,
  isMinimalist: true,
  onTap: () {
    context.push(
      AkeliRoutes.recipeDetailPath(recipe.id),
    );
  },
),
```

```dart
// AFTER:
child: AkeliRecipeCard(
  title: recipe.title,
  calories100g: recipe.calories100g?.round(),
  rating: recipe.averageRating,
  likes: recipe.likeCount,
  comments: recipe.commentCount,
  saves: recipe.saveCount,
  imageUrl: recipe.thumbnailUrl,
  isMinimalist: true,
  creatorId: recipe.creatorId,   // NEW
  onTap: () {
    appLogger.userAction('Eligibility recipe tapped',
        screen: 'SavedRecipesEligibilityPage',
        metadata: {'recipeId': recipe.id});
    context.push(
      AkeliRoutes.recipeDetailPath(recipe.id),
    );
  },
),
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/settings/saved_recipes_eligibility_page.dart
git commit -m "feat(eligibility): pass creatorId to AkeliRecipeCard"
```

---

### 3c — `lib/features/home/home_page.dart`

The home page shows a horizontal recipe carousel (line ~619).

- [ ] **Step 1: Edit the `AkeliRecipeCard` call in `home_page.dart` (around line 619)**

```dart
// BEFORE:
child: AkeliRecipeCard(
  title: recipe.title,
  calories100g: recipe.calories100g?.toInt(),
  rating: recipe.averageRating,
  likes: recipe.likeCount,
  comments: recipe.commentCount,
  saves: recipe.saveCount,
  region: recipe.regionId != null ? regionNames[recipe.regionId!] ?? recipe.regionId : null,
  imageUrl: recipe.thumbnailUrl,
  hasImage: true,
  onTap: () {
    _logger.userAction('Recipe card tapped',
        screen: 'HomePage',
        metadata: {'recipeId': recipe.id});
    context.go('/recipe/${recipe.id}');
  },
```

```dart
// AFTER:
child: AkeliRecipeCard(
  title: recipe.title,
  calories100g: recipe.calories100g?.toInt(),
  rating: recipe.averageRating,
  likes: recipe.likeCount,
  comments: recipe.commentCount,
  saves: recipe.saveCount,
  region: recipe.regionId != null ? regionNames[recipe.regionId!] ?? recipe.regionId : null,
  imageUrl: recipe.thumbnailUrl,
  hasImage: true,
  creatorId: recipe.creatorId,   // NEW
  onTap: () {
    _logger.userAction('Recipe card tapped',
        screen: 'HomePage',
        metadata: {'recipeId': recipe.id});
    context.go('/recipe/${recipe.id}');
  },
```

- [ ] **Step 2: Commit**

```bash
git add lib/features/home/home_page.dart
git commit -m "feat(home): pass creatorId to AkeliRecipeCard"
```

---

### 3d — `lib/features/recipes/feed_page.dart`

The feed's search/recipe list uses `AkeliRecipeCard` horizontal (around line 1057).

- [ ] **Step 1: Edit the `AkeliRecipeCard` call in `feed_page.dart` (around line 1057)**

```dart
// BEFORE:
child: AkeliRecipeCard(
  horizontal: true,
  title: recipe.title,
  calories100g: recipe.calories100g?.toInt(),
  rating: recipe.averageRating,
  likes: recipe.likeCount,
  comments: recipe.commentCount,
  saves: recipe.saveCount,
  emoji: null,
  region: recipe.regionId != null
      ? regionNames[recipe.regionId!] ?? recipe.regionId
      : null,
  tags: recipe.tagIds.take(2).toList(),
  onTap: () async {
    _logger.userAction('Recipe card tapped', screen: 'FeedPage', metadata: {'recipeId': recipe.id});
```

```dart
// AFTER:
child: AkeliRecipeCard(
  horizontal: true,
  title: recipe.title,
  calories100g: recipe.calories100g?.toInt(),
  rating: recipe.averageRating,
  likes: recipe.likeCount,
  comments: recipe.commentCount,
  saves: recipe.saveCount,
  emoji: null,
  region: recipe.regionId != null
      ? regionNames[recipe.regionId!] ?? recipe.regionId
      : null,
  tags: recipe.tagIds.take(2).toList(),
  creatorId: recipe.creatorId,   // NEW
  onTap: () async {
    _logger.userAction('Recipe card tapped', screen: 'FeedPage', metadata: {'recipeId': recipe.id});
```

- [ ] **Step 2: Run all tests**

```
flutter test
```

Expected: All tests pass.

- [ ] **Step 3: Commit**

```bash
git add lib/features/recipes/feed_page.dart
git commit -m "feat(feed): pass creatorId to AkeliRecipeCard"
```

---

## Self-Review

**Spec coverage:**
- ✅ Creator name + avatar on recipe cards — Task 2 adds `_AkeliCreatorRow` to `AkeliRecipeCard`
- ✅ Tappable creator row navigates to creator detail — `_AkeliCreatorRow.onTap` calls `context.push(AkeliRoutes.creatorDetailPath(...))`
- ✅ Fix `recipe_macro` parsing — Task 1 defensive cast
- ✅ Visible error/empty state — Task 3a improves `SavedRecipesPage` error state
- ✅ All 5 call sites updated — Tasks 3a–3d

**Placeholder scan:** No TBDs or "implement later" phrases found.

**Type consistency:**
- `creatorByIdProvider` returns `AsyncValue<Creator?>` — `_AkeliCreatorRow` accesses `.displayName` and `.avatarUrl` on the non-null `Creator`. ✅
- `AkeliRoutes.creatorDetailPath(String id)` matches usage in `_AkeliCreatorRow`. ✅
- `recipe.creatorId` is `String` (not nullable) in `Recipe` model — all call sites pass it correctly. ✅
