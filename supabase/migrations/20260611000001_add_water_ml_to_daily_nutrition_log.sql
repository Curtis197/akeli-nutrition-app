ALTER TABLE daily_nutrition_log
  ADD COLUMN IF NOT EXISTS water_ml numeric(6,0) DEFAULT 0;
