# Saved-Recipe Variety Eligibility Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Couple the "use saved recipes only" eligibility threshold to the user's `meal_variety_days` setting, make `generate_meal_plan_from_saved` skip its recency blacklist per meal type when the saved pool can't sustain it, and give the user proactive Dart-side feedback (backed by a DB-level security guard) when a change would break the saved-recipes/variety combination.

**Architecture:** One new SQL migration touches three existing functions (`generate_meal_plan_from_saved`, `evaluate_saved_recipe_eligibility`, `get_saved_recipe_eligibility_progress`) and adds two new triggers on `user_profile`. A new Dart file provides a client-side mirror of the eligibility formula used by two existing pages to show proactive SnackBar warnings; the DB triggers remain the actual source of truth.

**Tech Stack:** PostgreSQL/plpgsql (Supabase migrations, pgTAP tests), Flutter/Dart (Riverpod providers, `flutter_localizations`).

## Global Constraints

- Every Dart file created or modified in this project must contain full structured logging via `package:akeli/core/logger.dart` (`appLogger`) from the first line — see `CLAUDE.md` Logging Standard. No exceptions, including small utility files.
- No hardcoded user-visible strings in Dart widgets — every string goes through `AppLocalizations`, added to **both** `lib/l10n/app_en.arb` and `lib/l10n/app_fr.arb` before being referenced in code, followed by `flutter gen-l10n`.
- The eligibility threshold formula is `CASE WHEN v_variety_days = 0 THEN 7 ELSE v_variety_days * 2 END` — this exact formula must appear identically in both the SQL functions (Task 2) and the Dart mirror (Task 4). Keep them in sync by hand; there is no shared source between the two languages.
- SQL migrations in this repo fully replace function bodies via `CREATE OR REPLACE FUNCTION` — never attempt a partial in-place SQL edit of a function body.
- Run `supabase test db` from the project root after every SQL task; run `flutter analyze` and the relevant `flutter test` file after every Dart task.

---

### Task 1: Generator pool-size precheck in `generate_meal_plan_from_saved`

**Files:**
- Create: `supabase/migrations/20260705000002_saved_recipe_variety_eligibility.sql`
- Create: `supabase/tests/database/saved_recipe_eligibility.test.sql`

**Interfaces:**
- Consumes: existing `public.generate_meal_plan_from_saved(uuid, integer, integer, date, integer)` as defined in `supabase/migrations/20260705000001_fix_meal_plan_from_saved_service_role.sql` (the current on-disk definition — this task fully replaces it).
- Produces: same function signature and return shape (`meal_plan_id, entry_id, component_id, scheduled_date, meal_type, recipe_id, recipe_title, cover_image_url, calories, protein_g, score`). Later tasks (2, 3) append further `CREATE OR REPLACE FUNCTION` / `CREATE TRIGGER` statements to the same migration file — they do not touch this function again.

- [ ] **Step 1: Write the failing pgTAP test**

Create `supabase/tests/database/saved_recipe_eligibility.test.sql`:

