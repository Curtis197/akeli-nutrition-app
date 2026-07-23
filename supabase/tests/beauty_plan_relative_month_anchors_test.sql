-- supabase/tests/beauty_plan_relative_month_anchors_test.sql
BEGIN;
SELECT plan(5);

INSERT INTO auth.users (id, email, role, created_at, updated_at) VALUES
  ('b5000001-0000-0000-0000-000000000001', 'beautyanchor.user@akeli.test', 'authenticated', now(), now())
ON CONFLICT (id) DO NOTHING;

INSERT INTO user_profile (id, onboarding_done, is_creator, created_at, locale) VALUES
  ('b5000001-0000-0000-0000-000000000001', true, false, now(), 'fr')
ON CONFLICT (id) DO NOTHING;

-- No synthetic recipes needed: the permanently-seeded starter pool already
-- has 2 '2x_month' and 1 '1x_month' published beauty recipes, which is
-- enough to satisfy p_limit => 1 for each tier.

SET LOCAL "request.jwt.claims" TO '{"sub": "b5000001-0000-0000-0000-000000000001"}';

-- A 10-day plan simulates a user onboarding with only 10 days left in the
-- month -- short enough that v_day_num (1..10) never reaches the
-- hardcoded 14/28 anchors.
SELECT lives_ok(
  $$ SELECT generate_beauty_plan('b5000001-0000-0000-0000-000000000001'::uuid, CURRENT_DATE, 10) $$,
  'T1: generate_beauty_plan executes for a 10-day partial-month plan'
);

SELECT is(
  (SELECT count(*)::int FROM beauty_plan_slot bps
   JOIN beauty_plan bp ON bp.id = bps.plan_id
   WHERE bp.user_id = 'b5000001-0000-0000-0000-000000000001'
     AND bp.start_date = CURRENT_DATE
     AND bps.frequency_tier = '2x_month'),
  2,
  'T2: a 10-day plan still gets 2 slots for the 2x_month tier'
);

SELECT is(
  (SELECT count(*)::int FROM beauty_plan_slot bps
   JOIN beauty_plan bp ON bp.id = bps.plan_id
   WHERE bp.user_id = 'b5000001-0000-0000-0000-000000000001'
     AND bp.start_date = CURRENT_DATE
     AND bps.frequency_tier = '1x_month'),
  1,
  'T3: a 10-day plan still gets 1 slot for the 1x_month tier'
);

SELECT is(
  (SELECT count(*)::int FROM beauty_plan_slot bps
   JOIN beauty_plan bp ON bp.id = bps.plan_id
   WHERE bp.user_id = 'b5000001-0000-0000-0000-000000000001'
     AND bp.start_date = CURRENT_DATE
     AND bps.day_number = 5
     AND bps.frequency_tier = '2x_month'),
  1,
  'T4: the first 2x_month anchor lands on day GREATEST(1, 10/2) = 5'
);

SELECT is(
  (SELECT count(*)::int FROM beauty_plan_slot bps
   JOIN beauty_plan bp ON bp.id = bps.plan_id
   WHERE bp.user_id = 'b5000001-0000-0000-0000-000000000001'
     AND bp.start_date = CURRENT_DATE
     AND bps.day_number = 10
     AND bps.frequency_tier = '1x_month'),
  1,
  'T5: the 1x_month anchor lands on the last day (10)'
);

SELECT * FROM finish();
ROLLBACK;
