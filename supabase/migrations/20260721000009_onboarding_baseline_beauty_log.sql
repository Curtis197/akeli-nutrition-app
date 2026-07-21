-- Migration: Onboarding Baseline Beauty Log RPC
-- File: supabase/migrations/20260721000009_onboarding_baseline_beauty_log.sql

CREATE OR REPLACE FUNCTION create_initial_beauty_log(
    p_user_id UUID,
    p_hair_length_cm NUMERIC DEFAULT NULL,
    p_hair_strength_score NUMERIC DEFAULT NULL,
    p_hair_thickness_score NUMERIC DEFAULT NULL,
    p_hair_shedding_rate TEXT DEFAULT NULL,
    p_skin_hydration_level NUMERIC DEFAULT NULL,
    p_skin_clarity_score NUMERIC DEFAULT NULL,
    p_checkin_notes TEXT DEFAULT 'Initial onboarding baseline check-in'
)
RETURNS UUID
LANGUAGE plpgsql
AS $$
DECLARE
    v_log_id UUID;
BEGIN
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
    )
    RETURNING id INTO v_log_id;

    RETURN v_log_id;
END;
$$;