```sql
-- supabase/tests/database/saved_recipe_eligibility.test.sql
-- Tests: saved-recipe pool-size precheck in generate_meal_plan_from_saved,
-- and the meal_variety_days-coupled eligibility threshold + its triggers.

BEGIN;

SELECT plan(11);

-- ─── Seed: shared ingredient/unit ──────────────────────────────────────────

INSERT INTO public.measurement_unit (code, name_fr, name_en)
VALUES ('g', 'g', 'g') ON CONFLICT (code) DO NOTHING;

INSERT INTO public.ingredient (id, name, name_fr)
VALUES ('00000000-0000-0000-0000-000000000098'::uuid,
        'Eligibility Ingredient', 'Ingrédient Éligibilité')
ON CONFLICT (id) DO NOTHING;

-- ─── Seed: small-pool user (3 universal recipes, saved) ────────────────────

INSERT INTO auth.users (id, email, role, created_at, updated_at)
VALUES ('a1111111-0000-4000-8000-000000000001'::uuid,
        'smallpool@test.local', 'authenticated', now(), now())
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.user_profile (id, first_name, meal_variety_days)
VALUES ('a1111111-0000-4000-8000-000000000001'::uuid, 'SmallPool', 7)
ON CONFLICT (id) DO UPDATE SET meal_variety_days = 7;

INSERT INTO public.recipe (id, title, is_published, meal_types, preferred_meal_type, allergen_tags)
VALUES
  ('b1111111-0000-4000-8000-000000000001'::uuid, 'Small Pool Recipe 1', true,
   ARRAY['breakfast','lunch','dinner'], 'any', ARRAY[]::text[]),
  ('b1111111-0000-4000-8000-000000000002'::uuid, 'Small Pool Recipe 2', true,
   ARRAY['breakfast','lunch','dinner'], 'any', ARRAY[]::text[]),
  ('b1111111-0000-4000-8000-000000000003'::uuid, 'Small Pool Recipe 3', true,
   ARRAY['breakfast','lunch','dinner'], 'any', ARRAY[]::text[]);

INSERT INTO public.recipe_macro (recipe_id, calories, protein_g, carbs_g, fat_g, total_weight_g)
VALUES
  ('b1111111-0000-4000-8000-000000000001'::uuid, 400, 20, 50, 10, 300),
  ('b1111111-0000-4000-8000-000000000002'::uuid, 500, 25, 55, 12, 350),
  ('b1111111-0000-4000-8000-000000000003'::uuid, 600, 30, 60, 15, 400);

INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, quantity, unit, is_optional)
VALUES
  ('b1111111-0000-4000-8000-000000000001'::uuid, '00000000-0000-0000-0000-000000000098'::uuid, 100, 'g', false),
  ('b1111111-0000-4000-8000-000000000002'::uuid, '00000000-0000-0000-0000-000000000098'::uuid, 100, 'g', false),
  ('b1111111-0000-4000-8000-000000000003'::uuid, '00000000-0000-0000-0000-000000000098'::uuid, 100, 'g', false);

INSERT INTO public.recipe_save (user_id, recipe_id)
VALUES
  ('a1111111-0000-4000-8000-000000000001'::uuid, 'b1111111-0000-4000-8000-000000000001'::uuid),
  ('a1111111-0000-4000-8000-000000000001'::uuid, 'b1111111-0000-4000-8000-000000000002'::uuid),
  ('a1111111-0000-4000-8000-000000000001'::uuid, 'b1111111-0000-4000-8000-000000000003'::uuid);

-- ─── Seed: large-pool user (7 universal recipes, saved) ────────────────────

INSERT INTO auth.users (id, email, role, created_at, updated_at)
VALUES ('a1111111-0000-4000-8000-000000000002'::uuid,
        'largepool@test.local', 'authenticated', now(), now())
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.user_profile (id, first_name, meal_variety_days)
VALUES ('a1111111-0000-4000-8000-000000000002'::uuid, 'LargePool', 7)
ON CONFLICT (id) DO UPDATE SET meal_variety_days = 7;

INSERT INTO public.recipe (id, title, is_published, meal_types, preferred_meal_type, allergen_tags)
SELECT ('b2222222-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid,
       'Large Pool Recipe ' || i, true,
       ARRAY['breakfast','lunch','dinner'], 'any', ARRAY[]::text[]
FROM generate_series(1, 7) i;

INSERT INTO public.recipe_macro (recipe_id, calories, protein_g, carbs_g, fat_g, total_weight_g)
SELECT ('b2222222-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid,
       400 + (i * 10), 20, 50, 10, 300
FROM generate_series(1, 7) i;

INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, quantity, unit, is_optional)
SELECT ('b2222222-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid,
       '00000000-0000-0000-0000-000000000098'::uuid, 100, 'g', false
FROM generate_series(1, 7) i;

INSERT INTO public.recipe_save (user_id, recipe_id)
SELECT 'a1111111-0000-4000-8000-000000000002'::uuid,
       ('b2222222-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid
FROM generate_series(1, 7) i;

-- ─── Test 1 & 2: small pool (3 < variety_days=7) never raises insufficient_saved_recipes ──

SET LOCAL request.jwt.claims = '{"sub":"a1111111-0000-4000-8000-000000000001"}';

SELECT lives_ok(
  $$ SELECT public.generate_meal_plan_from_saved(
       'a1111111-0000-4000-8000-000000000001'::uuid,
       1, 3, (CURRENT_DATE + 400)::date, 3
     ) $$,
  'small pool (3 recipes/type, variety=7): week 1 generates without error'
);

SELECT lives_ok(
  $$ SELECT public.generate_meal_plan_from_saved(
       'a1111111-0000-4000-8000-000000000001'::uuid,
       1, 3, (CURRENT_DATE + 403)::date, 3
     ) $$,
  'small pool (3 recipes/type, variety=7): week 2 (3 days later, pool fully exhausted by blacklist) still generates without error'
);

-- ─── Test 3: large pool (7 >= variety_days=7) still enforces the blacklist ──

SET LOCAL request.jwt.claims = '{"sub":"a1111111-0000-4000-8000-000000000002"}';

SELECT public.generate_meal_plan_from_saved(
  'a1111111-0000-4000-8000-000000000002'::uuid,
  1, 3, (CURRENT_DATE + 400)::date, 3
);

CREATE TEMP TABLE t_elig_w1 AS
SELECT DISTINCT mpec.recipe_id
FROM public.meal_plan mp
JOIN public.meal_plan_entry mpe ON mpe.meal_plan_id = mp.id
JOIN public.meal_plan_entry_component mpec ON mpec.meal_plan_entry_id = mpe.id
WHERE mp.user_id         = 'a1111111-0000-4000-8000-000000000002'::uuid
  AND mpe.scheduled_date = (CURRENT_DATE + 400)::date
  AND mpec.role          = 'base';

SELECT public.generate_meal_plan_from_saved(
  'a1111111-0000-4000-8000-000000000002'::uuid,
  1, 3, (CURRENT_DATE + 403)::date, 3
);

SELECT ok(
  NOT EXISTS (
    SELECT 1
    FROM public.meal_plan mp
    JOIN public.meal_plan_entry mpe ON mpe.meal_plan_id = mp.id
    JOIN public.meal_plan_entry_component mpec ON mpec.meal_plan_entry_id = mpe.id
    WHERE mp.user_id         = 'a1111111-0000-4000-8000-000000000002'::uuid
      AND mpe.scheduled_date = (CURRENT_DATE + 403)::date
      AND mpec.role          = 'base'
      AND mpec.recipe_id IN (SELECT recipe_id FROM t_elig_w1)
  ),
  'large pool (7 recipes/type, variety=7): week 2 shares no recipe with week 1 — blacklist still enforced when pool is sufficient'
);

-- ─── Test 3b: pool smaller than variety_days skips the blacklist entirely ──
-- This is the one assertion in this file that actually distinguishes
-- pre-fix from post-fix behavior (see Step 2/Step 4 below for why Tests
-- 1-3 already pass today via the pre-existing Pass 2 fallback). It encodes
-- the accepted trade-off documented in the spec: a pool below variety_days
-- is not partially blacklist-protected — the whole meal type falls back to
-- unfiltered scoring instead of trying to salvage what little protection
-- the non-blacklisted remainder could offer.

INSERT INTO auth.users (id, email, role, created_at, updated_at)
VALUES ('a1111111-0000-4000-8000-000000000004'::uuid,
        'partialpool@test.local', 'authenticated', now(), now())
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.user_profile (id, first_name, meal_variety_days)
VALUES ('a1111111-0000-4000-8000-000000000004'::uuid, 'PartialPool', 7)
ON CONFLICT (id) DO UPDATE SET meal_variety_days = 7;

-- 5 universal recipes with distinct preferred_meal_type so scoring is
-- deterministic: A is the unambiguous top pick for the breakfast slot
-- (score 0.15), D/E are the "any" fallback (score 0.075), B/C prefer other
-- meal types (score 0 for a breakfast slot) so they never compete for it.
INSERT INTO public.recipe (id, title, is_published, meal_types, preferred_meal_type, allergen_tags)
VALUES
  ('b3333333-0000-4000-8000-000000000001'::uuid, 'Partial Pool A (breakfast)', true, ARRAY['breakfast','lunch','dinner'], 'breakfast', ARRAY[]::text[]),
  ('b3333333-0000-4000-8000-000000000002'::uuid, 'Partial Pool B (lunch)',     true, ARRAY['breakfast','lunch','dinner'], 'lunch',     ARRAY[]::text[]),
  ('b3333333-0000-4000-8000-000000000003'::uuid, 'Partial Pool C (dinner)',    true, ARRAY['breakfast','lunch','dinner'], 'dinner',    ARRAY[]::text[]),
  ('b3333333-0000-4000-8000-000000000004'::uuid, 'Partial Pool D (any)',       true, ARRAY['breakfast','lunch','dinner'], 'any',       ARRAY[]::text[]),
  ('b3333333-0000-4000-8000-000000000005'::uuid, 'Partial Pool E (any)',       true, ARRAY['breakfast','lunch','dinner'], 'any',       ARRAY[]::text[]);

INSERT INTO public.recipe_macro (recipe_id, calories, protein_g, carbs_g, fat_g, total_weight_g)
SELECT id, 400, 20, 50, 10, 300 FROM public.recipe WHERE id IN (
  'b3333333-0000-4000-8000-000000000001'::uuid, 'b3333333-0000-4000-8000-000000000002'::uuid,
  'b3333333-0000-4000-8000-000000000003'::uuid, 'b3333333-0000-4000-8000-000000000004'::uuid,
  'b3333333-0000-4000-8000-000000000005'::uuid
);

INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, quantity, unit, is_optional)
SELECT id, '00000000-0000-0000-0000-000000000098'::uuid, 100, 'g', false FROM public.recipe WHERE id IN (
  'b3333333-0000-4000-8000-000000000001'::uuid, 'b3333333-0000-4000-8000-000000000002'::uuid,
  'b3333333-0000-4000-8000-000000000003'::uuid, 'b3333333-0000-4000-8000-000000000004'::uuid,
  'b3333333-0000-4000-8000-000000000005'::uuid
);

INSERT INTO public.recipe_save (user_id, recipe_id)
SELECT 'a1111111-0000-4000-8000-000000000004'::uuid, id FROM public.recipe WHERE id IN (
  'b3333333-0000-4000-8000-000000000001'::uuid, 'b3333333-0000-4000-8000-000000000002'::uuid,
  'b3333333-0000-4000-8000-000000000003'::uuid, 'b3333333-0000-4000-8000-000000000004'::uuid,
  'b3333333-0000-4000-8000-000000000005'::uuid
);

SET LOCAL request.jwt.claims = '{"sub":"a1111111-0000-4000-8000-000000000004"}';

-- Week 1: breakfast/lunch/dinner slots deterministically pick A/B/C (each
-- strictly highest-scoring for its own slot type). D and E are unused.
SELECT public.generate_meal_plan_from_saved(
  'a1111111-0000-4000-8000-000000000004'::uuid,
  1, 3, (CURRENT_DATE + 450)::date, 3
);

-- Week 2, 3 days later (within the 7-day window): pool=5 < variety_days=7,
-- so the precheck should skip the blacklist for this meal type entirely,
-- and Pass 2's raw scoring picks A again for breakfast (A objectively
-- out-scores D/E even without the blacklist). Before this task's fix,
-- Pass 1 would still run with the blacklist active, exclude A/B/C, and
-- pick D or E instead — never A.
SELECT public.generate_meal_plan_from_saved(
  'a1111111-0000-4000-8000-000000000004'::uuid,
  1, 3, (CURRENT_DATE + 453)::date, 3
);

SELECT is(
  (
    SELECT mpec.recipe_id
    FROM public.meal_plan mp
    JOIN public.meal_plan_entry mpe ON mpe.meal_plan_id = mp.id
    JOIN public.meal_plan_entry_component mpec ON mpec.meal_plan_entry_id = mpe.id
    WHERE mp.user_id         = 'a1111111-0000-4000-8000-000000000004'::uuid
      AND mpe.scheduled_date = (CURRENT_DATE + 453)::date
      AND mpe.meal_type      = 'breakfast'
      AND mpec.role          = 'base'
  ),
  'b3333333-0000-4000-8000-000000000001'::uuid,
  'pool (5) < variety_days (7): breakfast slot reuses recipe A — precheck skips the blacklist entirely for this meal type instead of partially enforcing it (accepted trade-off, see spec Part 1 edge cases)'
);

-- ─── Test 4 & 5: meal_variety_days = 0 is unaffected by the precheck ───────

UPDATE public.user_profile
SET meal_variety_days = 0
WHERE id = 'a1111111-0000-4000-8000-000000000001'::uuid;

SET LOCAL request.jwt.claims = '{"sub":"a1111111-0000-4000-8000-000000000001"}';

SELECT lives_ok(
  $$ SELECT public.generate_meal_plan_from_saved(
       'a1111111-0000-4000-8000-000000000001'::uuid,
       1, 3, (CURRENT_DATE + 500)::date, 3
     ) $$,
  'variety=0: week 3 generates without error'
);

SELECT lives_ok(
  $$ SELECT public.generate_meal_plan_from_saved(
       'a1111111-0000-4000-8000-000000000001'::uuid,
       1, 3, (CURRENT_DATE + 503)::date, 3
     ) $$,
  'variety=0: week 4 (3 days later, reuse allowed) generates without error'
);

-- ─── Seed: eligibility user (14 universal recipes) — used by Tasks 2 & 3 ───
-- Tests 6-10 are written here but will fail until Tasks 2 and 3 land; that is
-- expected for this step (see Step 2 below).

INSERT INTO auth.users (id, email, role, created_at, updated_at)
VALUES ('a1111111-0000-4000-8000-000000000003'::uuid,
        'eligibility@test.local', 'authenticated', now(), now())
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.user_profile (id, first_name, meal_variety_days, use_saved_recipes_only, is_saved_recipe_eligible)
VALUES ('a1111111-0000-4000-8000-000000000003'::uuid, 'Eligibility', 7, false, false)
ON CONFLICT (id) DO UPDATE SET meal_variety_days = 7, use_saved_recipes_only = false, is_saved_recipe_eligible = false;

INSERT INTO public.recipe (id, title, is_published, meal_types, preferred_meal_type, allergen_tags)
SELECT ('c3333333-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid,
       'Eligibility Recipe ' || i, true,
       ARRAY['breakfast','lunch','dinner'], 'any', ARRAY[]::text[]
FROM generate_series(1, 14) i;

-- Save only the first 10 for now (Test 6 checks "not yet eligible").
INSERT INTO public.recipe_save (user_id, recipe_id)
SELECT 'a1111111-0000-4000-8000-000000000003'::uuid,
       ('c3333333-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid
FROM generate_series(1, 10) i;

-- Test 6: 10 saved/type, variety_days=7 (target 14) → NOT eligible
SELECT public.evaluate_saved_recipe_eligibility('a1111111-0000-4000-8000-000000000003'::uuid);

SELECT is(
  (SELECT is_saved_recipe_eligible FROM public.user_profile WHERE id = 'a1111111-0000-4000-8000-000000000003'::uuid),
  false,
  'eligibility: 10 saved recipes/type at variety_days=7 (target 14) is NOT eligible'
);

-- Save the remaining 4 (total 14) for Test 7.
INSERT INTO public.recipe_save (user_id, recipe_id)
SELECT 'a1111111-0000-4000-8000-000000000003'::uuid,
       ('c3333333-0000-4000-8000-' || lpad(i::text, 12, '0'))::uuid
FROM generate_series(11, 14) i;

SELECT public.evaluate_saved_recipe_eligibility('a1111111-0000-4000-8000-000000000003'::uuid);

-- Test 7: 14 saved/type, variety_days=7 (target 14) → eligible
SELECT is(
  (SELECT is_saved_recipe_eligible FROM public.user_profile WHERE id = 'a1111111-0000-4000-8000-000000000003'::uuid),
  true,
  'eligibility: 14 saved recipes/type at variety_days=7 (target 14) IS eligible'
);

-- Turn saved-only mode on so Test 8/9 can prove the variety-change trigger forces it back off.
UPDATE public.user_profile
SET use_saved_recipes_only = true
WHERE id = 'a1111111-0000-4000-8000-000000000003'::uuid;

-- Test 8 & 9: raising variety_days to 15 (target 30, still only 14 saved) fires
-- the trigger automatically and forces both flags off.
UPDATE public.user_profile
SET meal_variety_days = 15
WHERE id = 'a1111111-0000-4000-8000-000000000003'::uuid;

SELECT is(
  (SELECT is_saved_recipe_eligible FROM public.user_profile WHERE id = 'a1111111-0000-4000-8000-000000000003'::uuid),
  false,
  'trigger: raising meal_variety_days to 15 (target 30, still 14 saved) flips is_saved_recipe_eligible to false automatically'
);

SELECT is(
  (SELECT use_saved_recipes_only FROM public.user_profile WHERE id = 'a1111111-0000-4000-8000-000000000003'::uuid),
  false,
  'trigger: raising meal_variety_days also force-disables use_saved_recipes_only automatically'
);

-- Test 10: direct write guard — attempting to set use_saved_recipes_only=true
-- while ineligible is silently reverted.
UPDATE public.user_profile
SET use_saved_recipes_only = true
WHERE id = 'a1111111-0000-4000-8000-000000000003'::uuid;

SELECT is(
  (SELECT use_saved_recipes_only FROM public.user_profile WHERE id = 'a1111111-0000-4000-8000-000000000003'::uuid),
  false,
  'guard trigger: direct UPDATE setting use_saved_recipes_only=true while ineligible is silently reverted to false'
);

SELECT * FROM finish();

ROLLBACK;
```

