-- recipe_weight_impact
-- Stores per-user, per-recipe average weight delta computed by the Python nightly batch.
-- Algorithm: for each consecutive weight log pair, assign the delta to all recipes
-- consumed in that period. Average across all periods. min_samples = 3.

CREATE TABLE IF NOT EXISTS recipe_weight_impact (
  user_id       uuid             NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  recipe_id     uuid             NOT NULL REFERENCES recipe(id)     ON DELETE CASCADE,
  avg_delta_kg  double precision NOT NULL,
  sample_count  integer          NOT NULL,
  computed_at   timestamptz      NOT NULL DEFAULT now(),
  PRIMARY KEY (user_id, recipe_id)
);

ALTER TABLE recipe_weight_impact ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users read own recipe_weight_impact"
  ON recipe_weight_impact FOR SELECT
  USING (auth.uid() = user_id);

-- Index to quickly fetch the best recipe (lowest avg_delta_kg = most weight loss)
CREATE INDEX idx_recipe_weight_impact_user_delta
  ON recipe_weight_impact (user_id, avg_delta_kg ASC);
