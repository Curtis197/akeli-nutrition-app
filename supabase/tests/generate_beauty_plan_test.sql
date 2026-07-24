-- supabase/tests/generate_beauty_plan_test.sql
-- Beauty Mode Branch Review 2026-07-23, Area J, Finding #1(c): zero SQL/RPC
-- test coverage exists for generate_beauty_plan / the monthly plan generator.
-- Written against the FINAL corrected function from Area B Task 6
-- (supabase/migrations/20260722100500_beauty_plan_full_fallback_coverage.sql),
-- built on top of Area B Tasks 1, 4 and 5 (is_active column, p_frequency
-- passed on month-tier calls, and plan-length-relative month anchors).
--
-- PREREQUISITE: BLOCKED on Area B Tasks 1, 4, 5 and 6. Do not run this file
-- until all four of those migrations exist in supabase/migrations/ --
-- generate_beauty_plan will error with "column is_active does not exist"
-- (Task 1 missing) or insert a day-30 duplicate recipe under two frequency
-- tiers (Tasks 4/5 missing) otherwise.
--
-- No synthetic recipes are seeded here: the permanently-seeded starter
-- catalog (supabase/migrations/20260720000011, tagged by 20260721000001)
-- already ships 6 'daily', 7 '2x_week', 6 '1x_week', 2 '2x_month' and 1
-- '1x_month' published beauty recipes -- enough to generate a full 30-day
-- plan with zero fallback branches triggering.
BEGIN;
SELECT plan(8);

INSERT INTO auth.users (id, email, role, created_at, updated_at) VALUES
  ('a3000001-0000-0000-0000-000000000001', 'planintegrity.user@akeli.test', 'authenticated', now(), now())
ON CONFLICT (id) DO NOTHING;

INSERT INTO user_profile (id, onboarding_done, is_creator, created_at, locale) VALUES
  ('a3000001-0000-0000-0000-000000000001', true, false, now(), 'fr')
ON CONFLICT (id) DO NOTHING;

SET LOCAL "request.jwt.claims" TO '{"sub": "a3000001-0000-0000-0000-000000000001"}';

SELECT lives_ok(
  $$ SELECT generate_beauty_plan('a3000001-0000-0000-0000-000000000001'::uuid, CURRENT_DATE, 30) $$,
  'generate_beauty_plan executes for a full 30-day plan'
);

-- Every one of the 30 days has at least one slot.
SELECT is(
  (SELECT count(DISTINCT bps.day_number)::int
   FROM beauty_plan_slot bps
   JOIN beauty_plan bp ON bp.id = bps.plan_id
   WHERE bp.user_id = 'a3000001-0000-0000-0000-000000000001'
     AND bp.start_date = CURRENT_DATE),
  30,
  'all 30 days of the plan have at least one slot'
);

-- No (day_number, recipe_id) pair repeats -- the exact regression this
-- finding is about (2x_month/1x_month both landing the same top-1 recipe on
-- the same day under two different labels).
SELECT is(
  (SELECT count(*)::int FROM (
     SELECT bps.day_number, bps.recipe_id
     FROM beauty_plan_slot bps
     JOIN beauty_plan bp ON bp.id = bps.plan_id
     WHERE bp.user_id = 'a3000001-0000-0000-0000-000000000001'
       AND bp.start_date = CURRENT_DATE
     GROUP BY bps.day_number, bps.recipe_id
     HAVING count(*) > 1
   ) dupes),
  0,
  'no recipe_id is inserted twice for the same day_number anywhere in the plan'
);

-- Exactly 2 total 2x_month-tier slots across the whole plan (day 15 and day 30).
SELECT is(
  (SELECT count(*)::int FROM beauty_plan_slot bps
   JOIN beauty_plan bp ON bp.id = bps.plan_id
   WHERE bp.user_id = 'a3000001-0000-0000-0000-000000000001'
     AND bp.start_date = CURRENT_DATE
     AND bps.frequency_tier = '2x_month'),
  2,
  'exactly 2 total 2x_month-tier slots exist (anchors at day 15 and day 30)'
);

-- Exactly 1 total 1x_month-tier slot across the whole plan (day 30 only).
SELECT is(
  (SELECT count(*)::int FROM beauty_plan_slot bps
   JOIN beauty_plan bp ON bp.id = bps.plan_id
   WHERE bp.user_id = 'a3000001-0000-0000-0000-000000000001'
     AND bp.start_date = CURRENT_DATE
     AND bps.frequency_tier = '1x_month'),
  1,
  'exactly 1 total 1x_month-tier slot exists (anchor at day 30 only)'
);

-- Day 30 has exactly one 2x_month slot...
SELECT is(
  (SELECT count(*)::int FROM beauty_plan_slot bps
   JOIN beauty_plan bp ON bp.id = bps.plan_id
   WHERE bp.user_id = 'a3000001-0000-0000-0000-000000000001'
     AND bp.start_date = CURRENT_DATE
     AND bps.day_number = 30
     AND bps.frequency_tier = '2x_month'),
  1,
  'day 30 has exactly one 2x_month slot'
);

-- ...and exactly one 1x_month slot...
SELECT is(
  (SELECT count(*)::int FROM beauty_plan_slot bps
   JOIN beauty_plan bp ON bp.id = bps.plan_id
   WHERE bp.user_id = 'a3000001-0000-0000-0000-000000000001'
     AND bp.start_date = CURRENT_DATE
     AND bps.day_number = 30
     AND bps.frequency_tier = '1x_month'),
  1,
  'day 30 has exactly one 1x_month slot'
);

-- ...and those two same-day slots reference DIFFERENT recipes.
SELECT ok(
  (SELECT
     (SELECT bps.recipe_id FROM beauty_plan_slot bps JOIN beauty_plan bp ON bp.id = bps.plan_id
      WHERE bp.user_id = 'a3000001-0000-0000-0000-000000000001' AND bp.start_date = CURRENT_DATE
        AND bps.day_number = 30 AND bps.frequency_tier = '2x_month')
     IS DISTINCT FROM
     (SELECT bps.recipe_id FROM beauty_plan_slot bps JOIN beauty_plan bp ON bp.id = bps.plan_id
      WHERE bp.user_id = 'a3000001-0000-0000-0000-000000000001' AND bp.start_date = CURRENT_DATE
        AND bps.day_number = 30 AND bps.frequency_tier = '1x_month')
  ),
  'day 30''s 2x_month and 1x_month slots reference two different recipes, not a duplicate'
);

SELECT * FROM finish();
ROLLBACK;
