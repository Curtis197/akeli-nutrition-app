# Ingredient Quantity Rounding Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Round scaled ingredient quantities to human-usable cooking values (e.g. "1/2 fish" not "0.7 fish", "235g" not "236.7g") by applying per-unit and per-ingredient rounding rules at write time.

**Architecture:** Two new DB tables (`unit_rounding_config`, `ingredient_rounding_rule`) feed a `round_to_step()` SQL function. The three write points that scale ingredients (`generate_meal_plan`, `swap_meal_plan_entry`, `create_batch_sessions`) apply the function on INSERT. A Flutter helper `formatQuantity()` renders countable-unit values as fractions for display.

**Tech Stack:** PostgreSQL / Supabase MCP (migrations), Dart / Flutter (display helper), `package:collection` (already in pubspec)

---

## File Map

| File | Change |
|------|--------|
| `supabase/migrations/20260603000003_ingredient_rounding_schema.sql` | Create — tables + `round_to_step` + seed |
| `supabase/migrations/20260603000004_ingredient_rounding_write_points.sql` | Create — update 3 SQL write-point functions |
| `lib/core/quantity_formatter.dart` | Create — `formatQuantity(double, String)` helper |
| `test/core/quantity_formatter_test.dart` | Create — unit tests for `formatQuantity` |
| `lib/shared/models/meal_plan.dart` | Modify — update `quantityDisplay` getters on 3 models |
| `lib/shared/widgets/shopping_row.dart` | Modify — use `formatQuantity` instead of inline `toStringAsFixed` |
| `lib/features/meal_planner/batch_cooking_page.dart` | Modify — use `formatQuantity` for ingredient display |

`meal_detail_page.dart` already uses `ing.quantityDisplay` — updating the getter in the model is sufficient.

---

## Task 1: DB schema — tables, function, seed data

**Files:**
- Create: `supabase/migrations/20260603000003_ingredient_rounding_schema.sql`

- [ ] **Step 1: Write the migration file**

```sql
-- supabase/migrations/20260603000003_ingredient_rounding_schema.sql
-- Unit-level default rounding steps.
CREATE TABLE public.unit_rounding_config (
  unit          text PRIMARY KEY,
  rounding_step numeric NOT NULL
);

INSERT INTO public.unit_rounding_config (unit, rounding_step) VALUES
  ('unit',  0.5),   -- halves: 1/2 onion, 1/2 lemon
  ('piece', 0.5),   -- halves: 1/2 chicken breast
  ('tsp',   0.25),  -- quarter tsp
  ('tbsp',  0.5),   -- half tbsp
  ('clove', 1),     -- whole cloves only
  ('bunch', 1),     -- whole bunches only
  ('can',   1),     -- whole cans only
  ('pot',   1),     -- whole pots only
  ('pinch', 0.5),   -- half pinch at most
  ('g',     5),     -- nearest 5g
  ('ml',    5),     -- nearest 5ml
  ('kg',    0.1),   -- nearest 100g
  ('l',     0.1);   -- nearest 100ml

-- Per-(ingredient, unit) overrides. NULL rounding_step = no rounding.
CREATE TABLE public.ingredient_rounding_rule (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  ingredient_id   uuid NOT NULL REFERENCES public.ingredient(id) ON DELETE CASCADE,
  unit            text NOT NULL,
  rounding_step   numeric,
  UNIQUE (ingredient_id, unit)
);

-- Round qty to the nearest multiple of step.
-- GREATEST(step, ...) prevents non-zero quantities from rounding to 0.
CREATE OR REPLACE FUNCTION public.round_to_step(qty numeric, step numeric)
RETURNS numeric LANGUAGE sql IMMUTABLE AS $$
  SELECT CASE
    WHEN step IS NULL OR step = 0 THEN qty
    WHEN qty = 0                  THEN 0
    ELSE GREATEST(step, ROUND(qty / step) * step)
  END;
$$;
```

