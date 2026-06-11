-- Fix: meal_consumption.creator_id FK was pointing to user_profile(id) instead of creator(id).
-- recipe.creator_id → creator(id), so meal_consumption.creator_id must also reference creator(id).
-- The mismatch caused FK violations whenever a recipe's creator_id existed in creator but not user_profile.

ALTER TABLE meal_consumption
  DROP CONSTRAINT IF EXISTS meal_consumption_creator_id_fkey;

ALTER TABLE meal_consumption
  ADD CONSTRAINT meal_consumption_creator_id_fkey
    FOREIGN KEY (creator_id) REFERENCES creator(id) ON DELETE SET NULL;
