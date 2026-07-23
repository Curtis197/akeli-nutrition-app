-- supabase/tests/beauty_payout_fan_double_counting_test.sql
-- Finding #2 (Area C, Critical): calculate_creator_payouts counts active
-- fan_subscription rows into fan_earnings_cents, but Nutrition's existing
-- compute-monthly-revenue edge function ALREADY counts the exact same
-- fan_subscription rows into creator_balance.balance. This double-counts
-- the same euro. Fix keeps only pool_earnings_cents (plan-slot-completion
-- revenue), which is genuinely beauty-specific and not double-counted
-- anywhere else.
BEGIN;
SELECT plan(4);

INSERT INTO auth.users (id, email, role, created_at, updated_at) VALUES
  ('c2000001-0000-0000-0000-000000000001'::uuid, 'creator2@test.local', 'authenticated', now(), now()),
  ('c2000001-0000-0000-0000-000000000002'::uuid, 'planowner2@test.local', 'authenticated', now(), now()),
  ('c2000001-0000-0000-0000-000000000003'::uuid, 'fan2@test.local', 'authenticated', now(), now())
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.user_profile (id, first_name) VALUES
  ('c2000001-0000-0000-0000-000000000001'::uuid, 'CreatorUser2'),
  ('c2000001-0000-0000-0000-000000000002'::uuid, 'PlanOwnerUser2'),
  ('c2000001-0000-0000-0000-000000000003'::uuid, 'FanUser2')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.creator (id, user_id, display_name)
VALUES ('c2000001-0000-0000-0000-000000000010'::uuid, 'c2000001-0000-0000-0000-000000000001'::uuid, 'Test Creator Two')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.recipe (id, creator_id, title, mode, is_published)
VALUES ('c2000001-0000-0000-0000-000000000020'::uuid, 'c2000001-0000-0000-0000-000000000010'::uuid, 'Test Beauty Recipe Two', 'beauty', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.beauty_plan (id, user_id, start_date, end_date)
VALUES (
  'c2000001-0000-0000-0000-000000000030'::uuid,
  'c2000001-0000-0000-0000-000000000002'::uuid,
  date_trunc('month', current_date)::date,
  (date_trunc('month', current_date) + interval '1 month - 1 day')::date
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.beauty_plan_slot (plan_id, day_of_week, routine_category, step_stage, recipe_id, is_completed, completed_at, revenue_value)
VALUES (
  'c2000001-0000-0000-0000-000000000030'::uuid, 1, 'hair', 'daily_hydration',
  'c2000001-0000-0000-0000-000000000020'::uuid, true, now(), 1.0
);

INSERT INTO public.fan_subscription (user_id, creator_id, status, subscribed_at)
VALUES (
  'c2000001-0000-0000-0000-000000000003'::uuid,
  'c2000001-0000-0000-0000-000000000010'::uuid,
  'active', now()
);

-- 1. The function must be callable at all (today it is not: the
--    creator_id FK still points at auth.users while this INSERT supplies
--    a creator.id value — see this plan's Global Constraints).
SELECT lives_ok(
  $$ SELECT calculate_creator_payouts(date_trunc('month', current_date)::date) $$,
  'calculate_creator_payouts executes without error'
);

-- 2. fan-mode revenue must NOT be recomputed here (compute-monthly-revenue
--    already owns it).
SELECT is(
  (SELECT fan_earnings_cents FROM creator_monthly_payouts
   WHERE creator_id = 'c2000001-0000-0000-0000-000000000010'::uuid
     AND period_month = date_trunc('month', current_date)::date),
  0,
  'fan-mode revenue is not double-counted by the beauty payout engine'
);

-- 3. The genuinely beauty-specific pool revenue must still be computed.
SELECT ok(
  (SELECT pool_earnings_cents FROM creator_monthly_payouts
   WHERE creator_id = 'c2000001-0000-0000-0000-000000000010'::uuid
     AND period_month = date_trunc('month', current_date)::date) > 0,
  'plan-slot-completion pool revenue is still computed correctly'
);

-- 4. No remaining reference to fan_earnings_cents anywhere in the function body.
SELECT is(
  (SELECT prosrc ~ 'fan_earnings_cents' FROM pg_proc WHERE proname = 'calculate_creator_payouts' AND pronargs = 2),
  false,
  'calculate_creator_payouts (2-arg) no longer references fan_earnings_cents anywhere in its body'
);

SELECT * FROM finish();
ROLLBACK;
