-- Migration: 20260721000018_first_beauty_log_onboarding.sql
-- Description: Update complete_beauty_onboarding RPC to accept initial baseline beauty_log measurements

DROP FUNCTION IF EXISTS complete_beauty_onboarding(uuid, text, text, text, text, text[]);
DROP FUNCTION IF EXISTS complete_beauty_onboarding(uuid, text, text, text, text, text[], text[]);
DROP FUNCTION IF EXISTS complete_beauty_onboarding(uuid, text, text, text, text, text[], text[], numeric, numeric, numeric, text, numeric, numeric, text);

CREATE OR REPLACE FUNCTION complete_beauty_onboarding(
  p_user_id              uuid,
  p_hair_type            text,
  p_porosity             text,
  p_skin_type            text,
  p_scalp_type           text,
  p_beauty_goals         text[],
  p_skin_concerns        text[] DEFAULT '{}',
  p_hair_length_cm       numeric DEFAULT 15,
  p_hair_strength_score   numeric DEFAULT 7,
  p_hair_thickness_score  numeric DEFAULT 7,
  p_hair_shedding_rate   text DEFAULT 'moderate',
  p_skin_hydration_level numeric DEFAULT 7,
  p_skin_clarity_score   numeric DEFAULT 7,
  p_checkin_notes        text DEFAULT 'Premier journal de bord initial'
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  -- 1. Upsert user_health_profile
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

  -- 2. Mark beauty_onboarding_done = true on user_profile
  UPDATE user_profile
  SET beauty_onboarding_done = true
  WHERE id = p_user_id;

  -- 3. Insert initial baseline beauty_log checkin
  INSERT INTO beauty_log (
    user_id,
    hair_length_cm,
    hair_strength_score,
    hair_thickness_score,
    hair_shedding_rate,
    skin_hydration_level,
    skin_clarity_score,
    checkin_notes,
    logged_at
  )
  VALUES (
    p_user_id,
    p_hair_length_cm,
    p_hair_strength_score,
    p_hair_thickness_score,
    p_hair_shedding_rate,
    p_skin_hydration_level,
    p_skin_clarity_score,
    p_checkin_notes,
    NOW()
  );

  -- 4. Generate initial 30-day Beauty Plan
  PERFORM generate_beauty_plan(p_user_id);

  RETURN true;
END;
$$;