- [ ] **Step 2: Apply the migration via Supabase MCP**

Use `mcp__claude_ai_Supabase__apply_migration` with:
- `project_id`: `njzqcftjzskwcpforwzf`
- `name`: `ingredient_rounding_schema`
- `query`: (full SQL above)

- [ ] **Step 3: Verify tables and function exist on remote DB**

Run via `mcp__claude_ai_Supabase__execute_sql`:
```sql
SELECT table_name FROM information_schema.tables
WHERE table_name IN ('unit_rounding_config', 'ingredient_rounding_rule');

SELECT COUNT(*) FROM unit_rounding_config;  -- must be 13

SELECT proname FROM pg_proc WHERE proname = 'round_to_step';
```

Expected: both tables, 13 rows seeded, function present.

- [ ] **Step 4: Verify round_to_step behaviour**

```sql
SELECT
  round_to_step(0.7,  0.5) AS fish_fractionable,   -- expect 0.5
  round_to_step(0.4,  0.5) AS fish_low,             -- expect 0.5 (minimum = step)
  round_to_step(0.4,  1.0) AS egg_whole,            -- expect 1   (minimum = step)
  round_to_step(237,  5)   AS flour_g,              -- expect 235
  round_to_step(423,  25)  AS chicken_g,            -- expect 425
  round_to_step(0.237,0.1) AS milk_l,               -- expect 0.2
  round_to_step(0,    0.5) AS zero_qty,             -- expect 0
  round_to_step(1.4,  0.5) AS fish_one_half;        -- expect 1.5
```

All values must match expectations. Fix `round_to_step` if any fails before proceeding.

- [ ] **Step 5: Commit migration file**

```powershell
git add supabase/migrations/20260603000003_ingredient_rounding_schema.sql
git commit -m "feat(db): add unit_rounding_config, ingredient_rounding_rule, round_to_step"
```

---

## Task 2: DB write points — update 3 SQL functions

**Files:**
- Create: `supabase/migrations/20260603000004_ingredient_rounding_write_points.sql`

### Background

Three functions insert scaled ingredient quantities and currently use `ROUND(..., 3)`. Replace each with `round_to_step(qty, effective_step)` where the step is looked up via:

```sql
COALESCE(
  (SELECT rounding_step FROM ingredient_rounding_rule
   WHERE ingredient_id = ri.ingredient_id AND unit = ri.unit),
  (SELECT rounding_step FROM unit_rounding_config WHERE unit = ri.unit)
)
```

- [ ] **Step 1: Write the migration file**

