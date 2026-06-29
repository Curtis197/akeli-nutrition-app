# Meal Plan 15-Day Variety Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Prevent meal plan generators from reusing recipes that appeared in the user's plans during the past 15 days, with a silent fallback when the recipe pool is exhausted.

**Architecture:** Add `v_recent_recipe_ids uuid[]` to each generator function, pre-loaded once from cross-plan history before the day loop. Each slot selection becomes a two-pass query: Pass 1 excludes blacklisted recipes; Pass 2 (fallback) runs without the exclusion only if Pass 1 returns NULL.

**Tech Stack:** PostgreSQL 15, pgTAP 1.x, Supabase CLI.

## Global Constraints

- Blacklist window: `p_start_date - 15` (relative to new plan start date, not `CURRENT_DATE`)
- `v_used_recipe_ids` (within-run dedup via `p_max_recipe_repeat`) applies in **both** passes
- Scoring weights, calorie math, ingredient inserts, SECURITY DEFINER, REVOKE grants — all unchanged
- `generate_meal_plan_from_saved` retains its `ORDER BY score DESC, random()` tiebreaker in both passes
- `generate_meal_plan_internal` uses `rm.calories` (not `rm.kcal_per_100g`) — keep its existing column names

---

### Task 1: Write failing pgTAP test

**Files:**
- Create: `supabase/tests/database/generate_meal_plan_variety.test.sql`

**Interfaces:**
- Produces: 3 pgTAP assertions — `plan(3)`. Tests 2 and 3 pass immediately; Test 1 fails until Task 2 is applied (no blacklist yet → week 2 reuses week 1 recipes).

- [ ] **Step 1: Create the test file**

```sql
-- supabase/tests/database/generate_meal_plan_variety.test.sql
-- Tests: 15-day blacklist prevents recipe repetition across weekly plans.

BEGIN;

SELECT plan(3);

-- ─── Seed ──────────────────────────────────────────────────────────────────

INSERT INTO public.measurement_unit (code, name_fr, name_en)
VALUES ('g', 'g', 'g') ON CONFLICT (code) DO NOTHING;

INSERT INTO public.ingredient (id, name, name_fr)
VALUES ('00000000-0000-0000-0000-000000000099'::uuid,
        'Variety Ingredient', 'Ingrédient Variété')
ON CONFLICT (id) DO NOTHING;

-- Test user
INSERT INTO auth.users (id, email, role, created_at, updated_at)
VALUES ('eeeeffff-0000-4000-8000-000000000099'::uuid,
        'variety@test.local', 'authenticated', now(), now())
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.user_profile (id, first_name)
VALUES ('eeeeffff-0000-4000-8000-000000000099'::uuid, 'Variety')
ON CONFLICT (id) DO NOTHING;

-- 6 recipes: 2 per meal type.
-- A recipes get one like → score higher → deterministically picked in week 1.
-- B recipes have no likes → picked only when A is blacklisted (week 2).
INSERT INTO public.recipe (id, title, is_published, meal_types, preferred_meal_type, allergen_tags)
VALUES
  ('cccc0001-0000-4000-8000-000000000099'::uuid, 'Variety Breakfast A', true,
   ARRAY['breakfast'], 'breakfast', ARRAY[]::text[]),
  ('cccc0002-0000-4000-8000-000000000099'::uuid, 'Variety Breakfast B', true,
   ARRAY['breakfast'], 'breakfast', ARRAY[]::text[]),
  ('cccc0003-0000-4000-8000-000000000099'::uuid, 'Variety Lunch A', true,
   ARRAY['lunch'], 'lunch', ARRAY[]::text[]),
  ('cccc0004-0000-4000-8000-000000000099'::uuid, 'Variety Lunch B', true,
   ARRAY['lunch'], 'lunch', ARRAY[]::text[]),
  ('cccc0005-0000-4000-8000-000000000099'::uuid, 'Variety Dinner A', true,
   ARRAY['dinner'], 'dinner', ARRAY[]::text[]),
  ('cccc0006-0000-4000-8000-000000000099'::uuid, 'Variety Dinner B', true,
   ARRAY['dinner'], 'dinner', ARRAY[]::text[]);

-- total_weight_g required so GENERATED kcal_per_100g > 0
INSERT INTO public.recipe_macro (recipe_id, calories, protein_g, carbs_g, fat_g, total_weight_g)
VALUES
  ('cccc0001-0000-4000-8000-000000000099'::uuid, 400, 20, 50, 10, 300),
  ('cccc0002-0000-4000-8000-000000000099'::uuid, 400, 20, 50, 10, 300),
  ('cccc0003-0000-4000-8000-000000000099'::uuid, 600, 30, 70, 15, 400),
  ('cccc0004-0000-4000-8000-000000000099'::uuid, 600, 30, 70, 15, 400),
  ('cccc0005-0000-4000-8000-000000000099'::uuid, 700, 35, 80, 20, 450),
  ('cccc0006-0000-4000-8000-000000000099'::uuid, 700, 35, 80, 20, 450);

INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, quantity, unit, is_optional)
VALUES
  ('cccc0001-0000-4000-8000-000000000099'::uuid,
   '00000000-0000-0000-0000-000000000099'::uuid, 100, 'g', false),
  ('cccc0002-0000-4000-8000-000000000099'::uuid,
   '00000000-0000-0000-0000-000000000099'::uuid, 100, 'g', false),
  ('cccc0003-0000-4000-8000-000000000099'::uuid,
   '00000000-0000-0000-0000-000000000099'::uuid, 150, 'g', false),
  ('cccc0004-0000-4000-8000-000000000099'::uuid,
   '00000000-0000-0000-0000-000000000099'::uuid, 150, 'g', false),
  ('cccc0005-0000-4000-8000-000000000099'::uuid,
   '00000000-0000-0000-0000-000000000099'::uuid, 200, 'g', false),
  ('cccc0006-0000-4000-8000-000000000099'::uuid,
   '00000000-0000-0000-0000-000000000099'::uuid, 200, 'g', false);

-- Likes on A recipes to break score ties deterministically
INSERT INTO public.recipe_like (recipe_id, user_id)
VALUES
  ('cccc0001-0000-4000-8000-000000000099'::uuid,
   'eeeeffff-0000-4000-8000-000000000099'::uuid),
  ('cccc0003-0000-4000-8000-000000000099'::uuid,
   'eeeeffff-0000-4000-8000-000000000099'::uuid),
  ('cccc0005-0000-4000-8000-000000000099'::uuid,
   'eeeeffff-0000-4000-8000-000000000099'::uuid);

-- ─── Test 1: 15-day blacklist — week 2 uses different recipes than week 1 ──

SET LOCAL request.jwt.claims =
  '{"sub":"eeeeffff-0000-4000-8000-000000000099"}';

-- Week 1 (1-day plan at far future offset to avoid collision with other tests)
PERFORM public.generate_meal_plan(
  'eeeeffff-0000-4000-8000-000000000099'::uuid,
  1, 3, (CURRENT_DATE + 200)::date, 3
);

CREATE TEMP TABLE t_variety_w1 AS
SELECT DISTINCT mpec.recipe_id
FROM public.meal_plan mp
JOIN public.meal_plan_entry mpe
  ON mpe.meal_plan_id = mp.id
JOIN public.meal_plan_entry_component mpec
  ON mpec.meal_plan_entry_id = mpe.id
WHERE mp.user_id         = 'eeeeffff-0000-4000-8000-000000000099'::uuid
  AND mpe.scheduled_date = (CURRENT_DATE + 200)::date
  AND mpec.role          = 'base';

-- Week 2 (1-day plan, 8 days later — within the 15-day window)
PERFORM public.generate_meal_plan(
  'eeeeffff-0000-4000-8000-000000000099'::uuid,
  1, 3, (CURRENT_DATE + 208)::date, 3
);

SELECT ok(
  NOT EXISTS (
    SELECT 1
    FROM public.meal_plan mp
    JOIN public.meal_plan_entry mpe
      ON mpe.meal_plan_id = mp.id
    JOIN public.meal_plan_entry_component mpec
      ON mpec.meal_plan_entry_id = mpe.id
    WHERE mp.user_id         = 'eeeeffff-0000-4000-8000-000000000099'::uuid
      AND mpe.scheduled_date = (CURRENT_DATE + 208)::date
      AND mpec.role          = 'base'
      AND mpec.recipe_id IN (SELECT recipe_id FROM t_variety_w1)
  ),
  '15-day blacklist: plan at day+208 shares no recipe with plan at day+200'
);

-- ─── Tests 2 & 3: fallback — two plans within 15 days must not crash ───────
-- Uses generate_meal_plan_internal (no auth guard) to avoid JWT setup inside
-- the lives_ok string.

SELECT lives_ok(
  $$ SELECT public.generate_meal_plan_internal(
       'eeeeffff-0000-4000-8000-000000000099'::uuid,
       1, 3, (CURRENT_DATE + 300)::date
     ) $$,
  'First plan at day+300 generates without error'
);

SELECT lives_ok(
  $$ SELECT public.generate_meal_plan_internal(
       'eeeeffff-0000-4000-8000-000000000099'::uuid,
       1, 3, (CURRENT_DATE + 305)::date
     ) $$,
  'Second plan within 15-day window (day+305) generates without error — fallback if pool exhausted'
);

SELECT * FROM finish();

ROLLBACK;
```

