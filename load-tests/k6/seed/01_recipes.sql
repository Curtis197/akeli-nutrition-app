-- 01_recipes.sql
-- Seeds 400 synthetic recipes with correct schema:
--   recipe.meal_types  text[]  (added in migration 20260524000003)
--   recipe_macro       separate table (calories NOT on recipe itself)
--   recipe.instructions NOT NULL
--
-- Known test UUIDs (deterministic) so scenario scripts can reference them:
--   first recipe id: '00000000-0000-0000-0000-000000000001'

BEGIN;

-- Seed a test creator (required FK on recipe.creator_id)
INSERT INTO creator (id, user_id, display_name)
SELECT
  '00000000-0000-0000-0000-000000000099'::uuid,
  (SELECT id FROM user_profile LIMIT 1),
  'Test Creator'
WHERE NOT EXISTS (
  SELECT 1 FROM creator WHERE id = '00000000-0000-0000-0000-000000000099'
);

DO $$
DECLARE
  i            INT;
  meal_types   text[][];
  recipe_id    uuid;
  known_id     uuid := '00000000-0000-0000-0000-000000000001';
BEGIN
  -- meal_types cycles: breakfast, lunch, dinner, snack — 100 each
  meal_types := ARRAY[
    ARRAY['breakfast'],
    ARRAY['lunch'],
    ARRAY['dinner'],
    ARRAY['snack']
  ];

  FOR i IN 1..400 LOOP
    -- First recipe gets a known deterministic UUID for scenario scripts
    recipe_id := CASE WHEN i = 1 THEN known_id ELSE gen_random_uuid() END;

    INSERT INTO recipe (id, creator_id, title, instructions, meal_types, is_published, prep_time_min, cook_time_min)
    VALUES (
      recipe_id,
      '00000000-0000-0000-0000-000000000099',
      'Synthetic Recipe ' || i,
      'Step 1: Cook. Step 2: Serve.',
      meal_types[1 + ((i - 1) % 4)],
      true,
      15,
      20
    );

    -- recipe_macro is required for the meal generator (calories live here)
    INSERT INTO recipe_macro (recipe_id, calories, protein_g, carbs_g, fat_g)
    VALUES (
      recipe_id,
      400 + ((i - 1) % 200),   -- 400–599 kcal range
      25 + ((i - 1) % 20),
      45 + ((i - 1) % 30),
      12 + ((i - 1) % 10)
    );

    -- recipe_vector is required for cosine similarity ranking
    -- Using a random 50-dim vector; real tests should use realistic embeddings
    INSERT INTO recipe_vector (recipe_id, vector)
    VALUES (
      recipe_id,
      (
        SELECT ('[' || string_agg(round(random()::numeric, 4)::text, ',') || ']')::vector
        FROM generate_series(1, 50)
      )
    )
    ON CONFLICT (recipe_id) DO NOTHING;
  END LOOP;
END $$;

COMMIT;
