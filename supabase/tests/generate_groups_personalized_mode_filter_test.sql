-- supabase/tests/generate_groups_personalized_mode_filter_test.sql
-- Finding #7 (Area C, High): Community "Browse Groups" has no mode filter.
-- Beauty groups leak into Nutrition mode's discovery feed and vice versa.
BEGIN;
SELECT plan(4);

INSERT INTO auth.users (id, email, role, created_at, updated_at)
VALUES ('70000001-0000-0000-0000-000000000001'::uuid, 'browsegroups7@test.local', 'authenticated', now(), now())
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.user_profile (id, first_name, locale)
VALUES ('70000001-0000-0000-0000-000000000001'::uuid, 'BrowseUser7', 'fr')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.community_group (id, name, "mode", topic, language, is_public, member_count)
VALUES
  ('70000001-0000-0000-0000-000000000002'::uuid, 'Nutrition Test Group Seven', 'nutrition', 'nutrition', 'fr', true, 10),
  ('70000001-0000-0000-0000-000000000003'::uuid, 'Beauty Test Group Seven', 'beauty', 'chebe_care', 'fr', true, 10)
ON CONFLICT (id) DO NOTHING;

-- 1. The 4-arg overload must exist (schema-level check, never throws).
SELECT has_function(
  'public', 'generate_groups_personalized', ARRAY['uuid','integer','uuid[]','text'],
  'generate_groups_personalized accepts a 4th p_mode text parameter'
);

SET LOCAL "request.jwt.claims" TO '{"sub": "70000001-0000-0000-0000-000000000001"}';

-- 2. Behavioral check, gated on the 4-arg overload actually existing so
--    this never throws an uncaught exception pre-fix.
DO $$
BEGIN
  PERFORM set_config(
    'pgtap_test.mode_param_exists',
    (EXISTS (
      SELECT 1 FROM pg_proc p
      JOIN pg_namespace n ON n.oid = p.pronamespace
      WHERE n.nspname = 'public' AND p.proname = 'generate_groups_personalized' AND p.pronargs = 4
    ))::text,
    true
  );
END;
$$;

-- Scoped to this test's own fixture group IDs -- the community_group table
-- already carries other legitimately-seeded, mode='beauty' production groups
-- (e.g. 'Secret du Chébé & Pousse 4C'), which correctly also match a
-- p_mode='beauty' filter and must not be treated as a false positive here.
SELECT CASE current_setting('pgtap_test.mode_param_exists', true)
  WHEN 'true' THEN (
    SELECT is(
      (SELECT array_agg(group_id ORDER BY group_id) FROM generate_groups_personalized(
        p_user_id => '70000001-0000-0000-0000-000000000001'::uuid,
        p_limit   => 20,
        p_exclude => '{}'::uuid[],
        p_mode    => 'beauty'
      ) WHERE group_id IN ('70000001-0000-0000-0000-000000000002'::uuid, '70000001-0000-0000-0000-000000000003'::uuid)),
      ARRAY['70000001-0000-0000-0000-000000000003'::uuid],
      'p_mode=beauty returns only the seeded beauty-mode group (scoped to this test''s fixtures)'
    )
  )
  ELSE fail('generate_groups_personalized(...,p_mode) not callable yet — Finding #7 fix not applied')
END AS beauty_filter_result;

SELECT CASE current_setting('pgtap_test.mode_param_exists', true)
  WHEN 'true' THEN (
    SELECT is(
      (SELECT array_agg(group_id ORDER BY group_id) FROM generate_groups_personalized(
        p_user_id => '70000001-0000-0000-0000-000000000001'::uuid,
        p_limit   => 20,
        p_exclude => '{}'::uuid[],
        p_mode    => 'nutrition'
      )),
      ARRAY['70000001-0000-0000-0000-000000000002'::uuid],
      'p_mode=nutrition returns only the seeded nutrition-mode group'
    )
  )
  ELSE fail('generate_groups_personalized(...,p_mode) not callable yet — Finding #7 fix not applied')
END AS nutrition_filter_result;

-- 4. p_mode omitted (NULL default) preserves prior no-filter behavior.
SELECT CASE current_setting('pgtap_test.mode_param_exists', true)
  WHEN 'true' THEN (
    SELECT is(
      (SELECT count(*)::int FROM generate_groups_personalized(
        p_user_id => '70000001-0000-0000-0000-000000000001'::uuid,
        p_limit   => 20,
        p_exclude => '{}'::uuid[]
      ) WHERE group_id IN ('70000001-0000-0000-0000-000000000002'::uuid, '70000001-0000-0000-0000-000000000003'::uuid)),
      2,
      'p_mode omitted (NULL default) returns both seeded groups — backward compatible'
    )
  )
  ELSE fail('generate_groups_personalized(...,p_mode) not callable yet — Finding #7 fix not applied')
END AS no_filter_result;

SELECT * FROM finish();
ROLLBACK;
