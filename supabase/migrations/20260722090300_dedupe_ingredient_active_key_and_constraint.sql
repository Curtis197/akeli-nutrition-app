-- Migration: De-duplicate ingredient rows for any active_key inserted more than
-- once (root cause: several seed migrations INSERT the same beauty active_keys
-- with `ON CONFLICT DO NOTHING`, which was a no-op because ingredient had no
-- UNIQUE constraint on active_key — repeated out-of-band re-runs during
-- development left some active_keys with 2, others with 4, copies), collapse
-- the resulting duplicate recipe_ingredient line items, then add a real UNIQUE
-- constraint so this cannot recur.
-- File: supabase/migrations/20260722090300_dedupe_ingredient_active_key_and_constraint.sql
-- Fixes: Beauty Mode Branch Review 2026-07-23, Area A, Finding #5 (Medium/High).
--
-- Originally scoped to a hardcoded list of 9 active_keys (matching what local
-- had); production had accumulated duplicates across 48 active_keys (9 of them
-- with 4 copies, not 2) from repeated manual re-seeding, so this is written
-- generically against whatever is actually duplicated rather than a fixed list.

-- Step 1: reassign every FK reference to a duplicate (to-be-deleted) ingredient
-- row over to the row we are keeping for that active_key. We keep the most
-- recently inserted row per active_key; ties broken by id descending for
-- determinism.
--
-- Computed once into a temp table and reused for every FK-referencing table
-- (ingredient.id is referenced by 9 tables in this schema — the original
-- version of this migration only reassigned recipe_ingredient and hard-failed
-- on production because a real shopping_list_item row referenced a duplicate).
CREATE TEMP TABLE ingredient_dedup_map ON COMMIT DROP AS
WITH ranked AS (
  SELECT
    id,
    active_key,
    ROW_NUMBER() OVER (
      PARTITION BY active_key
      ORDER BY created_at DESC, id DESC
    ) AS rn
  FROM ingredient
  WHERE active_key IS NOT NULL
),
keepers AS (
  SELECT active_key, id AS keep_id FROM ranked WHERE rn = 1
)
SELECT r.id AS dup_id, k.keep_id
FROM ranked r
JOIN keepers k ON k.active_key = r.active_key
WHERE r.rn > 1;

UPDATE recipe_ingredient ri
SET ingredient_id = d.keep_id
FROM ingredient_dedup_map d
WHERE ri.ingredient_id = d.dup_id;

UPDATE shopping_list_item t SET ingredient_id = d.keep_id
FROM ingredient_dedup_map d WHERE t.ingredient_id = d.dup_id;

UPDATE ingredient_submission t SET ingredient_id = d.keep_id
FROM ingredient_dedup_map d WHERE t.ingredient_id = d.dup_id;

UPDATE unit_conversion t SET ingredient_id = d.keep_id
FROM ingredient_dedup_map d WHERE t.ingredient_id = d.dup_id;

UPDATE cooking_session_ingredient t SET ingredient_id = d.keep_id
FROM ingredient_dedup_map d WHERE t.ingredient_id = d.dup_id;

UPDATE meal_ingredient t SET ingredient_id = d.keep_id
FROM ingredient_dedup_map d WHERE t.ingredient_id = d.dup_id;

UPDATE ingredient_allergen t SET ingredient_id = d.keep_id
FROM ingredient_dedup_map d WHERE t.ingredient_id = d.dup_id;

UPDATE ingredient_rounding_rule t SET ingredient_id = d.keep_id
FROM ingredient_dedup_map d WHERE t.ingredient_id = d.dup_id;

UPDATE ingredient_market_price t SET ingredient_id = d.keep_id
FROM ingredient_dedup_map d WHERE t.ingredient_id = d.dup_id;

-- Step 2: 20260720000012_beauty_recipe_ingredients_steps_and_translations.sql
-- links recipe ingredients via `JOIN ingredient i ON i.active_key = '<key>'`,
-- which fanned out across both duplicate ingredient rows and inserted the same
-- conceptual line item twice per recipe. After the reassignment above, those
-- pairs are now identical (recipe_id, ingredient_id) rows — collapse them,
-- keeping the lowest id.
WITH dup_lines AS (
  SELECT
    id,
    ROW_NUMBER() OVER (
      PARTITION BY recipe_id, ingredient_id
      ORDER BY id
    ) AS rn
  FROM recipe_ingredient
  WHERE ingredient_id IN (SELECT keep_id FROM ingredient_dedup_map)
)
DELETE FROM recipe_ingredient
USING dup_lines
WHERE recipe_ingredient.id = dup_lines.id
  AND dup_lines.rn > 1;

-- Step 3: delete the now-unreferenced duplicate ingredient rows (all FKs were
-- reassigned in Step 1, so this is safe regardless of which tables reference them).
DELETE FROM ingredient
WHERE id IN (SELECT dup_id FROM ingredient_dedup_map);

-- Step 4: add a real UNIQUE constraint on active_key so ON CONFLICT (active_key)
-- becomes meaningful and this class of duplicate can't recur. NULLs (nutrition
-- ingredients with no active_key) are unaffected — Postgres UNIQUE allows
-- multiple NULLs. Guarded idempotently, matching the existence-check idiom
-- already used for CREATE POLICY in 20260522000001_create_sdui_layouts.sql.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_name = 'ingredient'
      AND constraint_name = 'ingredient_active_key_unique'
  ) THEN
    ALTER TABLE ingredient
      ADD CONSTRAINT ingredient_active_key_unique UNIQUE (active_key);
  END IF;
END $$;
