-- =============================================================================
-- Migration: 20260601000002_unique_recipe_comment.sql
-- Description: Enforce 1 comment per user per recipe
-- =============================================================================

BEGIN;

-- 1. Deduplicate existing comments (keep the most recent comment for each user on each recipe)
DELETE FROM recipe_comment
WHERE id IN (
  SELECT id
  FROM (
    SELECT id,
           ROW_NUMBER() OVER (PARTITION BY recipe_id, user_id ORDER BY created_at DESC) as row_num
    FROM recipe_comment
  ) t
  WHERE t.row_num > 1
);

-- 2. Add the unique constraint
ALTER TABLE recipe_comment
  ADD CONSTRAINT unique_user_recipe_comment UNIQUE (user_id, recipe_id);

COMMIT;
