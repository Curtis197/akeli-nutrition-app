-- =============================================================================
-- Migration: 20260525000005_cooking_session_ingredient.sql
-- Description: Add scale_factor to cooking_session and create cooking_session_ingredient
-- =============================================================================

-- 1. Add scale_factor to cooking_session
ALTER TABLE cooking_session
  ADD COLUMN IF NOT EXISTS scale_factor numeric(6,3);

-- 2. Create cooking_session_ingredient table
CREATE TABLE IF NOT EXISTS cooking_session_ingredient (
  id                  uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  cooking_session_id  uuid REFERENCES cooking_session(id) ON DELETE CASCADE,
  ingredient_id       uuid REFERENCES ingredient(id),
  ingredient_name     text NOT NULL,
  quantity_needed     numeric(10,3) NOT NULL,
  unit                text NOT NULL,
  created_at          timestamptz DEFAULT now()
);

-- 3. Indexes
CREATE INDEX IF NOT EXISTS idx_csi_session ON cooking_session_ingredient(cooking_session_id);

-- 4. RLS for cooking_session_ingredient
ALTER TABLE cooking_session_ingredient ENABLE ROW LEVEL SECURITY;

CREATE POLICY "owner via cooking_session" ON cooking_session_ingredient
  FOR ALL USING (
    cooking_session_id IN (
      SELECT cs.id FROM cooking_session cs
      WHERE cs.user_id = auth.uid()
    )
  );

-- Note: meal_plan_entry_component.cooking_session_id is already ON DELETE SET NULL
-- from its original creation in 20260516000001_modular_meal_batch_cooking.sql
