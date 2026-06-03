# Meal Plan Scoring Improvements — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix three structural issues in `generate_meal_plan`: same recipe repeating across all meal slots in a day, poor macro alignment, and missing `create_batch_sessions` function.

**Architecture:** Four SQL migrations only — no Flutter changes. The RPC response shape is unchanged. Migrations are applied to the live Supabase project (`njzqcftjzskwcpforwzf`) via the Supabase MCP tool `apply_migration`. All verification is done via `execute_sql`.

**Tech Stack:** PostgreSQL 17, PL/pgSQL, pgvector, Supabase MCP.

---

## File Structure

| File | Action | Purpose |
|---|---|---|
| `supabase/migrations/20260529000005_add_preferred_meal_type_to_recipe.sql` | Create | Add `preferred_meal_type` column to `recipe` |
| `supabase/migrations/20260529000006_tag_existing_recipes_preferred_meal_type.sql` | Create | Set tags on the 14 live recipes |
| `supabase/migrations/20260529000007_create_batch_sessions_function.sql` | Create | Write `create_batch_sessions` RPC |
| `supabase/migrations/20260529000008_rewrite_generate_meal_plan_v2.sql` | Create | Weighted scoring RPC replacing migration `20260529000003` |

---

## Context for the implementer

**Supabase project ID:** `njzqcftjzskwcpforwzf`

**Test user ID:** `c70fdca2-3adb-4bcf-ac98-06dcc23dc9ca`
This user has: 180 cm / 100 kg male, target 90 kg, light activity.
Active `user_goal`: 1 852 kcal · 138.9g protein · 185.2g carbs · 61.7g fat.

**Current RPC:** `supabase/migrations/20260529000003_rewrite_generate_meal_plan.sql`
The v2 rewrite (Task 4) replaces the scoring logic inside that function. It does NOT change the return shape — same columns, same call signature.