- [ ] **Step 2: Run the test suite and verify only the expected test fails**

Run: `cd "c:/Users/DELL LATITUDE 7480/akeli-nutrition-app" && supabase test db`

Expected, and important to understand why: Tests 1, 2, and 3 (small pool lives_ok x2, large pool no-overlap) already **PASS** against today's unmodified `generate_meal_plan_from_saved` — Pass 2's pre-existing no-blacklist fallback already prevents any crash for the small pool, and Pass 1 already enforces the blacklist correctly whenever the pool has room to satisfy it (the large-pool case). Those three are regression/contract tests, not proof of this task's change — nothing before Step 3 can make them fail differently than they will after.

**Test 3b is the one assertion that must actually FAIL right now.** With today's code, Pass 1 always runs first regardless of pool size: for the 5-recipe partial-overlap fixture, Pass 1 (with the blacklist active) excludes A/B/C and finds D or E for the breakfast slot — it never reuses A. This task's fix changes that specific outcome (see Step 3), so Test 3b's assertion that breakfast reuses recipe A will fail until this task's SQL change lands.

Tests 6 through 10 (eligibility/trigger checks) also fail right now — they depend on Tasks 2 and 3, not yet written. Confirm the failure set is exactly {Test 3b, Tests 6-10} and that Tests 1, 2, 3 already pass. If 1, 2, or 3 fail, investigate before proceeding — they should already work against the unmodified function from migration `20260705000001`.

- [ ] **Step 3: Write the migration with the pool-size precheck**

Create `supabase/migrations/20260705000002_saved_recipe_variety_eligibility.sql`:

```sql
-- Migration: 20260705000002_saved_recipe_variety_eligibility
-- Description: Part 1 — generate_meal_plan_from_saved skips the recency
-- blacklist per meal type when the user's saved pool for that type can't
-- sustain meal_variety_days, instead of reactively discovering this via a
-- failed Pass-1 query on every slot.

DROP FUNCTION IF EXISTS public.generate_meal_plan_from_saved(uuid, integer, integer, date, integer);

CREATE OR REPLACE FUNCTION public.generate_meal_plan_from_saved(p_user_id uuid, p_days integer, p_meals_per_day integer, p_start_date date, p_max_recipe_repeat integer DEFAULT 3)
 RETURNS TABLE(meal_plan_id uuid, entry_id uuid, component_id uuid, scheduled_date date, meal_type text, recipe_id uuid, recipe_title text, cover_image_url text, calories numeric, protein_g numeric, score double precision)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
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
  v_variety_days           int    := 7;
  v_variety_eligible_types text[] := ARRAY[]::text[];
  v_pool_count             int;
  v_type                   text;
  v_random_order           boolean := false;
  v_user_allergens         text[];
  v_calorie_goal           numeric;
  v_target_meal_cal        numeric;
  v_grams                  integer;
  v_fan_count              int := 0;
  v_other_count            int := 0;
  v_total_slots            int;
  v_max_other_slots        int;
  v_entry                  record;
  v_weekly_budget          numeric(10,2);
  v_country_code           text;
  v_target_meal_cost       numeric(10,2);
BEGIN
  IF p_user_id IS DISTINCT FROM auth.uid() AND auth.role() IS DISTINCT FROM 'service_role' THEN
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

  SELECT COALESCE(meal_variety_days, 7), COALESCE(meal_schedule_random, false), COALESCE(weekly_budget, 0), COALESCE(country_code, 'FR')
  INTO v_variety_days, v_random_order, v_weekly_budget, v_country_code
  FROM public.user_profile WHERE id = p_user_id;

  IF v_weekly_budget > 0 THEN
    v_target_meal_cost := v_weekly_budget / NULLIF(v_total_slots, 0);
  END IF;

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
    AND mpe.scheduled_date >= (p_start_date - v_variety_days)
    AND mpe.scheduled_date <   p_start_date
    AND mpec.role          = 'base';

  -- Part 1: pool-size precheck — only apply the recency blacklist for a meal
  -- type if the saved pool for that type is at least as large as the variety
  -- window. Otherwise Pass 1 could never succeed anyway, so skip straight to
  -- the no-blacklist query below instead of burning a doomed query per slot.
  FOR v_type IN SELECT DISTINCT (s->>'meal_type') FROM unnest(v_slots) AS s LOOP
    SELECT count(DISTINCT r.id) INTO v_pool_count
    FROM recipe r
    INNER JOIN recipe_save rs ON r.id = rs.recipe_id
    WHERE rs.user_id = p_user_id
      AND r.is_published = true
      AND v_type = ANY(r.meal_types)
      AND NOT (r.allergen_tags && v_user_allergens);

    IF v_variety_days = 0 OR v_pool_count >= v_variety_days THEN
      v_variety_eligible_types := v_variety_eligible_types || v_type;
    END IF;
  END LOOP;

  DROP TABLE IF EXISTS temp_dates;
  DROP TABLE IF EXISTS temp_meals;
  CREATE TEMP TABLE temp_dates (
    id             serial,
    scheduled_date date,
    meal_type      text
  ) ON COMMIT DROP;

  CREATE TEMP TABLE temp_meals (
    id                serial,
    meal_type         text,
    recipe_id         uuid,
    recipe_title      text,
    cover_image_url   text,
    calories          numeric,
    protein_g         numeric,
    carbs_g           numeric,
    fat_g             numeric,
    grams             integer,
    slot_nickname     text,
    slot_sort_order   integer,
    total_weight_g    numeric,
    score             double precision
  ) ON COMMIT DROP;

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

      -- Pass 1: with blacklist — only attempted when the pool-size precheck
      -- flagged this meal type as able to sustain the variety window.
      v_recipe := NULL;
      IF v_meal_type = ANY(v_variety_eligible_types) THEN
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
        LEFT JOIN public.recipe_market_cost rmc
          ON rmc.recipe_id = r.id AND rmc.country_code = v_country_code
        WHERE rs.user_id = p_user_id
          AND r.is_published = true
          AND v_meal_type = ANY(r.meal_types)
          AND rm.kcal_per_100g > 0
          AND (SELECT count(*) FROM unnest(v_used_recipe_ids) x WHERE x = r.id) < p_max_recipe_repeat
          AND r.id != ALL(v_recent_recipe_ids)
          AND (v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR r.creator_id = v_fan_creator_id)
          AND (v_target_meal_cal IS NULL OR v_target_meal_cal / (rm.kcal_per_100g / 100) <= 1500)
          AND NOT (r.allergen_tags && v_user_allergens)
          AND (
            v_weekly_budget = 0 OR
            (
              rmc.recipe_id IS NOT NULL AND
              ((rmc.cost_per_100g / NULLIF(rm.kcal_per_100g, 0)) * v_target_meal_cal) <= v_target_meal_cost
            )
          )
        ORDER BY score DESC, random()
        LIMIT 1;
      END IF;

      -- Pass 2: fallback — no blacklist. Runs whenever Pass 1 was skipped
      -- (pool too small) or ran but found nothing.
      IF v_recipe.id IS NULL THEN
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
        LEFT JOIN public.recipe_market_cost rmc
          ON rmc.recipe_id = r.id AND rmc.country_code = v_country_code
        WHERE rs.user_id = p_user_id
          AND r.is_published = true
          AND v_meal_type = ANY(r.meal_types)
          AND rm.kcal_per_100g > 0
          AND (SELECT count(*) FROM unnest(v_used_recipe_ids) x WHERE x = r.id) < p_max_recipe_repeat
          AND (v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR r.creator_id = v_fan_creator_id)
          AND (v_target_meal_cal IS NULL OR v_target_meal_cal / (rm.kcal_per_100g / 100) <= 1500)
          AND NOT (r.allergen_tags && v_user_allergens)
          AND (
            v_weekly_budget = 0 OR
            (
              rmc.recipe_id IS NOT NULL AND
              ((rmc.cost_per_100g / NULLIF(rm.kcal_per_100g, 0)) * v_target_meal_cal) <= v_target_meal_cost
            )
          )
        ORDER BY score DESC, random()
        LIMIT 1;
      END IF;

      IF v_recipe.id IS NULL THEN
        IF v_weekly_budget > 0 AND EXISTS (
          SELECT 1
          FROM recipe r
          INNER JOIN recipe_save rs ON r.id = rs.recipe_id
          JOIN recipe_macro rm ON r.id = rm.recipe_id
          WHERE rs.user_id = p_user_id
            AND r.is_published = true
            AND v_meal_type = ANY(r.meal_types)
            AND rm.kcal_per_100g > 0
            AND (SELECT count(*) FROM unnest(v_used_recipe_ids) x WHERE x = r.id) < p_max_recipe_repeat
            AND NOT (r.allergen_tags && v_user_allergens)
            AND (v_fan_creator_id IS NULL OR v_other_count < v_max_other_slots OR r.creator_id = v_fan_creator_id)
            AND (v_target_meal_cal IS NULL OR v_target_meal_cal / (rm.kcal_per_100g / 100) <= 1500)
        ) THEN
          RAISE EXCEPTION 'insufficient_budget';
        ELSE
          RAISE EXCEPTION 'insufficient_saved_recipes' USING DETAIL = v_meal_type;
        END IF;
      END IF;

      IF v_target_meal_cal IS NOT NULL AND v_recipe.kcal_per_100g > 0 THEN
        v_grams := GREATEST(50, LEAST(1500,
          ROUND(v_target_meal_cal / (v_recipe.kcal_per_100g / 100))::integer));
      ELSE
        v_grams := 300;
      END IF;

      INSERT INTO temp_dates (scheduled_date, meal_type)
      VALUES (v_current_date, v_meal_type);

      INSERT INTO temp_meals (
        meal_type, recipe_id, recipe_title, cover_image_url,
        calories, protein_g, carbs_g, fat_g, grams,
        slot_nickname, slot_sort_order, total_weight_g, score
      )
      VALUES (
        v_meal_type, v_recipe.id, v_recipe.title, v_recipe.cover_image_url,
        ROUND((v_recipe.kcal_per_100g    * v_grams / 100)::numeric, 1),
        ROUND((v_recipe.protein_per_100g * v_grams / 100)::numeric, 1),
        ROUND((v_recipe.carbs_per_100g   * v_grams / 100)::numeric, 1),
        ROUND((v_recipe.fat_per_100g     * v_grams / 100)::numeric, 1),
        v_grams,
        v_slot_nickname,
        v_slot_sort_order,
        v_recipe.total_weight_g,
        v_recipe.score
      );

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

  FOR v_entry IN (
    WITH shuffled_meals AS (
      SELECT t.*, row_number() OVER (PARTITION BY t.meal_type ORDER BY CASE WHEN v_random_order THEN random() ELSE t.id::double precision END) as rn
      FROM temp_meals t
    ),
    ordered_dates AS (
      SELECT d.*, row_number() OVER (PARTITION BY d.meal_type ORDER BY d.scheduled_date) as rn
      FROM temp_dates d
    )
    SELECT od.scheduled_date, sm.meal_type, sm.recipe_id, sm.recipe_title, sm.cover_image_url,
           sm.calories, sm.protein_g, sm.carbs_g, sm.fat_g, sm.grams,
           sm.slot_nickname, sm.slot_sort_order, sm.total_weight_g, sm.score
    FROM ordered_dates od
    JOIN shuffled_meals sm ON od.meal_type = sm.meal_type AND od.rn = sm.rn
    ORDER BY od.scheduled_date, sm.slot_sort_order
  ) LOOP

    INSERT INTO meal_plan_entry (
      meal_plan_id, scheduled_date, meal_type, servings,
      calories_computed, protein_g_computed, carbs_g_computed, fat_g_computed,
      nickname, sort_order
    )
    VALUES (
      v_plan_id, v_entry.scheduled_date, v_entry.meal_type, v_entry.grams,
      v_entry.calories, v_entry.protein_g, v_entry.carbs_g, v_entry.fat_g,
      v_entry.slot_nickname, v_entry.slot_sort_order
    )
    RETURNING id INTO v_entry_id;

    INSERT INTO meal_plan_entry_component (meal_plan_entry_id, recipe_id, role, consumption_weight)
    VALUES (v_entry_id, v_entry.recipe_id, 'base', 1.0)
    RETURNING id INTO v_component_id;

    INSERT INTO meal_ingredient (meal_plan_entry_id, ingredient_id, ingredient_name, quantity, unit)
    SELECT
      v_entry_id,
      ri.ingredient_id,
      COALESCE(i.name_fr, i.name),
      round_to_step(
        ri.quantity * v_entry.grams / NULLIF(v_entry.total_weight_g, 0),
        COALESCE(
          (SELECT rounding_step FROM ingredient_rounding_rule
           WHERE ingredient_id = ri.ingredient_id AND unit = ri.unit),
          (SELECT rounding_step FROM unit_rounding_config WHERE unit = ri.unit)
        )
      ),
      ri.unit
    FROM recipe_ingredient ri
    JOIN ingredient i ON i.id = ri.ingredient_id
    WHERE ri.recipe_id = v_entry.recipe_id
      AND ri.is_optional = false;

    RETURN QUERY SELECT
      v_plan_id, v_entry_id, v_component_id,
      v_entry.scheduled_date, v_entry.meal_type,
      v_entry.recipe_id, v_entry.recipe_title, v_entry.cover_image_url,
      v_entry.calories, v_entry.protein_g,
      v_entry.score::double precision;

  END LOOP;

  DROP TABLE IF EXISTS temp_dates;
  DROP TABLE IF EXISTS temp_meals;

  PERFORM public.create_batch_sessions_internal(v_plan_id, p_user_id, 7);
  PERFORM public.generate_shopping_list_internal(v_plan_id, p_user_id);

END;
$function$;

REVOKE ALL ON FUNCTION public.generate_meal_plan_from_saved(uuid, integer, integer, date, integer) FROM PUBLIC;
REVOKE ALL ON FUNCTION public.generate_meal_plan_from_saved(uuid, integer, integer, date, integer) FROM anon;
REVOKE ALL ON FUNCTION public.generate_meal_plan_from_saved(uuid, integer, integer, date, integer) FROM authenticated;
```