- [ ] **Step 2: Run tests — confirm Test 1 fails**

```powershell
cd "C:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
supabase test db
```

Expected (before migration):
```
not ok 1 - 15-day blacklist: plan at day+208 shares no recipe with plan at day+200
ok 2 - First plan at day+300 generates without error
ok 3 - Second plan within 15-day window (day+305) generates without error ...
Files=4, Tests=30,  X wallclock secs
Result: FAIL
```

- [ ] **Step 3: Commit**

```bash
git add supabase/tests/database/generate_meal_plan_variety.test.sql
git commit -m "test(meal-plan): add pgTAP variety tests for 15-day recipe blacklist"
```

---

### Task 2: Migration — add 15-day blacklist to all three generators

**Files:**
- Create: `supabase/migrations/20260629000001_generate_meal_plan_15day_variety.sql`

**Interfaces:**
- Consumes: `meal_plan_entry_component.role = 'base'`, `meal_plan.user_id`, `meal_plan_entry.scheduled_date`
- Produces: `generate_meal_plan`, `generate_meal_plan_from_saved`, `generate_meal_plan_internal` — all with two-pass selection and 15-day blacklist

- [ ] **Step 1: Create the migration file**

Create `supabase/migrations/20260629000001_generate_meal_plan_15day_variety.sql`:

