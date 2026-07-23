-- supabase/tests/ingredient_active_key_dedup_test.sql
-- Fixes: Beauty Mode Branch Review 2026-07-23, Area A, Finding #5 (Medium/High).
-- ingredient has no UNIQUE constraint on active_key, so ON CONFLICT DO NOTHING in
-- 20260720000009_extensive_ingredient_seed_catalog.sql was a no-op against rows
-- already inserted by 20260720000005_ingredient_virtues_micronutrients.sql for the
-- same 9 active_keys, producing duplicate ingredient rows (and, via
-- 20260720000012's `JOIN ingredient ON active_key = '<key>'` linking pattern,
-- duplicate recipe_ingredient line items too).
BEGIN;
SELECT plan(12);

SELECT is((SELECT count(*)::int FROM ingredient WHERE active_key = 'shea_butter'), 1, 'exactly one shea_butter ingredient row remains');
SELECT is((SELECT count(*)::int FROM ingredient WHERE active_key = 'chebe'), 1, 'exactly one chebe ingredient row remains');
SELECT is((SELECT count(*)::int FROM ingredient WHERE active_key = 'aloe_vera'), 1, 'exactly one aloe_vera ingredient row remains');
SELECT is((SELECT count(*)::int FROM ingredient WHERE active_key = 'black_seed'), 1, 'exactly one black_seed ingredient row remains');
SELECT is((SELECT count(*)::int FROM ingredient WHERE active_key = 'argan'), 1, 'exactly one argan ingredient row remains');
SELECT is((SELECT count(*)::int FROM ingredient WHERE active_key = 'ricin'), 1, 'exactly one ricin ingredient row remains');
SELECT is((SELECT count(*)::int FROM ingredient WHERE active_key = 'hibiscus'), 1, 'exactly one hibiscus ingredient row remains');
SELECT is((SELECT count(*)::int FROM ingredient WHERE active_key = 'clay'), 1, 'exactly one clay ingredient row remains');
SELECT is((SELECT count(*)::int FROM ingredient WHERE active_key = 'jojoba'), 1, 'exactly one jojoba ingredient row remains');

-- The kept row is the more complete copy (20260720000009's insert has a superset
-- of beauty_virtues vs. 20260720000005's original — e.g. shea_butter gained
-- 'protective_care').
SELECT ok(
  (SELECT bool_or('protective_care' = ANY(beauty_virtues)) FROM ingredient WHERE active_key = 'shea_butter'),
  'the shea_butter row that survives has protective_care in beauty_virtues'
);

-- A real UNIQUE constraint on active_key now exists.
SELECT ok(
  EXISTS (
    SELECT 1 FROM information_schema.table_constraints
    WHERE table_name = 'ingredient'
      AND constraint_name = 'ingredient_active_key_unique'
      AND constraint_type = 'UNIQUE'
  ),
  'ingredient_active_key_unique UNIQUE constraint exists on ingredient(active_key)'
);

-- The fan-out into duplicate recipe_ingredient line items is also collapsed.
SELECT is(
  (SELECT count(*)::int FROM recipe_ingredient ri
   JOIN ingredient i ON i.id = ri.ingredient_id
   WHERE ri.recipe_id = 'b0000001-0000-0000-0000-000000000001'::uuid
     AND i.active_key = 'shea_butter'),
  1,
  'recipe b0000001 has exactly one shea_butter line item, not a duplicate'
);

SELECT * FROM finish();
ROLLBACK;
