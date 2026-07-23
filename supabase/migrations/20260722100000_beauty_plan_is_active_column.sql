-- Migration: Add missing is_active column to beauty_plan + backfill
-- File: supabase/migrations/20260722100000_beauty_plan_is_active_column.sql
-- Fixes: beauty_plan.is_active is referenced by generate_beauty_plan,
-- generate_initial_beauty_plan, and generate_beauty_plan_from_saved (both
-- variants) via UPDATE ... SET is_active = false and INSERT ... is_active,
-- but the column was never created on beauty_plan (created in
-- 20260721000002_beauty_plan_schema_and_generator.sql with only
-- id, user_id, start_date, end_date, created_at, updated_at). Every one of
-- those RPCs fails at runtime with "column is_active does not exist".

ALTER TABLE beauty_plan ADD COLUMN IF NOT EXISTS is_active BOOLEAN NOT NULL DEFAULT true;

-- Backfill: only the most recently created plan per user should be active;
-- older plans (if any already exist) must be marked inactive.
WITH ranked_plans AS (
    SELECT id, ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY created_at DESC) AS rn
    FROM beauty_plan
)
UPDATE beauty_plan bp
SET is_active = (ranked_plans.rn = 1)
FROM ranked_plans
WHERE bp.id = ranked_plans.id;
