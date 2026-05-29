# Meal Plan Scoring Improvements — Design Spec

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Fix three structural issues in `generate_meal_plan`: same recipe repeated across all meal slots in a day, poor macro alignment (protein/fat swings), and missing `create_batch_sessions` function.

**Architecture:** Pure backend — four SQL migrations, no Flutter changes. The RPC response shape is unchanged so all existing providers and UI continue to work without modification.

**Tech Stack:** PostgreSQL 17, pgvector, PL/pgSQL, Supabase MCP for applying migrations.

---

## Context: Issues Being Fixed

### Issue 1 — Same recipe for all 3 meals in a day
The RPC iterates meal slots (breakfast → lunch → dinner) and scores every recipe against the same user profile vector. Since the similarity score is identical across all slots, the highest-scoring recipe wins all three slots before hitting the 3-use cap. Result: the user eats the same dish at every meal.

**Fix:** Add a `preferred_meal_type` column to `recipe`. Breakfast slots reward breakfast-tagged recipes; lunch/dinner slots reward their tags. This steers variety structurally without any explicit same-day exclusion logic.

### Issue 2 — Weak macro alignment (protein swings 52g–266g vs target 138.9g)
The RPC ranks candidates by vector similarity only, then scales servings to hit the calorie target. Cultural fit dominates but macro fit is ignored. A dish like Fondé (millet porridge, 2.8g P/100kcal) beats a high-protein option if it has a slightly higher similarity score.

**Fix:** Replace single-signal ranking with a 4-component weighted score that incorporates protein density alignment and fat density alignment alongside similarity and slot preference.

### Issue 3 — `create_batch_sessions` not deployed
The edge function calls `create_batch_sessions` after every plan generation. The function doesn't exist in the live DB, so the call fails silently (non-fatal). Batch cooking sessions are never created.

**Fix:** Write and deploy the function.

---

## Design

### 1. Schema — `preferred_meal_type` on `recipe`

```sql
ALTER TABLE public.recipe
  ADD COLUMN preferred_meal_type text NOT NULL DEFAULT 'any'
  CHECK (preferred_meal_type IN ('breakfast', 'lunch', 'dinner', 'snack', 'any'));
```

- Default `'any'` — all existing recipes remain valid immediately.
- Set by recipe creators on the website (out of scope for this spec).
- The RPC reads this column during candidate scoring.

### 2. Data — Tag existing recipes

Assign `preferred_meal_type` to the ~14 live recipes based on their culinary profile:

| Recipe | Tag |
|---|---|
| Fondé | `breakfast` |
| Soupe du Pêcheur — Atiéké | `lunch` |
| Sauce Pistache — Fufu d'Ignames | `dinner` |
| Sauce Gouagouassou — Foutou | `dinner` |
| Sauce Arachide — Riz Blanc | `lunch` |
| Sauce Noix de Cajou — Riz Blanc | `lunch` |
| Sauce Aubergine — Riz | `dinner` |
| Bawoin — Riz Blanc | `lunch` |
| Bouillon de Pieds de Porc — Riz Blanc | `dinner` |
| Nyama Choma | `dinner` |
| Sauce Pklala — Riz | `dinner` |
| Ewa Aganyin | `lunch` |
| Pap en Vleis | `breakfast` |
| Bunny Chow | `lunch` |

Recipes not in this list keep the default `'any'`.

### 3. Weighted Scoring Formula

The RPC currently picks the top candidate by `similarity DESC`. Replace with `v_final_score DESC`:

```sql
-- Computed per candidate inside the selection loop

v_protein_density := rm.protein_g / NULLIF(rm.calories, 0) * 100;
v_fat_density     := rm.fat_g     / NULLIF(rm.calories, 0) * 100;

-- Target densities derived from user_goal (fetched once before the day loop)
-- v_target_protein_density and v_target_fat_density set once per plan:
--   = (goal_g / meals_per_day) / (calorie_goal / meals_per_day) * 100

v_protein_distance := LEAST(
  ABS(v_protein_density - v_target_protein_density)
    / NULLIF(v_target_protein_density, 0),
  1.0
);
v_fat_distance := LEAST(
  ABS(v_fat_density - v_target_fat_density)
    / NULLIF(v_target_fat_density, 0),
  1.0
);

v_slot_match := CASE
  WHEN r.preferred_meal_type = v_meal_type THEN 1.0
  WHEN r.preferred_meal_type = 'any'       THEN 0.5
  ELSE 0.0
END;

v_final_score :=
    0.50 * v_similarity
  + 0.25 * (1.0 - v_protein_distance)
  + 0.15 * v_slot_match
  + 0.10 * (1.0 - v_fat_distance);
```

