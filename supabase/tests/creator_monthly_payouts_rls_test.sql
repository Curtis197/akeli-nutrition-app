-- supabase/tests/creator_monthly_payouts_rls_test.sql
-- Finding #6 (Area C, Medium): creator_monthly_payouts' only RLS policy
-- compares auth.uid() = creator_id, but creator_id stores creator.id (a
-- separate table's PK, populated from recipe.creator_id by
-- calculate_creator_payouts), not the creator's own auth uid. Legitimate
-- creators can never see their own payout row through this policy.
BEGIN;
SELECT plan(3);

INSERT INTO auth.users (id, email, role, created_at, updated_at) VALUES
  ('c6000001-0000-0000-0000-000000000001'::uuid, 'creatorA6@test.local', 'authenticated', now(), now()),
  ('c6000001-0000-0000-0000-000000000002'::uuid, 'creatorB6@test.local', 'authenticated', now(), now())
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.user_profile (id, first_name) VALUES
  ('c6000001-0000-0000-0000-000000000001'::uuid, 'CreatorAUser6'),
  ('c6000001-0000-0000-0000-000000000002'::uuid, 'CreatorBUser6')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.creator (id, user_id, display_name) VALUES
  ('c6000001-0000-0000-0000-000000000010'::uuid, 'c6000001-0000-0000-0000-000000000001'::uuid, 'Creator A Six')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.creator_monthly_payouts (creator_id, period_month, pool_earnings_cents, status)
VALUES ('c6000001-0000-0000-0000-000000000010'::uuid, date_trunc('month', current_date)::date, 500, 'pending')
ON CONFLICT (creator_id, period_month) DO NOTHING;

-- Creator A (rightful owner) must be able to see their own payout row.
SET LOCAL "request.jwt.claims" TO '{"sub": "c6000001-0000-0000-0000-000000000001"}';
SET LOCAL ROLE authenticated;

SELECT is(
  (SELECT count(*)::int FROM creator_monthly_payouts WHERE creator_id = 'c6000001-0000-0000-0000-000000000010'::uuid),
  1,
  'creator A can see their own payout row via the corrected RLS policy'
);

-- Creator B must NOT see creator A's payout row.
SET LOCAL "request.jwt.claims" TO '{"sub": "c6000001-0000-0000-0000-000000000002"}';
SET LOCAL ROLE authenticated;

SELECT is(
  (SELECT count(*)::int FROM creator_monthly_payouts WHERE creator_id = 'c6000001-0000-0000-0000-000000000010'::uuid),
  0,
  'creator B cannot see creator A''s payout row'
);

RESET ROLE;

-- Sanity: the policy definition itself uses the corrected subquery idiom.
SELECT ok(
  (SELECT qual FROM pg_policies WHERE tablename = 'creator_monthly_payouts' AND policyname = 'Creators view own payouts') LIKE '%SELECT id FROM creator%',
  'RLS policy uses the creator-ownership subquery idiom, not a raw auth.uid() = creator_id comparison'
);

SELECT * FROM finish();
ROLLBACK;
