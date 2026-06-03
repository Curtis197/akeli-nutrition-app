-- =============================================================================
-- Migration: 20260531000003_add_is_cooked_to_cooking_session.sql
-- Description: Add is_cooked to cooking_session.
--              Cooking (batch prep) and meal consumption are independent events.
-- =============================================================================

ALTER TABLE cooking_session ADD COLUMN IF NOT EXISTS is_cooked boolean NOT NULL DEFAULT false;