- [ ] **Step 4: Run the test suite and verify Tests 1-3b pass, 6-10 still fail as expected**

Run: `cd "c:/Users/DELL LATITUDE 7480/akeli-nutrition-app" && supabase db reset && supabase test db`

Expected: Tests 1, 2, 3 (already passing, unaffected) and **Test 3b now flips from FAIL to PASS** — confirming the precheck causes Pass 1 to be skipped entirely for the 5-recipe pool, so Pass 2's unfiltered scoring reuses recipe A. Tests 6 through 10 (eligibility/trigger behavior) still FAIL — they depend on Tasks 2 and 3, not yet written. Confirm no *other* test file in the suite regressed (compare the total pass count against the pre-existing baseline recorded in Step 2).

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260705000002_saved_recipe_variety_eligibility.sql supabase/tests/database/saved_recipe_eligibility.test.sql
git commit -m "feat(db): skip recency blacklist per meal type when saved pool is too small"
```

---

### Task 2: Dynamic eligibility threshold formula

**Files:**
- Modify: `supabase/migrations/20260705000002_saved_recipe_variety_eligibility.sql` (append — do not touch the function from Task 1)

**Interfaces:**
- Consumes: existing `public.evaluate_saved_recipe_eligibility(uuid)` and `public.get_saved_recipe_eligibility_progress(uuid)` as defined in `supabase/migrations/20260617085800_saved_recipes_eligibility.sql`.
- Produces: same signatures. `evaluate_saved_recipe_eligibility` still sets `user_profile.is_saved_recipe_eligible` and force-disables `use_saved_recipes_only` on regression — Task 3's triggers call this function by name, so the signature `evaluate_saved_recipe_eligibility(p_user_id uuid) RETURNS void` must not change.

- [ ] **Step 1: Run the existing tests to confirm Test 6/7 fail for the expected reason**

Run: `cd "c:/Users/DELL LATITUDE 7480/akeli-nutrition-app" && supabase test db`

Expected: Test 6 ("10 saved recipes/type at variety_days=7 (target 14) is NOT eligible") currently FAILS because `evaluate_saved_recipe_eligibility` still uses the hardcoded threshold of 7 — with 10 saved recipes and a target of 7, today's code marks the user eligible (`10 >= 7`), so `is_saved_recipe_eligible` comes back `true`, not the expected `false`.

- [ ] **Step 2: Append the updated functions to the migration file**

Append to `supabase/migrations/20260705000002_saved_recipe_variety_eligibility.sql`:

```sql

-- ─────────────────────────────────────────────────────────────────────────────
-- Part 2: couple the eligibility threshold to meal_variety_days.
-- 0 -> 7 (unchanged baseline), 7 -> 14, 15 -> 30.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.evaluate_saved_recipe_eligibility(p_user_id uuid)
RETURNS void
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_breakfast_count int;
  v_lunch_count int;
  v_dinner_count int;
  v_was_eligible boolean;
  v_now_eligible boolean;
  v_variety_days int;
  v_target_count int;
BEGIN
  SELECT is_saved_recipe_eligible, COALESCE(meal_variety_days, 7)
  INTO v_was_eligible, v_variety_days
  FROM user_profile WHERE id = p_user_id;

  v_target_count := CASE WHEN v_variety_days = 0 THEN 7 ELSE v_variety_days * 2 END;

  SELECT count(*) INTO v_breakfast_count
  FROM recipe_save rs
  JOIN recipe r ON r.id = rs.recipe_id
  WHERE rs.user_id = p_user_id AND 'breakfast' = ANY(r.meal_types);

  SELECT count(*) INTO v_lunch_count
  FROM recipe_save rs
  JOIN recipe r ON r.id = rs.recipe_id
  WHERE rs.user_id = p_user_id AND 'lunch' = ANY(r.meal_types);

  SELECT count(*) INTO v_dinner_count
  FROM recipe_save rs
  JOIN recipe r ON r.id = rs.recipe_id
  WHERE rs.user_id = p_user_id AND 'dinner' = ANY(r.meal_types);

  IF v_breakfast_count >= v_target_count AND v_lunch_count >= v_target_count AND v_dinner_count >= v_target_count THEN
    v_now_eligible := true;
  ELSE
    v_now_eligible := false;
  END IF;

  IF v_now_eligible != COALESCE(v_was_eligible, false) THEN
    IF v_now_eligible = false THEN
      UPDATE user_profile
      SET is_saved_recipe_eligible = false, use_saved_recipes_only = false
      WHERE id = p_user_id;
    ELSE
      UPDATE user_profile
      SET is_saved_recipe_eligible = true
      WHERE id = p_user_id;
    END IF;
  END IF;
END;
$$;

DROP FUNCTION IF EXISTS public.get_saved_recipe_eligibility_progress(uuid);

CREATE OR REPLACE FUNCTION public.get_saved_recipe_eligibility_progress(p_user_id uuid)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_breakfast_count int;
  v_lunch_count int;
  v_dinner_count int;
  v_is_eligible boolean;
  v_variety_days int;
  v_target_count int;
BEGIN
  IF p_user_id IS DISTINCT FROM auth.uid() THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  SELECT is_saved_recipe_eligible, COALESCE(meal_variety_days, 7)
  INTO v_is_eligible, v_variety_days
  FROM user_profile WHERE id = p_user_id;

  v_target_count := CASE WHEN v_variety_days = 0 THEN 7 ELSE v_variety_days * 2 END;

  SELECT count(*) INTO v_breakfast_count
  FROM recipe_save rs
  JOIN recipe r ON r.id = rs.recipe_id
  WHERE rs.user_id = p_user_id AND 'breakfast' = ANY(r.meal_types);

  SELECT count(*) INTO v_lunch_count
  FROM recipe_save rs
  JOIN recipe r ON r.id = rs.recipe_id
  WHERE rs.user_id = p_user_id AND 'lunch' = ANY(r.meal_types);

  SELECT count(*) INTO v_dinner_count
  FROM recipe_save rs
  JOIN recipe r ON r.id = rs.recipe_id
  WHERE rs.user_id = p_user_id AND 'dinner' = ANY(r.meal_types);

  RETURN json_build_object(
    'is_eligible', COALESCE(v_is_eligible, false),
    'progress', json_build_array(
      json_build_object('meal_type', 'breakfast', 'saved_count', v_breakfast_count, 'target_count', v_target_count),
      json_build_object('meal_type', 'lunch', 'saved_count', v_lunch_count, 'target_count', v_target_count),
      json_build_object('meal_type', 'dinner', 'saved_count', v_dinner_count, 'target_count', v_target_count)
    )
  );
END;
$$;