```sql
-- supabase/migrations/20260603000004_ingredient_rounding_write_points.sql

-- ── 1. generate_meal_plan ──────────────────────────────────────────────────
-- Only the meal_ingredient INSERT changes; all other logic is identical to
-- the version in 20260603000002_fix_generate_meal_plan_max_repeat.sql.
CREATE OR REPLACE FUNCTION generate_meal_plan(
  p_user_id            uuid,
  p_days               integer,
  p_meals_per_day      integer,
  p_start_date         date,
  p_max_recipe_repeat  integer DEFAULT 3
)
RETURNS TABLE (
  meal_plan_id      uuid,
  entry_id          uuid,
  component_id      uuid,
  scheduled_date    date,
  meal_type         text,
  recipe_id         uuid,
  recipe_title      text,
  cover_image_url   text,
  calories          numeric,
  protein_g         numeric,
  score             double precision
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
  v_user_allergens         text[];
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
  IF p_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  IF EXISTS (
    SELECT 1 FROM meal_plan
    WHERE user_id = p_user_id
      AND start_date = p_start_date
      AND is_active = true
  ) THEN
    RETURN;
  END IF;

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

  SELECT COALESCE(array_agg(a.slug), ARRAY[]::text[]) INTO v_user_allergens
  FROM user_allergy ua
  JOIN allergen a ON a.id = ua.allergen_id
  WHERE ua.user_id = p_user_id;

  SELECT calorie_goal, protein_goal, fat_goal
  INTO v_calorie_goal, v_protein_goal, v_fat_goal
  FROM user_goal
  WHERE user_id = p_user_id AND is_active = true
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_calorie_goal IS NOT NULL AND v_calorie_goal > 0 AND p_meals_per_day > 0 THEN
    v_target_protein_density :=
      COALESCE(v_protein_goal, 0) / (v_calorie_goal / p_meals_per_day) * 100;
    v_target_fat_density :=
      COALESCE(v_fat_goal, 0) / (v_calorie_goal / p_meals_per_day) * 100;
  ELSE
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
          AND (SELECT count(*) FROM unnest(v_used_recipe_ids) x WHERE x = r.id) < p_max_recipe_repeat
          AND (
            v_fan_creator_id IS NULL
            OR v_other_count < v_max_other_slots
            OR r.creator_id = v_fan_creator_id
          )
          AND (
            v_target_meal_cal IS NULL
            OR (v_target_meal_cal / rm.calories) <= 4.0
          )
          AND NOT (r.allergen_tags && v_user_allergens)
        ORDER BY score DESC
        LIMIT 1;
      ELSE
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
          AND (SELECT count(*) FROM unnest(v_used_recipe_ids) x WHERE x = r.id) < p_max_recipe_repeat
          AND (
            v_fan_creator_id IS NULL
            OR v_other_count < v_max_other_slots
            OR r.creator_id = v_fan_creator_id
          )
          AND (
            v_target_meal_cal IS NULL
            OR (v_target_meal_cal / rm.calories) <= 4.0
          )
          AND NOT (r.allergen_tags && v_user_allergens)
        GROUP BY r.id, r.title, r.cover_image_url, r.creator_id, r.preferred_meal_type,
                 rm.calories, rm.protein_g, rm.carbs_g, rm.fat_g
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

      -- KEY CHANGE: round_to_step replaces ROUND(..., 3)
      INSERT INTO meal_ingredient (meal_plan_entry_id, ingredient_id, ingredient_name, quantity, unit)
      SELECT
        v_entry_id,
        ri.ingredient_id,
        COALESCE(i.name_fr, i.name),
        round_to_step(
          ri.quantity * v_servings,
          COALESCE(
            (SELECT rounding_step FROM ingredient_rounding_rule
             WHERE ingredient_id = ri.ingredient_id AND unit = ri.unit),
            (SELECT rounding_step FROM unit_rounding_config WHERE unit = ri.unit)
          )
        ),
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
        v_plan_id, v_entry_id, v_component_id,
        v_current_date, v_meal_type,
        v_recipe.id, v_recipe.title, v_recipe.cover_image_url,
        ROUND((v_recipe.calories  * v_servings)::numeric, 1),
        ROUND((v_recipe.protein_g * v_servings)::numeric, 1),
        v_recipe.score::double precision;

    END LOOP;
  END LOOP;
END;
$$;


-- ── 2. swap_meal_plan_entry ────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION swap_meal_plan_entry(
  p_entry_id      uuid,
  p_new_recipe_id uuid
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user_id              uuid;
  v_plan_id              uuid;
  v_meals_per_day        int;
  v_calorie_goal         numeric;
  v_target_meal_calories numeric;
  v_recipe_calories      numeric;
  v_recipe_protein_g     numeric;
  v_recipe_carbs_g       numeric;
  v_recipe_fat_g         numeric;
  v_new_servings         numeric(4,1) := 1.0;
  v_entry_date           date;
BEGIN
  SELECT mp.user_id, mp.id, mpe.scheduled_date
  INTO   v_user_id, v_plan_id, v_entry_date
  FROM   meal_plan_entry mpe
  JOIN   meal_plan mp ON mp.id = mpe.meal_plan_id
  WHERE  mpe.id = p_entry_id;

  IF v_user_id IS NULL OR v_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Unauthorized or entry not found';
  END IF;

  SELECT COUNT(*) INTO v_meals_per_day
  FROM   meal_plan_entry
  WHERE  meal_plan_id = v_plan_id AND scheduled_date = v_entry_date;

  IF v_meals_per_day = 0 THEN v_meals_per_day := 3; END IF;

  SELECT calorie_goal INTO v_calorie_goal
  FROM   user_goal
  WHERE  user_id = v_user_id AND is_active = true
  ORDER  BY created_at DESC LIMIT 1;

  SELECT calories, protein_g, carbs_g, fat_g
  INTO   v_recipe_calories, v_recipe_protein_g, v_recipe_carbs_g, v_recipe_fat_g
  FROM   recipe_macro
  WHERE  recipe_id = p_new_recipe_id;

  IF v_calorie_goal IS NOT NULL AND v_calorie_goal > 0
     AND v_recipe_calories IS NOT NULL AND v_recipe_calories > 0 THEN
    v_target_meal_calories := v_calorie_goal / v_meals_per_day;
    v_new_servings := ROUND((v_target_meal_calories / v_recipe_calories)::numeric, 1);
    IF v_new_servings < 0.1 THEN v_new_servings := 0.1; END IF;
  END IF;

  UPDATE meal_plan_entry
  SET
    servings           = v_new_servings,
    calories_computed  = ROUND((COALESCE(v_recipe_calories,  0) * v_new_servings)::numeric, 1),
    protein_g_computed = ROUND((COALESCE(v_recipe_protein_g, 0) * v_new_servings)::numeric, 1),
    carbs_g_computed   = ROUND((COALESCE(v_recipe_carbs_g,   0) * v_new_servings)::numeric, 1),
    fat_g_computed     = ROUND((COALESCE(v_recipe_fat_g,     0) * v_new_servings)::numeric, 1)
  WHERE id = p_entry_id;

  DELETE FROM meal_plan_entry_component WHERE meal_plan_entry_id = p_entry_id;

  INSERT INTO meal_plan_entry_component (meal_plan_entry_id, recipe_id, role, consumption_weight)
  VALUES (p_entry_id, p_new_recipe_id, 'base', 1.0);

  DELETE FROM meal_ingredient WHERE meal_plan_entry_id = p_entry_id;

  -- KEY CHANGE: round_to_step replaces ROUND(..., 3)
  INSERT INTO meal_ingredient (meal_plan_entry_id, ingredient_id, ingredient_name, quantity, unit)
  SELECT
    p_entry_id,
    ri.ingredient_id,
    COALESCE(i.name_fr, i.name),
    round_to_step(
      ri.quantity * v_new_servings,
      COALESCE(
        (SELECT rounding_step FROM ingredient_rounding_rule
         WHERE ingredient_id = ri.ingredient_id AND unit = ri.unit),
        (SELECT rounding_step FROM unit_rounding_config WHERE unit = ri.unit)
      )
    ),
    ri.unit
  FROM   recipe_ingredient ri
  JOIN   ingredient i ON i.id = ri.ingredient_id
  WHERE  ri.recipe_id = p_new_recipe_id
    AND  ri.is_optional = false
    AND  ri.ingredient_id IS NOT NULL;

  PERFORM generate_shopping_list(v_plan_id);
  PERFORM create_batch_sessions(v_plan_id, v_user_id, 7);
END;
$$;


-- ── 3. create_batch_sessions ───────────────────────────────────────────────
CREATE OR REPLACE FUNCTION create_batch_sessions(
  p_meal_plan_id  uuid,
  p_user_id       uuid,
  p_max_portions  integer
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_rec              RECORD;
  v_recipe_servings  numeric;
  v_scale_factor     numeric(6,3);
  v_session_id       uuid;
BEGIN
  IF p_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM public.meal_plan
    WHERE id = p_meal_plan_id AND user_id = p_user_id
  ) THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  DELETE FROM public.cooking_session
  WHERE meal_plan_id = p_meal_plan_id AND user_id = p_user_id;

  FOR v_rec IN
    SELECT
      mpec.recipe_id,
      COUNT(*)                AS appearance_count,
      SUM(mpe.servings)       AS total_portions_needed,
      MIN(mpe.scheduled_date) AS first_date
    FROM public.meal_plan_entry mpe
    JOIN public.meal_plan_entry_component mpec
      ON mpec.meal_plan_entry_id = mpe.id
    WHERE mpe.meal_plan_id = p_meal_plan_id
      AND mpec.role = 'base'
    GROUP BY mpec.recipe_id
    HAVING COUNT(*) >= 2 AND COUNT(*) <= p_max_portions
  LOOP
    SELECT servings INTO v_recipe_servings
    FROM public.recipe WHERE id = v_rec.recipe_id;

    v_scale_factor := ROUND(
      (v_rec.total_portions_needed / GREATEST(COALESCE(v_recipe_servings, 1), 1))::numeric,
      3
    );

    INSERT INTO public.cooking_session (
      user_id, meal_plan_id, recipe_id,
      planned_date, total_portions, portions_used, scale_factor
    ) VALUES (
      p_user_id, p_meal_plan_id, v_rec.recipe_id,
      v_rec.first_date, v_rec.appearance_count::int, 0, v_scale_factor
    )
    RETURNING id INTO v_session_id;

    -- KEY CHANGE: round_to_step replaces ROUND(..., 3)
    INSERT INTO public.cooking_session_ingredient
      (cooking_session_id, ingredient_id, ingredient_name, quantity_needed, unit)
    SELECT
      v_session_id,
      ri.ingredient_id,
      COALESCE(i.name_fr, i.name),
      round_to_step(
        ri.quantity * v_scale_factor,
        COALESCE(
          (SELECT rounding_step FROM ingredient_rounding_rule
           WHERE ingredient_id = ri.ingredient_id AND unit = ri.unit),
          (SELECT rounding_step FROM unit_rounding_config WHERE unit = ri.unit)
        )
      ),
      ri.unit
    FROM public.recipe_ingredient ri
    JOIN public.ingredient i ON i.id = ri.ingredient_id
    WHERE ri.recipe_id = v_rec.recipe_id
      AND ri.is_optional = false;

    UPDATE public.meal_plan_entry_component mpec
    SET cooking_session_id = v_session_id
    FROM public.meal_plan_entry mpe
    WHERE mpec.meal_plan_entry_id = mpe.id
      AND mpe.meal_plan_id = p_meal_plan_id
      AND mpec.recipe_id = v_rec.recipe_id;

  END LOOP;
END;
$$;
```

