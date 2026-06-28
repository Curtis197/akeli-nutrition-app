-- supabase/migrations/20260628000001_add_meal_schedule_columns.sql

-- meal_distribution: per-slot display label + macro targets
ALTER TABLE meal_distribution
  ADD COLUMN IF NOT EXISTS nickname    text,
  ADD COLUMN IF NOT EXISTS protein_pct double precision,
  ADD COLUMN IF NOT EXISTS carbs_pct   double precision,
  ADD COLUMN IF NOT EXISTS fat_pct     double precision;

-- meal_plan_entry: propagated from distribution at generation time
ALTER TABLE meal_plan_entry
  ADD COLUMN IF NOT EXISTS nickname   text,
  ADD COLUMN IF NOT EXISTS sort_order integer;

-- user_profile: hint banner dismissal flag
ALTER TABLE user_profile
  ADD COLUMN IF NOT EXISTS has_dismissed_meal_schedule_hint boolean NOT NULL DEFAULT false;