REVOKE ALL ON FUNCTION get_saved_recipe_eligibility_progress(uuid) FROM PUBLIC;
REVOKE ALL ON FUNCTION get_saved_recipe_eligibility_progress(uuid) FROM anon;
GRANT EXECUTE ON FUNCTION get_saved_recipe_eligibility_progress(uuid) TO authenticated;
```

- [ ] **Step 3: Run the test suite and verify Tests 6/7 pass, 8-10 still fail as expected**

Run: `cd "c:/Users/DELL LATITUDE 7480/akeli-nutrition-app" && supabase db reset && supabase test db`

Expected: Tests 1, 2, 3, 3b, 4, 5, 6, 7 all PASS. Tests 8, 9, 10 still FAIL — they depend on the two new triggers from Task 3.

- [ ] **Step 4: Commit**

```bash
git add supabase/migrations/20260705000002_saved_recipe_variety_eligibility.sql
git commit -m "feat(db): couple saved-recipe eligibility threshold to meal_variety_days"
```

---

### Task 3: DB triggers (variety-change re-evaluation + write guard) and backfill

**Files:**
- Modify: `supabase/migrations/20260705000002_saved_recipe_variety_eligibility.sql` (append)

**Interfaces:**
- Consumes: `public.evaluate_saved_recipe_eligibility(uuid)` from Task 2.
- Produces: two new trigger functions (`trg_fn_evaluate_saved_recipe_eligibility_on_variety_change`, `trg_fn_guard_use_saved_recipes_only`) and their triggers on `public.user_profile`. No later task depends on their names directly (they're DB-internal), but Task 6/7's Dart SnackBar copy describes the behavior these triggers perform, so the behavior itself must match what's documented there.

- [ ] **Step 1: Confirm Tests 8-10 currently fail for the expected reason**

Run: `cd "c:/Users/DELL LATITUDE 7480/akeli-nutrition-app" && supabase test db`

Expected: Test 8 fails because updating `meal_variety_days` alone does nothing today (no trigger re-evaluates eligibility), so `is_saved_recipe_eligible` stays `true` from Test 7 instead of flipping to `false`. Test 9 fails for the same reason (`use_saved_recipes_only` stays `true`). Test 10 fails because nothing currently stops a direct `UPDATE ... SET use_saved_recipes_only = true`.

- [ ] **Step 2: Append the triggers and backfill to the migration file**

Append to `supabase/migrations/20260705000002_saved_recipe_variety_eligibility.sql`:

```sql

-- ─────────────────────────────────────────────────────────────────────────────
-- Part 4a: re-evaluate eligibility live when meal_variety_days changes.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.trg_fn_evaluate_saved_recipe_eligibility_on_variety_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM public.evaluate_saved_recipe_eligibility(NEW.id);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_evaluate_saved_recipe_eligibility_on_variety_change ON public.user_profile;
CREATE TRIGGER trg_evaluate_saved_recipe_eligibility_on_variety_change
  AFTER UPDATE OF meal_variety_days ON public.user_profile
  FOR EACH ROW
  WHEN (OLD.meal_variety_days IS DISTINCT FROM NEW.meal_variety_days)
  EXECUTE FUNCTION public.trg_fn_evaluate_saved_recipe_eligibility_on_variety_change();

-- ─────────────────────────────────────────────────────────────────────────────
-- Part 4b: security backstop — silently revert any attempt to set
-- use_saved_recipes_only=true while ineligible, regardless of which client
-- or code path performed the write.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION public.trg_fn_guard_use_saved_recipes_only()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF NEW.use_saved_recipes_only = true AND COALESCE(NEW.is_saved_recipe_eligible, false) = false THEN
    NEW.use_saved_recipes_only := false;
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_guard_use_saved_recipes_only ON public.user_profile;
CREATE TRIGGER trg_guard_use_saved_recipes_only
  BEFORE UPDATE OF use_saved_recipes_only ON public.user_profile
  FOR EACH ROW
  EXECUTE FUNCTION public.trg_fn_guard_use_saved_recipes_only();

-- ─────────────────────────────────────────────────────────────────────────────
-- Part 4c: backfill — apply the new (higher) thresholds to existing rows now,
-- rather than waiting for each user's next recipe-save or variety-day change.
-- Known, accepted effect: some users eligible today under the old threshold
-- of 7 will become ineligible immediately (e.g. exactly 7 saved recipes/type
-- at meal_variety_days=7, old target 7, new target 14), and if
-- use_saved_recipes_only was on, it will be force-disabled — identical to
-- what happens today when a user unsaves a recipe below threshold.
-- ─────────────────────────────────────────────────────────────────────────────

DO $$
DECLARE
  v_row record;
BEGIN
  FOR v_row IN SELECT id FROM public.user_profile LOOP
    PERFORM public.evaluate_saved_recipe_eligibility(v_row.id);
  END LOOP;
END;
$$;
```

- [ ] **Step 3: Run the full test suite and verify all 11 tests pass**

Run: `cd "c:/Users/DELL LATITUDE 7480/akeli-nutrition-app" && supabase db reset && supabase test db`

Expected: `Files=<N>, Tests=<M+11>, Result: PASS` where `<N>`/`<M>` are the pre-existing file/test counts before this plan started (check the output of the very first `supabase test db` run in Task 1 Step 2 for the baseline). All 11 assertions in `saved_recipe_eligibility.test.sql` pass, and no other test file regresses.

- [ ] **Step 4: Manually verify the backfill against a realistic existing row**

Run (adjust the UUID to a real seeded test user from the local dataset, e.g. `aa000001-0000-4000-8000-000000000001` from the standard local test fixture — see `docs/meal_plan_test_results.md`):

```bash
docker exec supabase_db_akeli_nutrition_app psql -U postgres -d postgres -c "SELECT id, meal_variety_days, is_saved_recipe_eligible, use_saved_recipes_only FROM user_profile WHERE id = 'aa000001-0000-4000-8000-000000000001';"
```

Expected: the row reflects the new formula (target `14` at `meal_variety_days=7`) rather than the old hardcoded `7` — confirms the backfill ran during `supabase db reset` and the column values are self-consistent (`is_saved_recipe_eligible=false` implies `use_saved_recipes_only=false`).

- [ ] **Step 5: Commit**

```bash
git add supabase/migrations/20260705000002_saved_recipe_variety_eligibility.sql
git commit -m "feat(db): add triggers to keep saved-recipe eligibility in sync and guard direct writes"
```

---

### Task 4: Shared Dart eligibility formula

**Files:**
- Create: `lib/core/saved_recipe_eligibility.dart`
- Test: `test/core/saved_recipe_eligibility_test.dart`

**Interfaces:**
- Produces: `int savedRecipeEligibilityTarget(int mealVarietyDays)` — pure function, no side effects. Tasks 6 and 7 import and call this directly.

- [ ] **Step 1: Write the failing test**

Create `test/core/saved_recipe_eligibility_test.dart`:

```dart
// test/core/saved_recipe_eligibility_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:akeli/core/saved_recipe_eligibility.dart';

void main() {
  group('savedRecipeEligibilityTarget', () {
    test('variety off (0) returns the baseline floor of 7', () {
      expect(savedRecipeEligibilityTarget(0), 7);
    });
    test('7-day variety returns 14', () {
      expect(savedRecipeEligibilityTarget(7), 14);
    });
    test('15-day variety returns 30', () {
      expect(savedRecipeEligibilityTarget(15), 30);
    });
  });
}
```

- [ ] **Step 2: Run the test to verify it fails**

Run: `cd "c:/Users/DELL LATITUDE 7480/akeli-nutrition-app" && flutter test test/core/saved_recipe_eligibility_test.dart`

Expected: FAIL — `Error: Not found: 'package:akeli/core/saved_recipe_eligibility.dart'` (the file doesn't exist yet).

- [ ] **Step 3: Write the implementation**

Create `lib/core/saved_recipe_eligibility.dart`:

```dart
// lib/core/saved_recipe_eligibility.dart
import 'package:akeli/core/logger.dart';

final _logger = appLogger;

