-- Migration: Standardize virtue_weights and skin_virtue_weights maps across beauty ingredients
-- File: supabase/migrations/20260721000004_standardize_ingredient_virtue_vectors.sql

-- 1. Shea Butter (Karité)
UPDATE ingredient
SET 
  virtue_weights = '{"intense_hydration": 0.95, "anti_breakage": 0.85, "protective_care": 0.90, "shine_softness": 0.80}'::jsonb,
  skin_virtue_weights = '{"moisture_barrier": 0.95, "body_nourishing": 0.90, "sensitive_soothing": 0.80}'::jsonb
WHERE active_key = 'shea_butter' OR name = 'shea_butter';

-- 2. Aloé Véra
UPDATE ingredient
SET 
  virtue_weights = '{"intense_hydration": 0.95, "scalp_soothing": 0.90, "curl_definition": 0.80}'::jsonb,
  skin_virtue_weights = '{"moisture_barrier": 0.90, "sensitive_soothing": 0.95, "glow_brightening": 0.80, "sebum_acne_control": 0.75}'::jsonb
WHERE active_key = 'aloe_vera' OR name = 'aloe_vera';

-- 3. Chébé
UPDATE ingredient
SET 
  virtue_weights = '{"growth_retention": 0.95, "anti_breakage": 0.95, "protective_care": 0.85}'::jsonb,
  skin_virtue_weights = '{}'::jsonb
WHERE active_key = 'chebe' OR name = 'chebe';

-- 4. Black Seed / Nigelle
UPDATE ingredient
SET 
  virtue_weights = '{"growth_retention": 0.85, "scalp_soothing": 0.90, "scalp_detox": 0.95}'::jsonb,
  skin_virtue_weights = '{"sebum_acne_control": 0.95, "sensitive_soothing": 0.85, "anti_dark_spots": 0.80}'::jsonb
WHERE active_key = 'black_seed' OR name = 'black_seed';

-- 5. Argan Oil
UPDATE ingredient
SET 
  virtue_weights = '{"shine_softness": 0.95, "anti_breakage": 0.80, "intense_hydration": 0.85}'::jsonb,
  skin_virtue_weights = '{"anti_aging_elasticity": 0.90, "glow_brightening": 0.85, "moisture_barrier": 0.85}'::jsonb
WHERE active_key = 'argan' OR name = 'argan';

-- 6. Castor Oil (Ricin)
UPDATE ingredient
SET 
  virtue_weights = '{"growth_retention": 0.95, "anti_breakage": 0.90, "volume_thickness": 0.85}'::jsonb,
  skin_virtue_weights = '{"moisture_barrier": 0.80}'::jsonb
WHERE active_key = 'ricin' OR name = 'ricin';

-- 7. Hibiscus / Karkadé
UPDATE ingredient
SET 
  virtue_weights = '{"shine_softness": 0.90, "growth_retention": 0.80, "curl_definition": 0.75}'::jsonb,
  skin_virtue_weights = '{"glow_brightening": 0.95, "anti_dark_spots": 0.85, "exfoliation_smoothing": 0.80}'::jsonb
WHERE active_key = 'hibiscus' OR name = 'hibiscus';

-- 8. Green / White Clay (Argile)
UPDATE ingredient
SET 
  virtue_weights = '{"scalp_detox": 0.95, "scalp_soothing": 0.80}'::jsonb,
  skin_virtue_weights = '{"sebum_acne_control": 0.95, "exfoliation_smoothing": 0.85}'::jsonb
WHERE active_key = 'clay' OR name = 'clay';

-- 9. Jojoba Oil
UPDATE ingredient
SET 
  virtue_weights = '{"scalp_soothing": 0.85, "shine_softness": 0.85, "intense_hydration": 0.75}'::jsonb,
  skin_virtue_weights = '{"sebum_acne_control": 0.90, "moisture_barrier": 0.85}'::jsonb
WHERE active_key = 'jojoba' OR name = 'jojoba';
