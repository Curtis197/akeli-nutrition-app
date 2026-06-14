---
name: meal-plan-generator
description: Authoritative reference for the Akeli meal plan generator — three RPCs, calorie model, scoring, day-count logic, and batch cooking integration
metadata:
  type: spec
---

# Meal Plan Generator — Authoritative Reference

**Date:** 2026-06-14
**Status:** Live in production
**Last updated by migration:** `20260614154145_fix_day_count_and_initial_plan_function.sql`

> **Update policy:** Every time `generate_meal_plan`, `generate_initial_meal_plan`, `swap_meal_plan_entry`, or `create_batch_sessions_internal` is modified in a migration, this document MUST be updated in the same commit. Stale docs are worse than no docs.

---

## Overview

The meal plan generator produces a personalised weekly eating schedule for each user. It selects recipes, computes portion sizes in grams to hit per-meal calorie targets, pre-computes macros, scales ingredient quantities, creates batch cooking sessions for repeated recipes, and generates a shopping list — all in a single DB-side transaction.

Three public RPCs cover three distinct lifecycle moments:

| RPC | Caller | When | Days covered |
|-----|--------|------|--------------|
| `generate_meal_plan` | Internal (cron / update flow) | Monday batch or mid-week update | Caller-specified |
| `generate_initial_meal_plan` | App (new user) | First plan after onboarding | Today → Sunday |
| `swap_meal_plan_entry` | App (user swaps one meal) | Any time | 1 entry |

---

## Calorie Model — Per-100g

**All calorie and macro computations use the per-100g model.**

```
servings column  = portion size in grams
calories_computed = calories_per_100g × grams / 100
```

`recipe_macro` stores nutrient density (`calories_per_100g`, `protein_per_100g`, `carbs_per_100g`, `fat_per_100g`). The generator computes the actual values for the user's portion at write time and stores them on `meal_plan_entry`:

```sql
calories_computed  = ROUND((calories_per_100g  * v_grams / 100)::numeric, 1)
protein_g_computed = ROUND((protein_per_100g   * v_grams / 100)::numeric, 1)
carbs_g_computed   = ROUND((carbs_per_100g     * v_grams / 100)::numeric, 1)
fat_g_computed     = ROUND((fat_per_100g       * v_grams / 100)::numeric, 1)
```

Dart reads these stored values directly — no runtime macro computation from recipe components.

---

## Per-Meal Calorie Targets and Portion Bounds

For each meal slot the generator reads from `meal_distribution` (joined through `nutrition_plan`):

| Column | Type | Default | Purpose |
|--------|------|---------|---------|
| `calorie_target` | numeric | NULL | Absolute kcal target for this meal type (computed by trigger from `calorie_pct × nutrition_plan.calorie_goal`) |
| `min_portion_g` | integer | 50 | Hard floor on portion grams |
| `max_portion_g` | integer | 1500 | Hard ceiling on portion grams |

`calorie_target` is maintained by trigger `trg_sync_calorie_target_on_dist` — it auto-recomputes on any INSERT or UPDATE to `meal_distribution`. Never set it manually.

**Portion computation:**

```sql
v_grams := GREATEST(v_min_g, LEAST(v_max_g,
  ROUND(v_target_meal_cal / (v_recipe.calories_per_100g / 100))::integer
));
```

If no `meal_distribution` row exists for a meal type, the fallback is `calorie_goal / meals_per_day`.
If no `calorie_goal` exists at all, the fallback is 300 g (clamped by bounds).

---

## Day-Count Logic

Three flows, three day counts. Getting this wrong produces plans that misalign with the Monday batch cycle.

### 1. Monday batch (cron)

Always 7 days, always starting Monday. The cron calls `generate_meal_plan` directly:

```sql
SELECT * FROM generate_meal_plan(
  p_user_id     => <uuid>,
  p_days        => 7,
  p_meals_per_day => 3,
  p_start_date  => date_trunc('week', CURRENT_DATE + 1)::date,  -- next Monday
  p_max_recipe_repeat => 2
);
```

### 2. Mid-week update (user-triggered)

User regenerates their plan from today through the end of the current week (Sunday). The app computes `days_remaining` and calls `generate_meal_plan`:

```sql
-- App passes days_remaining = (current_sunday - CURRENT_DATE + 1)
SELECT * FROM generate_meal_plan(
  p_user_id     => <uuid>,
  p_days        => :days_remaining,
  p_meals_per_day => 3,
  p_start_date  => CURRENT_DATE,
  p_max_recipe_repeat => 2
);
```

