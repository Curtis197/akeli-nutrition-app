---
name: meal-generator-stress-test
description: Full rework of the meal plan generator — algorithm correctness, macro accuracy, all-or-nothing generation, fan rule, and live testing plan
metadata:
  type: spec
---

# Meal Generator Stress Test — Design Spec

**Date:** 2026-05-28
**Reference:** [Meal Plan Philosophy](..\..\..\03_v1_app_flutter\recommendation_vectorization\meal_plan_generator_philosophy.md)
**Depends on:** [Modular Removal Spec](2026-05-28-modular-removal-design.md)

---

## Context

The meal plan generator has six correctness issues identified through code audit:

| Priority | Issue | Current behaviour |
|----------|-------|-------------------|
| C | Silent slot failures | Slots silently skipped on no match; partial plan returned |
| A | Wrong macros displayed | Dart model sums raw component macros without × servings |
| A | Per-meal calorie targets ignored | Uses `total / meals_per_day` instead of per-meal goals |
| B | No 3-entry cap per recipe | A recipe with 8 portions dominates the plan |
| B | Fan 90% rule not enforced | Fan creator recipes only boosted 1.5x, not constrained to 90% |
| D | Serving scale unbounded | Scale of 12.0 possible for low-calorie recipes |

This spec covers the algorithm rewrite, the new DB additions for pre-computed macros and scaled ingredients, and a six-scenario live testing plan.

---

## Architecture

### DB Layer

**New table: `meal_ingredient`**
Stores pre-computed ingredient quantities scaled to the user's portion size. Populated during plan generation. The meal detail view reads from this table — the user sees their actual portion amounts, not the base recipe amounts.

```sql
meal_ingredient (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  meal_plan_entry_id  uuid NOT NULL REFERENCES meal_plan_entry(id) ON DELETE CASCADE,
  ingredient_id       uuid REFERENCES ingredient(id),
  ingredient_name     text NOT NULL,
  quantity            numeric NOT NULL,  -- recipe_ingredient.quantity × entry.servings
  unit                text NOT NULL
);
CREATE INDEX idx_meal_ingredient_entry ON meal_ingredient(meal_plan_entry_id);
```

**New columns on `meal_plan_entry`**
Pre-computed macros stored at generation time. Dart reads these directly — no runtime computation from components.

```sql
ALTER TABLE meal_plan_entry ADD COLUMN calories_computed   numeric;
ALTER TABLE meal_plan_entry ADD COLUMN protein_g_computed  numeric;
ALTER TABLE meal_plan_entry ADD COLUMN carbs_g_computed    numeric;
ALTER TABLE meal_plan_entry ADD COLUMN fat_g_computed      numeric;
```

**New columns on `user_goal`**
Per-meal calorie targets gathered at onboarding. Added alongside the existing `calorie_goal` column (kept for backward compatibility). The generator reads the new per-meal columns; `calorie_goal` is preserved for any existing consumers.

```sql
ALTER TABLE user_goal ADD COLUMN breakfast_cal_target  numeric;
ALTER TABLE user_goal ADD COLUMN lunch_cal_target      numeric;
ALTER TABLE user_goal ADD COLUMN dinner_cal_target     numeric;
ALTER TABLE user_goal ADD COLUMN snack_cal_target      numeric;
```

### RPC Layer

**Rewritten: `generate_meal_plan`**

Core algorithm changes:

1. **Pool fetch (once per meal type)** — fetch top 20 candidates per meal type ordered by cosine similarity, weighted by fan subscription boost. Pool is held in memory for the entire generation loop — no per-slot DB round trips.

2. **Fan 90% rule** — when a fan subscription is active, at least 90% of selections must come from that creator. Enforced by tracking creator counts during slot assignment.

3. **Use-count map** — replaces the boolean `v_used_recipe_ids` array. Each recipe tracks how many times it has been selected. A recipe is excluded when its count reaches 3.

4. **Per-meal calorie targets** — reads `breakfast_cal_target`, `lunch_cal_target`, `dinner_cal_target`, `snack_cal_target` from `user_goal`. Falls back to 1.0 servings if a target is absent.

