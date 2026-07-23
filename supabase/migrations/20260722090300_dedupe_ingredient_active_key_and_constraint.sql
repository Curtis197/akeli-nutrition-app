-- Migration: De-duplicate ingredient rows for the 9 beauty active_keys re-inserted
-- by 20260720000009_extensive_ingredient_seed_catalog.sql (ON CONFLICT DO NOTHING
-- was a no-op because ingredient has no UNIQUE constraint on active_key), collapse
-- the resulting duplicate recipe_ingredient line items, then add a real UNIQUE
-- constraint so this cannot recur.
-- File: supabase/migrations/20260722090300_dedupe_ingredient_active_key_and_constraint.sql
-- Fixes: Beauty Mode Branch Review 2026-07-23, Area A, Finding #5 (Medium/High).

-- Step 1: reassign recipe_ingredient rows pointing at a duplicate (to-be-deleted)
-- ingredient row over to the row we are keeping for that active_key. We keep the
-- most recently inserted row per active_key (20260720000009's copy, which carries
-- a superset of beauty_virtues vs. 20260720000005's original insert — e.g.
-- shea_butter/chebe/ricin gain 'protective_care', black_seed/argan/clay gain
-- 'glow_brightening', jojoba gains 'scalp_soothing'); ties broken by id descending
-- for determinism.
WITH ranked AS (
  SELECT
    id,
    active_key,
    ROW_NUMBER() OVER (
      PARTITION BY active_key
      ORDER BY created_at DESC, id DESC
    ) AS rn
  FROM ingredient
  WHERE active_key IN (
    'shea_butter', 'chebe', 'aloe_vera', 'black_seed',
    'argan', 'ricin', 'hibiscus', 'clay', 'jojoba'
  )
),
keepers AS (
  SELECT active_key, id AS keep_id FROM ranked WHERE rn = 1
),
duplicates AS (
  SELECT r.id AS dup_id, k.keep_id
  FROM ranked r
  JOIN keepers k ON k.active_key = r.active_key
  WHERE r.rn > 1
)
UPDATE recipe_ingredient ri
SET ingredient_id = d.keep_id
FROM duplicates d
WHERE ri.ingredient_id = d.dup_id;

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
  WHERE ingredient_id IN (
    SELECT id FROM ingredient WHERE active_key IN (
      'shea_butter', 'chebe', 'aloe_vera', 'black_seed',
      'argan', 'ricin', 'hibiscus', 'clay', 'jojoba'
    )
  )
)
DELETE FROM recipe_ingredient
USING dup_lines
WHERE recipe_ingredient.id = dup_lines.id
  AND dup_lines.rn > 1;

-- Step 3: delete the now-unreferenced duplicate ingredient rows.
WITH ranked AS (
  SELECT
    id,
    active_key,
    ROW_NUMBER() OVER (
      PARTITION BY active_key
      ORDER BY created_at DESC, id DESC
    ) AS rn
  FROM ingredient
  WHERE active_key IN (
    'shea_butter', 'chebe', 'aloe_vera', 'black_seed',
    'argan', 'ricin', 'hibiscus', 'clay', 'jojoba'
  )
)
DELETE FROM ingredient
USING ranked
WHERE ingredient.id = ranked.id
  AND ranked.rn > 1;

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
