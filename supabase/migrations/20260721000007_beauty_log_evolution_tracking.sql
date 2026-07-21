-- Migration: Extensive Beauty Log & Evolution Tracking Table
-- File: supabase/migrations/20260721000007_beauty_log_evolution_tracking.sql

CREATE TABLE IF NOT EXISTS beauty_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES user_profile(id) ON DELETE CASCADE,
    
    -- 💇‍♀️ HAIR METRICS
    hair_length_cm NUMERIC(5,2),             -- Stretched length in cm
    hair_strength_score NUMERIC(3,2),        -- 1.0 to 10.0 (Elasticity & anti-breakage)
    hair_thickness_score NUMERIC(3,2),       -- 1.0 to 10.0 (Strand density & volume)
    hair_shedding_rate TEXT,                  -- 'low', 'normal', 'high', 'excessive'
    scalp_health_score NUMERIC(3,2),         -- 1.0 to 10.0 (Calmness & no itching)
    curl_retention_score NUMERIC(3,2),       -- 1.0 to 10.0 (Definition & bounce)
    porosity_level TEXT,                     -- 'low', 'medium', 'high'
    protective_style_active BOOLEAN DEFAULT FALSE,
    
    -- 🧴 SKIN METRICS
    skin_hydration_level NUMERIC(3,2),       -- 1.0 to 10.0 (Moisture barrier)
    skin_clarity_score NUMERIC(3,2),         -- 1.0 to 10.0 (Even tone & dark spot fading)
    sebum_oil_level TEXT,                    -- 'dry', 'balanced', 'oily', 'excessive'
    acne_breakout_count INT DEFAULT 0,
    skin_elasticity_score NUMERIC(3,2),       -- 1.0 to 10.0 (Firmness & smoothness)
    skin_redness_level TEXT,                 -- 'none', 'mild', 'moderate', 'severe'
    
    -- 📋 ROUTINE COMPLIANCE & JOURNAL
    routine_compliance_pct NUMERIC(5,2),     -- 0.0 to 100.0% weekly completion rate
    routine_satisfaction_score NUMERIC(3,2), -- 1.0 to 10.0 subjective score
    checkin_photo_urls TEXT[],               -- Array of progress photo URLs
    checkin_notes TEXT,                      -- User journal note
    
    logged_at TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Index for time-series evolution queries
CREATE INDEX IF NOT EXISTS idx_beauty_log_user_logged ON beauty_log(user_id, logged_at DESC);

-- Enable RLS
ALTER TABLE beauty_log ENABLE ROW LEVEL SECURITY;

-- RLS Policies
CREATE POLICY "Users can read own beauty logs"
    ON beauty_log FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own beauty logs"
    ON beauty_log FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own beauty logs"
    ON beauty_log FOR UPDATE
    USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own beauty logs"
    ON beauty_log FOR DELETE
    USING (auth.uid() = user_id);

-- Helper RPC: Fetch beauty evolution history for progress graphs
CREATE OR REPLACE FUNCTION get_beauty_evolution_history(p_user_id UUID, p_limit INT DEFAULT 30)
RETURNS TABLE (
    log_id UUID,
    hair_length_cm NUMERIC(5,2),
    hair_strength_score NUMERIC(3,2),
    hair_thickness_score NUMERIC(3,2),
    skin_hydration_level NUMERIC(3,2),
    skin_clarity_score NUMERIC(3,2),
    routine_compliance_pct NUMERIC(5,2),
    checkin_photo_urls TEXT[],
    checkin_notes TEXT,
    logged_at TIMESTAMPTZ
)
LANGUAGE plpgsql
STABLE
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        bl.id AS log_id,
        bl.hair_length_cm,
        bl.hair_strength_score,
        bl.hair_thickness_score,
        bl.skin_hydration_level,
        bl.skin_clarity_score,
        bl.routine_compliance_pct,
        bl.checkin_photo_urls,
        bl.checkin_notes,
        bl.logged_at
    FROM beauty_log bl
    WHERE bl.user_id = p_user_id
    ORDER BY bl.logged_at DESC
    LIMIT p_limit;
END;
$$;