```sql
-- supabase/migrations/20260629000001_generate_meal_plan_15day_variety.sql
-- Description: Add 15-day cross-plan recipe blacklist to all three meal plan
-- generators. Each slot tries to exclude recipes used in the past 15 days
-- (relative to p_start_date). Falls back silently to the best available
-- recipe when the blacklisted pool exhausts the slot's candidates.

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. generate_meal_plan  (user-facing RPC)
-- ─────────────────────────────────────────────────────────────────────────────

DROP FUNCTION IF EXISTS generate_meal_plan(uuid, integer, integer, date, integer);

CREATE OR REPLACE FUNCTION generate_meal_plan(
  p_user_id            uuid,
  p_days               integer,
  p_meals_per_day      integer,
  p_start_date         date,
  p_max_recipe_repeat  integer DEFAULT 3
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
  score           double precision
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_user_vector            vector(50);
  v_fan_creator_id         uuid;
  v_plan_id                uuid;
  v_existing_plan_id       uuid;
  v_slots                  JSONB[];
  v_slot_rec               JSONB;
  v_slot_nickname          text;
  v_slot_sort_order        integer;
  v_day                    int;
  v_meal_type              text;
  v_current_date           date;
  v_recipe                 record;
  v_entry_id               uuid;
  v_component_id           uuid;
  v_used_recipe_ids        uuid[] := ARRAY[]::uuid[];
  v_recent_recipe_ids      uuid[] := ARRAY[]::uuid[];
  v_user_allergens         text[];
  v_calorie_goal           numeric;
  v_protein_goal           numeric;
  v_fat_goal               numeric;
  v_target_meal_cal        numeric;
  v_target_protein_density numeric;
  v_target_fat_density     numeric;
  v_grams                  integer;
  v_fan_count              int := 0;
  v_other_count            int := 0;
  v_total_slots            int;
  v_max_other_slots        int;
BEGIN
  IF p_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  SELECT array_agg(
    jsonb_build_object(
      'meal_type',      md.meal_type,
      'calorie_target', COALESCE(md.calorie_target, 0),
      'protein_pct',    COALESCE(md.protein_pct, 25.0),
      'fat_pct',        COALESCE(md.fat_pct, 25.0),
      'nickname',       md.nickname,
      'sort_order',     md.sort_order
    ) ORDER BY md.sort_order
  ) INTO v_slots
  FROM meal_distribution md
  JOIN nutrition_plan np ON np.id = md.nutrition_plan_id
  WHERE np.user_id = p_user_id AND np.is_active = true;

  IF v_slots IS NULL THEN
    v_slots := ARRAY[
      jsonb_build_object('meal_type','breakfast','calorie_target',0,'protein_pct',25.0,'fat_pct',25.0,'nickname',NULL,'sort_order',0),
      jsonb_build_object('meal_type','lunch',    'calorie_target',0,'protein_pct',25.0,'fat_pct',25.0,'nickname',NULL,'sort_order',1),
      jsonb_build_object('meal_type','dinner',   'calorie_target',0,'protein_pct',25.0,'fat_pct',25.0,'nickname',NULL,'sort_order',2)
    ];
  END IF;

  v_total_slots     := p_days * array_length(v_slots, 1);
  v_max_other_slots := FLOOR(v_total_slots * 0.10);

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

  SELECT id INTO v_existing_plan_id
  FROM public.meal_plan
  WHERE user_id    =  p_user_id
    AND start_date <= (p_start_date + (p_days - 1))
    AND end_date   >=  p_start_date
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_existing_plan_id IS NOT NULL THEN
    DELETE FROM meal_plan_entry AS e
    WHERE e.meal_plan_id    = v_existing_plan_id
      AND e.scheduled_date >= CURRENT_DATE;

    UPDATE public.meal_plan
    SET end_date = GREATEST(end_date, p_start_date + (p_days - 1))
    WHERE id = v_existing_plan_id;

    v_plan_id := v_existing_plan_id;
  ELSE
    INSERT INTO meal_plan (user_id, start_date, end_date, is_active)
    VALUES (p_user_id, p_start_date, p_start_date + (p_days - 1), true)
    RETURNING id INTO v_plan_id;
  END IF;

  SELECT COALESCE(array_agg(mpec.recipe_id), ARRAY[]::uuid[])
  INTO v_used_recipe_ids
  FROM meal_plan_entry mpe
  JOIN meal_plan_entry_component mpec ON mpec.meal_plan_entry_id = mpe.id
  WHERE mpe.meal_plan_id   = v_plan_id
    AND mpe.scheduled_date < CURRENT_DATE
    AND mpec.role = 'base';

  SELECT COALESCE(array_agg(DISTINCT mpec.recipe_id), ARRAY[]::uuid[])
  INTO v_recent_recipe_ids
  FROM meal_plan_entry mpe
  JOIN meal_plan_entry_component mpec ON mpec.meal_plan_entry_id = mpe.id
  JOIN meal_plan mp ON mp.id = mpe.meal_plan_id
  WHERE mp.user_id         = p_user_id
    AND mpe.scheduled_date >= (p_start_date - 15)
    AND mpe.scheduled_date <   p_start_date
    AND mpec.role          = 'base';

  FOR v_day IN 0..(p_days - 1) LOOP
    v_current_date := p_start_date + v_day;

    IF v_current_date < CURRENT_DATE THEN
      CONTINUE;
    END IF;

    FOREACH v_slot_rec IN ARRAY v_slots LOOP
      v_meal_type       := v_slot_rec->>'meal_type';
      v_slot_nickname   := v_slot_rec->>'nickname';
      v_slot_sort_order := (v_slot_rec->>'sort_order')::integer;

      v_target_meal_cal := (v_slot_rec->>'calorie_target')::numeric;
      IF (v_target_meal_cal IS NULL OR v_target_meal_cal = 0)
         AND v_calorie_goal IS NOT NULL AND v_calorie_goal > 0 THEN
        v_target_meal_cal := v_calorie_goal / array_length(v_slots, 1);
      END IF;

      IF v_calorie_goal IS NOT NULL AND v_calorie_goal > 0 THEN
        v_target_protein_density := (v_slot_rec->>'protein_pct')::numeric;
        v_target_fat_density     := (v_slot_rec->>'fat_pct')::numeric;
      ELSE
        v_target_protein_density := 7.5;
        v_target_fat_density     := 3.3;
      END IF;

      -- Pass 1: with 15-day blacklist
      IF v_user_vector IS NOT NULL THEN
        SELECT r.id, r.title, r.cover_image_url,
               rm.kcal_per_100g, rm.protein_per_100g, rm.carbs_per_100g, rm.fat_per_100g,
               rm.total_weight_g, r.creator_id,
               (
                 0.50 * (1 - (rv.vector <=> v_user_vector))
                        * CASE WHEN v_fan_creator_id IS NOT NULL
                                    AND r.creator_id = v_fan_creator_id
                               THEN 1.5 ELSE 1.0 END
                 + 0.25 * GREATEST(0.0, 1.0 - LEAST(
                     ABS(rm.protein_g / NULLIF(rm.calories, 0) * 100
                         - v_target_protein_density)
                     / NULLIF(v_target_protein_density, 0.001), 1.0))
                 + 0.15 * CASE
                     WHEN r.preferred_meal_type = v_meal_type THEN 1.0
                     WHEN r.preferred_meal_type = 'any'       THEN 0.5
                     ELSE 0.0
                   END
                 + 0.10 * GREATEST(0.0, 1.0 - LEAST(
                     ABS(rm.fat_g / NULLIF(rm.calories, 0) * 100
                         - v_target_fat_density)
                     / NULLIF(v_target_fat_density, 0.001), 1.0))
               ) AS score
        INTO v_recipe
        FROM recipe r
        JOIN recipe_vector rv ON r.id = rv.recipe_id
        JOIN recipe_macro rm ON r.id = rm.recipe_id
        WHERE r.is_published = true
          AND v_meal_type = ANY(r.meal_types)
          AND rm.kcal_per_100g > 0
          AND (SELECT count(*) FROM unnest(v_used_recipe_ids) x WHERE x = r.id) < p_max_recipe_repeat
          AND r.id != ALL(v_recent_recipe_ids)
          AND (v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR r.creator_id = v_fan_creator_id)
          AND (v_target_meal_cal IS NULL OR v_target_meal_cal / (rm.kcal_per_100g / 100) <= 1500)
          AND NOT (r.allergen_tags && v_user_allergens)
        ORDER BY score DESC
        LIMIT 1;
      ELSE
        SELECT r.id, r.title, r.cover_image_url,
               rm.kcal_per_100g, rm.protein_per_100g, rm.carbs_per_100g, rm.fat_per_100g,
               rm.total_weight_g, r.creator_id,
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
          AND rm.kcal_per_100g > 0
          AND (SELECT count(*) FROM unnest(v_used_recipe_ids) x WHERE x = r.id) < p_max_recipe_repeat
          AND r.id != ALL(v_recent_recipe_ids)
          AND (v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR r.creator_id = v_fan_creator_id)
          AND (v_target_meal_cal IS NULL OR v_target_meal_cal / (rm.kcal_per_100g / 100) <= 1500)
          AND NOT (r.allergen_tags && v_user_allergens)
        GROUP BY r.id, r.title, r.cover_image_url, r.creator_id, r.preferred_meal_type,
                 rm.kcal_per_100g, rm.protein_per_100g, rm.carbs_per_100g, rm.fat_per_100g,
                 rm.total_weight_g
        ORDER BY score DESC, COUNT(rl.recipe_id) DESC
        LIMIT 1;
      END IF;

      -- Pass 2: fallback — retry without blacklist if pool exhausted
      IF v_recipe.id IS NULL AND array_length(v_recent_recipe_ids, 1) IS NOT NULL THEN
        IF v_user_vector IS NOT NULL THEN
          SELECT r.id, r.title, r.cover_image_url,
                 rm.kcal_per_100g, rm.protein_per_100g, rm.carbs_per_100g, rm.fat_per_100g,
                 rm.total_weight_g, r.creator_id,
                 (
                   0.50 * (1 - (rv.vector <=> v_user_vector))
                          * CASE WHEN v_fan_creator_id IS NOT NULL
                                      AND r.creator_id = v_fan_creator_id
                                 THEN 1.5 ELSE 1.0 END
                   + 0.25 * GREATEST(0.0, 1.0 - LEAST(
                       ABS(rm.protein_g / NULLIF(rm.calories, 0) * 100
                           - v_target_protein_density)
                       / NULLIF(v_target_protein_density, 0.001), 1.0))
                   + 0.15 * CASE
                       WHEN r.preferred_meal_type = v_meal_type THEN 1.0
                       WHEN r.preferred_meal_type = 'any'       THEN 0.5
                       ELSE 0.0
                     END
                   + 0.10 * GREATEST(0.0, 1.0 - LEAST(
                       ABS(rm.fat_g / NULLIF(rm.calories, 0) * 100
                           - v_target_fat_density)
                       / NULLIF(v_target_fat_density, 0.001), 1.0))
                 ) AS score
          INTO v_recipe
          FROM recipe r
          JOIN recipe_vector rv ON r.id = rv.recipe_id
          JOIN recipe_macro rm ON r.id = rm.recipe_id
          WHERE r.is_published = true
            AND v_meal_type = ANY(r.meal_types)
            AND rm.kcal_per_100g > 0
            AND (SELECT count(*) FROM unnest(v_used_recipe_ids) x WHERE x = r.id) < p_max_recipe_repeat
            AND (v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR r.creator_id = v_fan_creator_id)
            AND (v_target_meal_cal IS NULL OR v_target_meal_cal / (rm.kcal_per_100g / 100) <= 1500)
            AND NOT (r.allergen_tags && v_user_allergens)
          ORDER BY score DESC
          LIMIT 1;
        ELSE
          SELECT r.id, r.title, r.cover_image_url,
                 rm.kcal_per_100g, rm.protein_per_100g, rm.carbs_per_100g, rm.fat_per_100g,
                 rm.total_weight_g, r.creator_id,
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
            AND rm.kcal_per_100g > 0
            AND (SELECT count(*) FROM unnest(v_used_recipe_ids) x WHERE x = r.id) < p_max_recipe_repeat
            AND (v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR r.creator_id = v_fan_creator_id)
            AND (v_target_meal_cal IS NULL OR v_target_meal_cal / (rm.kcal_per_100g / 100) <= 1500)
            AND NOT (r.allergen_tags && v_user_allergens)
          GROUP BY r.id, r.title, r.cover_image_url, r.creator_id, r.preferred_meal_type,
                   rm.kcal_per_100g, rm.protein_per_100g, rm.carbs_per_100g, rm.fat_per_100g,
                   rm.total_weight_g
          ORDER BY score DESC, COUNT(rl.recipe_id) DESC
          LIMIT 1;
        END IF;
      END IF;

      IF v_recipe.id IS NULL THEN
        RAISE EXCEPTION 'insufficient_recipes' USING DETAIL = v_meal_type;
      END IF;

      IF v_target_meal_cal IS NOT NULL AND v_recipe.kcal_per_100g > 0 THEN
        v_grams := GREATEST(50, LEAST(1500,
          ROUND(v_target_meal_cal / (v_recipe.kcal_per_100g / 100))::integer));
      ELSE
        v_grams := 300;
      END IF;

      INSERT INTO meal_plan_entry (
        meal_plan_id, scheduled_date, meal_type, servings,
        calories_computed, protein_g_computed, carbs_g_computed, fat_g_computed,
        nickname, sort_order
      )
      VALUES (
        v_plan_id, v_current_date, v_meal_type, v_grams,
        ROUND((v_recipe.kcal_per_100g    * v_grams / 100)::numeric, 1),
        ROUND((v_recipe.protein_per_100g * v_grams / 100)::numeric, 1),
        ROUND((v_recipe.carbs_per_100g   * v_grams / 100)::numeric, 1),
        ROUND((v_recipe.fat_per_100g     * v_grams / 100)::numeric, 1),
        v_slot_nickname,
        v_slot_sort_order
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
        round_to_step(
          ri.quantity * v_grams / NULLIF(v_recipe.total_weight_g, 0),
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
        ROUND((v_recipe.kcal_per_100g    * v_grams / 100)::numeric, 1),
        ROUND((v_recipe.protein_per_100g * v_grams / 100)::numeric, 1),
        NULL::double precision;

    END LOOP;
  END LOOP;
END;
$$;


-- ─────────────────────────────────────────────────────────────────────────────
-- 2. generate_meal_plan_from_saved  (batch/service_role)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.generate_meal_plan_from_saved(
  p_user_id            uuid,
  p_days               integer,
  p_meals_per_day      integer,
  p_start_date         date,
  p_max_recipe_repeat  integer DEFAULT 3
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
  score           double precision
)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_fan_creator_id         uuid;
  v_plan_id                uuid;
  v_existing_plan_id       uuid;
  v_slots                  JSONB[];
  v_slot_rec               JSONB;
  v_slot_nickname          text;
  v_slot_sort_order        integer;
  v_day                    int;
  v_meal_type              text;
  v_current_date           date;
  v_recipe                 record;
  v_entry_id               uuid;
  v_component_id           uuid;
  v_used_recipe_ids        uuid[] := ARRAY[]::uuid[];
  v_recent_recipe_ids      uuid[] := ARRAY[]::uuid[];
  v_user_allergens         text[];
  v_calorie_goal           numeric;
  v_target_meal_cal        numeric;
  v_grams                  integer;
  v_fan_count              int := 0;
  v_other_count            int := 0;
  v_total_slots            int;
  v_max_other_slots        int;
BEGIN
  SELECT array_agg(
    jsonb_build_object(
      'meal_type',      md.meal_type,
      'calorie_target', COALESCE(md.calorie_target, 0),
      'protein_pct',    COALESCE(md.protein_pct, 25.0),
      'fat_pct',        COALESCE(md.fat_pct, 25.0),
      'nickname',       md.nickname,
      'sort_order',     md.sort_order
    ) ORDER BY md.sort_order
  ) INTO v_slots
  FROM meal_distribution md
  JOIN nutrition_plan np ON np.id = md.nutrition_plan_id
  WHERE np.user_id = p_user_id AND np.is_active = true;

  IF v_slots IS NULL THEN
    v_slots := ARRAY[
      jsonb_build_object('meal_type','breakfast','calorie_target',0,'protein_pct',25.0,'fat_pct',25.0,'nickname',NULL,'sort_order',0),
      jsonb_build_object('meal_type','lunch',    'calorie_target',0,'protein_pct',25.0,'fat_pct',25.0,'nickname',NULL,'sort_order',1),
      jsonb_build_object('meal_type','dinner',   'calorie_target',0,'protein_pct',25.0,'fat_pct',25.0,'nickname',NULL,'sort_order',2)
    ];
  END IF;

  v_total_slots     := p_days * array_length(v_slots, 1);
  v_max_other_slots := FLOOR(v_total_slots * 0.10);

  SELECT fs.creator_id INTO v_fan_creator_id
  FROM fan_subscription fs
  WHERE fs.user_id = p_user_id AND fs.status = 'active'
  LIMIT 1;

  SELECT COALESCE(array_agg(a.slug), ARRAY[]::text[]) INTO v_user_allergens
  FROM user_allergy ua
  JOIN allergen a ON a.id = ua.allergen_id
  WHERE ua.user_id = p_user_id;

  SELECT calorie_goal INTO v_calorie_goal
  FROM user_goal
  WHERE user_id = p_user_id AND is_active = true
  ORDER BY created_at DESC
  LIMIT 1;

  SELECT id INTO v_existing_plan_id
  FROM public.meal_plan
  WHERE user_id    =  p_user_id
    AND start_date <= (p_start_date + (p_days - 1))
    AND end_date   >=  p_start_date
  ORDER BY created_at DESC
  LIMIT 1;

  IF v_existing_plan_id IS NOT NULL THEN
    DELETE FROM meal_plan_entry AS e
    WHERE e.meal_plan_id    = v_existing_plan_id
      AND e.scheduled_date >= p_start_date;

    UPDATE public.meal_plan
    SET end_date = GREATEST(end_date, p_start_date + (p_days - 1))
    WHERE id = v_existing_plan_id;

    v_plan_id := v_existing_plan_id;
  ELSE
    INSERT INTO meal_plan (user_id, start_date, end_date, is_active)
    VALUES (p_user_id, p_start_date, p_start_date + (p_days - 1), true)
    RETURNING id INTO v_plan_id;
  END IF;

  SELECT COALESCE(array_agg(mpec.recipe_id), ARRAY[]::uuid[])
  INTO v_used_recipe_ids
  FROM meal_plan_entry mpe
  JOIN meal_plan_entry_component mpec ON mpec.meal_plan_entry_id = mpe.id
  WHERE mpe.meal_plan_id   = v_plan_id
    AND mpe.scheduled_date < p_start_date
    AND mpec.role = 'base';

  SELECT COALESCE(array_agg(DISTINCT mpec.recipe_id), ARRAY[]::uuid[])
  INTO v_recent_recipe_ids
  FROM meal_plan_entry mpe
  JOIN meal_plan_entry_component mpec ON mpec.meal_plan_entry_id = mpe.id
  JOIN meal_plan mp ON mp.id = mpe.meal_plan_id
  WHERE mp.user_id         = p_user_id
    AND mpe.scheduled_date >= (p_start_date - 15)
    AND mpe.scheduled_date <   p_start_date
    AND mpec.role          = 'base';

  FOR v_day IN 0..(p_days - 1) LOOP
    v_current_date := p_start_date + v_day;

    FOREACH v_slot_rec IN ARRAY v_slots LOOP
      v_meal_type       := v_slot_rec->>'meal_type';
      v_slot_nickname   := v_slot_rec->>'nickname';
      v_slot_sort_order := (v_slot_rec->>'sort_order')::integer;

      v_target_meal_cal := (v_slot_rec->>'calorie_target')::numeric;
      IF (v_target_meal_cal IS NULL OR v_target_meal_cal = 0)
         AND v_calorie_goal IS NOT NULL AND v_calorie_goal > 0 THEN
        v_target_meal_cal := v_calorie_goal / array_length(v_slots, 1);
      END IF;

      -- Pass 1: with 15-day blacklist
      SELECT r.id, r.title, r.cover_image_url,
             rm.kcal_per_100g, rm.protein_per_100g, rm.carbs_per_100g, rm.fat_per_100g,
             rm.total_weight_g, r.creator_id,
             (
               0.15 * CASE
                 WHEN r.preferred_meal_type = v_meal_type THEN 1.0
                 WHEN r.preferred_meal_type = 'any'       THEN 0.5
                 ELSE 0.0
               END
             ) AS score
      INTO v_recipe
      FROM recipe r
      INNER JOIN recipe_save rs ON r.id = rs.recipe_id
      JOIN recipe_macro rm ON r.id = rm.recipe_id
      WHERE rs.user_id = p_user_id
        AND r.is_published = true
        AND v_meal_type = ANY(r.meal_types)
        AND rm.kcal_per_100g > 0
        AND (SELECT count(*) FROM unnest(v_used_recipe_ids) x WHERE x = r.id) < p_max_recipe_repeat
        AND r.id != ALL(v_recent_recipe_ids)
        AND (v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR r.creator_id = v_fan_creator_id)
        AND (v_target_meal_cal IS NULL OR v_target_meal_cal / (rm.kcal_per_100g / 100) <= 1500)
        AND NOT (r.allergen_tags && v_user_allergens)
      ORDER BY score DESC, random()
      LIMIT 1;

      -- Pass 2: fallback — retry without blacklist if pool exhausted
      IF v_recipe.id IS NULL AND array_length(v_recent_recipe_ids, 1) IS NOT NULL THEN
        SELECT r.id, r.title, r.cover_image_url,
               rm.kcal_per_100g, rm.protein_per_100g, rm.carbs_per_100g, rm.fat_per_100g,
               rm.total_weight_g, r.creator_id,
               (
                 0.15 * CASE
                   WHEN r.preferred_meal_type = v_meal_type THEN 1.0
                   WHEN r.preferred_meal_type = 'any'       THEN 0.5
                   ELSE 0.0
                 END
               ) AS score
        INTO v_recipe
        FROM recipe r
        INNER JOIN recipe_save rs ON r.id = rs.recipe_id
        JOIN recipe_macro rm ON r.id = rm.recipe_id
        WHERE rs.user_id = p_user_id
          AND r.is_published = true
          AND v_meal_type = ANY(r.meal_types)
          AND rm.kcal_per_100g > 0
          AND (SELECT count(*) FROM unnest(v_used_recipe_ids) x WHERE x = r.id) < p_max_recipe_repeat
          AND (v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR r.creator_id = v_fan_creator_id)
          AND (v_target_meal_cal IS NULL OR v_target_meal_cal / (rm.kcal_per_100g / 100) <= 1500)
          AND NOT (r.allergen_tags && v_user_allergens)
        ORDER BY score DESC, random()
        LIMIT 1;
      END IF;

      IF v_recipe.id IS NULL THEN
        RAISE EXCEPTION 'insufficient_saved_recipes' USING DETAIL = v_meal_type;
      END IF;

      IF v_target_meal_cal IS NOT NULL AND v_recipe.kcal_per_100g > 0 THEN
        v_grams := GREATEST(50, LEAST(1500,
          ROUND(v_target_meal_cal / (v_recipe.kcal_per_100g / 100))::integer));
      ELSE
        v_grams := 300;
      END IF;

      INSERT INTO meal_plan_entry (
        meal_plan_id, scheduled_date, meal_type, servings,
        calories_computed, protein_g_computed, carbs_g_computed, fat_g_computed,
        nickname, sort_order
      )
      VALUES (
        v_plan_id, v_current_date, v_meal_type, v_grams,
        ROUND((v_recipe.kcal_per_100g    * v_grams / 100)::numeric, 1),
        ROUND((v_recipe.protein_per_100g * v_grams / 100)::numeric, 1),
        ROUND((v_recipe.carbs_per_100g   * v_grams / 100)::numeric, 1),
        ROUND((v_recipe.fat_per_100g     * v_grams / 100)::numeric, 1),
        v_slot_nickname,
        v_slot_sort_order
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
        round_to_step(
          ri.quantity * v_grams / NULLIF(v_recipe.total_weight_g, 0),
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
        ROUND((v_recipe.kcal_per_100g    * v_grams / 100)::numeric, 1),
        ROUND((v_recipe.protein_per_100g * v_grams / 100)::numeric, 1),
        v_recipe.score::double precision;

    END LOOP;
  END LOOP;

  PERFORM public.create_batch_sessions_internal(v_plan_id, p_user_id, 7);
  PERFORM public.generate_shopping_list_internal(v_plan_id, p_user_id);

END;
$$;

REVOKE ALL ON FUNCTION public.generate_meal_plan_from_saved(uuid, integer, integer, date, integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.generate_meal_plan_from_saved(uuid, integer, integer, date, integer) FROM anon;
REVOKE ALL ON FUNCTION public.generate_meal_plan_from_saved(uuid, integer, integer, date, integer) FROM authenticated;


-- ─────────────────────────────────────────────────────────────────────────────
-- 3. generate_meal_plan_internal  (onboarding batch / cron recovery)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.generate_meal_plan_internal(
  p_user_id       uuid,
  p_days          integer DEFAULT 7,
  p_meals_per_day integer DEFAULT 3,
  p_start_date    date    DEFAULT CURRENT_DATE
)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'pg_temp'
AS $function$
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
  v_recent_recipe_ids      uuid[] := ARRAY[]::uuid[];
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

  SELECT COALESCE(array_agg(DISTINCT mpec.recipe_id), ARRAY[]::uuid[])
  INTO v_recent_recipe_ids
  FROM meal_plan_entry mpe
  JOIN meal_plan_entry_component mpec ON mpec.meal_plan_entry_id = mpe.id
  JOIN meal_plan mp ON mp.id = mpe.meal_plan_id
  WHERE mp.user_id         = p_user_id
    AND mpe.scheduled_date >= (p_start_date - 15)
    AND mpe.scheduled_date <   p_start_date
    AND mpec.role          = 'base';

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

      -- Pass 1: with 15-day blacklist
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
                     / NULLIF(v_target_protein_density, 0.001), 1.0))
                 + 0.15 * CASE
                     WHEN r.preferred_meal_type = v_meal_type THEN 1.0
                     WHEN r.preferred_meal_type = 'any'       THEN 0.5
                     ELSE 0.0
                   END
                 + 0.10 * GREATEST(0.0, 1.0 - LEAST(
                     ABS(rm.fat_g / NULLIF(rm.calories, 0) * 100
                         - v_target_fat_density)
                     / NULLIF(v_target_fat_density, 0.001), 1.0))
               ) AS score
        INTO v_recipe
        FROM recipe r
        JOIN recipe_vector rv ON r.id = rv.recipe_id
        JOIN recipe_macro rm ON r.id = rm.recipe_id
        WHERE r.is_published = true
          AND v_meal_type = ANY(r.meal_types)
          AND rm.calories > 0
          AND (SELECT count(*) FROM unnest(v_used_recipe_ids) x WHERE x = r.id) < 3
          AND r.id != ALL(v_recent_recipe_ids)
          AND (v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR r.creator_id = v_fan_creator_id)
          AND (v_target_meal_cal IS NULL OR (v_target_meal_cal / rm.calories) <= 4.0)
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
          AND (SELECT count(*) FROM unnest(v_used_recipe_ids) x WHERE x = r.id) < 3
          AND r.id != ALL(v_recent_recipe_ids)
          AND (v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR r.creator_id = v_fan_creator_id)
          AND (v_target_meal_cal IS NULL OR (v_target_meal_cal / rm.calories) <= 4.0)
        GROUP BY r.id, r.title, r.cover_image_url, r.creator_id, r.preferred_meal_type,
                 rm.calories, rm.protein_g, rm.carbs_g, rm.fat_g
        ORDER BY score DESC, COUNT(rl.recipe_id) DESC
        LIMIT 1;
      END IF;

      -- Pass 2: fallback — retry without blacklist if pool exhausted
      IF v_recipe.id IS NULL AND array_length(v_recent_recipe_ids, 1) IS NOT NULL THEN
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
                       / NULLIF(v_target_protein_density, 0.001), 1.0))
                   + 0.15 * CASE
                       WHEN r.preferred_meal_type = v_meal_type THEN 1.0
                       WHEN r.preferred_meal_type = 'any'       THEN 0.5
                       ELSE 0.0
                     END
                   + 0.10 * GREATEST(0.0, 1.0 - LEAST(
                       ABS(rm.fat_g / NULLIF(rm.calories, 0) * 100
                           - v_target_fat_density)
                       / NULLIF(v_target_fat_density, 0.001), 1.0))
                 ) AS score
          INTO v_recipe
          FROM recipe r
          JOIN recipe_vector rv ON r.id = rv.recipe_id
          JOIN recipe_macro rm ON r.id = rm.recipe_id
          WHERE r.is_published = true
            AND v_meal_type = ANY(r.meal_types)
            AND rm.calories > 0
            AND (SELECT count(*) FROM unnest(v_used_recipe_ids) x WHERE x = r.id) < 3
            AND (v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR r.creator_id = v_fan_creator_id)
            AND (v_target_meal_cal IS NULL OR (v_target_meal_cal / rm.calories) <= 4.0)
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
            AND (SELECT count(*) FROM unnest(v_used_recipe_ids) x WHERE x = r.id) < 3
            AND (v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR r.creator_id = v_fan_creator_id)
            AND (v_target_meal_cal IS NULL OR (v_target_meal_cal / rm.calories) <= 4.0)
          GROUP BY r.id, r.title, r.cover_image_url, r.creator_id, r.preferred_meal_type,
                   rm.calories, rm.protein_g, rm.carbs_g, rm.fat_g
          ORDER BY score DESC, COUNT(rl.recipe_id) DESC
          LIMIT 1;
        END IF;
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

    END LOOP;
  END LOOP;
END;
$function$;

REVOKE ALL ON FUNCTION public.generate_meal_plan_internal(uuid, integer, integer, date) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.generate_meal_plan_internal(uuid, integer, integer, date) FROM anon;
REVOKE ALL ON FUNCTION public.generate_meal_plan_internal(uuid, integer, integer, date) FROM authenticated;
```

