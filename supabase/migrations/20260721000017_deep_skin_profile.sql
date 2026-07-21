-- Migration: 20260721000017_deep_skin_profile.sql
-- Description: Add skin_concerns column to user_health_profile and update complete_beauty_onboarding RPC

ALTER TABLE user_health_profile 
ADD COLUMN IF NOT EXISTS skin_concerns text[] DEFAULT '{}';

DROP FUNCTION IF EXISTS complete_beauty_onboarding(uuid, text, text, text, text, text[]);
DROP FUNCTION IF EXISTS complete_beauty_onboarding(uuid, text, text, text, text, text[], text[]);

CREATE OR REPLACE FUNCTION complete_beauty_onboarding(
  p_user_id       uuid,
  p_hair_type     text,
  p_porosity      text,
  p_skin_type     text,
  p_scalp_type    text,
  p_beauty_goals  text[],
  p_skin_concerns text[] DEFAULT '{}'
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  INSERT INTO user_health_profile (
    user_id, hair_type, porosity, skin_type, sensitive_scalp, beauty_goals, skin_concerns, updated_at
  )
  VALUES (
    p_user_id, p_hair_type, p_porosity, p_skin_type, (p_scalp_type = 'sensitive'), p_beauty_goals, p_skin_concerns, NOW()
  )
  ON CONFLICT (user_id) DO UPDATE SET
    hair_type = EXCLUDED.hair_type,
    porosity = EXCLUDED.porosity,
    skin_type = EXCLUDED.skin_type,
    sensitive_scalp = EXCLUDED.sensitive_scalp,
    beauty_goals = EXCLUDED.beauty_goals,
    skin_concerns = EXCLUDED.skin_concerns,
    updated_at = NOW();

  UPDATE user_profile
  SET beauty_onboarding_done = true
  WHERE id = p_user_id;

  IF NOT EXISTS (SELECT 1 FROM beauty_log WHERE user_id = p_user_id) THEN
    PERFORM create_initial_beauty_log(p_user_id, p_hair_type, p_porosity, p_skin_type, p_scalp_type, p_beauty_goals);
  END IF;

  PERFORM generate_beauty_plan(p_user_id);

  RETURN true;
END;
$$;
