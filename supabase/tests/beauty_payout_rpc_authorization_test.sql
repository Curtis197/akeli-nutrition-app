-- supabase/tests/beauty_payout_rpc_authorization_test.sql
-- Finding #3 (Area C, High): no authorization check on
-- get_creator_beauty_payout_breakdown, get_platform_retained_beauty_revenue,
-- get_creator_beauty_revenue_share. Any user can query any creator's/
-- platform's financial data.
BEGIN;
SELECT plan(4);

INSERT INTO auth.users (id, email, role, created_at, updated_at) VALUES
  ('c3000001-0000-0000-0000-000000000001'::uuid, 'creatorA3@test.local', 'authenticated', now(), now()),
  ('c3000001-0000-0000-0000-000000000002'::uuid, 'creatorB3@test.local', 'authenticated', now(), now())
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.user_profile (id, first_name) VALUES
  ('c3000001-0000-0000-0000-000000000001'::uuid, 'CreatorAUser3'),
  ('c3000001-0000-0000-0000-000000000002'::uuid, 'CreatorBUser3')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.creator (id, user_id, display_name) VALUES
  ('c3000001-0000-0000-0000-000000000010'::uuid, 'c3000001-0000-0000-0000-000000000001'::uuid, 'Creator A Three'),
  ('c3000001-0000-0000-0000-000000000020'::uuid, 'c3000001-0000-0000-0000-000000000002'::uuid, 'Creator B Three')
ON CONFLICT (id) DO NOTHING;

-- Impersonate Creator B, attempt to query Creator A's revenue.
SET LOCAL "request.jwt.claims" TO '{"sub": "c3000001-0000-0000-0000-000000000002"}';

SELECT throws_ok(
  $$ SELECT * FROM get_creator_beauty_revenue_share('c3000001-0000-0000-0000-000000000010'::uuid) $$,
  'Unauthorized',
  'creator B cannot query creator A''s get_creator_beauty_revenue_share'
);

SELECT throws_ok(
  $$ SELECT * FROM get_creator_beauty_payout_breakdown('c3000001-0000-0000-0000-000000000010'::uuid) $$,
  'Unauthorized',
  'creator B cannot query creator A''s get_creator_beauty_payout_breakdown'
);

SELECT ok(
  NOT has_function_privilege('authenticated', 'get_platform_retained_beauty_revenue(date, integer)', 'EXECUTE'),
  'authenticated role loses EXECUTE on get_platform_retained_beauty_revenue'
);

SELECT ok(
  has_function_privilege('service_role', 'get_platform_retained_beauty_revenue(date, integer)', 'EXECUTE'),
  'service_role retains EXECUTE on get_platform_retained_beauty_revenue'
);

SELECT * FROM finish();
ROLLBACK;
