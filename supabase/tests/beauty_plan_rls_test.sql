-- supabase/tests/beauty_plan_rls_test.sql
BEGIN;
SELECT plan(8);

-- ── Seed: two users ──────────────────────────────────────────────────────────
INSERT INTO auth.users (id, email, role, created_at, updated_at) VALUES
  ('b2000001-0000-0000-0000-000000000001', 'beautyrls.a@akeli.test', 'authenticated', now(), now()),
  ('b2000001-0000-0000-0000-000000000002', 'beautyrls.b@akeli.test', 'authenticated', now(), now())
ON CONFLICT (id) DO NOTHING;

INSERT INTO user_profile (id, onboarding_done, is_creator, created_at, locale) VALUES
  ('b2000001-0000-0000-0000-000000000001', true, false, now(), 'fr'),
  ('b2000001-0000-0000-0000-000000000002', true, false, now(), 'fr')
ON CONFLICT (id) DO NOTHING;

-- ── Seed: beauty_plan + slot owned by user A ────────────────────────────────
INSERT INTO recipe (id, title, instructions, is_published, mode, frequency, created_at)
VALUES ('b2000001-0000-0000-0000-000000000010', 'RLS Test Recipe', 'Steps.', true, 'beauty', 'daily', now())
ON CONFLICT (id) DO NOTHING;

INSERT INTO beauty_plan (id, user_id, start_date, end_date, is_active)
VALUES ('b2000001-0000-0000-0000-000000000020', 'b2000001-0000-0000-0000-000000000001', CURRENT_DATE, CURRENT_DATE + 6, true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO beauty_plan_slot (id, plan_id, day_of_week, routine_category, step_stage, recipe_id, day_number, week_number, frequency_tier)
VALUES ('b2000001-0000-0000-0000-000000000030', 'b2000001-0000-0000-0000-000000000020', 1, 'both', 'daily_hydration', 'b2000001-0000-0000-0000-000000000010', 1, 1, 'daily')
ON CONFLICT (id) DO NOTHING;

-- ── T1/T2: RLS is enabled on both tables ─────────────────────────────────────
SELECT ok(
  (SELECT relrowsecurity FROM pg_class WHERE oid = 'beauty_plan'::regclass),
  'T1: RLS is enabled on beauty_plan'
);
SELECT ok(
  (SELECT relrowsecurity FROM pg_class WHERE oid = 'beauty_plan_slot'::regclass),
  'T2: RLS is enabled on beauty_plan_slot'
);

-- ── T3-T7: other user (B) cannot read/write user A's rows ───────────────────
SET LOCAL request.jwt.claims = '{"sub":"b2000001-0000-0000-0000-000000000002"}';
SET LOCAL ROLE authenticated;

SELECT is(
  (SELECT count(*)::int FROM beauty_plan WHERE id = 'b2000001-0000-0000-0000-000000000020'),
  0,
  'T3: other user cannot select user A''s beauty_plan row'
);

SELECT is(
  (SELECT count(*)::int FROM beauty_plan_slot WHERE id = 'b2000001-0000-0000-0000-000000000030'),
  0,
  'T4: other user cannot select user A''s beauty_plan_slot row'
);

SELECT is(
  (WITH upd AS (
      UPDATE beauty_plan SET end_date = end_date + 1
      WHERE id = 'b2000001-0000-0000-0000-000000000020'
      RETURNING id
   ) SELECT count(*)::int FROM upd),
  0,
  'T5: other user UPDATE on user A''s plan affects 0 rows'
);

SELECT is(
  (WITH del AS (
      DELETE FROM beauty_plan_slot
      WHERE id = 'b2000001-0000-0000-0000-000000000030'
      RETURNING id
   ) SELECT count(*)::int FROM del),
  0,
  'T6: other user DELETE on user A''s slot affects 0 rows'
);

SELECT throws_ok(
  $$ INSERT INTO beauty_plan (user_id, start_date, end_date, is_active)
     VALUES ('b2000001-0000-0000-0000-000000000001'::uuid, CURRENT_DATE, CURRENT_DATE + 6, true) $$,
  'new row violates row-level security policy for table "beauty_plan"',
  'T7: RLS prevents inserting a beauty_plan row as another user'
);

-- ── T8: owning user CAN select their own plan ────────────────────────────────
SET LOCAL request.jwt.claims = '{"sub":"b2000001-0000-0000-0000-000000000001"}';
SET LOCAL ROLE authenticated;

SELECT is(
  (SELECT count(*)::int FROM beauty_plan WHERE id = 'b2000001-0000-0000-0000-000000000020'),
  1,
  'T8: owning user can select own beauty_plan row'
);

RESET ROLE;

SELECT * FROM finish();
ROLLBACK;