- [ ] **Step 2: Apply the migration**

```powershell
cd "C:\Users\DELL LATITUDE 7480\akeli-nutrition-app"
supabase db reset
```

Expected last line: `Finished supabase db reset.`

- [ ] **Step 3: Run the full test suite**

```powershell
supabase test db
```

Expected:
```
/Users/.../generate_meal_plan_variety.test.sql ............. ok
/Users/.../generate_meal_plan_regenerate.test.sql .......... ok
/Users/.../swap_meal_plan_entry.test.sql ................... ok
/Users/.../generate_meal_plan_custom_schedule_test.sql ..... ok
All tests successful.
Files=4, Tests=30,  X wallclock secs
Result: PASS
```

If Test 1 still fails (NOT EXISTS is false — overlap still found), verify that `meal_plan_entry.scheduled_date` for the week-1 plan is being reached by the cross-plan query. Check by running this against the local DB after a manual generate:

```sql
SELECT mpec.recipe_id, mpe.scheduled_date
FROM meal_plan mp
JOIN meal_plan_entry mpe ON mpe.meal_plan_id = mp.id
JOIN meal_plan_entry_component mpec ON mpec.meal_plan_entry_id = mpe.id
WHERE mp.user_id = 'eeeeffff-0000-4000-8000-000000000099'
  AND mpe.scheduled_date >= (CURRENT_DATE + 208 - 15)
  AND mpe.scheduled_date <  (CURRENT_DATE + 208)
  AND mpec.role = 'base';
```

This should return the 3 rows from the week-1 plan.

- [ ] **Step 4: Smoke-test with seed users — confirm different recipes week over week**

```powershell
$C = "supabase_db_akeli_landing_page"
docker exec $C psql -U postgres -d postgres -t -c "
SET request.jwt.claims = '{""sub"":""aa000001-0000-4000-8000-000000000001""}';
SELECT meal_type, recipe_title FROM generate_meal_plan(
  'aa000001-0000-4000-8000-000000000001'::uuid, 1, 3, CURRENT_DATE+7, 3
) ORDER BY meal_type;"

docker exec $C psql -U postgres -d postgres -t -c "
SET request.jwt.claims = '{""sub"":""aa000001-0000-4000-8000-000000000001""}';
SELECT meal_type, recipe_title FROM generate_meal_plan(
  'aa000001-0000-4000-8000-000000000001'::uuid, 1, 3, CURRENT_DATE+14, 3
) ORDER BY meal_type;"
```

Expected: the two outputs show **different** `recipe_title` values for each meal type.

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260629000001_generate_meal_plan_15day_variety.sql
git commit -m "feat(meal-plan): exclude recipes used in past 15 days from weekly plan generation"
```
