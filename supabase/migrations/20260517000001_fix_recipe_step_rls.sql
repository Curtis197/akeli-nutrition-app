-- =============================================================================
-- AKELI V1 — Migration: Fix recipe_step RLS Policies
-- Migration: 20260517000001_fix_recipe_step_rls.sql
-- Fixes RLS-01: SELECT policy references r.status (column doesn't exist)
-- Fixes RLS-02: Mutate policy checks creator_id = auth.uid() (wrong join)
-- =============================================================================

-- DROP the two broken policies created in 20260314000001_recipe_tracking_schema.sql

DROP POLICY IF EXISTS "recipe_step_select_published" ON recipe_step;
DROP POLICY IF EXISTS "recipe_step_mutate_creator" ON recipe_step;

-- Public can read steps of published recipes (uses is_published boolean, not r.status)
CREATE POLICY "recipe_step_select_published" ON recipe_step
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM recipe r
      WHERE r.id = recipe_step.recipe_id
        AND r.is_published = true
    )
  );

-- Only the recipe creator can insert/update/delete steps
-- creator_id on recipe references the creator table (not auth.users),
-- so we must join through creator.user_id to get the auth UUID.
CREATE POLICY "recipe_step_mutate_creator" ON recipe_step
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM recipe r
      JOIN creator c ON c.id = r.creator_id
      WHERE r.id = recipe_step.recipe_id
        AND c.user_id = auth.uid()
    )
  );
