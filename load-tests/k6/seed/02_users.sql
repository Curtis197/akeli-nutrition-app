-- 02_users.sql
-- Seeds 500 synthetic user profiles.
--
-- IMPORTANT: auth.users rows must be created BEFORE this script runs.
-- The create-jwt-pool.ts script creates auth.users entries via the Supabase
-- Admin API using the service_role key, then outputs jwt-pool.json.
-- Run create-jwt-pool.ts first, then run this SQL script.
--
-- This script populates the public-schema tables that the edge functions read:
--   user_profile, user_health_profile, user_goal, user_vector

BEGIN;

DO $$
DECLARE
  i           INT;
  auth_id     uuid;
  email_addr  text;
BEGIN
  FOR i IN 1..500 LOOP
    email_addr := 'testuser' || i || '@akeli.local';

    -- Resolve the auth.users id for this email (created by create-jwt-pool.ts)
    SELECT id INTO auth_id FROM auth.users WHERE email = email_addr;

    IF auth_id IS NULL THEN
      RAISE NOTICE 'Skipping %: not found in auth.users (run create-jwt-pool.ts first)', email_addr;
      CONTINUE;
    END IF;

    -- user_profile (extends auth.users via FK)
    INSERT INTO user_profile (id, username, first_name, last_name, onboarding_done)
    VALUES (
      auth_id,
      'testuser' || i,
      'Test',
      'User ' || i,
      true
    )
    ON CONFLICT (id) DO NOTHING;

    -- user_health_profile
    INSERT INTO user_health_profile (user_id, sex, height_cm, weight_kg, activity_level)
    VALUES (
      auth_id,
      CASE WHEN i % 2 = 0 THEN 'female' ELSE 'male' END,
      160 + (i % 30),
      60 + (i % 40),
      'moderate'
    )
    ON CONFLICT (user_id) DO NOTHING;

    -- user_goal (required for per-meal calorie targets)
    INSERT INTO user_goal (user_id, goal_type, is_active)
    VALUES (auth_id, 'maintenance', true)
    ON CONFLICT DO NOTHING;

    -- user_vector (50-dim, random; generator falls back to popularity if absent)
    INSERT INTO user_vector (user_id, vector)
    VALUES (
      auth_id,
      (
        SELECT ('[' || string_agg(round(random()::numeric, 4)::text, ',') || ']')::vector
        FROM generate_series(1, 50)
      )
    )
    ON CONFLICT (user_id) DO NOTHING;
  END LOOP;
END $$;

COMMIT;
