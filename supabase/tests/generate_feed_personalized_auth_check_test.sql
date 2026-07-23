-- supabase/tests/generate_feed_personalized_auth_check_test.sql
-- Fixes: bug found during Area A verification (not one of the review's original
-- 8 listed findings). generate_feed_personalized's auth.uid() = p_user_id check
-- was dropped by 20260721000010/20260721000015 the same way recommend_recipes's
-- was (Finding #2) — any user can pull another user's personalized feed.
BEGIN;
SELECT plan(2);

DO $$
BEGIN
  INSERT INTO auth.users (id, email, role, created_at, updated_at)
  VALUES
    ('00000000-0000-0000-0000-000000000501', 'gfp-owner@akeli.test', 'authenticated', now(), now()),
    ('00000000-0000-0000-0000-000000000502', 'gfp-attacker@akeli.test', 'authenticated', now(), now())
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO user_profile (id, onboarding_done, is_creator, created_at, locale)
  VALUES
    ('00000000-0000-0000-0000-000000000501', true, false, now(), 'fr'),
    ('00000000-0000-0000-0000-000000000502', true, false, now(), 'fr')
  ON CONFLICT (id) DO NOTHING;
END $$;

SET LOCAL "request.jwt.claims" TO '{"sub": "00000000-0000-0000-0000-000000000502"}';

SELECT throws_ok(
  $$ SELECT * FROM generate_feed_personalized('00000000-0000-0000-0000-000000000501'::uuid, 20) $$,
  'P0001',
  'Unauthorized',
  'generate_feed_personalized rejects a caller passing a different user''s p_user_id'
);

SET LOCAL "request.jwt.claims" TO '{"sub": "00000000-0000-0000-0000-000000000501"}';

SELECT lives_ok(
  $$ SELECT * FROM generate_feed_personalized('00000000-0000-0000-0000-000000000501'::uuid, 20) $$,
  'generate_feed_personalized succeeds when auth.uid() matches p_user_id'
);

SELECT * FROM finish();
ROLLBACK;
