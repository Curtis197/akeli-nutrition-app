-- Migration: 20260721000016_beauty_onboarding_flag.sql
-- Description: Add beauty_onboarding_done flag to user_profile and create complete_beauty_onboarding RPC

ALTER TABLE user_profile 
ADD COLUMN IF NOT EXISTS beauty_onboarding_done boolean DEFAULT false;

-- Drop function if exists to avoid signature mismatch
DROP FUNCTION IF EXISTS complete_beauty_onboarding(uuid, text, text, text, text, text[]);

CREATE OR REPLACE FUNCTION complete_beauty_onboarding(
  p_user_id       uuid,
  p_hair_type     text,
  p_porosity      text,
  p_skin_type     text,
  p_scalp_type    text,
  p_beauty_goals  text[]
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- 1. Upsert user_health_profile with physical beauty attributes
  INSERT INTO user_health_profile (
    user_id, hair_type, porosity, skin_type, sensitive_scalp, beauty_goals, updated_at
  )
  VALUES (
    p_user_id, p_hair_type, p_porosity, p_skin_type, (p_scalp_type = 'sensitive'), p_beauty_goals, NOW()
  )
  ON CONFLICT (user_id) DO UPDATE SET
    hair_type = EXCLUDED.hair_type,
    porosity = EXCLUDED.porosity,
    skin_type = EXCLUDED.skin_type,
    sensitive_scalp = EXCLUDED.sensitive_scalp,
    beauty_goals = EXCLUDED.beauty_goals,
    updated_at = NOW();

  -- 2. Mark beauty_onboarding_done = true on user_profile
  UPDATE user_profile
  SET beauty_onboarding_done = true
  WHERE id = p_user_id;

  -- 3. Create initial baseline log entry if not present
  IF NOT EXISTS (SELECT 1 FROM beauty_log WHERE user_id = p_user_id) THEN
    PERFORM create_initial_beauty_log(p_user_id, p_hair_type, p_porosity, p_skin_type, p_scalp_type, p_beauty_goals);
  END IF;

  -- 4. Generate initial 30-day Beauty Plan
  PERFORM generate_beauty_plan(p_user_id);

  RETURN true;
END;
$$;
