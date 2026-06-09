-- =============================================================================
-- Migration: 20260531000004_add_creator_id_to_meal_consumption.sql
-- Description: Add creator_id to meal_consumption.
--              log-meal-consumption edge function inserts this for creator
--              revenue tracking but the column was never created.
-- =============================================================================

-- creator_id already exists in the initial schema (20260301000001) as REFERENCES creator(id).
-- This migration is a no-op on any DB that ran the initial schema; it is retained only as a
-- documented safety-net for fresh environments. The FK must reference creator(id), NOT user_profile(id).
ALTER TABLE meal_consumption
  ADD COLUMN IF NOT EXISTS creator_id uuid REFERENCES creator(id) ON DELETE SET NULL;