- [ ] **Step 2: Apply via Supabase MCP**

Use `mcp__claude_ai_Supabase__apply_migration` with:
- `project_id`: `njzqcftjzskwcpforwzf`
- `name`: `ingredient_rounding_write_points`
- `query`: (full SQL above)

- [ ] **Step 3: Smoke-test rounding in a dry-run plan**

```sql
BEGIN;
SET LOCAL request.jwt.claim.sub = 'f068c92c-b9ea-496d-af52-94f40c8fab26';
SELECT ingredient_name, quantity, unit
FROM generate_meal_plan(
  'f068c92c-b9ea-496d-af52-94f40c8fab26', 3, 3, '2026-06-20'::date, 2
)
-- join to meal_ingredient via the plan just created:
-- (the function returns entry_id; SELECT from meal_ingredient where entry in those)
;
ROLLBACK;
```

Run instead:
```sql
BEGIN;
SET LOCAL request.jwt.claim.sub = 'f068c92c-b9ea-496d-af52-94f40c8fab26';

SELECT mi.ingredient_name, mi.quantity, mi.unit
FROM generate_meal_plan(
  'f068c92c-b9ea-496d-af52-94f40c8fab26', 3, 3, '2026-06-20'::date, 2
) p
JOIN meal_ingredient mi ON mi.meal_plan_entry_id = p.entry_id
ORDER BY mi.unit, mi.ingredient_name
LIMIT 30;

ROLLBACK;
```

