-- =============================================================================
-- Migration: 20260531000001_add_consumed_columns_to_meal_plan_entry.sql
-- Description: Add is_consumed and consumed_at columns to meal_plan_entry.
--              Required by log-meal-consumption and rate-meal-consumption
--              edge functions.
-- =============================================================================

ALTER TABLE meal_plan_entry
  ADD COLUMN IF NOT EXISTS is_consumed boolean NOT NULL DEFAULT false,
  ADD COLUMN IF NOT EXISTS consumed_at timestamptz;
