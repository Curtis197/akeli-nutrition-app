-- supabase/tests/beauty_plan_from_saved_monthly_tiers_test.sql
BEGIN;
SELECT plan(6);

INSERT INTO auth.users (id, email, role, created_at, updated_at) VALUES
  ('b7000001-0000-0000-0000-000000000001', 'beautysaved.user@akeli.test', 'authenticated', now(), now())
ON CONFLICT (id) DO NOTHING;

INSERT INTO user_profile (id, onboarding_done, is_creator, created_at, locale) VALUES
  ('b7000001-0000-0000-0000-000000000001', true, false, now(), 'fr')
ON CONFLICT (id) DO NOTHING;

-- Three synthetic published recipes to act as the saved pool
INSERT INTO recipe (id, title, instructions, is_published, mode, beauty_type, beauty_sub_type, frequency, created_at) VALUES
  ('b7000001-0000-0000-0000-000000000010', 'Saved Recipe Daily', 'Steps.', true, 'beauty', 'both', 'daily_hydration', 'daily', now()),
  ('b7000001-0000-0000-0000-000000000011', 'Saved Recipe 2x Month', 'Steps.', true, 'beauty', 'both', 'protein_clarifying_care', '2x_month', now()),
  ('b7000001-0000-0000-0000-000000000012', 'Saved Recipe 1x Month', 'Steps.', true, 'beauty', 'both', 'monthly_detox_checkin', '1x_month', now())
ON CONFLICT (id) DO NOTHING;

INSERT INTO recipe_save (user_id, recipe_id) VALUES
  ('b7000001-0000-0000-0000-000000000001', 'b7000001-0000-0000-0000-000000000010'),
  ('b7000001-0000-0000-0000-000000000001', 'b7000001-0000-0000-0000-000000000011'),
  ('b7000001-0000-0000-0000-000000000001', 'b7000001-0000-0000-0000-000000000012')
ON CONFLICT DO NOTHING;

SET LOCAL "request.jwt.claims" TO '{"sub": "b7000001-0000-0000-0000-000000000001"}';

-- ── 3-Argument Overload (legacy signature without strict threshold checks) ───

SELECT lives_ok(
  $$ SELECT generate_beauty_plan_from_saved('b7000001-0000-0000-0000-000000000001'::uuid, CURRENT_DATE, 10) $$,
  'T1: 3-arg generate_beauty_plan_from_saved executes for a 10-day plan'
);

SELECT is(
  (SELECT count(*)::int FROM beauty_plan_slot bps
   JOIN beauty_plan bp ON bp.id = bps.plan_id
   WHERE bp.user_id = 'b7000001-0000-0000-0000-000000000001'
     AND bp.start_date = CURRENT_DATE
     AND bps.frequency_tier = '2x_month'),
  2,
  'T2: 3-arg variant now generates 2x_month slots (2 instances on a 10-day plan)'
);

SELECT is(
  (SELECT count(*)::int FROM beauty_plan_slot bps
   JOIN beauty_plan bp ON bp.id = bps.plan_id
   WHERE bp.user_id = 'b7000001-0000-0000-0000-000000000001'
     AND bp.start_date = CURRENT_DATE
     AND bps.frequency_tier = '1x_month'
     AND bps.recipe_id = 'b7000001-0000-0000-0000-000000000012'),
  1,
  'T3: 3-arg variant sources the 1x_month slot from the saved recipes pool'
);

-- Reset for next test
DELETE FROM beauty_plan WHERE user_id = 'b7000001-0000-0000-0000-000000000001';

-- ── 5-Argument Overload (newer signature with threshold limits) ──────────────

SELECT lives_ok(
  $$ SELECT generate_beauty_plan_from_saved('b7000001-0000-0000-0000-000000000001'::uuid, CURRENT_DATE, 10, 2, false) $$,
  'T4: 5-arg generate_beauty_plan_from_saved executes for a 10-day plan'
);

SELECT is(
  (SELECT count(*)::int FROM beauty_plan_slot bps
   JOIN beauty_plan bp ON bp.id = bps.plan_id
   WHERE bp.user_id = 'b7000001-0000-0000-0000-000000000001'
     AND bp.start_date = CURRENT_DATE
     AND bps.frequency_tier = '2x_month'),
  2,
  'T5: 5-arg variant now generates 2x_month slots (2 instances on a 10-day plan)'
);

SELECT is(
  (SELECT count(*)::int FROM beauty_plan_slot bps
   JOIN beauty_plan bp ON bp.id = bps.plan_id
   WHERE bp.user_id = 'b7000001-0000-0000-0000-000000000001'
     AND bp.start_date = CURRENT_DATE
     AND bps.frequency_tier = '1x_month'
     AND bps.recipe_id = 'b7000001-0000-0000-0000-000000000012'),
  1,
  'T6: 5-arg variant sources the 1x_month slot from the saved recipes pool'
);

SELECT * FROM finish();
ROLLBACK;