Expected: no `quantity` values with more than 1 decimal place for `g`/`ml`, no fractional values > 0 but < step for `unit` ingredients.

- [ ] **Step 4: Commit migration file**

```powershell
git add supabase/migrations/20260603000004_ingredient_rounding_write_points.sql
git commit -m "feat(db): apply round_to_step in generate_meal_plan, swap_meal_plan_entry, create_batch_sessions"
```

---

## Task 3: Flutter — `quantity_formatter.dart` + tests

**Files:**
- Create: `lib/core/quantity_formatter.dart`
- Create: `test/core/quantity_formatter_test.dart`

- [ ] **Step 1: Write the failing tests**

```dart
// test/core/quantity_formatter_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/core/quantity_formatter.dart';

void main() {
  group('formatQuantity — weight/volume (non-countable)', () {
    test('whole grams shows as integer', () {
      expect(formatQuantity(235, 'g'), '235g');
    });
    test('whole ml shows as integer', () {
      expect(formatQuantity(250, 'ml'), '250ml');
    });
    test('decimal litre shows 1dp', () {
      expect(formatQuantity(0.2, 'l'), '0.2l');
    });
    test('decimal kg shows 1dp', () {
      expect(formatQuantity(0.1, 'kg'), '0.1kg');
    });
  });

  group('formatQuantity — countable units (fractions)', () {
    test('0.5 unit shows as 1/2', () {
      expect(formatQuantity(0.5, 'unit'), '1/2');
    });
    test('1.5 unit shows as 1 1/2', () {
      expect(formatQuantity(1.5, 'unit'), '1 1/2');
    });
    test('1.0 unit shows as integer', () {
      expect(formatQuantity(1.0, 'unit'), '1');
    });
    test('2.0 unit shows as integer', () {
      expect(formatQuantity(2.0, 'unit'), '2');
    });
    test('0.25 tsp shows as 1/4', () {
      expect(formatQuantity(0.25, 'tsp'), '1/4 tsp');
    });
    test('0.75 tsp shows as 3/4', () {
      expect(formatQuantity(0.75, 'tsp'), '3/4 tsp');
    });
    test('0.5 tbsp shows as 1/2 tbsp', () {
      expect(formatQuantity(0.5, 'tbsp'), '1/2 tbsp');
    });
    test('1.25 tsp shows as 1 1/4 tsp', () {
      expect(formatQuantity(1.25, 'tsp'), '1 1/4 tsp');
    });
    test('whole clove shows as integer', () {
      expect(formatQuantity(2.0, 'clove'), '2 clove');
    });
    test('0.5 pinch shows as 1/2 pinch', () {
      expect(formatQuantity(0.5, 'pinch'), '1/2 pinch');
    });
  });

  group('formatQuantity — unit suffix omission', () {
    test('unit suffix hidden for plain unit', () {
      // "unit" as unit label is omitted from display (just show the number)
      expect(formatQuantity(1.0, 'unit'), '1');
      expect(formatQuantity(0.5, 'unit'), '1/2');
    });
    test('tsp suffix shown', () {
      expect(formatQuantity(0.5, 'tsp'), '1/2 tsp');
    });
  });
}
```