**`recipe` table already has a `meal_types text[]` column** used as a hard eligibility filter (`v_meal_type = ANY(r.meal_types)`). All live recipes currently have all meal types in that array (so the filter doesn't restrict anything). The new `preferred_meal_type text` column is different — it's a single value used for scoring, not filtering.

**How `apply_migration` works:** it both executes the SQL on the remote DB AND registers the migration version so `supabase db push` won't re-apply it. Use it instead of `execute_sql` for all DDL and function changes.

---

## Task 1: Add `preferred_meal_type` column to `recipe`

**Files:**
- Create: `supabase/migrations/20260529000005_add_preferred_meal_type_to_recipe.sql`

- [ ] **Step 1: Write the migration file**

```sql
-- supabase/migrations/20260529000005_add_preferred_meal_type_to_recipe.sql
ALTER TABLE public.recipe
  ADD COLUMN IF NOT EXISTS preferred_meal_type text NOT NULL DEFAULT 'any'
  CHECK (preferred_meal_type IN ('breakfast', 'lunch', 'dinner', 'snack', 'any'));
```

- [ ] **Step 2: Apply via MCP**

Use `mcp__claude_ai_Supabase__apply_migration` with:
- `project_id`: `njzqcftjzskwcpforwzf`
- `name`: `add_preferred_meal_type_to_recipe`
- `query`: the SQL above

Expected: `{"success": true}`

- [ ] **Step 3: Verify column exists**

Use `mcp__claude_ai_Supabase__execute_sql`:
```sql
SELECT column_name, data_type, column_default, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'recipe'
  AND column_name = 'preferred_meal_type';
```

Expected: one row — `preferred_meal_type | text | 'any' | NO`

- [ ] **Step 4: Commit the migration file**

```bash
git add supabase/migrations/20260529000005_add_preferred_meal_type_to_recipe.sql
git commit -m "feat: add preferred_meal_type column to recipe table"
```

---

## Task 2: Tag the 14 live recipes

**Files:**
- Create: `supabase/migrations/20260529000006_tag_existing_recipes_preferred_meal_type.sql`

- [ ] **Step 1: Write the migration file**

```sql
-- supabase/migrations/20260529000006_tag_existing_recipes_preferred_meal_type.sql
-- Tag existing recipes with their preferred meal slot.
-- Unrecognised titles keep the default 'any'.

UPDATE public.recipe SET preferred_meal_type = 'breakfast'
WHERE title IN ('Fondé', 'Pap en Vleis');

UPDATE public.recipe SET preferred_meal_type = 'lunch'
WHERE title IN (
  'Soupe du Pêcheur — Atiéké',
  'Sauce Arachide — Riz Blanc',
  'Sauce Noix de Cajou — Riz Blanc',
  'Bawoin — Riz Blanc',
  'Ewa Aganyin',
  'Bunny Chow'
);

UPDATE public.recipe SET preferred_meal_type = 'dinner'
WHERE title IN (
  'Sauce Pistache — Fufu d''Ignames',
  'Sauce Gouagouassou — Foutou',
  'Sauce Aubergine — Riz',
  'Bouillon de Pieds de Porc — Riz Blanc',
  'Nyama Choma',
  'Sauce Pklala — Riz'
);
```

- [ ] **Step 2: Apply via MCP**

Use `mcp__claude_ai_Supabase__apply_migration` with:
- `project_id`: `njzqcftjzskwcpforwzf`
- `name`: `tag_existing_recipes_preferred_meal_type`
- `query`: the SQL above

Expected: `{"success": true}`

- [ ] **Step 3: Verify tags applied correctly**

Use `mcp__claude_ai_Supabase__execute_sql`:
```sql
SELECT title, preferred_meal_type
FROM public.recipe
WHERE preferred_meal_type != 'any'
ORDER BY preferred_meal_type, title;
```

Expected: 14 rows grouped under `breakfast` (2), `lunch` (6), `dinner` (6). Zero rows with `'any'` that should have a tag.

- [ ] **Step 4: Verify no recipe left unintentionally as 'any'**

```sql
SELECT title, preferred_meal_type
FROM public.recipe
WHERE preferred_meal_type = 'any'
ORDER BY title;
```

This should return 0 rows (all 14 known recipes are tagged). If any appear, update the migration to add them.

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260529000006_tag_existing_recipes_preferred_meal_type.sql
git commit -m "feat: tag existing 14 recipes with preferred_meal_type"
```

---

## Task 3: Write and deploy `create_batch_sessions`

**Files:**
- Create: `supabase/migrations/20260529000007_create_batch_sessions_function.sql`

- [ ] **Step 1: Write the migration file**

```sql
-- supabase/migrations/20260529000007_create_batch_sessions_function.sql
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
      COUNT(*)                AS portion_count,
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

- [ ] **Step 2: Apply via MCP**

Use `mcp__claude_ai_Supabase__apply_migration` with:
- `project_id`: `njzqcftjzskwcpforwzf`
- `name`: `create_batch_sessions_function`
- `query`: the SQL above

Expected: `{"success": true}`

- [ ] **Step 3: Verify function exists**

Use `mcp__claude_ai_Supabase__execute_sql`:
```sql
SELECT proname, pronargs
FROM pg_proc
WHERE proname = 'create_batch_sessions';
```

Expected: one row — `create_batch_sessions | 2`

- [ ] **Step 4: Smoke-test against the latest plan**

Get the most recent active meal plan for the test user, then call the function:
```sql
-- Get latest plan id
SELECT id FROM meal_plan
WHERE user_id = 'c70fdca2-3adb-4bcf-ac98-06dcc23dc9ca'
  AND is_active = true
ORDER BY created_at DESC
LIMIT 1;
```

Then (replace `<plan_id>` with the result):
```sql
SELECT create_batch_sessions(
  '<plan_id>'::uuid,
  'c70fdca2-3adb-4bcf-ac98-06dcc23dc9ca'::uuid
);

SELECT cs.id, r.title, cs.total_portions, cs.planned_date
FROM cooking_session cs
JOIN recipe r ON r.id = cs.recipe_id
WHERE cs.meal_plan_id = '<plan_id>'
ORDER BY cs.planned_date;
```

Expected: rows for recipes used ≥2 times in the plan, with `total_portions` matching their count.

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260529000007_create_batch_sessions_function.sql
git commit -m "feat: add create_batch_sessions RPC for batch cooking session creation"
```

---

## Task 4: Rewrite `generate_meal_plan` with weighted scoring

**Files:**
- Create: `supabase/migrations/20260529000008_rewrite_generate_meal_plan_v2.sql`

This replaces the scoring logic from `20260529000003`. The function signature and return shape are identical — no callers change.

**What changes vs `20260529000003`:**
1. Fetch `protein_goal` and `fat_goal` from `user_goal` (previously only `calorie_goal` was fetched)
2. Pre-compute `v_target_protein_density` and `v_target_fat_density` once before the day loop
3. Replace `ORDER BY score DESC` (single similarity) with a 4-component weighted formula
4. Fallback path (no vector): add slot match bonus alongside like count

- [ ] **Step 1: Write the migration file**

```sql
-- supabase/migrations/20260529000008_rewrite_generate_meal_plan_v2.sql
-- V2: weighted scoring = 50% similarity + 25% protein alignment
--                       + 15% meal slot preference + 10% fat alignment

DROP FUNCTION IF EXISTS generate_meal_plan(uuid, int, int, date);
CREATE OR REPLACE FUNCTION generate_meal_plan(
  p_user_id       uuid,
  p_days          int     DEFAULT 7,
  p_meals_per_day int     DEFAULT 3,
  p_start_date    date    DEFAULT CURRENT_DATE
)
RETURNS TABLE (
  meal_plan_id    uuid,
  entry_id        uuid,
  component_id    uuid,
  scheduled_date  date,
  meal_type       text,
  recipe_id       uuid,
  recipe_title    text,
  cover_image_url text,
  calories        numeric,
  protein_g       numeric,
  similarity      float
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_vector            vector(50);
  v_fan_creator_id         uuid;
  v_plan_id                uuid;
  v_meal_types             text[] := ARRAY['breakfast', 'lunch', 'dinner'];
  v_day                    int;
  v_meal_type              text;
  v_current_date           date;
  v_recipe                 record;
  v_entry_id               uuid;
  v_component_id           uuid;
  v_used_recipe_ids        uuid[] := ARRAY[]::uuid[];
  v_calorie_goal           numeric;
  v_protein_goal           numeric;
  v_fat_goal               numeric;
  v_target_meal_cal        numeric;
  v_target_protein_density numeric;
  v_target_fat_density     numeric;
  v_servings               numeric(4,1);
  v_fan_count              int := 0;
  v_other_count            int := 0;
  v_total_slots            int;
  v_max_other_slots        int;
BEGIN
  v_total_slots     := p_days * p_meals_per_day;
  v_max_other_slots := FLOOR(v_total_slots * 0.10);

  IF p_meals_per_day = 2 THEN
    v_meal_types := ARRAY['lunch', 'dinner'];
  ELSIF p_meals_per_day = 4 THEN
    v_meal_types := ARRAY['breakfast', 'lunch', 'dinner', 'snack'];
  END IF;

  SELECT uv.vector INTO v_user_vector
  FROM user_vector uv WHERE uv.user_id = p_user_id;

  SELECT fs.creator_id INTO v_fan_creator_id
  FROM fan_subscription fs
  WHERE fs.user_id = p_user_id AND fs.status = 'active'
  LIMIT 1;

  -- Fetch all three macro goals in one query
  SELECT calorie_goal, protein_goal, fat_goal
  INTO v_calorie_goal, v_protein_goal, v_fat_goal
  FROM user_goal
  WHERE user_id = p_user_id AND is_active = true
  ORDER BY created_at DESC
  LIMIT 1;

  -- Pre-compute target macro densities (g per 100 kcal, per-meal basis).
  -- Used in weighted scoring for the entire plan; computed once here.
  IF v_calorie_goal IS NOT NULL AND v_calorie_goal > 0 AND p_meals_per_day > 0 THEN
    v_target_protein_density :=
      COALESCE(v_protein_goal, 0) / (v_calorie_goal / p_meals_per_day) * 100;
    v_target_fat_density :=
      COALESCE(v_fat_goal, 0) / (v_calorie_goal / p_meals_per_day) * 100;
  ELSE
    -- Sensible defaults when no goal exists (~30%P / 30%F of 1850 kcal / 3 meals)
    v_target_protein_density := 7.5;
    v_target_fat_density     := 3.3;
  END IF;

  UPDATE meal_plan SET is_active = false
  WHERE user_id = p_user_id AND is_active = true;

  INSERT INTO meal_plan (user_id, start_date, end_date, is_active)
  VALUES (p_user_id, p_start_date, p_start_date + (p_days - 1), true)
  RETURNING id INTO v_plan_id;

  FOR v_day IN 0..(p_days - 1) LOOP
    v_current_date := p_start_date + v_day;

    FOREACH v_meal_type IN ARRAY v_meal_types LOOP
      v_target_meal_cal := NULL;
      SELECT md.calorie_target INTO v_target_meal_cal
      FROM meal_distribution md
      JOIN nutrition_plan np ON np.id = md.nutrition_plan_id
      WHERE np.user_id = p_user_id
        AND np.is_active = true
        AND md.meal_type = v_meal_type
      LIMIT 1;

      IF v_target_meal_cal IS NULL AND v_calorie_goal IS NOT NULL AND v_calorie_goal > 0 THEN
        v_target_meal_cal := v_calorie_goal / p_meals_per_day;
      END IF;

      IF v_user_vector IS NOT NULL THEN
        -- Weighted score:
        --   0.50 × cultural similarity (fan bonus preserved)
        --   0.25 × protein density alignment
        --   0.15 × meal slot preference (preferred_meal_type)
        --   0.10 × fat density alignment
        SELECT r.id, r.title, r.cover_image_url,
               rm.calories, rm.protein_g, rm.carbs_g, rm.fat_g,
               r.creator_id,
               (
                 0.50 * (1 - (rv.vector <=> v_user_vector))
                        * CASE WHEN v_fan_creator_id IS NOT NULL
                                    AND r.creator_id = v_fan_creator_id
                               THEN 1.5 ELSE 1.0 END
                 + 0.25 * GREATEST(0.0, 1.0 - LEAST(
                     ABS(rm.protein_g / NULLIF(rm.calories, 0) * 100
                         - v_target_protein_density)
                     / NULLIF(v_target_protein_density, 0.001),
                     1.0))
                 + 0.15 * CASE
                     WHEN r.preferred_meal_type = v_meal_type THEN 1.0
                     WHEN r.preferred_meal_type = 'any'       THEN 0.5
                     ELSE 0.0
                   END
                 + 0.10 * GREATEST(0.0, 1.0 - LEAST(
                     ABS(rm.fat_g / NULLIF(rm.calories, 0) * 100
                         - v_target_fat_density)
                     / NULLIF(v_target_fat_density, 0.001),
                     1.0))
               ) AS score
        INTO v_recipe
        FROM recipe r
        JOIN recipe_vector rv ON r.id = rv.recipe_id
        JOIN recipe_macro rm ON r.id = rm.recipe_id
        WHERE r.is_published = true
          AND v_meal_type = ANY(r.meal_types)
          AND rm.calories > 0
          AND (SELECT count(*) FROM unnest(v_used_recipe_ids) x WHERE x = r.id) < 3
          AND (
            v_fan_creator_id IS NULL
            OR v_other_count < v_max_other_slots
            OR r.creator_id = v_fan_creator_id
          )
          AND (
            v_target_meal_cal IS NULL
            OR (v_target_meal_cal / rm.calories) <= 4.0
          )
        ORDER BY score DESC
        LIMIT 1;
      ELSE
        -- No user vector: rank by slot preference then popularity
        SELECT r.id, r.title, r.cover_image_url,
               rm.calories, rm.protein_g, rm.carbs_g, rm.fat_g,
               r.creator_id,
               (
                 0.15 * CASE
                   WHEN r.preferred_meal_type = v_meal_type THEN 1.0
                   WHEN r.preferred_meal_type = 'any'       THEN 0.5
                   ELSE 0.0
                 END
               ) AS score
        INTO v_recipe
        FROM recipe r
        JOIN recipe_macro rm ON r.id = rm.recipe_id
        LEFT JOIN recipe_like rl ON r.id = rl.recipe_id
        WHERE r.is_published = true
          AND v_meal_type = ANY(r.meal_types)
          AND rm.calories > 0
          AND (SELECT count(*) FROM unnest(v_used_recipe_ids) x WHERE x = r.id) < 3
          AND (
            v_fan_creator_id IS NULL
            OR v_other_count < v_max_other_slots
            OR r.creator_id = v_fan_creator_id
          )
          AND (
            v_target_meal_cal IS NULL
            OR (v_target_meal_cal / rm.calories) <= 4.0
          )
        GROUP BY r.id, rm.calories, rm.protein_g, rm.carbs_g, rm.fat_g,
                 r.creator_id, r.preferred_meal_type
        ORDER BY score DESC, COUNT(rl.recipe_id) DESC
        LIMIT 1;
      END IF;

      IF v_recipe.id IS NULL THEN
        RAISE EXCEPTION 'insufficient_recipes' USING DETAIL = v_meal_type;
      END IF;

      IF v_target_meal_cal IS NOT NULL AND v_recipe.calories > 0 THEN
        v_servings := GREATEST(0.1, LEAST(4.0,
          ROUND((v_target_meal_cal / v_recipe.calories)::numeric, 1)));
      ELSE
        v_servings := 1.0;
      END IF;

      INSERT INTO meal_plan_entry (
        meal_plan_id, scheduled_date, meal_type, servings,
        calories_computed, protein_g_computed, carbs_g_computed, fat_g_computed
      )
      VALUES (
        v_plan_id, v_current_date, v_meal_type, v_servings,
        ROUND((v_recipe.calories  * v_servings)::numeric, 1),
        ROUND((v_recipe.protein_g * v_servings)::numeric, 1),
        ROUND((v_recipe.carbs_g   * v_servings)::numeric, 1),
        ROUND((v_recipe.fat_g     * v_servings)::numeric, 1)
      )
      RETURNING id INTO v_entry_id;

      INSERT INTO meal_plan_entry_component (meal_plan_entry_id, recipe_id, role, consumption_weight)
      VALUES (v_entry_id, v_recipe.id, 'base', 1.0)
      RETURNING id INTO v_component_id;

      INSERT INTO meal_ingredient (meal_plan_entry_id, ingredient_id, ingredient_name, quantity, unit)
      SELECT
        v_entry_id,
        ri.ingredient_id,
        COALESCE(i.name_fr, i.name),
        ROUND((ri.quantity * v_servings)::numeric, 3),
        ri.unit
      FROM recipe_ingredient ri
      JOIN ingredient i ON i.id = ri.ingredient_id
      WHERE ri.recipe_id = v_recipe.id
        AND ri.is_optional = false;

      v_used_recipe_ids := v_used_recipe_ids || v_recipe.id;
      IF v_fan_creator_id IS NOT NULL THEN
        IF v_recipe.creator_id = v_fan_creator_id THEN
          v_fan_count := v_fan_count + 1;
        ELSE
          v_other_count := v_other_count + 1;
        END IF;
      END IF;

      RETURN QUERY SELECT
        v_plan_id,
        v_entry_id,
        v_component_id,
        v_current_date,
        v_meal_type,
        v_recipe.id,
        v_recipe.title,
        v_recipe.cover_image_url,
        ROUND((v_recipe.calories  * v_servings)::numeric, 1),
        ROUND((v_recipe.protein_g * v_servings)::numeric, 1),
        v_recipe.score::float;

    END LOOP;
  END LOOP;
END;
$$;
```

- [ ] **Step 2: Apply via MCP**

Use `mcp__claude_ai_Supabase__apply_migration` with:
- `project_id`: `njzqcftjzskwcpforwzf`
- `name`: `rewrite_generate_meal_plan_v2`
- `query`: the full SQL above

Expected: `{"success": true}`

- [ ] **Step 3: Run the full live test**

Use `mcp__claude_ai_Supabase__execute_sql`:
```sql
SELECT * FROM generate_meal_plan(
  p_user_id       := 'c70fdca2-3adb-4bcf-ac98-06dcc23dc9ca',
  p_days          := 7,
  p_meals_per_day := 3,
  p_start_date    := CURRENT_DATE
);
```

Expected: 21 rows returned, no errors.

- [ ] **Step 4: Verify daily slot variety (Issue 1 fix)**

```sql
-- No day should have the same recipe_title in all 3 meal slots
SELECT scheduled_date, recipe_title, COUNT(*) AS slot_count
FROM (
  SELECT mpe.scheduled_date, mpe.meal_type, r.title AS recipe_title
  FROM meal_plan_entry mpe
  JOIN meal_plan_entry_component mpec ON mpec.meal_plan_entry_id = mpe.id
  JOIN recipe r ON r.id = mpec.recipe_id
  WHERE mpe.meal_plan_id = (
    SELECT id FROM meal_plan
    WHERE user_id = 'c70fdca2-3adb-4bcf-ac98-06dcc23dc9ca'
      AND is_active = true
    ORDER BY created_at DESC LIMIT 1
  )
) sub
GROUP BY scheduled_date, recipe_title
HAVING COUNT(*) = 3;
```

Expected: **0 rows** — no recipe appears in all 3 slots of the same day.

- [ ] **Step 5: Verify slot preference is respected (Fondé → breakfast only)**

```sql
SELECT mpe.scheduled_date, mpe.meal_type, r.title
FROM meal_plan_entry mpe
JOIN meal_plan_entry_component mpec ON mpec.meal_plan_entry_id = mpe.id
JOIN recipe r ON r.id = mpec.recipe_id
WHERE mpe.meal_plan_id = (
  SELECT id FROM meal_plan
  WHERE user_id = 'c70fdca2-3adb-4bcf-ac98-06dcc23dc9ca'
    AND is_active = true
  ORDER BY created_at DESC LIMIT 1
)
  AND r.title = 'Fondé';
```

Expected: rows only with `meal_type = 'breakfast'`.

- [ ] **Step 6: Verify macro alignment improvement (Issue 2 fix)**

```sql
-- Daily protein totals — should be closer to 138.9g target
SELECT
  mpe.scheduled_date,
  ROUND(SUM(mpe.protein_g_computed), 1) AS daily_protein_g,
  138.9 AS target_protein_g,
  ROUND(ABS(SUM(mpe.protein_g_computed) - 138.9), 1) AS deviation_g
FROM meal_plan_entry mpe
WHERE mpe.meal_plan_id = (
  SELECT id FROM meal_plan
  WHERE user_id = 'c70fdca2-3adb-4bcf-ac98-06dcc23dc9ca'
    AND is_active = true
  ORDER BY created_at DESC LIMIT 1
)
GROUP BY mpe.scheduled_date
ORDER BY mpe.scheduled_date;
```

Expected: deviations smaller than before. The previous worst day was 52g (Fondé day). With v2, Fondé should only appear in breakfast (1 slot, not 3), so no day will have all-Fondé and protein crash that severely.

- [ ] **Step 7: Verify batch sessions created (Issue 3 fix)**

```sql
SELECT cs.id, r.title, cs.total_portions, cs.planned_date
FROM cooking_session cs
JOIN recipe r ON r.id = cs.recipe_id
WHERE cs.meal_plan_id = (
  SELECT id FROM meal_plan
  WHERE user_id = 'c70fdca2-3adb-4bcf-ac98-06dcc23dc9ca'
    AND is_active = true
  ORDER BY created_at DESC LIMIT 1
)
ORDER BY cs.planned_date;
```

Expected: rows for recipes that appear ≥2 times in the plan. The edge function calls `create_batch_sessions` automatically after generation; since the function now exists, rows should appear.

Note: if the plan was generated by the RPC directly (not via edge function), call the function manually:
```sql
SELECT create_batch_sessions(
  (SELECT id FROM meal_plan
   WHERE user_id = 'c70fdca2-3adb-4bcf-ac98-06dcc23dc9ca'
     AND is_active = true
   ORDER BY created_at DESC LIMIT 1),
  'c70fdca2-3adb-4bcf-ac98-06dcc23dc9ca'::uuid
);
```

- [ ] **Step 8: Commit**

```bash
git add supabase/migrations/20260529000008_rewrite_generate_meal_plan_v2.sql
git commit -m "feat: weighted scoring in generate_meal_plan (slot preference + macro alignment)"
```
