ALTER TABLE user_health_profile
  ADD COLUMN IF NOT EXISTS weight_goal      TEXT CHECK (weight_goal IN ('loss', 'maintenance', 'gain')),
  ADD COLUMN IF NOT EXISTS muscle_goal      TEXT CHECK (muscle_goal IN ('loss', 'maintenance', 'gain')),
  ADD COLUMN IF NOT EXISTS cooking_time     TEXT CHECK (cooking_time IN ('quick', 'medium', 'any'));
