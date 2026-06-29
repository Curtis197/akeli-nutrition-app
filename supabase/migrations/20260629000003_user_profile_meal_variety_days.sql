-- supabase/migrations/20260629000003_user_profile_meal_variety_days.sql
-- Description: Add meal_variety_days to user_profile.
-- Values: 0 (none), 7 (7-day window, default), 15 (15-day window).
-- Existing rows get DEFAULT 7 automatically.

ALTER TABLE public.user_profile
  ADD COLUMN IF NOT EXISTS meal_variety_days INT NOT NULL DEFAULT 7
  CONSTRAINT meal_variety_days_check CHECK (meal_variety_days IN (0, 7, 15));

COMMENT ON COLUMN public.user_profile.meal_variety_days IS
  'Cross-plan recipe blacklist window in days. 0=off, 7=7-day (default), 15=15-day.';
