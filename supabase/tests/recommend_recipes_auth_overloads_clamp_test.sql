-- supabase/tests/recommend_recipes_auth_overloads_clamp_test.sql
-- Fixes: Beauty Mode Branch Review 2026-07-23, Area A, Findings #2 (Critical),
-- #3 (High), #8 (Medium).
BEGIN;
SELECT plan(3);

-- Seed: legitimate owner, attacker, and a creator the owner fan-subscribes to,
-- plus a recipe/user vector pair with raw cosine similarity of exactly 1.0 so the
-- fan-mode 1.5x boost would push similarity to 1.5 if left unclamped.
DO $$
BEGIN
  INSERT INTO auth.users (id, email, role, created_at, updated_at)
  VALUES
    ('00000000-0000-0000-0000-000000000201', 'rr-owner@akeli.test', 'authenticated', now(), now()),
    ('00000000-0000-0000-0000-000000000202', 'rr-attacker@akeli.test', 'authenticated', now(), now()),
    ('00000000-0000-0000-0000-000000000203', 'rr-creator@akeli.test', 'authenticated', now(), now())
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO user_profile (id, onboarding_done, is_creator, created_at, locale)
  VALUES
    ('00000000-0000-0000-0000-000000000201', true, false, now(), 'fr'),
    ('00000000-0000-0000-0000-000000000202', true, false, now(), 'fr'),
    ('00000000-0000-0000-0000-000000000203', true, true, now(), 'fr')
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO creator (id, user_id, display_name)
  VALUES ('00000000-0000-0000-0000-000000000301', '00000000-0000-0000-0000-000000000203', 'RR Test Creator')
  ON CONFLICT (id) DO NOTHING;

  -- fan_subscription has no UNIQUE(user_id, status) constraint as of
  -- 20260717053537_reconcile_local_with_prod_schema.sql (dropped to match
  -- production) -- plain INSERT is safe inside this rolled-back transaction.
  INSERT INTO fan_subscription (user_id, creator_id, status)
  VALUES ('00000000-0000-0000-0000-000000000201', '00000000-0000-0000-0000-000000000301', 'active');

  INSERT INTO recipe (id, creator_id, title, is_published, mode)
  VALUES (
    '00000000-0000-0000-0000-000000000401',
    '00000000-0000-0000-0000-000000000301',
    'RR Test Fan Recipe',
    true,
    'beauty'
  )
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO user_vector (user_id, vector)
  VALUES (
    '00000000-0000-0000-0000-000000000201',
    ('[' || array_to_string(array_fill(0.42::numeric, ARRAY[50]), ',') || ']')::vector(50)
  )
  ON CONFLICT (user_id) DO UPDATE SET vector = EXCLUDED.vector;

  INSERT INTO recipe_vector (recipe_id, vector)
  VALUES (
    '00000000-0000-0000-0000-000000000401',
    ('[' || array_to_string(array_fill(0.42::numeric, ARRAY[50]), ',') || ']')::vector(50)
  )
  ON CONFLICT (recipe_id) DO UPDATE SET vector = EXCLUDED.vector;
END $$;

-- Assertion 1: an attacker cannot pull the owner's personalized recommendations.
SET LOCAL "request.jwt.claims" TO '{"sub": "00000000-0000-0000-0000-000000000202"}';

SELECT throws_ok(
  $$ SELECT * FROM recommend_recipes('00000000-0000-0000-0000-000000000201'::uuid, 10, NULL, NULL, NULL, NULL) $$,
  'P0001',
  'Unauthorized',
  'recommend_recipes rejects a caller passing a different user''s p_user_id'
);

-- Assertion 2: only one recommend_recipes overload remains (no PGRST203-style risk).
SELECT is(
  (SELECT count(*)::int FROM pg_proc p
   JOIN pg_namespace n ON n.oid = p.pronamespace
   WHERE p.proname = 'recommend_recipes' AND n.nspname = 'public'),
  1,
  'exactly one recommend_recipes overload exists after dropping the 2 stale signatures'
);

-- Assertion 3: fan-mode 1.5x boost is clamped to 1.0, not left at 1.5.
SET LOCAL "request.jwt.claims" TO '{"sub": "00000000-0000-0000-0000-000000000201"}';

SELECT is(
  (SELECT similarity FROM recommend_recipes(
     '00000000-0000-0000-0000-000000000201'::uuid, 1000, NULL, NULL, NULL, NULL
   ) WHERE recipe_id = '00000000-0000-0000-0000-000000000401'::uuid),
  1.0::double precision,
  'fan-mode boosted similarity is clamped to 1.0 for an identical-vector, fan-subscribed-creator recipe'
);

SELECT * FROM finish();
ROLLBACK;
