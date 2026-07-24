-- supabase/tests/recommend_recipes_fan_mode_test.sql
-- Beauty Mode Branch Review 2026-07-23, Area J, Finding #1(b): zero SQL/RPC
-- test coverage exists for the fan-mode 1.5x recommendation boost. Written
-- against the CORRECTED recommend_recipes body from Area A Task 2
-- (supabase/migrations/20260722090100_fix_recommend_recipes_auth_overloads_clamp.sql),
-- which restores the auth.uid() check and clamps the fan-mode boosted
-- similarity to LEAST(raw_similarity * 1.5, 1.0).
--
-- PREREQUISITE: BLOCKED on Area A Task 2. Do not run this file until that
-- migration exists in supabase/migrations/.
--
-- Vector design: the user vector has 25 leading 1.0 dims (rest 0.0); BOTH the
-- fan-subscribed creator's recipe and the non-fan creator's recipe share the
-- IDENTICAL vector with 9 leading 1.0 dims (rest 0.0) -- i.e. equal base
-- similarity for both. cosine_similarity = dot / (|u| * |r|) = 9 / (5 * 3) =
-- 0.6 exactly for both recipes before the fan-mode multiplier is applied.
-- 0.6 * 1.5 = 0.9, which is < 1.0, so the fan-subscribed recipe's boosted
-- score is NOT clamped -- this test exercises the actual 1.5x multiplier
-- itself, not just the clamp ceiling (already covered by Area A's own test).
BEGIN;
SELECT plan(5);

INSERT INTO auth.users (id, email, role, created_at, updated_at) VALUES
  ('a2000001-0000-0000-0000-000000000001', 'fanboost.user@akeli.test', 'authenticated', now(), now()),
  ('a2000001-0000-0000-0000-000000000002', 'fanboost.fancreator@akeli.test', 'authenticated', now(), now()),
  ('a2000001-0000-0000-0000-000000000003', 'fanboost.othercreator@akeli.test', 'authenticated', now(), now())
ON CONFLICT (id) DO NOTHING;

INSERT INTO user_profile (id, onboarding_done, is_creator, created_at, locale) VALUES
  ('a2000001-0000-0000-0000-000000000001', true, false, now(), 'fr'),
  ('a2000001-0000-0000-0000-000000000002', true, true, now(), 'fr'),
  ('a2000001-0000-0000-0000-000000000003', true, true, now(), 'fr')
ON CONFLICT (id) DO NOTHING;

INSERT INTO creator (id, user_id, display_name) VALUES
  ('a2000001-0000-0000-0000-000000000010', 'a2000001-0000-0000-0000-000000000002', 'Fan Boost Fan Creator'),
  ('a2000001-0000-0000-0000-000000000011', 'a2000001-0000-0000-0000-000000000003', 'Fan Boost Other Creator')
ON CONFLICT (id) DO NOTHING;

-- fan_subscription has no UNIQUE(user_id, status) constraint as of
-- 20260717053537_reconcile_local_with_prod_schema.sql (dropped to match
-- production) -- plain INSERT is safe inside this rolled-back transaction.
INSERT INTO fan_subscription (user_id, creator_id, status) VALUES
  ('a2000001-0000-0000-0000-000000000001', 'a2000001-0000-0000-0000-000000000010', 'active');

INSERT INTO recipe (id, creator_id, title, is_published, mode) VALUES
  ('a2000001-0000-0000-0000-000000000020', 'a2000001-0000-0000-0000-000000000010', 'Fan Creator Recipe (boosted)', true, 'beauty'),
  ('a2000001-0000-0000-0000-000000000021', 'a2000001-0000-0000-0000-000000000011', 'Other Creator Recipe (baseline)', true, 'beauty')
ON CONFLICT (id) DO NOTHING;

-- User vector: dims 1-25 = 1.0, dims 26-50 = 0.0. |u| = sqrt(25) = 5.
INSERT INTO user_vector (user_id, vector) VALUES (
  'a2000001-0000-0000-0000-000000000001',
  (SELECT ('[' || string_agg(CASE WHEN gs <= 25 THEN '1' ELSE '0' END, ',' ORDER BY gs) || ']')::vector(50)
   FROM generate_series(1, 50) AS gs)
) ON CONFLICT (user_id) DO UPDATE SET vector = EXCLUDED.vector;

-- BOTH recipes get the IDENTICAL vector: dims 1-9 = 1.0, dims 10-50 = 0.0.
-- |r| = sqrt(9) = 3. dot(u,r) = 9. cosine_similarity = 9 / (5*3) = 0.6 for both.
INSERT INTO recipe_vector (recipe_id, vector) VALUES
  ('a2000001-0000-0000-0000-000000000020',
   (SELECT ('[' || string_agg(CASE WHEN gs <= 9 THEN '1' ELSE '0' END, ',' ORDER BY gs) || ']')::vector(50)
    FROM generate_series(1, 50) AS gs)),
  ('a2000001-0000-0000-0000-000000000021',
   (SELECT ('[' || string_agg(CASE WHEN gs <= 9 THEN '1' ELSE '0' END, ',' ORDER BY gs) || ']')::vector(50)
    FROM generate_series(1, 50) AS gs))
ON CONFLICT (recipe_id) DO UPDATE SET vector = EXCLUDED.vector;

SET LOCAL "request.jwt.claims" TO '{"sub": "a2000001-0000-0000-0000-000000000001"}';

SELECT lives_ok(
  $$ SELECT * FROM recommend_recipes('a2000001-0000-0000-0000-000000000001'::uuid, 10, 'beauty'::text, NULL, NULL, NULL) $$,
  'recommend_recipes executes for the owning user'
);

-- Non-fan creator's recipe returns its raw, un-boosted similarity: 0.6 exactly.
SELECT is(
  (SELECT ROUND(similarity::numeric, 4) FROM recommend_recipes('a2000001-0000-0000-0000-000000000001'::uuid, 10, 'beauty'::text, NULL, NULL, NULL)
   WHERE recipe_id = 'a2000001-0000-0000-0000-000000000021'::uuid),
  0.6000::numeric,
  'non-fan creator recipe raw similarity is exactly 0.6 (unboosted baseline)'
);

-- Fan-subscribed creator's recipe (equal base similarity) is boosted to
-- exactly 0.6 * 1.5 = 0.9 -- below the 1.0 clamp ceiling, so this proves the
-- actual multiplier, not just the clamp.
SELECT is(
  (SELECT ROUND(similarity::numeric, 4) FROM recommend_recipes('a2000001-0000-0000-0000-000000000001'::uuid, 10, 'beauty'::text, NULL, NULL, NULL)
   WHERE recipe_id = 'a2000001-0000-0000-0000-000000000020'::uuid),
  0.9000::numeric,
  'fan-subscribed creator recipe similarity is boosted to exactly 0.9 (0.6 * 1.5)'
);

-- The boost ratio between the two equal-baseline recipes is exactly 1.5.
SELECT is(
  (SELECT ROUND(
     (fan.similarity / other.similarity)::numeric, 2
   )
   FROM recommend_recipes('a2000001-0000-0000-0000-000000000001'::uuid, 10, 'beauty'::text, NULL, NULL, NULL) fan,
        recommend_recipes('a2000001-0000-0000-0000-000000000001'::uuid, 10, 'beauty'::text, NULL, NULL, NULL) other
   WHERE fan.recipe_id = 'a2000001-0000-0000-0000-000000000020'::uuid
     AND other.recipe_id = 'a2000001-0000-0000-0000-000000000021'::uuid),
  1.50::numeric,
  'fan-mode boost ratio between two equal-baseline recipes is exactly 1.5x'
);

-- The fan-subscribed recipe ranks strictly first when ordered by similarity.
SELECT is(
  (SELECT recipe_id FROM recommend_recipes('a2000001-0000-0000-0000-000000000001'::uuid, 10, 'beauty'::text, NULL, NULL, NULL)
   ORDER BY similarity DESC LIMIT 1),
  'a2000001-0000-0000-0000-000000000020'::uuid,
  'fan-subscribed creator recipe ranks first once boosted, despite equal base similarity'
);

SELECT * FROM finish();
ROLLBACK;
