-- Migration: 20260611000004_add_ingredient_ids_to_recipe_step.sql
-- Description: Add ingredient_ids array to recipe_step so cooking mode can
--              filter the ingredient list to only those used in each step.

ALTER TABLE recipe_step ADD COLUMN IF NOT EXISTS ingredient_ids uuid[] DEFAULT '{}';