/// Mirrors the SQL formula in evaluate_saved_recipe_eligibility /
/// get_saved_recipe_eligibility_progress (supabase/migrations/
/// 20260705000002_saved_recipe_variety_eligibility.sql). Keep both in sync
/// by hand if this formula ever changes.
int savedRecipeEligibilityTarget(int mealVarietyDays) {
  final target = mealVarietyDays == 0 ? 7 : mealVarietyDays * 2;
  _logger.d('savedRecipeEligibilityTarget | varietyDays: $mealVarietyDays -> target: $target');
  return target;
}
```

- [ ] **Step 4: Run the test to verify it passes**

Run: `cd "c:/Users/DELL LATITUDE 7480/akeli-nutrition-app" && flutter test test/core/saved_recipe_eligibility_test.dart`

Expected: `00:0X +3: All tests passed!`

- [ ] **Step 5: Commit**

```bash
git add lib/core/saved_recipe_eligibility.dart test/core/saved_recipe_eligibility_test.dart
git commit -m "feat(core): add Dart mirror of the saved-recipe eligibility threshold formula"
```

---

### Task 5: ARB strings for the eligibility/variety copy

**Files:**
- Modify: `lib/l10n/app_en.arb`
- Modify: `lib/l10n/app_fr.arb`

**Interfaces:**
- Produces: `AppLocalizations.savedRecipesEligibilityBlocked(int target)` (changed from a no-argument getter to a method taking `target`), `AppLocalizations.savedRecipesEligibilityShortfallToast(String mealType, int needed, int saved, int target)`, `AppLocalizations.mealScheduleVarietyDisablesSavedOnly(int days)`. Tasks 6 and 7 call these three.

- [ ] **Step 1: Update `savedRecipesEligibilityBlocked` and add the two new keys in `app_en.arb`**

In `lib/l10n/app_en.arb`, replace the existing entry:

```json
  "savedRecipesEligibilityBlocked": "Locked: You must reach 7 recipes for each category above.",
  "@savedRecipesEligibilityBlocked": {},
```

with:

```json
  "savedRecipesEligibilityBlocked": "Locked: You need at least {target} recipes for each category above.",
  "@savedRecipesEligibilityBlocked": {
    "placeholders": { "target": { "type": "int" } }
  },

  "savedRecipesEligibilityShortfallToast": "{mealType}: save {needed} more (currently {saved}/{target})",
  "@savedRecipesEligibilityShortfallToast": {
    "placeholders": {
      "mealType": { "type": "String" },
      "needed": { "type": "int" },
      "saved": { "type": "int" },
      "target": { "type": "int" }
    }
  },
```

- [ ] **Step 2: Add `mealScheduleVarietyDisablesSavedOnly` in `app_en.arb`**

In `lib/l10n/app_en.arb`, after the existing `mealScheduleVariety15Days` entry:

```json
  "mealScheduleVariety15Days": "15 days",
  "@mealScheduleVariety15Days": {},
```

insert:

```json
  "mealScheduleVariety15Days": "15 days",
  "@mealScheduleVariety15Days": {},
  "mealScheduleVarietyDisablesSavedOnly": "Switching to {days}-day variety will turn off \"use only saved recipes\" — you don't have enough saved recipes for this level of variety.",
  "@mealScheduleVarietyDisablesSavedOnly": {
    "placeholders": { "days": { "type": "int" } }
  },
```

- [ ] **Step 3: Mirror all three keys in `app_fr.arb`**

In `lib/l10n/app_fr.arb`, replace:

```json
  "savedRecipesEligibilityBlocked": "Bloqué: Vous devez atteindre 7 recettes pour chaque catégorie ci-dessus.",
```

with:

```json
  "savedRecipesEligibilityBlocked": "Bloqué : vous devez atteindre {target} recettes pour chaque catégorie ci-dessus.",
  "savedRecipesEligibilityShortfallToast": "{mealType} : enregistrez {needed} recette(s) de plus (actuellement {saved}/{target})",
```

Then find the `mealScheduleVariety15Days` entry in `app_fr.arb` and insert after it:

```json
  "mealScheduleVarietyDisablesSavedOnly": "Passer à une variété de {days} jours désactivera « utiliser uniquement les favoris » — vous n'avez pas assez de recettes enregistrées pour ce niveau de variété.",
```

- [ ] **Step 4: Regenerate localizations**

Run: `cd "c:/Users/DELL LATITUDE 7480/akeli-nutrition-app" && flutter gen-l10n`

Expected: completes with no errors. Verify: `grep -n "savedRecipesEligibilityShortfallToast\|mealScheduleVarietyDisablesSavedOnly" lib/l10n/app_localizations_en.dart` returns matches (confirms the generator picked up the new keys).

- [ ] **Step 5: Run static analysis to confirm no ARB/codegen errors**

Run: `cd "c:/Users/DELL LATITUDE 7480/akeli-nutrition-app" && flutter analyze lib/l10n`

Expected: `No issues found!`

- [ ] **Step 6: Commit**

```bash
git add lib/l10n/app_en.arb lib/l10n/app_fr.arb lib/l10n/app_localizations*.dart
git commit -m "feat(l10n): add variety-aware saved-recipe eligibility copy"
```

---

### Task 6: `SavedRecipesEligibilityPage` — derive eligibility from counts, add shortfall SnackBar

**Files:**
- Modify: `lib/features/settings/saved_recipes_eligibility_page.dart`

**Interfaces:**
- Consumes: `savedRecipeEligibilityTarget()` (unused directly here — the page already gets per-meal-type `targetCount` from `SavedRecipeProgressModel.progress`, produced server-side by Task 2's `get_saved_recipe_eligibility_progress`), `MealTypeProgress` (`mealType`, `savedCount`, `targetCount`) from `lib/features/settings/models/saved_recipe_progress_model.dart` (unchanged), `mealTypeLabel(AppLocalizations, String)` from `lib/core/meal_type_l10n.dart`.
- Produces: no new public interface — this is a leaf page widget.

- [ ] **Step 1: Read the current file to confirm line numbers before editing**

Run: `grep -n "isEligible\|savedRecipesEligibilityBlocked\|SwitchListTile" "lib/features/settings/saved_recipes_eligibility_page.dart"`

Expected output includes (from the current file, confirmed during planning):
```
91:          final isEligible = progressData.isEligible;
230:                      Container(
...
233:                                isEligible
234:                                    ? l10n.savedRecipesEligibilityEnabled
235:                                    : l10n.savedRecipesEligibilityBlocked,
...
238:                          onChanged: isEligible
```

- [ ] **Step 2: Derive `isEligible` from per-meal-type counts instead of the server flag**

In `lib/features/settings/saved_recipes_eligibility_page.dart`, replace:

```dart
          final isEligible = progressData.isEligible;
```

with:

```dart
          final isEligible = progressData.progress.isNotEmpty &&
              progressData.progress.every((p) => p.savedCount >= p.targetCount);
          final currentTarget = progressData.progress.isNotEmpty
              ? progressData.progress.first.targetCount
              : 7;
```

- [ ] **Step 3: Parametrize the blocked message and add the tap-to-explain SnackBar**

Replace the `Container` wrapping the `SwitchListTile` (the block starting at the original line 224 `Container(` through its closing and the `SwitchListTile`'s closing):

```dart
                      Container(
                        decoration: BoxDecoration(
                          color: AkeliColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AkeliColors.surfaceContainerHighest),
                        ),
                        child: SwitchListTile(
                          title: Text(l10n.savedRecipesEligibilityToggleTitle),
                          subtitle: Text(
                            isEligible
                                ? l10n.savedRecipesEligibilityEnabled
                                : l10n.savedRecipesEligibilityBlocked,
                          ),
                          value: prefs.useSavedRecipesOnly,
                          onChanged: isEligible
                              ? (val) async {
                                  final updated = prefs.copyWith(useSavedRecipesOnly: val);
                                  await ref.read(userPreferencesProvider.notifier).save(updated);
                                }
                              : null,
                          activeThumbColor: AkeliColors.primary,
                          inactiveThumbColor: Colors.white,
                        ),
                      ),
```

with:

```dart
                      GestureDetector(
                        onTap: isEligible
                            ? null
                            : () {
                                final shortfalls = progressData.progress
                                    .where((p) => p.savedCount < p.targetCount)
                                    .toList();
                                appLogger.userAction(
                                    'Saved-recipes toggle tapped while ineligible',
                                    screen: 'SavedRecipesEligibilityPage',
                                    metadata: {
                                      'shortfallCount': shortfalls.length.toString(),
                                    });
                                final message = shortfalls
                                    .map((p) => l10n.savedRecipesEligibilityShortfallToast(
                                          mealTypeLabel(l10n, p.mealType),
                                          p.targetCount - p.savedCount,
                                          p.savedCount,
                                          p.targetCount,
                                        ))
                                    .join('\n');
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(message)),
                                );
                              },
                        child: Container(
                          decoration: BoxDecoration(
                            color: AkeliColors.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AkeliColors.surfaceContainerHighest),
                          ),
                          child: SwitchListTile(
                            title: Text(l10n.savedRecipesEligibilityToggleTitle),
                            subtitle: Text(
                              isEligible
                                  ? l10n.savedRecipesEligibilityEnabled
                                  : l10n.savedRecipesEligibilityBlocked(currentTarget),
                            ),
                            value: prefs.useSavedRecipesOnly,
                            onChanged: isEligible
                                ? (val) async {
                                    final updated = prefs.copyWith(useSavedRecipesOnly: val);
                                    await ref.read(userPreferencesProvider.notifier).save(updated);
                                  }
                                : null,
                            activeThumbColor: AkeliColors.primary,
                            inactiveThumbColor: Colors.white,
                          ),
                        ),
                      ),