5. **Serving scale bounds** — `servings = ROUND(target_cal / recipe.calories, 1)`, clamped to [0.1, 4.0]. If the natural scale exceeds 4.0, the recipe is skipped and the next candidate is tried.

6. **All-or-nothing via transaction** — the entire function runs inside a transaction. If any slot cannot be filled after exhausting its top-20 pool, the transaction is rolled back and a structured error is raised:
   ```sql
   RAISE EXCEPTION 'insufficient_recipes' USING DETAIL = meal_type;
   ```

7. **Pre-computed macros** — after inserting each entry, compute and store `calories_computed = recipe.calories × servings` (and protein, carbs, fat equivalents) directly on `meal_plan_entry`.

8. **`meal_ingredient` population** — after each entry is inserted, copy `recipe_ingredient` rows scaled by `entry.servings` into `meal_ingredient`.

### Edge Function Layer

`generate-meal-plan/index.ts` remains the orchestrator. No structural change — it calls the rewritten RPC, then `create_batch_sessions`, then `generate_shopping_list`. Error handling is extended:

```typescript
// Catch the new structured error from the RPC
if (error?.message === 'insufficient_recipes') {
  return err(`Not enough recipes for ${error.detail}. Please check back later.`);
}
```

Returns a structured warning summary to the Flutter app:
```json
{
  "meal_plan_id": "...",
  "entries": [...],
  "warnings": []
}
```

### Dart Layer

**`MealPlanEntry` model (`lib/shared/models/meal_plan.dart`)**
- `calories`, `proteinG`, `carbsG`, `fatG` getters read `calories_computed` etc. from JSON directly
- No multiplication by servings in Dart — values are pre-computed in the backend
- `fromJson` maps `calories_computed`, `protein_g_computed`, `carbs_g_computed`, `fat_g_computed`

**`activeMealPlanProvider` (`lib/providers/meal_plan_provider.dart`)**
- Query extended to include `meal_ingredient` rows nested under each entry
- Used by `MealDetailPage` for the ingredient list display

---

## Algorithm Pseudocode

```
FUNCTION generate_meal_plan(user_id, days, meals_per_day, start_date):
  BEGIN TRANSACTION

  user_vector    ← fetch user_vector WHERE user_id
  fan_creator_id ← fetch active fan_subscription WHERE user_id
  cal_targets    ← fetch user_goal per meal_type WHERE user_id

  -- Fetch recipe pool once per meal type
  pool ← {}
  FOR each meal_type IN meal_types:
    pool[meal_type] ← SELECT top 20 recipes
                      WHERE meal_type = ANY(r.meal_types)
                        AND r.is_published = true
                        AND recipe_macro EXISTS
                      ORDER BY cosine_similarity(rv.vector, user_vector) DESC
                               × fan_boost(r.creator_id, fan_creator_id)

  use_count      ← {}   -- recipe_id → int
  creator_counts ← { fan: 0, other: 0 }
  plan_id        ← INSERT meal_plan

  FOR day IN 0..days-1:
    FOR meal_type IN meal_types:
      target_cal ← cal_targets[meal_type] OR NULL

      -- Pre-compute max allowed non-fan entries for 90% rule
      max_other_slots ← FLOOR(days × meals_per_day × 0.10)

      candidate ← first recipe in pool[meal_type] WHERE:
        - use_count[recipe_id] < 3
        - fan rule: if fan_creator_id AND creator_counts.other >= max_other_slots
                    → only consider fan creator recipes
        - servings = ROUND(target_cal / recipe.calories, 1) BETWEEN 0.1 AND 4.0
                    (skip recipe if target_cal is set and scale would exceed 4.0)

      IF candidate IS NULL:
        ROLLBACK
        RAISE 'insufficient_recipes' DETAIL meal_type

      servings ← target_cal IS NOT NULL
                 ? CLAMP(ROUND(target_cal / candidate.calories, 1), 0.1, 4.0)
                 : 1.0

      entry_id ← INSERT meal_plan_entry (servings, calories_computed = calories × servings, ...)
      INSERT meal_plan_entry_component (entry_id, recipe_id, role='base')
      INSERT meal_ingredient SELECT ingredient_id, name, quantity × servings, unit
                             FROM recipe_ingredient WHERE recipe_id = candidate.id

      use_count[candidate.id] += 1
      UPDATE creator_counts

  COMMIT
  RETURN entries
```

