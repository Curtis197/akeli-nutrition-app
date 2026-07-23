-- supabase/tests/calculate_creator_payouts_test.sql
-- Beauty Mode Branch Review 2026-07-23, Area J, Finding #1(a): zero SQL/RPC
-- test coverage exists for calculate_creator_payouts. Written against the
-- CORRECTED function body from Area C Task 2
-- (supabase/migrations/20260722110100_fix_beauty_payout_fan_double_counting.sql),
-- which removes the double-counted fan_earnings_cents component and computes
-- pool_earnings_cents as ROUND(SUM(bps.revenue_value) * plan_revenue_cents)
-- over each creator's completed beauty_plan_slot rows in the target month.
--
-- PREREQUISITE: BLOCKED on Area C Task 2. Do not run this file until that
-- migration exists in supabase/migrations/.
BEGIN;
SELECT plan(7);

-- ── Seed: plan-owner user, 3 creators (X completes partially, Y completes
-- fully, Z has a recipe but zero completed slots) ─────────────────────────
INSERT INTO auth.users (id, email, role, created_at, updated_at) VALUES
  ('j1000001-0000-0000-0000-000000000001', 'payout.owner@akeli.test', 'authenticated', now(), now()),
  ('j1000001-0000-0000-0000-000000000002', 'payout.creatorx@akeli.test', 'authenticated', now(), now()),
  ('j1000001-0000-0000-0000-000000000003', 'payout.creatory@akeli.test', 'authenticated', now(), now()),
  ('j1000001-0000-0000-0000-000000000004', 'payout.creatorz@akeli.test', 'authenticated', now(), now())
ON CONFLICT (id) DO NOTHING;

INSERT INTO user_profile (id, onboarding_done, is_creator, created_at, locale) VALUES
  ('j1000001-0000-0000-0000-000000000001', true, false, now(), 'fr'),
  ('j1000001-0000-0000-0000-000000000002', true, true, now(), 'fr'),
  ('j1000001-0000-0000-0000-000000000003', true, true, now(), 'fr'),
  ('j1000001-0000-0000-0000-000000000004', true, true, now(), 'fr')
ON CONFLICT (id) DO NOTHING;

INSERT INTO creator (id, user_id, display_name) VALUES
  ('j1000001-0000-0000-0000-000000000010', 'j1000001-0000-0000-0000-000000000002', 'Payout Creator X'),
  ('j1000001-0000-0000-0000-000000000011', 'j1000001-0000-0000-0000-000000000003', 'Payout Creator Y'),
  ('j1000001-0000-0000-0000-000000000012', 'j1000001-0000-0000-0000-000000000004', 'Payout Creator Z')
ON CONFLICT (id) DO NOTHING;

INSERT INTO recipe (id, creator_id, title, instructions, is_published, mode) VALUES
  ('j1000001-0000-0000-0000-000000000020', 'j1000001-0000-0000-0000-000000000010', 'Payout Test Recipe X', 'Steps.', true, 'beauty'),
  ('j1000001-0000-0000-0000-000000000021', 'j1000001-0000-0000-0000-000000000011', 'Payout Test Recipe Y', 'Steps.', true, 'beauty'),
  ('j1000001-0000-0000-0000-000000000022', 'j1000001-0000-0000-0000-000000000012', 'Payout Test Recipe Z', 'Steps.', true, 'beauty')
ON CONFLICT (id) DO NOTHING;

INSERT INTO beauty_plan (id, user_id, start_date, end_date) VALUES (
  'j1000001-0000-0000-0000-000000000030',
  'j1000001-0000-0000-0000-000000000001',
  date_trunc('month', current_date)::date,
  (date_trunc('month', current_date) + interval '1 month - 1 day')::date
) ON CONFLICT (id) DO NOTHING;

-- Creator X: 3 completed slots @ revenue_value 0.25 (sum 0.75) + 1 INCOMPLETE
-- slot @ 0.25 that must NOT be counted.
INSERT INTO beauty_plan_slot (plan_id, day_of_week, routine_category, step_stage, recipe_id, is_completed, completed_at, revenue_value) VALUES
  ('j1000001-0000-0000-0000-000000000030', 1, 'hair', 'daily_hydration', 'j1000001-0000-0000-0000-000000000020', true,  now(), 0.25),
  ('j1000001-0000-0000-0000-000000000030', 2, 'hair', 'daily_hydration', 'j1000001-0000-0000-0000-000000000020', true,  now(), 0.25),
  ('j1000001-0000-0000-0000-000000000030', 3, 'hair', 'daily_hydration', 'j1000001-0000-0000-0000-000000000020', true,  now(), 0.25),
  ('j1000001-0000-0000-0000-000000000030', 4, 'hair', 'daily_hydration', 'j1000001-0000-0000-0000-000000000020', false, NULL, 0.25);

