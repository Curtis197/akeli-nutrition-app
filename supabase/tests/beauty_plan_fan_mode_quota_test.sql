-- supabase/tests/beauty_plan_fan_mode_quota_test.sql
BEGIN;
SELECT plan(4);

-- ── Seed: plan-owning user + 2 creator accounts ─────────────────────────────
INSERT INTO auth.users (id, email, role, created_at, updated_at) VALUES
  ('b3000001-0000-0000-0000-000000000001', 'beautyfan.user@akeli.test', 'authenticated', now(), now()),
  ('b3000001-0000-0000-0000-000000000002', 'beautyfan.owner1@akeli.test', 'authenticated', now(), now()),
  ('b3000001-0000-0000-0000-000000000003', 'beautyfan.owner2@akeli.test', 'authenticated', now(), now())
ON CONFLICT (id) DO NOTHING;

INSERT INTO user_profile (id, onboarding_done, is_creator, created_at, locale) VALUES
  ('b3000001-0000-0000-0000-000000000001', true, false, now(), 'fr'),
  ('b3000001-0000-0000-0000-000000000002', true, true, now(), 'fr'),
  ('b3000001-0000-0000-0000-000000000003', true, true, now(), 'fr')
ON CONFLICT (id) DO NOTHING;

INSERT INTO creator (id, user_id, display_name, created_at, updated_at) VALUES
  ('b3000001-0000-0000-0000-000000000004', 'b3000001-0000-0000-0000-000000000002', 'Fan Creator Test', now(), now()),
  ('b3000001-0000-0000-0000-000000000005', 'b3000001-0000-0000-0000-000000000003', 'Other Creator Test', now(), now())
ON CONFLICT (id) DO NOTHING;

INSERT INTO fan_subscription (user_id, creator_id, status, effective_from) VALUES
  ('b3000001-0000-0000-0000-000000000001', 'b3000001-0000-0000-0000-000000000004', 'active', CURRENT_DATE)
ON CONFLICT (user_id, status) DO NOTHING;

-- created_at far in the future so these two synthetic recipes always beat
-- the 6 permanently-seeded 'daily' starter recipes on the created_at DESC
-- tie-break inside recommend_recipes's no-vector branch.
INSERT INTO recipe (id, title, instructions, is_published, mode, beauty_type, beauty_sub_type, frequency, creator_id, created_at) VALUES
  ('b3000001-0000-0000-0000-000000000010', 'Fan Creator Daily Recipe', 'Steps.', true, 'beauty', 'both', 'daily_hydration', 'daily', 'b3000001-0000-0000-0000-000000000004', '2099-01-01'::timestamptz),
  ('b3000001-0000-0000-0000-000000000011', 'Other Creator Daily Recipe', 'Steps.', true, 'beauty', 'both', 'daily_hydration', 'daily', 'b3000001-0000-0000-0000-000000000005', '2099-01-02'::timestamptz)
ON CONFLICT (id) DO NOTHING;

-- Helper: next Monday on/after CURRENT_DATE, so a 2-day plan covers only
-- Mon+Tue (ISODOW 1,2) and never touches the 2x_week/1x_week/monthly
-- branches, keeping the daily-only math fully deterministic.
CREATE OR REPLACE FUNCTION _test_b3_next_monday()
RETURNS date LANGUAGE sql AS $$
  SELECT CURRENT_DATE + ((1 - EXTRACT(ISODOW FROM CURRENT_DATE)::int + 7) % 7);
$$;

SET LOCAL "request.jwt.claims" TO '{"sub": "b3000001-0000-0000-0000-000000000001"}';

-- Estimated total slots for a 2-day, no-weekly/no-monthly plan = 2*2 + 3 = 7
-- (see migration comment for the estimate formula) -> v_max_other_slots =
-- FLOOR(7 * 0.10) = 0. So the "other creator" recipe must be blocked on
-- BOTH days once the quota is enforced.
SELECT lives_ok(
  $$ SELECT generate_beauty_plan('b3000001-0000-0000-0000-000000000001'::uuid, _test_b3_next_monday(), 2) $$,
  'T1: generate_beauty_plan executes for fan-mode quota scenario'
);

SELECT is(
  (SELECT count(*)::int FROM beauty_plan_slot bps
   JOIN beauty_plan bp ON bp.id = bps.plan_id
   WHERE bp.user_id = 'b3000001-0000-0000-0000-000000000001'
     AND bp.start_date = _test_b3_next_monday()
     AND bps.recipe_id = 'b3000001-0000-0000-0000-000000000011'),
  0,
  'T2: other-creator recipe is blocked once the 90% fan-mode quota is reached'
);

SELECT is(
  (SELECT count(*)::int FROM beauty_plan_slot bps
   JOIN beauty_plan bp ON bp.id = bps.plan_id
   WHERE bp.user_id = 'b3000001-0000-0000-0000-000000000001'
     AND bp.start_date = _test_b3_next_monday()
     AND bps.recipe_id = 'b3000001-0000-0000-0000-000000000010'),
  2,
  'T3: fan-creator recipe is still inserted on both days'
);

SELECT is(
  (SELECT count(*)::int FROM beauty_plan_slot bps
   JOIN beauty_plan bp ON bp.id = bps.plan_id
   WHERE bp.user_id = 'b3000001-0000-0000-0000-000000000001'
     AND bp.start_date = _test_b3_next_monday()),
  2,
  'T4: total slot count for the plan is exactly 2 (no unquota''d other-creator slots leaked in)'
);

SELECT * FROM finish();
ROLLBACK;