### 3. New-user onboarding (first plan)

`generate_initial_meal_plan` computes days from today to the coming Sunday inclusive using the formula:

```sql
v_days_until_sunday := (7 - EXTRACT(dow FROM CURRENT_DATE)::integer) % 7 + 1;
```

Day-of-week lookup table (PostgreSQL `dow`: Sunday = 0):

| Day | `dow` | Days (today → Sunday) |
|-----|-------|-----------------------|
| Sunday | 0 | 1 |
| Monday | 1 | 7 |
| Tuesday | 2 | 6 |
| Wednesday | 3 | 5 |
| Thursday | 4 | 4 |
| Friday | 5 | 3 |
| Saturday | 6 | 2 |

On Monday this produces 7 days — identical to a full batch week. On Sunday it produces 1 day, then Monday's batch takes over for the following full week.

---

## RPC Reference

### `generate_meal_plan`

```sql
FUNCTION public.generate_meal_plan(
  p_user_id            uuid,
  p_days               integer,
  p_meals_per_day      integer,   -- 2, 3, or 4
  p_start_date         date,
  p_max_recipe_repeat  integer DEFAULT 3
)
RETURNS TABLE (
  meal_plan_id uuid, entry_id uuid, component_id uuid,
  scheduled_date date, meal_type text, recipe_id uuid,
  recipe_title text, cover_image_url text,
  calories numeric, protein_g numeric, score double precision
)
SECURITY DEFINER
```

**What it does:**

1. Reads user vector, fan subscription, allergens, and active nutrition goals.
2. Finds or creates a `meal_plan` row covering `[p_start_date, p_start_date + p_days - 1]`. If an overlapping plan exists, deletes future entries from it and expands its end date rather than creating a duplicate.
3. For each `(day, meal_type)` slot selects the highest-scoring eligible recipe (see Scoring below).
4. Inserts `meal_plan_entry` (with pre-computed macros), `meal_plan_entry_component`, and `meal_ingredient` rows.
5. Calls `create_batch_sessions_internal(v_plan_id, p_user_id, p_days)` — `p_days` is passed through, not hardcoded.
6. Calls `generate_shopping_list_internal(v_plan_id, p_user_id)`.
7. Returns one row per slot.

**Auth:** `auth.uid()` must equal `p_user_id` — enforced in function body.

**Error:** Raises `insufficient_recipes` with `DETAIL = meal_type` if no eligible recipe is found for any slot.

---

### `generate_initial_meal_plan`

```sql
FUNCTION public.generate_initial_meal_plan(
  p_user_id           uuid,
  p_meals_per_day     integer DEFAULT 3,
  p_max_recipe_repeat integer DEFAULT 2
)
RETURNS TABLE ( ... same columns as generate_meal_plan ... )
SECURITY DEFINER
```

Thin wrapper: computes `v_days_until_sunday` and delegates to `generate_meal_plan(p_user_id, v_days_until_sunday, p_meals_per_day, CURRENT_DATE, p_max_recipe_repeat)`.

Default `p_max_recipe_repeat = 2` is intentionally stricter than `generate_meal_plan`'s default of 3, since the initial plan may cover as few as 1–2 days.

---

### `swap_meal_plan_entry`

```sql
FUNCTION public.swap_meal_plan_entry(
  p_entry_id  uuid,
  p_recipe_id uuid DEFAULT NULL  -- NULL = auto-select best alternative
)
RETURNS TABLE ( ... recipe details + calories ... )
SECURITY DEFINER
```

Replaces a single meal plan entry with a different recipe. Reads `meal_distribution` bounds for the entry's meal type to compute portion grams. Updates `meal_plan_entry`, `meal_plan_entry_component`, and `meal_ingredient`. Does NOT regenerate the shopping list or batch sessions (those require a full plan regeneration).

---

## Recipe Scoring

The generator uses a composite score to select the best recipe per slot. Two branches:

### With user vector (pgvector)

```
score =
  0.50 × cosine_similarity(recipe_vector, user_vector)
       × fan_boost              -- 1.5× if recipe.creator_id = fan_creator_id, else 1.0
+ 0.25 × protein_density_match -- 1 − min(|actual − target| / target, 1)
+ 0.15 × meal_type_match       -- 1.0 exact, 0.5 'any', 0.0 mismatch
+ 0.10 × fat_density_match     -- same formula as protein
```

`v_target_protein_density` and `v_target_fat_density` are derived from the user's macro goals as g-per-100-kcal ratios.