- [ ] **Step 2: Run tests to confirm they fail**

```powershell
cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
flutter test test/core/quantity_formatter_test.dart
```

Expected: `FAIL` — `quantity_formatter.dart` does not exist yet.

- [ ] **Step 3: Create `lib/core/quantity_formatter.dart`**

```dart
// lib/core/quantity_formatter.dart
import 'package:collection/collection.dart';

// Units where fractional display (1/2, 1/4 etc.) is appropriate.
const _countableUnits = {
  'unit', 'piece', 'clove', 'bunch', 'can', 'pot', 'tsp', 'tbsp', 'pinch',
};

// Units whose label is omitted when displaying (e.g. "1/2" not "1/2 unit").
const _silentUnits = {'unit', 'piece'};

// Decimal → fraction string mapping. Tolerance: ±0.01.
const _fractionMap = <double, String>{
  0.25: '1/4',
  0.333: '1/3',
  0.5: '1/2',
  0.667: '2/3',
  0.75: '3/4',
};

/// Format a scaled ingredient quantity for display.
///
/// Non-countable units (g, ml, kg, l): plain decimal, no fraction.
/// Countable units (unit, tsp, etc.): renders decimal part as fraction.
/// The unit suffix is appended unless the unit is in [_silentUnits].
String formatQuantity(double qty, String unit) {
  final suffix = _silentUnits.contains(unit) ? '' : ' $unit';

  if (!_countableUnits.contains(unit)) {
    // Weight / volume — strip trailing decimal zeros.
    if (qty % 1 == 0) return '${qty.toInt()}$unit';
    return '${qty.toStringAsFixed(1)}$unit';
  }

  final whole = qty.floor();
  final decimal = qty - whole;

  if (decimal < 0.01) return '$whole$suffix'.trim();

  final entry = _fractionMap.entries.firstWhereOrNull(
    (e) => (e.key - decimal).abs() < 0.01,
  );
  final fractionStr = entry?.value ?? qty.toStringAsFixed(2);

  if (whole == 0) return '$fractionStr$suffix'.trim();
  return '$whole $fractionStr$suffix'.trim();
}
```

