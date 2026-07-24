-- supabase/tests/beauty_plan_month_tier_frequency_test.sql
BEGIN;
SELECT plan(4);

INSERT INTO auth.users (id, email, role, created_at, updated_at) VALUES
  ('b4000001-0000-0000-0000-000000000001', 'beautymonth.user@akeli.test', 'authenticated', now(), now())
ON CONFLICT (id) DO NOTHING;

INSERT INTO user_profile (id, onboarding_done, is_creator, created_at, locale) VALUES
  ('b4000001-0000-0000-0000-000000000001', true, false, now(), 'fr')
ON CONFLICT (id) DO NOTHING;

-- Two synthetic recipes, each tagged with a DIFFERENT month-tier frequency,
-- created_at far in the future so each deterministically wins its own
-- frequency-filtered pool over the 2 pre-existing '2x_month' and 1
-- pre-existing '1x_month' starter recipes. recipe 0011's created_at is
-- later than 0010's, so with NO frequency filter at all (the pre-fix bug)
-- recommend_recipes(p_limit=>1, p_mode=>'beauty') deterministically
-- returns 0011 for every one of the three month-tier calls.
INSERT INTO recipe (id, title, is_published, mode, beauty_type, beauty_sub_type, frequency, created_at) VALUES
  ('b4000001-0000-0000-0000-000000000010', 'Test 2x Month Clarifying Treatment', true, 'beauty', 'both', 'protein_clarifying_care', '2x_month', '2099-01-01'::timestamptz),
  ('b4000001-0000-0000-0000-000000000011', 'Test 1x Month Detox Mask', true, 'beauty', 'both', 'monthly_detox_checkin', '1x_month', '2099-01-02'::timestamptz)
ON CONFLICT (id) DO NOTHING;

SET LOCAL "request.jwt.claims" TO '{"sub": "b4000001-0000-0000-0000-000000000001"}';

SELECT lives_ok(
  $$ SELECT generate_beauty_plan('b4000001-0000-0000-0000-000000000001'::uuid, CURRENT_DATE, 28) $$,
  'T1: generate_beauty_plan executes for a 28-day plan'
);

SELECT is(
  (SELECT count(*)::int FROM beauty_plan_slot bps
   JOIN beauty_plan bp ON bp.id = bps.plan_id
   WHERE bp.user_id = 'b4000001-0000-0000-0000-000000000001'
     AND bp.start_date = CURRENT_DATE
     AND bps.frequency_tier = '2x_month'
     AND bps.recipe_id = 'b4000001-0000-0000-0000-000000000010'),
  2,
  'T2: the 2x_month tier uses the recipe actually tagged 2x_month, on both anchor days'
);

SELECT is(
  (SELECT count(*)::int FROM beauty_plan_slot bps
   JOIN beauty_plan bp ON bp.id = bps.plan_id
   WHERE bp.user_id = 'b4000001-0000-0000-0000-000000000001'
     AND bp.start_date = CURRENT_DATE
     AND bps.frequency_tier = '1x_month'
     AND bps.recipe_id = 'b4000001-0000-0000-0000-000000000011'),
  1,
  'T3: the 1x_month tier uses the recipe actually tagged 1x_month'
);

SELECT is(
  (SELECT count(*)::int FROM beauty_plan_slot bps
   JOIN beauty_plan bp ON bp.id = bps.plan_id
   WHERE bp.user_id = 'b4000001-0000-0000-0000-000000000001'
     AND bp.start_date = CURRENT_DATE
     AND bps.frequency_tier = '2x_month'
     AND bps.recipe_id = 'b4000001-0000-0000-0000-000000000011'),
  0,
  'T4: the 2x_month tier no longer duplicates the 1x_month recipe'
);

SELECT * FROM finish();
ROLLBACK;
