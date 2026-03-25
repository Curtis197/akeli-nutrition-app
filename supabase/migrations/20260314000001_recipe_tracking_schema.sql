-- V1 Recipe Schema Additions
-- Adds: recipe_step, recipe_save, recipe_impression, recipe_open
-- Drops: recipe.instructions (replaced by recipe_step)
-- Author: Curtis — Fondateur Akeli
-- Date: 2026-03-14

-- ============================================================
-- 1. DROP recipe.instructions
-- Safe: table was empty at migration time.
-- recipe_translation.instructions is preserved (translated text block, V2 will add step-level translation).
-- ============================================================

ALTER TABLE recipe DROP COLUMN IF EXISTS instructions;


-- ============================================================
-- 2. recipe_step — Structured preparation steps
-- ============================================================

CREATE TABLE recipe_step (
  id              uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id       uuid NOT NULL REFERENCES recipe(id) ON DELETE CASCADE,
  step_number     int  NOT NULL,
  title           text,
  content         text NOT NULL,
  image_url       text,
  timer_seconds   int,
  created_at      timestamptz DEFAULT now(),

  CONSTRAINT uq_recipe_step_order UNIQUE (recipe_id, step_number)
);

CREATE INDEX idx_recipe_step_recipe ON recipe_step (recipe_id);

-- RLS
ALTER TABLE recipe_step ENABLE ROW LEVEL SECURITY;

-- Public can read steps of published recipes
CREATE POLICY "recipe_step_select_published" ON recipe_step
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM recipe r
      WHERE r.id = recipe_step.recipe_id
        AND r.status = 'published'
    )
  );

-- Only the recipe creator can insert/update/delete steps
CREATE POLICY "recipe_step_mutate_creator" ON recipe_step
  FOR ALL USING (
    EXISTS (
      SELECT 1 FROM recipe r
      WHERE r.id = recipe_step.recipe_id
        AND r.creator_id = auth.uid()
    )
  );


-- ============================================================
-- 3. recipe_save — User bookmarks
-- ============================================================

CREATE TABLE recipe_save (
  user_id    uuid NOT NULL REFERENCES user_profile(id) ON DELETE CASCADE,
  recipe_id  uuid NOT NULL REFERENCES recipe(id) ON DELETE CASCADE,
  saved_at   timestamptz DEFAULT now(),

  PRIMARY KEY (user_id, recipe_id)
);

CREATE INDEX idx_recipe_save_user ON recipe_save (user_id);

-- RLS
ALTER TABLE recipe_save ENABLE ROW LEVEL SECURITY;

-- Owner only
CREATE POLICY "recipe_save_owner" ON recipe_save
  FOR ALL USING (user_id = auth.uid());


-- ============================================================
-- 4. recipe_impression — Card seen (passive signal)
-- ============================================================

CREATE TABLE recipe_impression (
  id         uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id  uuid NOT NULL REFERENCES recipe(id) ON DELETE CASCADE,
  user_id    uuid REFERENCES user_profile(id) ON DELETE SET NULL,  -- nullable: anonymous
  source     text NOT NULL CHECK (source IN ('feed', 'search', 'meal_planner')),
  seen_at    timestamptz DEFAULT now()
);

CREATE INDEX idx_recipe_impression_recipe ON recipe_impression (recipe_id);
CREATE INDEX idx_recipe_impression_user   ON recipe_impression (user_id);

-- RLS
ALTER TABLE recipe_impression ENABLE ROW LEVEL SECURITY;

-- Authenticated users can insert their own impressions
CREATE POLICY "recipe_impression_insert_auth" ON recipe_impression
  FOR INSERT WITH CHECK (user_id = auth.uid());

-- Creator can read impressions for their own recipes
CREATE POLICY "recipe_impression_select_creator" ON recipe_impression
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM recipe r
      WHERE r.id = recipe_impression.recipe_id
        AND r.creator_id = auth.uid()
    )
  );


-- ============================================================
-- 5. recipe_open — Recipe opened + session duration (intentional signal)
-- ============================================================

CREATE TABLE recipe_open (
  id                       uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  recipe_id                uuid NOT NULL REFERENCES recipe(id) ON DELETE CASCADE,
  user_id                  uuid REFERENCES user_profile(id) ON DELETE SET NULL,  -- nullable: anonymous
  source                   text NOT NULL CHECK (source IN ('feed', 'search', 'meal_planner')),
  opened_at                timestamptz DEFAULT now(),
  closed_at                timestamptz,
  session_duration_seconds int
);

CREATE INDEX idx_recipe_open_recipe ON recipe_open (recipe_id);
CREATE INDEX idx_recipe_open_user   ON recipe_open (user_id);

-- RLS
ALTER TABLE recipe_open ENABLE ROW LEVEL SECURITY;

-- Authenticated users can insert their own open events
CREATE POLICY "recipe_open_insert_auth" ON recipe_open
  FOR INSERT WITH CHECK (user_id = auth.uid());

-- Owner can update their own row (to send closed_at + session_duration_seconds)
CREATE POLICY "recipe_open_update_owner" ON recipe_open
  FOR UPDATE USING (user_id = auth.uid());

-- Creator can read opens for their own recipes
CREATE POLICY "recipe_open_select_creator" ON recipe_open
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM recipe r
      WHERE r.id = recipe_open.recipe_id
        AND r.creator_id = auth.uid()
    )
  );
