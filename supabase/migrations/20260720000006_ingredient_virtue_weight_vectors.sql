-- ================================================================
-- AKELI BEAUTY MODE: CONTINUOUS INGREDIENT VIRTUE WEIGHT VECTORS
-- ================================================================

-- 1. ADD CONTINUOUS VIRTUE WEIGHTS JSONB TO INGREDIENT TABLE
ALTER TABLE ingredient
  ADD COLUMN IF NOT EXISTS virtue_weights JSONB DEFAULT '{}'::jsonb;

COMMENT ON COLUMN ingredient.virtue_weights IS 'Continuous virtue intensity weights (0.0 to 1.0) across all beauty dimensions (moisture, anti_breakage, growth_retention, scalp_soothing, sebum_balance, glow_brightening, protective_care)';

-- 2. UPDATE INGREDIENT SEED WITH CONTINUOUS VIRTUE WEIGHT VECTORS
UPDATE ingredient
SET virtue_weights = '{"moisture": 0.90, "anti_breakage": 0.85, "growth_retention": 0.40, "scalp_soothing": 0.40, "sebum_balance": 0.10, "glow_brightening": 0.20, "protective_care": 0.50}'::jsonb
WHERE active_key = 'shea_butter' OR name LIKE '%Karité%';

UPDATE ingredient
SET virtue_weights = '{"growth_retention": 0.95, "anti_breakage": 0.90, "moisture": 0.35, "scalp_soothing": 0.20, "sebum_balance": 0.10, "glow_brightening": 0.10, "protective_care": 0.40}'::jsonb
WHERE active_key = 'chebe' OR name LIKE '%Chébé%';

UPDATE ingredient
SET virtue_weights = '{"moisture": 0.95, "scalp_soothing": 0.80, "glow_brightening": 0.75, "growth_retention": 0.50, "sebum_balance": 0.50, "anti_breakage": 0.30, "protective_care": 0.60}'::jsonb
WHERE active_key = 'aloe_vera' OR name LIKE '%Aloé%';

UPDATE ingredient
SET virtue_weights = '{"scalp_soothing": 0.95, "sebum_balance": 0.90, "glow_brightening": 0.65, "growth_retention": 0.60, "moisture": 0.30, "anti_breakage": 0.50, "protective_care": 0.40}'::jsonb
WHERE active_key = 'black_seed' OR name LIKE '%Nigelle%';

UPDATE ingredient
SET virtue_weights = '{"moisture": 0.85, "anti_breakage": 0.80, "growth_retention": 0.50, "glow_brightening": 0.60, "scalp_soothing": 0.40, "sebum_balance": 0.40, "protective_care": 0.50}'::jsonb
WHERE active_key = 'argan' OR name LIKE '%Argan%';

UPDATE ingredient
SET virtue_weights = '{"growth_retention": 0.90, "anti_breakage": 0.85, "moisture": 0.50, "scalp_soothing": 0.45, "protective_care": 0.50, "glow_brightening": 0.30, "sebum_balance": 0.20}'::jsonb
WHERE active_key = 'ricin' OR name LIKE '%Ricin%';

UPDATE ingredient
SET virtue_weights = '{"glow_brightening": 0.90, "growth_retention": 0.65, "anti_breakage": 0.50, "moisture": 0.40, "sebum_balance": 0.40, "scalp_soothing": 0.30, "protective_care": 0.30}'::jsonb
WHERE active_key = 'hibiscus' OR name LIKE '%Hibiscus%';

UPDATE ingredient
SET virtue_weights = '{"sebum_balance": 1.00, "scalp_soothing": 0.75, "glow_brightening": 0.50, "moisture": 0.10, "anti_breakage": 0.20, "growth_retention": 0.20, "protective_care": 0.20}'::jsonb
WHERE active_key = 'clay' OR name LIKE '%Argile%';

UPDATE ingredient
SET virtue_weights = '{"sebum_balance": 0.90, "protective_care": 0.85, "moisture": 0.60, "scalp_soothing": 0.50, "glow_brightening": 0.50, "growth_retention": 0.40, "anti_breakage": 0.40}'::jsonb
WHERE active_key = 'jojoba' OR name LIKE '%Jojoba%';
