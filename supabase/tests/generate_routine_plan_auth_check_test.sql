-- supabase/tests/generate_routine_plan_auth_check_test.sql
-- Fixes: Beauty Mode Branch Review 2026-07-23, Area A, Finding #1 (Critical).
-- generate_routine_plan is SECURITY DEFINER with no auth.uid() = p_user_id
-- check, so any authenticated user can pass another user's UUID and
-- deactivate/overwrite their beauty routine plan.
BEGIN;
SELECT plan(3);

-- Seed two distinct test users (idempotent).
DO $$
BEGIN
  INSERT INTO auth.users (id, email, role, created_at, updated_at)
  VALUES
    ('00000000-0000-0000-0000-000000000101', 'routine-owner@akeli.test', 'authenticated', now(), now()),
    ('00000000-0000-0000-0000-000000000102', 'routine-attacker@akeli.test', 'authenticated', now(), now())
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO user_profile (id, onboarding_done, is_creator, created_at, locale)
  VALUES
    ('00000000-0000-0000-0000-000000000101', true, false, now(), 'fr'),
    ('00000000-0000-0000-0000-000000000102', true, false, now(), 'fr')
  ON CONFLICT (id) DO NOTHING;
END $$;

-- Act as the attacker (user 102) and attempt to generate/overwrite user 101's plan.
SET LOCAL "request.jwt.claims" TO '{"sub": "00000000-0000-0000-0000-000000000102"}';

SELECT throws_ok(
  $$ SELECT generate_routine_plan('00000000-0000-0000-0000-000000000101'::uuid, 7) $$,
  'P0001',
  'Unauthorized',
  'generate_routine_plan rejects a caller passing a different user''s p_user_id'
);

-- Confirm no rogue plan row was inserted for the victim during the failed attempt.
SELECT is(
  (SELECT count(*)::int FROM meal_plan WHERE user_id = '00000000-0000-0000-0000-000000000101' AND mode = 'beauty'),
  0,
  'no beauty plan row was created for the victim by the unauthorized call'
);

-- Now act as the legitimate owner (user 101) — this must succeed.
SET LOCAL "request.jwt.claims" TO '{"sub": "00000000-0000-0000-0000-000000000101"}';

SELECT lives_ok(
  $$ SELECT generate_routine_plan('00000000-0000-0000-0000-000000000101'::uuid, 7) $$,
  'generate_routine_plan succeeds when auth.uid() matches p_user_id'
);

SELECT * FROM finish();
ROLLBACK;
