# Consumed Toggle & Conditional Rating Sheet — Design Spec

**Date:** 2026-06-09

## Goal

Three tightly related fixes to the meal consumption UX:

1. **Consumed checkbox becomes a full toggle** — re-tapping an already-consumed meal unconsumes it (soft undo: reset `is_consumed`, delete `meal_consumption` rows, keep `recipe_comment`).
2. **Conditional rating sheet** — the automatic rating bottom sheet only appears on first consumption; if the entry already has a rating, it is skipped.
3. **Adaptive review button** — the "Note & commentaire" button in the meal detail page changes its label and icon to "Modifier votre avis" when the user has already submitted a review.

---

## Root Cause of Issue 2 & 3

`MealPlanEntry.isRated` is derived in `fromJson` by inspecting `meal_consumption.rating`:

```dart
isRated: ((json['meal_consumption'] as List<dynamic>?) ?? [])
    .any((c) => (c as Map<String, dynamic>)['rating'] != null),
```

Two problems:
- The `activeMealPlanProvider` query does not join `meal_consumption` at all, so `json['meal_consumption']` is always `null`.
- Migration `20260609000002` dropped `meal_consumption.rating`, so the column no longer exists.

Result: `isRated` is always `false`, causing the rating sheet to fire on every consumption including re-consumption after unconsume.

---

## Design

### 1. New edge function — `unconsume-meal`

**File:** `supabase/functions/unconsume-meal/index.ts`

**Input body:** `{ meal_plan_entry_id: string }`

**Steps:**
1. Auth check — return 401 if no user.
2. Fetch `meal_plan_entry` — verify it exists and `is_consumed = true`; return 400 if not consumed.
3. Delete all `meal_consumption` rows where `meal_plan_entry_id = ?` and `user_id = ?` (RLS client, user can only delete own rows).
4. Reset entry via service client: `UPDATE meal_plan_entry SET is_consumed = false, consumed_at = null WHERE id = ?`.
5. Return `{ unconsumed: true }`.

`recipe_comment` rows are intentionally left untouched — the rating persists.

Full structured logging per CLAUDE.md standard (ENTRY, STEP N, EARLY RETURN, EXIT, error handler).

---

### 2. `MealConsumptionNotifier` — toggle logic

**File:** `lib/providers/meal_plan_provider.dart`

Rename `logConsumption(entryId)` to `toggleConsumption(entryId, { required bool isCurrentlyConsumed })`.

- If `isCurrentlyConsumed = false` → call `log-meal-consumption` (existing path).
- If `isCurrentlyConsumed = true` → call `unconsume-meal` (new path).

Both paths invalidate `activeMealPlanProvider` on success.

**Call site** (`meal_planner_page.dart` line 132–134): pass `entry.isConsumed` to the toggle call.

---

### 3. Fix `isRated` derivation

**Approach:** fetch rated recipe IDs as a second query in `activeMealPlanProvider`, then pass the set into model parsing.

**In `activeMealPlanProvider`** (`meal_plan_provider.dart`):

After fetching the meal plan data, run a second query:

```dart
final ratedData = await client
    .from('recipe_comment')
    .select('recipe_id')
    .eq('user_id', user.id)
    .not('rating', 'is', null);

final ratedRecipeIds = (ratedData as List)
    .map((r) => r['recipe_id'] as String)
    .toSet();
```

Pass `ratedRecipeIds` to `MealPlan.fromJson(data, ratedRecipeIds: ratedRecipeIds)`.

**In `MealPlan.fromJson`** (`meal_plan.dart`): thread `ratedRecipeIds` through to each `MealPlanEntry.fromJson`.

**In `MealPlanEntry.fromJson`**: replace the broken check with:

```dart
isRated: components.any((c) => ratedRecipeIds.contains(c.recipeId)),
```

where `components` is parsed first (before setting `isRated`), and `ratedRecipeIds` defaults to an empty set if not provided.

---

### 4. UI changes

#### `meal_detail_page.dart`

**Consume row** (line 259): remove the `entry.isConsumed ? null :` guard. The `onTap` always calls `onConsume`. The visual state (green / unchecked) already reflects `entry.isConsumed`.

**Review button** (line 512–528): adapt label and icon based on `entry.isRated`:

| State | Icon | Label |
|---|---|---|
| Not consumed | `Icons.star_border_rounded` | `'Consommez d\'abord ce repas'` (disabled, `onTap: null`) |
| Consumed, not rated | `Icons.star_border_rounded` | `'Laisser un avis'` |
| Consumed, rated | `Icons.star_rounded` | `'Modifier votre avis'` |

#### `meal_planner_page.dart`

No change needed — the `!entry.isRated` guard at line 27 already correctly skips the sheet when rated. It will work automatically once `isRated` is fixed.

---

## Files Changed

| File | Change |
|---|---|
| `supabase/functions/unconsume-meal/index.ts` | NEW — unconsume edge function |
| `lib/providers/meal_plan_provider.dart` | Toggle logic in `MealConsumptionNotifier`; second `recipe_comment` query in `activeMealPlanProvider` |
| `lib/shared/models/meal_plan.dart` | Thread `ratedRecipeIds` through `fromJson`; fix `isRated` derivation |
| `lib/features/meal_planner/meal_detail_page.dart` | Remove consume guard; 3-state review button |

---

## Out of Scope

- Undo time window (any consumed meal can be unchecked at any time).
- The `meal_planner_day_row.dart` widget already passes `entry.isConsumed` via `onConsumedToggle` — the toggle direction is handled in the notifier, not the widget.
- No DB migration needed (no schema changes).
