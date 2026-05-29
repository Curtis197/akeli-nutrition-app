# Meal Consumption Rating — Design Spec

**Date:** 2026-05-29  
**Status:** Approved  
**Scope:** Add multi-dimensional optional rating to consumed meals; gate rating access behind consumption.

---

## Context

The `meal_consumption` table already has a `rating integer` column (1-5, never written).
Migration `20260529000004` added `average_rating`, `rating_count`, `like_count` computed columns
to `recipe` with triggers that fire on `meal_consumption.rating` updates.

This spec layers the full rating UX on top of that foundation.

---

## Requirements

1. **4-score model**: overall (mandatory), taste (optional), ease-to-cook (optional), satiety (optional). All 1-5.
2. **Consumption gate**: rating UI is accessible only after `meal_plan_entry.is_consumed = true`.
3. **Entry point**: bottom sheet appears immediately after "Marquer comme consommé" succeeds.
4. **Public score**: only `rating` (overall) feeds `recipe.average_rating`.
5. **No modular recipes at launch** — each meal entry has exactly one component → one `meal_consumption` row.

---

## Architecture

### 1. Database — Migration `20260529000005`

Add three nullable columns to `meal_consumption`:

```sql
ALTER TABLE meal_consumption
  ADD COLUMN rating_taste    integer CHECK (rating_taste    BETWEEN 1 AND 5),
  ADD COLUMN rating_ease     integer CHECK (rating_ease     BETWEEN 1 AND 5),
  ADD COLUMN rating_satiety  integer CHECK (rating_satiety  BETWEEN 1 AND 5);
```

Existing `rating` column (overall, 1-5) is unchanged. The trigger
`trg_recipe_rating_stats` (from migration `20260529000004`) fires automatically
on `UPDATE OF rating ON meal_consumption` — no trigger changes needed.

### 2. Edge Function — `rate-meal-consumption`

**Endpoint:** `POST /functions/v1/rate-meal-consumption`

**Body:**
```json
{
  "meal_plan_entry_id": "<uuid>",   // required
  "rating": 4,                      // required, 1-5
  "rating_taste": 5,                // optional, 1-5
  "rating_ease": 3,                 // optional, 1-5
  "rating_satiety": 4               // optional, 1-5
}
```

**Flow:**
1. Auth guard — 401 if no user.
2. `[STEP 1]` Parse + validate body — `rating` present and 1-5, else 400.
3. `[STEP 2]` Fetch `meal_plan_entry` — verify `user_id = auth.uid()` AND `is_consumed = true`. Return 403 if not consumed, 404 if not found.
4. `[STEP 3]` UPDATE `meal_consumption` rows for `meal_plan_entry_id` — set `rating`, `rating_taste`, `rating_ease`, `rating_satiety` using `serviceClient()` (no UPDATE RLS policy exists).
5. Return `ok({ rated: true })`.

**Error cases:**
- `meal_plan_entry_id` missing → 400
- `rating` out of range → 400
- Entry not found → 404
- Entry not consumed → 403 `"meal_not_consumed"`
- Unexpected → 500

Full structured logging per CLAUDE.md standard.

### 3. Dart — Provider

**`RatingNotifier`** (new, in `meal_plan_provider.dart`):

```dart
class RatingNotifier extends AutoDisposeAsyncNotifier<void> {
  Future<void> submitRating(
    String mealPlanEntryId, {
    required int rating,
    int? ratingTaste,
    int? ratingEase,
    int? ratingSatiety,
  }) async { ... }
}

final ratingProvider = AsyncNotifierProvider.autoDispose<RatingNotifier, void>(RatingNotifier.new);
```

Calls edge function `rate-meal-consumption`. On success, invalidates `activeMealPlanProvider`.

**`MealConsumptionNotifier.logConsumption`** — changed return type from `void` to `bool`.
Returns `true` when consumption is successfully logged. `MealDetailPage` watches this
and opens `RatingBottomSheet` when `true` is returned.

### 4. UI — `RatingBottomSheet`

New widget: `lib/features/meal_planner/rating_bottom_sheet.dart`

**Layout:**
```
╔══════════════════════════════════════╗
║  Comment était ce repas ?            ║
║                                      ║
║  ★ ★ ★ ★ ★   (overall — required)   ║
║                                      ║
║  Goût         ○ ○ ○ ○ ○  (optional) ║
║  Facilité     ○ ○ ○ ○ ○  (optional) ║
║  Satiété      ○ ○ ○ ○ ○  (optional) ║
║                                      ║
║  [Passer]          [Soumettre]       ║
╚══════════════════════════════════════╝
```

**Behaviour:**
- Overall star row: larger icons (`Icons.star_rounded`, 28px), tappable 1-5.
- Optional rows: smaller icons (20px), same tap mechanic.
- "Soumettre" disabled until `rating != null`.
- "Passer" calls `Navigator.pop()` without calling the provider.
- On submit: calls `ratingProvider.notifier.submitRating(...)`, shows loading on button, dismisses on success. Shows `SnackBar` on error.
- Sheet is `isDismissible: false` so the user must choose Passer or Soumettre.

---

## Data Flow

```
User taps "Marquer comme consommé"
  → MealConsumptionNotifier.logConsumption(entryId)
    → log-meal-consumption edge fn → inserts meal_consumption row(s)
    → meal_plan_entry.is_consumed = true
    → returns true
  → MealDetailPage opens RatingBottomSheet(entryId)
    → User sets overall ★ (+ optional dimensions)
    → taps "Soumettre"
      → RatingNotifier.submitRating(entryId, rating, ...)
        → rate-meal-consumption edge fn
          → UPDATE meal_consumption SET rating=..., rating_taste=..., ...
            → trg_recipe_rating_stats fires
              → recipe.average_rating + rating_count updated
        → invalidate activeMealPlanProvider
      → sheet dismissed
```

---

## Out of Scope (V1)

- Editing a rating after submission (no re-entry point on MealDetailPage).
- Showing per-dimension averages on recipe cards or detail page.
- Rating for modular multi-recipe meals (deferred).
- `is_liked` fix on direct recipe queries (tracked separately).