### Without user vector (fallback)

Ranks by `preferred_meal_type` match (weight 0.15) then by total recipe likes. Used for new users who have not yet built a preference vector.

### Eligibility filters (both branches)

- `recipe.is_published = true`
- `v_meal_type = ANY(recipe.meal_types)`
- `recipe_macro.calories_per_100g > 0`
- Recipe appears fewer than `p_max_recipe_repeat` times in `v_used_recipe_ids`
- Fan rule: if user has an active fan subscription, non-fan recipes are capped at 10% of total slots (`v_max_other_slots = FLOOR(total_slots × 0.10)`)
- Allergen exclusion: `NOT (recipe.allergen_tags && v_user_allergens)`
- Portion feasibility: `v_target_meal_cal / (calories_per_100g / 100) BETWEEN v_min_g AND v_max_g` (recipe's natural portion must fit within both bounds — too calorie-sparse AND too calorie-dense recipes are excluded)

---

## Batch Cooking Sessions

`create_batch_sessions_internal(p_plan_id, p_user_id, p_days)` is called at the end of `generate_meal_plan`. It:

1. Finds recipes that appear 2+ times in the plan.
2. Creates one `cooking_session` per repeated recipe with `total_portions = count_of_appearances`.
3. Scales ingredient quantities: `ingredient.quantity × (total_portions / recipe.total_weight_g × user_grams)` and stores them in `cooking_session_ingredient`.

`p_days` is passed through so the session ceiling is the actual plan length. Before fix `20260614154145`, this was hardcoded to `7`, making the max-portions ceiling meaningless for shorter plans.

---

## Data Tables

| Table | Role |
|-------|------|
| `meal_plan` | One row per plan; covers a date range |
| `meal_plan_entry` | One row per (day, meal_type) slot; stores pre-computed macros and grams |
| `meal_plan_entry_component` | Links entry to recipe; `role = 'base'` |
| `meal_ingredient` | Scaled ingredient quantities for the user's portion |
| `cooking_session` | Batch cooking session for recipes appearing 2+ times |
| `cooking_session_ingredient` | Scaled ingredient quantities for the full batch |
| `shopping_list` / `shopping_list_item` | Auto-generated from all plan ingredients |
| `meal_consumption` | Records when a meal was eaten; `meal_plan_entry_id` is SET NULL on entry delete (history preserved) |
| `meal_distribution` | Per-meal-type calorie target + portion bounds; keyed to `nutrition_plan` |
| `recipe_macro` | Per-100g nutrient density for each recipe |
| `recipe_vector` | 50-dimension preference vector for cosine scoring |
| `user_vector` | 50-dimension user preference vector |

**Cascade:** `DELETE FROM meal_plan` cascades to entries → components → ingredients → cooking sessions → shopping list. `meal_consumption.meal_plan_entry_id` is SET NULL (not deleted).

---

## Known Constraints and Edge Cases

- **Sunday onboarding → 1-day plan:** If a user onboards on Sunday, `generate_initial_meal_plan` creates a 1-meal-per-type plan covering only Sunday. Monday's batch cron creates the full next week.
- **Insufficient recipes:** If the recipe catalogue is too small relative to `p_max_recipe_repeat`, generation raises `insufficient_recipes`. The fan cap (10% non-fan) can also trigger this if the fan creator has fewer recipes than `p_meals_per_day × p_days`.
- **No nutrition plan:** If the user has no active `nutrition_plan` or `user_goal`, the generator falls back to equal-split calories (`calorie_goal / meals_per_day`) and 300 g portions.
- **Overlapping plan on update:** If a plan already covers the requested date range, the generator deletes future entries from it and reuses its `id`. It does not create a second plan row.
- **Meals per day:**
  - `2` → `['lunch', 'dinner']`
  - `3` → `['breakfast', 'lunch', 'dinner']` (default)
  - `4` → `['breakfast', 'lunch', 'dinner', 'snack']`

---

## Flutter Integration

The Flutter `MealDistribution` model ([lib/shared/models/nutrition_plan.dart](../../../../lib/shared/models/nutrition_plan.dart)) mirrors the DB columns:

```dart
final int minPortionG;  // maps to min_portion_g, default 50
final int maxPortionG;  // maps to max_portion_g, default 1500
```

The app passes `p_user_id`, `p_meals_per_day`, and `p_max_recipe_repeat` when calling `generate_initial_meal_plan`. The returned rows are used to populate the meal plan UI directly; no additional macro computation is required client-side.
