ALTER TABLE user_health_profile
  ADD COLUMN IF NOT EXISTS starting_weight_kg numeric(5,1),
  ADD COLUMN IF NOT EXISTS target_time_weeks integer;

COMMENT ON COLUMN user_health_profile.starting_weight_kg IS 'ROLE: User starting weight | PURPOSE: Track total progress from origin';
COMMENT ON COLUMN user_health_profile.target_time_weeks IS 'ROLE: Goal duration in weeks | PURPOSE: Compute weekly weight loss rate';