- [ ] **Step 4: Run tests again — all must pass**

```powershell
flutter test test/core/quantity_formatter_test.dart
```

Expected: all tests PASS.

- [ ] **Step 5: Commit**

```powershell
git add lib/core/quantity_formatter.dart test/core/quantity_formatter_test.dart
git commit -m "feat(flutter): add formatQuantity helper with fraction display for countable units"
```

---

## Task 4: Flutter — wire `formatQuantity` into all display sites

**Files:**
- Modify: `lib/shared/models/meal_plan.dart:381-382` (ShoppingItem.quantityDisplay)
- Modify: `lib/shared/models/meal_plan.dart:437-438` (MealIngredient.quantityDisplay)
- Modify: `lib/shared/widgets/shopping_row.dart:19-20`
- Modify: `lib/features/meal_planner/batch_cooking_page.dart:260`

### Background

Three display sites currently use inline `toStringAsFixed`:
1. `ShoppingItem.quantityDisplay` getter — `lib/shared/models/meal_plan.dart:382`
2. `MealIngredient.quantityDisplay` getter — `lib/shared/models/meal_plan.dart:438`
3. `shopping_row.dart:20` — duplicates the logic inline (ignores the getter)
4. `batch_cooking_page.dart:260` — `ing.quantityNeeded.toStringAsFixed(1)`

`meal_detail_page.dart:380` already uses `ing.quantityDisplay` — updating the getter is sufficient.

`CookingSessionIngredient` has no `quantityDisplay` getter yet — add one.

- [ ] **Step 1: Add import to `meal_plan.dart`**

At the top of `lib/shared/models/meal_plan.dart`, add:
```dart
import '../../../core/quantity_formatter.dart';
```

(The file is at `lib/shared/models/meal_plan.dart`, so the relative import path is `'../../core/quantity_formatter.dart'`.)

- [ ] **Step 2: Update `ShoppingItem.quantityDisplay` getter**

Find (line ~382):
```dart
  String get quantityDisplay =>
      '${quantity.toStringAsFixed(quantity % 1 == 0 ? 0 : 1)} $unit';
```

