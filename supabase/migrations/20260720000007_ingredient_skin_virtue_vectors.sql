-- ================================================================
-- AKELI BEAUTY MODE: INGREDIENT SKINCARE VIRTUE WEIGHT VECTORS
-- ================================================================

-- 1. ADD SKINCARE VIRTUE WEIGHTS JSONB TO INGREDIENT TABLE
ALTER TABLE ingredient
  ADD COLUMN IF NOT EXISTS skin_virtue_weights JSONB DEFAULT '{}'::jsonb;

COMMENT ON COLUMN ingredient.skin_virtue_weights IS 'Continuous skincare virtue intensity weights (0.0 to 1.0) across skincare concerns (dry_skin_moisture, oily_acne_sebum, sensitive_skin_soothing, brightening_anti_spots, anti_aging_elasticity, barrier_repair)';

-- 2. UPDATE INGREDIENT SEED WITH CONTINUOUS SKINCARE VIRTUE VECTORS
UPDATE ingredient
SET skin_virtue_weights = '{"dry_skin_moisture": 0.95, "sensitive_skin_soothing": 0.90, "brightening_anti_spots": 0.75, "barrier_repair": 0.80, "anti_aging_elasticity": 0.60}'::jsonb
WHERE active_key = 'aloe_vera' OR name LIKE '%Aloé%';

UPDATE ingredient
SET skin_virtue_weights = '{"oily_acne_sebum": 0.95, "sensitive_skin_soothing": 0.85, "brightening_anti_spots": 0.70, "barrier_repair": 0.60, "dry_skin_moisture": 0.30}'::jsonb
WHERE active_key = 'black_seed' OR name LIKE '%Nigelle%';

UPDATE ingredient
SET skin_virtue_weights = '{"dry_skin_moisture": 0.90, "barrier_repair": 0.95, "anti_aging_elasticity": 0.75, "sensitive_skin_soothing": 0.60, "oily_acne_sebum": 0.10}'::jsonb
WHERE active_key = 'shea_butter' OR name LIKE '%Karité%';

UPDATE ingredient
SET skin_virtue_weights = '{"brightening_anti_spots": 0.95, "anti_aging_elasticity": 0.80, "dry_skin_moisture": 0.50, "sensitive_skin_soothing": 0.40}'::jsonb
WHERE active_key = 'hibiscus' OR name LIKE '%Hibiscus%';

UPDATE ingredient
SET skin_virtue_weights = '{"oily_acne_sebum": 1.00, "sensitive_skin_soothing": 0.60, "brightening_anti_spots": 0.50, "dry_skin_moisture": 0.10}'::jsonb
WHERE active_key = 'clay' OR name LIKE '%Argile%';

UPDATE ingredient
SET skin_virtue_weights = '{"oily_acne_sebum": 0.90, "barrier_repair": 0.85, "dry_skin_moisture": 0.70, "sensitive_skin_soothing": 0.60}'::jsonb
WHERE active_key = 'jojoba' OR name LIKE '%Jojoba%';

UPDATE ingredient
SET skin_virtue_weights = '{"anti_aging_elasticity": 0.90, "dry_skin_moisture": 0.85, "barrier_repair": 0.80, "brightening_anti_spots": 0.60}'::jsonb
WHERE active_key = 'argan' OR name LIKE '%Argan%';
