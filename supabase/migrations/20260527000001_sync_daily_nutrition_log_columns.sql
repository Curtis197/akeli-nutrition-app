-- Rename daily_nutrition_log columns to match application schema.
-- The initial_schema migration was edited locally after being applied to
-- the remote DB, leaving the remote with old column names.
-- The trigger function (update_daily_nutrition_on_consumption) and all
-- Dart providers already use the new names, so the table was broken.

DO $$ BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='daily_nutrition_log' AND column_name='date') THEN
    ALTER TABLE daily_nutrition_log RENAME COLUMN date TO log_date;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='daily_nutrition_log' AND column_name='total_calories') THEN
    ALTER TABLE daily_nutrition_log RENAME COLUMN total_calories TO calories;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='daily_nutrition_log' AND column_name='total_protein_g') THEN
    ALTER TABLE daily_nutrition_log RENAME COLUMN total_protein_g TO protein_g;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='daily_nutrition_log' AND column_name='total_carbs_g') THEN
    ALTER TABLE daily_nutrition_log RENAME COLUMN total_carbs_g TO carbs_g;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='daily_nutrition_log' AND column_name='total_fat_g') THEN
    ALTER TABLE daily_nutrition_log RENAME COLUMN total_fat_g TO fat_g;
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='daily_nutrition_log' AND column_name='created_at'
    AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='daily_nutrition_log' AND column_name='updated_at')) THEN
    ALTER TABLE daily_nutrition_log RENAME COLUMN created_at TO updated_at;
  END IF;
END $$;

ALTER TABLE daily_nutrition_log
  ADD COLUMN IF NOT EXISTS fiber_g     numeric(6,1) DEFAULT 0,
  ADD COLUMN IF NOT EXISTS meals_count int          DEFAULT 0;
