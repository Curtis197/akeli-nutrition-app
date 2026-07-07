-- Migration: health_profile_target_date
-- Replaces target_time_weeks (an unanchored duration) with target_date
-- (a date anchor), per spec D1/D4:
-- docs/superpowers/specs/2026-07-07-nutrition-targets-calculation-design-v2.md §1.3
-- Backfill: existing durations are re-anchored to today. Approximate by
-- design — the local DB has no production users yet.

ALTER TABLE public.user_health_profile
  ADD COLUMN IF NOT EXISTS target_date date;

COMMENT ON COLUMN public.user_health_profile.target_date IS
  'ROLE: Goal deadline | PURPOSE: pace = remaining delta / remaining weeks (floor 4) in calculate_nutrition_targets callers';

UPDATE public.user_health_profile
SET target_date = CURRENT_DATE + (target_time_weeks * 7)
WHERE target_time_weeks IS NOT NULL AND target_date IS NULL;

ALTER TABLE public.user_health_profile
  DROP COLUMN IF EXISTS target_time_weeks;
