-- ================================================================
-- AKELI BEAUTY MODE: ADD BEAUTY DIAGNOSTIC COLUMNS TO USER_HEALTH_PROFILE
-- ================================================================

ALTER TABLE user_health_profile
  ADD COLUMN IF NOT EXISTS hair_type VARCHAR(20) DEFAULT '4C',
  ADD COLUMN IF NOT EXISTS porosity VARCHAR(20) DEFAULT 'medium',
  ADD COLUMN IF NOT EXISTS skin_type VARCHAR(20) DEFAULT 'combination',
  ADD COLUMN IF NOT EXISTS sensitive_scalp BOOLEAN DEFAULT false,
  ADD COLUMN IF NOT EXISTS beauty_goals TEXT[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS preferred_actives TEXT[] DEFAULT '{}';

COMMENT ON COLUMN user_health_profile.hair_type IS 'Beauty diagnostic: Hair curl pattern (e.g. 4A, 4B, 4C, 3C)';
COMMENT ON COLUMN user_health_profile.porosity IS 'Beauty diagnostic: Hair porosity (high, medium, low)';
COMMENT ON COLUMN user_health_profile.skin_type IS 'Beauty diagnostic: Skin type (dry, oily, combination, sensitive, normal)';
COMMENT ON COLUMN user_health_profile.sensitive_scalp IS 'Beauty diagnostic: Sensitive scalp indicator';
COMMENT ON COLUMN user_health_profile.beauty_goals IS 'Beauty diagnostic: Goal tags (growth, glow, anti_breakage, protective_style)';
COMMENT ON COLUMN user_health_profile.preferred_actives IS 'Beauty diagnostic: Natural active ingredients preferences (shea_butter, aloe_vera, chebe, ricin, etc)';
