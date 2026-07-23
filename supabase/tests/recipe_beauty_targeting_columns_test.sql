-- supabase/tests/recipe_beauty_targeting_columns_test.sql
-- Fixes: 20260723000000_add_missing_recipe_beauty_targeting_columns.sql
-- Covers both bugs fixed by that migration: (1) recipe.suitable_hair_type /
-- skin_target / formulation / scalp_target did not exist, so
-- python/engine/database.py's get_recipe_data() errored on every call; and
-- (2) complete_beauty_onboarding discarded the real onboarding scalp
-- selection (normal/dry/oily/sensitive) instead of persisting it to
-- user_health_profile.scalp_type.
BEGIN;
SELECT plan(6);

-- Assertions 1-4: the 4 new recipe columns exist with the expected nullable
-- text type (a stand-in for pgTAP's has_column, using information_schema
-- directly since that's the idiom this test suite already relies on
-- elsewhere in this migration set, e.g. 20260722100000's own dedup logic).
SELECT is(
  (SELECT data_type FROM information_schema.columns
   WHERE table_name = 'recipe' AND column_name = 'suitable_hair_type'),
  'text',
  'recipe.suitable_hair_type exists as text (previously missing entirely)'
);

SELECT is(
  (SELECT data_type FROM information_schema.columns
   WHERE table_name = 'recipe' AND column_name = 'skin_target'),
  'text',
  'recipe.skin_target exists as text (previously missing entirely)'
);

SELECT is(
  (SELECT data_type FROM information_schema.columns
   WHERE table_name = 'recipe' AND column_name = 'formulation'),
  'text',
  'recipe.formulation exists as text (previously missing entirely)'
);

SELECT is(
  (SELECT data_type FROM information_schema.columns
   WHERE table_name = 'recipe' AND column_name = 'scalp_target'),
  'text',
  'recipe.scalp_target exists as text (previously missing entirely)'
);

-- Seed a test user + auth identity so complete_beauty_onboarding's
-- auth.uid() = p_user_id check passes.
DO $$
BEGIN
  INSERT INTO auth.users (id, email, role, created_at, updated_at)
  VALUES ('00000000-0000-0000-0000-000000000501', 'scalp-test@akeli.test', 'authenticated', now(), now())
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO user_profile (id, onboarding_done, is_creator, created_at, locale)
  VALUES ('00000000-0000-0000-0000-000000000501', true, false, now(), 'fr')
  ON CONFLICT (id) DO NOTHING;
END $$;

SET LOCAL "request.jwt.claims" TO '{"sub": "00000000-0000-0000-0000-000000000501"}';

SELECT complete_beauty_onboarding(
  p_user_id       => '00000000-0000-0000-0000-000000000501'::uuid,
  p_hair_type     => '4C',
  p_porosity      => 'high',
  p_skin_type     => 'oily',
  p_scalp_type    => 'dry',
  p_beauty_goals  => ARRAY['scalp_soothing']
);

-- Assertion 5: the real 4-way onboarding selection ('dry') is now persisted
-- verbatim to scalp_type, not discarded.
SELECT is(
  (SELECT scalp_type FROM user_health_profile WHERE user_id = '00000000-0000-0000-0000-000000000501'::uuid),
  'dry',
  'complete_beauty_onboarding persists the real p_scalp_type value to user_health_profile.scalp_type'
);

-- Assertion 6: the existing sensitive_scalp boolean derivation is
-- unchanged/still correct (regression guard) — 'dry' must NOT flip it true.
SELECT is(
  (SELECT sensitive_scalp FROM user_health_profile WHERE user_id = '00000000-0000-0000-0000-000000000501'::uuid),
  false,
  'sensitive_scalp derivation is unchanged: only p_scalp_type = ''sensitive'' sets it true'
);

SELECT * FROM finish();
ROLLBACK;