```

- [ ] **Step 4: Add the `meal_type_l10n.dart` import**

At the top of `lib/features/settings/saved_recipes_eligibility_page.dart`, add alongside the existing imports:

```dart
import '../../core/meal_type_l10n.dart';
```

- [ ] **Step 5: Run static analysis**

Run: `cd "c:/Users/DELL LATITUDE 7480/akeli-nutrition-app" && flutter analyze lib/features/settings/saved_recipes_eligibility_page.dart`

Expected: `No issues found!`

- [ ] **Step 6: Manually verify in the running app**

Run: `flutter run -d <device>` (or use the project's `run` skill if available), sign in as a test user with fewer than the required saved recipes, and navigate to the saved-recipes eligibility settings page. Confirm: the "locked" subtitle shows the correct numeric target (not a hardcoded "7"), and tapping the disabled switch shows a SnackBar listing which meal type(s) are short and by how much.

- [ ] **Step 7: Commit**

```bash
git add lib/features/settings/saved_recipes_eligibility_page.dart
git commit -m "feat(settings): derive saved-recipe eligibility from live counts and explain why it's locked"
```

---

### Task 7: `MealSchedulePage` variety chips — SnackBar warning + provider invalidation

**Files:**
- Modify: `lib/features/settings/meal_schedule_page.dart`
- Modify: `lib/providers/user_profile_provider.dart:358-372` (`setMealVarietyDaysProvider`)

**Interfaces:**
- Consumes: `savedRecipeEligibilityTarget()` from Task 4, `savedRecipeProgressProvider` from `lib/providers/saved_recipe_progress_provider.dart` (existing, unchanged — returns `AsyncValue<SavedRecipeProgressModel?>`), `userPreferencesProvider` from `lib/providers/user_preferences_provider.dart` (existing, unchanged — exposes `UserPreferencesModel.useSavedRecipesOnly`).
- Produces: no new public interface.

- [ ] **Step 1: Add the invalidation to `setMealVarietyDaysProvider`**

In `lib/providers/user_profile_provider.dart`, replace:

```dart
    await client
        .from('user_profile')
        .update({'meal_variety_days': args.days})
        .eq('id', args.userId);
    appLogger.db('AFTER | table: user_profile | op: UPDATE | success');
    ref.invalidate(userProfileProvider);
```

with:

```dart
    await client
        .from('user_profile')
        .update({'meal_variety_days': args.days})
        .eq('id', args.userId);
    appLogger.db('AFTER | table: user_profile | op: UPDATE | success');
    ref.invalidate(userProfileProvider);
    ref.invalidate(savedRecipeProgressProvider);
```

Add the import at the top of `lib/providers/user_profile_provider.dart`, alongside the existing imports:

```dart
import 'saved_recipe_progress_provider.dart';
```

- [ ] **Step 2: Add the SnackBar warning to `_VarietySection`**

In `lib/features/settings/meal_schedule_page.dart`, replace the `_VarietySection` class body:

```dart
class _VarietySection extends ConsumerWidget {
  final int current;
  final String? profileId;

  const _VarietySection({required this.current, required this.profileId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final options = [
      (0,  l10n.mealScheduleVarietyNone),
      (7,  l10n.mealScheduleVariety7Days),
      (15, l10n.mealScheduleVariety15Days),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.mealScheduleVarietyTitle,
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(l10n.mealScheduleVarietySubtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AkeliColors.onSurfaceVariant)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: options.map((opt) {
            final (days, label) = opt;
            final selected = current == days;
            return ChoiceChip(
              label: Text(label),
              selected: selected,
              onSelected: (_) {
                if (profileId == null || selected) return;
                appLogger.userAction(
                    'MealSchedulePage variety chip tapped',
                    screen: 'MealSchedulePage',
                    metadata: {'days': days.toString()});
                ref.read(setMealVarietyDaysProvider(
                        (userId: profileId!, days: days))
                    .future);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
```

with:

```dart
class _VarietySection extends ConsumerWidget {
  final int current;
  final String? profileId;

  const _VarietySection({required this.current, required this.profileId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final options = [
      (0,  l10n.mealScheduleVarietyNone),
      (7,  l10n.mealScheduleVariety7Days),
      (15, l10n.mealScheduleVariety15Days),
    ];

    final useSavedRecipesOnly =
        ref.watch(userPreferencesProvider).valueOrNull?.useSavedRecipesOnly ?? false;
    final savedProgress = ref.watch(savedRecipeProgressProvider).valueOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.mealScheduleVarietyTitle,
            style: Theme.of(context).textTheme.titleSmall),
        const SizedBox(height: 4),
        Text(l10n.mealScheduleVarietySubtitle,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AkeliColors.onSurfaceVariant)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: options.map((opt) {
            final (days, label) = opt;
            final selected = current == days;
            return ChoiceChip(
              label: Text(label),
              selected: selected,
              onSelected: (_) {
                if (profileId == null || selected) return;
                appLogger.userAction(
                    'MealSchedulePage variety chip tapped',
                    screen: 'MealSchedulePage',
                    metadata: {'days': days.toString()});

                if (useSavedRecipesOnly && savedProgress != null) {
                  final target = savedRecipeEligibilityTarget(days);
                  final wouldBreak = savedProgress.progress
                      .any((p) => p.savedCount < target);
                  if (wouldBreak) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          l10n.mealScheduleVarietyDisablesSavedOnly(days),
                        ),
                      ),
                    );
                  }
                }

                ref.read(setMealVarietyDaysProvider(
                        (userId: profileId!, days: days))
                    .future);
              },
            );
          }).toList(),
        ),
      ],
    );
  }
}
```

- [ ] **Step 3: Add the two new imports to `meal_schedule_page.dart`**

At the top of `lib/features/settings/meal_schedule_page.dart`, add alongside the existing imports:

```dart
import 'package:akeli/core/saved_recipe_eligibility.dart';
import 'package:akeli/providers/saved_recipe_progress_provider.dart';
import 'package:akeli/providers/user_preferences_provider.dart';
```

- [ ] **Step 4: Run static analysis**

Run: `cd "c:/Users/DELL LATITUDE 7480/akeli-nutrition-app" && flutter analyze lib/features/settings/meal_schedule_page.dart lib/providers/user_profile_provider.dart`

Expected: `No issues found!`

- [ ] **Step 5: Manually verify in the running app**

Sign in as a test user with `use_saved_recipes_only=true` and a saved-recipe pool just barely meeting the 7-day target (14/type). Open meal schedule settings and tap the "15 days" variety chip. Confirm: a SnackBar appears explaining that saved-only mode will turn off, the chip selection still updates, and navigating to the saved-recipes eligibility page afterward shows the toggle now disabled with updated (30) target counts — not stale (14) ones.

- [ ] **Step 6: Commit**

```bash
git add lib/features/settings/meal_schedule_page.dart lib/providers/user_profile_provider.dart
git commit -m "feat(settings): warn before a variety change disables saved-recipes-only mode"
```

---

## Self-Review Notes

**Spec coverage:** Part 1 (generator precheck) → Task 1. Part 2 (threshold formula) → Task 2. Part 3 (Dart proactive UI: formula mirror, SavedRecipesEligibilityPage, MealSchedulePage, provider invalidation) → Tasks 4, 5, 6, 7. Part 4 (DB triggers + backfill) → Task 3. Out-of-scope items (snack generalization, `generate_meal_plan`/`generate_meal_plan_internal` changes, blocking confirmation dialogs, changing allowed `meal_variety_days` values) are intentionally not covered by any task.

**Type/name consistency check:** `savedRecipeEligibilityTarget(int) -> int` (Task 4) is called identically in Task 7's `_VarietySection`. `MealTypeProgress.mealType/savedCount/targetCount` (existing model, unchanged) is used consistently in Tasks 6 and 7. `SavedRecipeProgressModel.progress` (existing, unchanged) is used in both. `l10n.savedRecipesEligibilityBlocked` changes from a getter to a one-argument method between Task 5 (ARB) and Task 6 (usage) — consistent. `l10n.savedRecipesEligibilityShortfallToast(mealType, needed, saved, target)` and `l10n.mealScheduleVarietyDisablesSavedOnly(days)` argument order/types match between Task 5's ARB placeholders and Tasks 6/7's call sites.
