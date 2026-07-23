-- supabase/tests/beauty_plan_full_fallback_coverage_test.sql
BEGIN;
SELECT plan(4);

INSERT INTO auth.users (id, email, role, created_at, updated_at) VALUES
  ('b6000001-0000-0000-0000-000000000001', 'beautyfallback.user@akeli.test', 'authenticated', now(), now())
ON CONFLICT (id) DO NOTHING;

INSERT INTO user_profile (id, onboarding_done, is_creator, created_at, locale) VALUES
  ('b6000001-0000-0000-0000-000000000001', true, false, now(), 'fr')
ON CONFLICT (id) DO NOTHING;

-- Temporarily mark ALL recipes as unpublished so recommend_recipes()
-- returns zero rows for every tier.
UPDATE recipe SET is_published = false;

SET LOCAL "request.jwt.claims" TO '{"sub": "b6000001-0000-0000-0000-000000000001"}';

-- Helper: next Sunday (so a 2-day plan hits Sun/Mon and exercises the 1x_week and daily branches)
CREATE OR REPLACE FUNCTION _test_b6_next_sunday()
RETURNS date LANGUAGE sql AS $$
  SELECT CURRENT_DATE + ((7 - EXTRACT(ISODOW FROM CURRENT_DATE)::int + 7) % 7);
$$;

SELECT lives_ok(
  $$ SELECT generate_beauty_plan('b6000001-0000-0000-0000-000000000001'::uuid, _test_b6_next_sunday(), 2) $$,
  'T1: generate_beauty_plan executes with zero available recipes without throwing "record v_rec is unassigned"'
);

-- Under the old logic, 'daily' and '1x_week' lacked the v_found fallback,
-- so zero rows returned by recommend_recipes meant the loop body never
-- ran, and nothing was inserted. With the fix, the fallback loop should
-- run and insert the fallback-mode recipes.
SELECT is(
  (SELECT count(*)::int FROM beauty_plan_slot bps
   JOIN beauty_plan bp ON bp.id = bps.plan_id
   WHERE bp.user_id = 'b6000001-0000-0000-0000-000000000001'
     AND bp.start_date = _test_b6_next_sunday()
     AND bps.frequency_tier = 'daily'),
  4, -- 2 slots/day * 2 days
  'T2: daily slots fall back to p_mode=>beauty if p_frequency=>daily is empty'
);

SELECT is(
  (SELECT count(*)::int FROM beauty_plan_slot bps
   JOIN beauty_plan bp ON bp.id = bps.plan_id
   WHERE bp.user_id = 'b6000001-0000-0000-0000-000000000001'
     AND bp.start_date = _test_b6_next_sunday()
     AND bps.frequency_tier = '1x_week'),
  2, -- 2 slots for the Sunday
  'T3: 1x_week slots fall back to p_mode=>beauty if p_frequency=>1x_week is empty'
);

SELECT is(
  (SELECT count(*)::int FROM beauty_plan_slot bps
   JOIN beauty_plan bp ON bp.id = bps.plan_id
   WHERE bp.user_id = 'b6000001-0000-0000-0000-000000000001'
     AND bp.start_date = _test_b6_next_sunday()
     AND bps.recipe_id IS NULL),
  0,
  'T4: no slots have a NULL recipe_id (fallback successfully pulled non-frequency recipes)'
);

SELECT * FROM finish();
ROLLBACK;
