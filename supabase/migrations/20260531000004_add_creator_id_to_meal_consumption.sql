-- =============================================================================
-- Migration: 20260531000004_add_creator_id_to_meal_consumption.sql
-- Description: Add creator_id to meal_consumption.
--              log-meal-consumption edge function inserts this for creator
--              revenue tracking but the column was never created.
-- =============================================================================

ALTER TABLE meal_consumption
  ADD COLUMN IF NOT EXISTS creator_id uuid REFERENCES user_profile(id) ON DELETE SET NULL;
