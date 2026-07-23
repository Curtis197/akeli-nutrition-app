-- supabase/tests/beauty_plan_is_active_column_test.sql
BEGIN;
SELECT plan(6);

-- ── Seed: test user ──────────────────────────────────────────────────────────
INSERT INTO auth.users (id, email, role, created_at, updated_at)
VALUES ('b1000001-0000-0000-0000-000000000001', 'beautyactive.test@akeli.test', 'authenticated', now(), now())
ON CONFLICT (id) DO NOTHING;

INSERT INTO user_profile (id, onboarding_done, is_creator, created_at, locale)
VALUES ('b1000001-0000-0000-0000-000000000001', true, false, now(), 'fr')
ON CONFLICT (id) DO NOTHING;

-- ── Seed: one published beauty recipe with a 'daily' frequency ──────────────
INSERT INTO recipe (id, title, instructions, is_published, mode, beauty_type, beauty_sub_type, frequency, created_at)
VALUES ('b1000001-0000-0000-0000-000000000010', 'Test Daily Hydration Mask', 'Apply and rinse.', true, 'beauty', 'both', 'daily_hydration', 'daily', now())
ON CONFLICT (id) DO NOTHING;

SET LOCAL "request.jwt.claims" TO '{"sub": "b1000001-0000-0000-0000-000000000001"}';

-- ── T1: column exists ────────────────────────────────────────────────────────
SELECT has_column('beauty_plan', 'is_active', 'T1: beauty_plan has is_active column');

-- ── T2/T3: column is NOT NULL with a default ─────────────────────────────────
SELECT col_not_null('beauty_plan', 'is_active', 'T2: is_active is NOT NULL');
SELECT col_has_default('beauty_plan', 'is_active', 'T3: is_active has a default');

-- ── T4/T5: backfill sets only the most recent plan per user active ──────────
INSERT INTO beauty_plan (id, user_id, start_date, end_date, created_at)
VALUES
  ('b1000001-0000-0000-0000-000000000020', 'b1000001-0000-0000-0000-000000000001', CURRENT_DATE - 60, CURRENT_DATE - 31, now() - INTERVAL '60 days'),
  ('b1000001-0000-0000-0000-000000000021', 'b1000001-0000-0000-0000-000000000001', CURRENT_DATE - 30, CURRENT_DATE - 1, now() - INTERVAL '30 days');

SELECT is(
  (SELECT is_active FROM beauty_plan WHERE id = 'b1000001-0000-0000-0000-000000000021'),
  true,
  'T4: most recently created plan is active'
);
SELECT is(
  (SELECT is_active FROM beauty_plan WHERE id = 'b1000001-0000-0000-0000-000000000020'),
  false,
  'T5: older plan is inactive'
);

-- ── T6: generate_beauty_plan runs without "column is_active does not exist" ─
SELECT lives_ok(
  $$ SELECT generate_beauty_plan('b1000001-0000-0000-0000-000000000001'::uuid, CURRENT_DATE, 2) $$,
  'T6: generate_beauty_plan executes without is_active column error'
);

SELECT * FROM finish();
ROLLBACK;