-- Creator Y: 2 completed slots @ revenue_value 0.5 (sum 1.0).
INSERT INTO beauty_plan_slot (plan_id, day_of_week, routine_category, step_stage, recipe_id, is_completed, completed_at, revenue_value) VALUES
  ('j1000001-0000-0000-0000-000000000030', 5, 'skin', 'treatment', 'j1000001-0000-0000-0000-000000000021', true, now(), 0.5),
  ('j1000001-0000-0000-0000-000000000030', 6, 'skin', 'treatment', 'j1000001-0000-0000-0000-000000000021', true, now(), 0.5);

-- Creator Z: recipe exists in the plan, but its only slot is NOT completed —
-- Creator Z must get no payout row at all this month.
INSERT INTO beauty_plan_slot (plan_id, day_of_week, routine_category, step_stage, recipe_id, is_completed, completed_at, revenue_value) VALUES
  ('j1000001-0000-0000-0000-000000000030', 7, 'both', 'wash_day_mask', 'j1000001-0000-0000-0000-000000000022', false, NULL, 1.0);

-- ── Act ──────────────────────────────────────────────────────────────────
SELECT lives_ok(
  $$ SELECT calculate_creator_payouts(date_trunc('month', current_date)::date) $$,
  'calculate_creator_payouts executes without error'
);

-- Creator X: ROUND(0.75 * 100) = 75 cents. The incomplete 4th slot's 0.25 is
-- deliberately excluded from this sum — if it were wrongly included this
-- would be 100, not 75.
SELECT is(
  (SELECT pool_earnings_cents FROM creator_monthly_payouts
   WHERE creator_id = 'j1000001-0000-0000-0000-000000000010'
     AND period_month = date_trunc('month', current_date)::date),
  75,
  'Creator X payout is exactly ROUND(0.75 * 100) = 75 cents, excluding the incomplete slot'
);

-- Creator Y: ROUND(1.0 * 100) = 100 cents.
SELECT is(
  (SELECT pool_earnings_cents FROM creator_monthly_payouts
   WHERE creator_id = 'j1000001-0000-0000-0000-000000000011'
     AND period_month = date_trunc('month', current_date)::date),
  100,
  'Creator Y payout is exactly ROUND(1.0 * 100) = 100 cents'
);

-- fan_earnings_cents must stay at its table default of 0 — Area C Task 2
-- deliberately never computes fan-mode revenue in this function anymore.
SELECT is(
  (SELECT fan_earnings_cents FROM creator_monthly_payouts
   WHERE creator_id = 'j1000001-0000-0000-0000-000000000010'
     AND period_month = date_trunc('month', current_date)::date),
  0,
  'Creator X fan_earnings_cents remains 0 (not double-counted by this function)'
);

SELECT is(
  (SELECT status FROM creator_monthly_payouts
   WHERE creator_id = 'j1000001-0000-0000-0000-000000000010'
     AND period_month = date_trunc('month', current_date)::date),
  'pending',
  'Creator X payout row status defaults to pending'
);

-- Creator Z has zero completed slots this month -> no payout row at all.
SELECT is(
  (SELECT count(*)::int FROM creator_monthly_payouts
   WHERE creator_id = 'j1000001-0000-0000-0000-000000000012'
     AND period_month = date_trunc('month', current_date)::date),
  0,
  'Creator Z (zero completed slots) gets no creator_monthly_payouts row'
);

-- Exactly 2 of our 3 test creators (X and Y) got a row this month.
SELECT is(
  (SELECT count(*)::int FROM creator_monthly_payouts
   WHERE creator_id IN (
     'j1000001-0000-0000-0000-000000000010',
     'j1000001-0000-0000-0000-000000000011',
     'j1000001-0000-0000-0000-000000000012'
   )
   AND period_month = date_trunc('month', current_date)::date),
  2,
  'exactly 2 of the 3 test creators received a payout row this month'
);

SELECT * FROM finish();
ROLLBACK;