---

## Live Testing Plan

### T1 — Complete Plan (Baseline)
**Setup:** User with vector + per-meal calorie goals + 20+ published recipes per meal type with `recipe_macro`.
**Expected:**
- 21-entry plan (7 days × 3 meals), all entries present
- No recipe appears more than 3 times
- `calories_computed` on each entry within ±5% of `cal_targets[meal_type]`
- `meal_ingredient` rows present for every entry, quantities = `recipe_ingredient.quantity × entry.servings`
- `cooking_session` rows created for recipes appearing 2+ times

### T2 — All-or-Nothing on Missing Meal Type
**Setup:** Remove all published recipes tagged `breakfast` (or set `meal_types = []` on all breakfast recipes).
**Expected:**
- Generation aborts — no `meal_plan` row persisted in DB
- Edge function returns `{ error: "insufficient_recipes", meal_type: "breakfast" }`
- Flutter UI surfaces the error message, no empty plan shown

### T3 — Macro Accuracy
**Setup:** User with breakfast target 400 kcal; select a recipe with `calories = 300` in `recipe_macro`.
**Expected:**
- `meal_plan_entry.servings = 1.3`
- `meal_plan_entry.calories_computed = 390` (300 × 1.3)
- `meal_ingredient` rows have ingredient quantities × 1.3
- Shopping list quantity for each ingredient matches `recipe_ingredient.quantity × 1.3`
- Dart `MealPlanEntry.calories` returns 390 (reads `calories_computed` directly)

### T4 — Fan Subscription 90% Rule
**Setup:** User with active fan subscription to Creator A who has 15+ published recipes across all meal types.
**Expected:**
- At least 19 of 21 entries use Creator A's recipes (≥90%)
- Remaining ≤2 entries come from general catalogue

### T5 — Serving Scale Cap
**Setup:** Recipe with `calories = 50` in `recipe_macro`; user lunch target = 600 kcal (natural scale = 12.0).
**Expected:**
- Recipe is skipped (scale > 4.0)
- Next candidate from pool[lunch] is selected
- No `meal_plan_entry` has `servings > 4.0`

### T6 — Data Gaps
Three sub-scenarios run independently:

| Sub | Setup | Expected |
|-----|-------|----------|
| T6a | User has no `user_vector` row | Plan generated using popularity fallback (most-liked recipes); no error |
| T6b | User has no calorie goals in `user_goal` | Plan generated with `servings = 1.0` for all entries; `calories_computed = recipe.calories` |
| T6c | Some recipes have no `recipe_macro` row | Those recipes excluded from pool; plan completes if enough other recipes exist |

---

## Migration Summary

| File | Type | Purpose |
|------|------|---------|
| `YYYYMMDD_add_meal_ingredient_table.sql` | Migration | Create `meal_ingredient` table |
| `YYYYMMDD_add_computed_macros_to_entry.sql` | Migration | Add `calories_computed` etc. to `meal_plan_entry` |
| `YYYYMMDD_add_per_meal_calorie_targets.sql` | Migration | Add per-meal target columns to `user_goal` |
| `YYYYMMDD_rewrite_generate_meal_plan.sql` | Migration | Replace `generate_meal_plan` RPC |
| `generate-meal-plan/index.ts` | Edge function | Extended error handling + `meal_ingredient` population call |
| `lib/shared/models/meal_plan.dart` | Dart | Read pre-computed macros from JSON |
| `lib/providers/meal_plan_provider.dart` | Dart | Include `meal_ingredient` in active plan query |

---

## Out of Scope

- Swap entry edge function refactor (separate task — swap currently calls RPC directly from Flutter)
- User-configurable portion cap (post-launch)
- User-defined cooking days (post-launch)
- Recipe pool size configuration (post-launch)
