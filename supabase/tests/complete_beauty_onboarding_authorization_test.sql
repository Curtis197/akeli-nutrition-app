-- supabase/tests/complete_beauty_onboarding_authorization_test.sql
-- Finding #1 (Area C): complete_beauty_onboarding has no auth.uid() = p_user_id
-- check. Any authenticated client can overwrite another user's beauty
-- health profile / onboarding flag / plan by calling the RPC directly.
--
-- NOTE: this test deliberately does NOT assert the full onboarding success
-- path for the legitimate owner. generate_initial_beauty_plan ->
-- generate_beauty_plan references beauty_plan.is_active, a column that
-- Area B (not this plan) never actually adds to the table — see this
-- plan's Global Constraints. Test 4 below only proves the new guard does
-- not itself block the rightful owner; it does not require the whole
-- chain to succeed.
BEGIN;
SELECT plan(4);

INSERT INTO auth.users (id, email, role, created_at, updated_at) VALUES
  ('a1000001-0000-0000-0000-000000000001'::uuid, 'victim-onboarding@test.local', 'authenticated', now(), now()),
  ('a1000001-0000-0000-0000-000000000002'::uuid, 'attacker-onboarding@test.local', 'authenticated', now(), now())
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.user_profile (id, first_name) VALUES
  ('a1000001-0000-0000-0000-000000000001'::uuid, 'VictimUser'),
  ('a1000001-0000-0000-0000-000000000002'::uuid, 'AttackerUser')
ON CONFLICT (id) DO NOTHING;

-- 1. Signature is unchanged (CREATE OR REPLACE must replace in place, not
--    create a new ambiguous overload).
SELECT has_function(
  'public', 'complete_beauty_onboarding',
  ARRAY['uuid','text','text','text','text','text[]','text[]','numeric','numeric','numeric','text','numeric','numeric','text'],
  'complete_beauty_onboarding retains its exact 14-parameter signature after the authorization fix'
);

-- 2. Still SECURITY DEFINER (unchanged).
SELECT is(
  (SELECT prosecdef FROM pg_proc WHERE proname = 'complete_beauty_onboarding' LIMIT 1),
  true,
  'complete_beauty_onboarding remains SECURITY DEFINER'
);

-- 3. THE core regression test: an attacker cannot onboard on behalf of
--    another user's p_user_id.
SET LOCAL "request.jwt.claims" TO '{"sub": "a1000001-0000-0000-0000-000000000002"}';

SELECT throws_ok(
  $$ SELECT complete_beauty_onboarding(
       'a1000001-0000-0000-0000-000000000001'::uuid,
       'straight', 'low', 'oily', 'normal', ARRAY['hydration']::text[]
     ) $$,
  'Unauthorized',
  'attacker cannot call complete_beauty_onboarding with another user''s p_user_id'
);

-- 4. The legitimate owner is never blocked by the new guard (whatever
--    happens further down the call chain is a separate, already-flagged
--    Area B concern, not this fix's responsibility).
SET LOCAL "request.jwt.claims" TO '{"sub": "a1000001-0000-0000-0000-000000000001"}';

DO $$
DECLARE
  v_msg text := 'NO_EXCEPTION';
BEGIN
  BEGIN
    PERFORM complete_beauty_onboarding(
      'a1000001-0000-0000-0000-000000000001'::uuid,
      'straight', 'low', 'oily', 'normal', ARRAY['hydration']::text[]
    );
  EXCEPTION WHEN OTHERS THEN
    GET STACKED DIAGNOSTICS v_msg = MESSAGE_TEXT;
  END;
  PERFORM set_config('pgtap_test.owner_call_result', v_msg, true);
END;
$$;

SELECT isnt(
  current_setting('pgtap_test.owner_call_result', true),
  'Unauthorized',
  'legitimate owner (auth.uid() = p_user_id) is never blocked by the new Unauthorized guard'
);

SELECT * FROM finish();
ROLLBACK;
