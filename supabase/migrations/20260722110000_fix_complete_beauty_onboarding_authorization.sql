-- Migration: 20260722110000_fix_complete_beauty_onboarding_authorization.sql
-- Finding #1 (Area C, Critical): complete_beauty_onboarding is
-- SECURITY DEFINER with no auth.uid() = p_user_id check. Any authenticated
-- client can call it directly via supabase.rpc(...), bypassing the
-- complete-beauty-onboarding edge function's own auth entirely, and
-- overwrite another user's health profile / onboarding flag / plan.
--
-- This CREATE OR REPLACE targets the exact 14-parameter signature that is
-- live today (confirmed by reading 20260721000016, 20260721000017, and
-- 20260721000018 — the final rewrite; no later migration touches this
-- function). Every line below Step 0 is unchanged from 20260721000018.

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
  -- Step 0 (new): reject any caller who is not the profile owner.
  IF auth.uid() IS DISTINCT FROM p_user_id THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

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

  -- 4. Generate initial Beauty Plan for remainder of current week until Sunday (matching Nutrition mode parity)
  PERFORM generate_initial_beauty_plan(p_user_id);

  RETURN true;
END;
$$;
