# Design: Recipe Card Creator Info + Saved Recipes Fix

**Date:** 2026-06-26
**Branch:** `docs/copywriting-foundation` → will be implemented on a new feature branch

---

## Problem Statement

1. Multiple creators can upload recipes with identical names. The recipe feed cards show no attribution, making it impossible to know who made a recipe.
2. The **Recettes Sauvegardées** link in Settings opens a blank page.

---

## Change 1 — Creator name + avatar on recipe cards

### Root cause of missing data

The `Recipe` model has `creatorId` but no creator name or avatar URL. The feed uses an RPC (`get_personalized_feed`) whose response shape is fixed without a DB migration. Direct queries could be extended, but that only solves half the surface.

### Solution: `creatorSummaryProvider` (Riverpod family)

Add a lightweight provider keyed by `creatorId` that fetches `display_name` and `profile_image_url` from the `creator_profile` table. Both `RecipeCard` and `AkeliRecipeCard` watch this provider and render a small creator row below the title.

**Provider spec:**

```dart
// lib/providers/creator_summary_provider.dart
@riverpod
Future<({String displayName, String? avatarUrl})> creatorSummary(
  Ref ref,
  String creatorId,
) async {
  // SELECT display_name, profile_image_url FROM creator WHERE id = creatorId
}
```

Riverpod caches by `creatorId`, so a feed with 20 cards from 5 creators fires only 5 fetches.

### UI — Creator row

Below the recipe title in `RecipeCard` and `AkeliRecipeCard`:

```
[24px avatar]  [Creator Name]  →  taps to /creators/:creatorId
```

- Avatar: `CircleAvatar` 24 px, falls back to initials if no image
- Name: `labelSmall`, `AkeliColors.textSecondary`
- Full row is tappable, navigates to `AkeliRoutes.creatorDetailPath(creatorId)`
- The creator row is shown in both normal and compact modes

### Files touched

| File | Change |
|------|--------|
| `lib/providers/creator_summary_provider.dart` | New provider |
| `lib/providers/creator_summary_provider.g.dart` | Generated (run build_runner) |
| `lib/shared/widgets/recipe_card.dart` | Add `_CreatorRow` widget, watch provider |
| `lib/shared/widgets/akeli_recipe_card.dart` | Same treatment |

---

## Change 2 — Fix blank Saved Recipes page

### Root cause

`Recipe.fromJson` casts `recipe_macro` as `Map<String, dynamic>?`:

```dart
final macro = json['recipe_macro'] as Map<String, dynamic>?;
```

When called from a **direct Supabase query** (`.select('*, recipe_macro(...)') `), PostgREST returns related rows as a `List<dynamic>` (has-many shape), not a bare Map. The cast throws a `TypeError`, the provider enters the error state, and the error text (`AkeliColors.outline` on `AkeliColors.background`) is nearly invisible — the page appears blank.

The RPC-based feed works because the RPC returns a flattened JSON object without the nested list.

### Solution: Defensive `recipe_macro` parsing

```dart
final macroRaw = json['recipe_macro'];
final macro = macroRaw is Map<String, dynamic>
    ? macroRaw
    : (macroRaw is List && macroRaw.isNotEmpty)
        ? macroRaw.first as Map<String, dynamic>
        : null;
```

This handles both the RPC shape (Map) and the direct-query shape (List with one item).

### Secondary fix: Visible error state

Update `SavedRecipesPage`'s error widget to use a contrasting color and a clearer message so future bugs surface visibly.

### Files touched

| File | Change |
|------|--------|
| `lib/shared/models/recipe.dart` | Defensive `recipe_macro` parsing in `fromJson` |
| `lib/features/recipes/saved_recipes_page.dart` | More visible error state |

---

## Out of scope

- Modifying the Supabase RPC or any DB migration
- Redesigning the `SavedRecipesEligibilityPage` or changing its route
- Adding creator info to the `Recipe` model itself

---

## Acceptance criteria

1. Each recipe card in the feed shows a small avatar + creator name below the title.
2. Tapping the creator row navigates to the creator's detail page.
3. Navigating to Saved Recipes from Settings shows the list of saved recipes (or a clearly visible empty/error state if there are none).
