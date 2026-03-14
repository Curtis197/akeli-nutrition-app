-- =============================================================================
-- Migration: 20260302000003_add_recipe_steps.sql
-- Description: Add recipe_step table for detailed instructions
-- =============================================================================

CREATE TABLE IF NOT EXISTS recipe_step (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id       uuid REFERENCES recipe(id) ON DELETE CASCADE,
  step_number     int NOT NULL,
  instruction     text NOT NULL,
  duration_min    int,
  image_url       text,
  created_at      timestamptz DEFAULT now()
);

-- Indice pour optimiser le fetch par recette
CREATE INDEX IF NOT EXISTS idx_recipe_step_recipe ON recipe_step(recipe_id);

-- RLS
ALTER TABLE recipe_step ENABLE ROW LEVEL SECURITY;

CREATE POLICY "public reads recipe_step" ON recipe_step 
  FOR SELECT USING (true);

CREATE POLICY "creator manages recipe_step" ON recipe_step
  USING (
    recipe_id IN (
      SELECT r.id FROM recipe r
      JOIN creator c ON r.creator_id = c.id
      WHERE c.user_id = auth.uid()
    )
  );

-- Trigger pour updated_at (optionnel car pas encore de updated_at sur cette table, 
-- mais bon réflexe pour le futur si on l'ajoute)
-- ALTER TABLE recipe_step ADD COLUMN updated_at timestamptz DEFAULT now();
-- CREATE TRIGGER trg_recipe_step_updated_at
--   BEFORE UPDATE ON recipe_step
--   FOR EACH ROW EXECUTE FUNCTION update_updated_at();
