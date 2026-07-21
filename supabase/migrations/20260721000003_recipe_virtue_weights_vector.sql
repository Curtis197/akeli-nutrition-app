-- Migration: Add virtue_weights JSONB column to recipe table for continuous virtue vectors
-- File: supabase/migrations/20260721000003_recipe_virtue_weights_vector.sql

ALTER TABLE recipe
ADD COLUMN IF NOT EXISTS virtue_weights JSONB DEFAULT '{}'::jsonb;

-- Populate continuous virtue weight vectors for starter beauty remedies (0.0 to 1.0 intensity)
UPDATE recipe
SET virtue_weights = '{"growth_retention": 0.95, "anti_breakage": 0.90, "intense_hydration": 0.85, "protective_care": 0.80}'::jsonb
WHERE id = 'b0000001-0000-0000-0000-000000000001';

UPDATE recipe
SET virtue_weights = '{"sebum_balance": 0.95, "anti_dandruff": 0.90, "detox_cleansing": 0.95, "scalp_soothing": 0.85}'::jsonb
WHERE id = 'b0000002-0000-0000-0000-000000000002';

UPDATE recipe
SET virtue_weights = '{"intense_hydration": 0.95, "glow_brightening": 0.90, "sensitive_soothing": 0.85, "curl_definition": 0.75}'::jsonb
WHERE id = 'b0000003-0000-0000-0000-000000000003';

UPDATE recipe
SET virtue_weights = '{"growth_retention": 0.90, "anti_breakage": 0.95, "shine_softness": 0.90, "protective_care": 0.85}'::jsonb
WHERE id = 'b0000004-0000-0000-0000-000000000004';

UPDATE recipe
SET virtue_weights = '{"anti_dark_spots": 0.95, "glow_brightening": 0.90, "exfoliation_smoothing": 0.85}'::jsonb
WHERE id = 'b0000005-0000-0000-0000-000000000005';