**Weight rationale:**
- `0.50 × similarity` — cultural and preference fit remains the primary signal
- `0.25 × protein alignment` — corrects the main macro drift observed in testing
- `0.15 × slot match` — steers breakfast recipes to breakfast, dinner to dinner; provides daily variety without hard exclusion
- `0.10 × fat alignment` — secondary correction, keeps high-fat dishes from dominating

**Validated on test data** (user: 180cm/100kg male, target 90kg, light activity):

| Recipe | Slot | Old rank | New score | New rank |
|---|---|---|---|---|
| Fondé *(breakfast)* | breakfast | 1st (0.647 sim) | 0.650 | 1st ✅ |
| Soupe du Pêcheur *(lunch)* | breakfast | 2nd (0.670 sim) | 0.534 | 3rd ✅ |
| Sauce Arachide *(lunch)* | lunch | 3rd | 0.548 | 1st ✅ |
| Sauce Aubergine *(dinner)* | dinner | 4th | 0.404 | last |

Fondé correctly wins the breakfast slot (slot bonus applies). Soupe du Pêcheur correctly drops for breakfast (slot mismatch). Sauce Arachide correctly wins the lunch slot (protein alignment 0.893, slot bonus 0.15).

### 4. `generate_meal_plan` RPC Changes

The existing RPC (migration `20260529000003`) is replaced by a new migration. Changes from the current version:

1. **Fetch user goal macros** before the day loop: extract `calorie_goal`, `protein_goal`, `fat_goal` from `user_goal` to compute target densities.
2. **Candidate query** joins `recipe` to access `preferred_meal_type` alongside `recipe_macro` for density computation.
3. **Scoring loop** replaces `ORDER BY embedding <=> v_user_vector LIMIT 1` with `LIMIT 20` candidates scored individually, then `SELECT max(v_final_score)` to pick the winner.
4. **Return shape unchanged** — same columns as current version.

### 5. `create_batch_sessions` Function

```sql
CREATE OR REPLACE FUNCTION public.create_batch_sessions(
  p_meal_plan_id uuid,
  p_user_id      uuid
) RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_rec RECORD;
BEGIN
  FOR v_rec IN
    SELECT
      mpec.recipe_id,
      COUNT(*)               AS portion_count,
      MIN(mpe.scheduled_date) AS first_date
    FROM meal_plan_entry mpe
    JOIN meal_plan_entry_component mpec
      ON mpec.meal_plan_entry_id = mpe.id
    WHERE mpe.meal_plan_id = p_meal_plan_id
      AND mpec.role = 'base'
    GROUP BY mpec.recipe_id
    HAVING COUNT(*) >= 2
  LOOP
    INSERT INTO public.cooking_session (
      user_id, meal_plan_id, recipe_id,
      planned_date, total_portions, portions_used
    ) VALUES (
      p_user_id, p_meal_plan_id, v_rec.recipe_id,
      v_rec.first_date, v_rec.portion_count, 0
    )
    ON CONFLICT DO NOTHING;
  END LOOP;
END;
$$;
```

Logic: for every recipe that appears ≥2 times in the plan (as a `base` component), create one `cooking_session` row. `total_portions` = number of uses. `planned_date` = first day the recipe appears. `ON CONFLICT DO NOTHING` makes re-generation idempotent.

---

## Migrations

Four new migration files, applied in order:

| File | Purpose |
|---|---|
| `20260529000005_add_preferred_meal_type_to_recipe.sql` | Add column, default 'any' |
| `20260529000006_tag_existing_recipes_preferred_meal_type.sql` | UPDATE existing 14 recipes |
| `20260529000007_create_batch_sessions_function.sql` | Write the RPC |
| `20260529000008_rewrite_generate_meal_plan_v2.sql` | Weighted scoring RPC |

All applied via Supabase MCP `apply_migration`.

---

## What Does NOT Change

- Flutter app: zero changes. No model updates, no provider changes, no UI changes.
- Edge function `generate-meal-plan`: zero changes. It already calls `create_batch_sessions` and already returns `meal_plan_id`.
- Response shape of `generate_meal_plan`: same columns returned.
- RLS policies: unchanged.
- Recipe creation UI: handled separately on the website (Kelen-African_Network repo).

---

## Testing

After all 4 migrations are applied, re-run the live test:

```sql
SELECT * FROM generate_meal_plan(
  p_user_id    := 'c70fdca2-3adb-4bcf-ac98-06dcc23dc9ca',
  p_days       := 7,
  p_meals_per_day := 3,
  p_start_date := CURRENT_DATE
);
```

**Pass criteria:**
1. No recipe appears in both breakfast and dinner slots on the same day
2. Fondé appears only in breakfast slots
3. Daily protein totals stay within 20% of the 138.9g target across all 7 days
4. `cooking_session` rows created for recipes used ≥2 times
5. 21 entries returned, all macros computed