Replace with:
```dart
  String get quantityDisplay => formatQuantity(quantity, unit);
```

- [ ] **Step 3: Update `MealIngredient.quantityDisplay` getter**

Find (line ~438):
```dart
  String get quantityDisplay =>
      '${quantity.toStringAsFixed(quantity % 1 == 0 ? 0 : 1)} $unit';
```

Replace with:
```dart
  String get quantityDisplay => formatQuantity(quantity, unit);
```

- [ ] **Step 4: Add `quantityDisplay` getter to `CookingSessionIngredient`**

Find the `CookingSessionIngredient` class closing `}` (around line 293). Add the getter before it:
```dart
  String get quantityDisplay => formatQuantity(quantityNeeded, unit);
```

- [ ] **Step 5: Update `shopping_row.dart`**

Add import at top of `lib/shared/widgets/shopping_row.dart`:
```dart
import 'package:akeli/core/quantity_formatter.dart';
```

Find (line ~19-20):
```dart
    final qtyText =
        '${item.quantity.toStringAsFixed(item.quantity % 1 == 0 ? 0 : 1)} ${item.unit}';
```

Replace with:
```dart
    final qtyText = formatQuantity(item.quantity, item.unit);
```

- [ ] **Step 6: Update `batch_cooking_page.dart`**

Add import at top of `lib/features/meal_planner/batch_cooking_page.dart`:
```dart
import 'package:akeli/core/quantity_formatter.dart';
```

Find (line ~260):
```dart
                      '• ${ing.ingredientName} — ${ing.quantityNeeded.toStringAsFixed(1)} ${ing.unit}',
```

Replace with:
```dart
                      '• ${ing.ingredientName} — ${ing.quantityDisplay}',
```

- [ ] **Step 7: Run full test suite**

```powershell
cd "c:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
flutter test
```

Expected: all tests pass (56+ passing).

- [ ] **Step 8: Run `dart analyze`**

```powershell
dart analyze lib/
```

Expected: no errors.

- [ ] **Step 9: Commit**

```powershell
git add lib/shared/models/meal_plan.dart lib/shared/widgets/shopping_row.dart lib/features/meal_planner/batch_cooking_page.dart
git commit -m "feat(flutter): wire formatQuantity into all ingredient display sites"
```

---

## Self-Review

**Spec coverage:**
- ✅ `unit_rounding_config` table + 13 unit seed rows — Task 1
- ✅ `ingredient_rounding_rule` table — Task 1
- ✅ `round_to_step` function with GREATEST minimum — Task 1
- ✅ Lookup: ingredient override → unit default → NULL (no rounding) — Task 2
- ✅ `generate_meal_plan` write point — Task 2
- ✅ `swap_meal_plan_entry` write point — Task 2
- ✅ `create_batch_sessions` write point — Task 2
- ✅ `formatQuantity` Flutter helper — Task 3
- ✅ Fraction map: 1/4, 1/3, 1/2, 2/3, 3/4 — Task 3
- ✅ Silent units (`unit`, `piece`) suppress suffix — Task 3
- ✅ `ShoppingItem.quantityDisplay` updated — Task 4
- ✅ `MealIngredient.quantityDisplay` updated — Task 4
- ✅ `CookingSessionIngredient.quantityDisplay` added — Task 4
- ✅ `shopping_row.dart` updated — Task 4
- ✅ `batch_cooking_page.dart` updated — Task 4
- ✅ `recipe_ingredient` untouched — not in any task ✓
- ✅ `meal_plan_entry.servings` untouched — not in any task ✓

**Type consistency:**
- `formatQuantity(double qty, String unit) → String` — used consistently across Tasks 3 and 4
- `round_to_step(qty numeric, step numeric) → numeric` — used consistently across Task 2
- `CookingSessionIngredient.quantityDisplay` uses `quantityNeeded` (Double) and `unit` (String) — both exist on the model ✓
