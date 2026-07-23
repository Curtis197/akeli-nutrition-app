-- Migration: Re-merge virtue_weights/skin_virtue_weights keys that
-- 20260721000004_standardize_ingredient_virtue_vectors.sql silently discarded via
-- a full-object overwrite instead of a merge, for the 9 beauty ingredients it
-- touched. Values below are the exact originals from
-- 20260720000006_ingredient_virtue_weight_vectors.sql (virtue_weights) and
-- 20260720000007_ingredient_skin_virtue_vectors.sql (skin_virtue_weights),
-- restricted to keys whose names do not already exist in the post-20260721000004
-- objects (keys present in both, e.g. shea_butter's anti_breakage, are left at
-- their current value — only missing keys are re-added).
-- File: supabase/migrations/20260722090400_restore_lost_ingredient_virtue_weights.sql
-- Fixes: Beauty Mode Branch Review 2026-07-23, Area A, Finding #6 (Medium).
--
-- Runs after Task 4's dedup, so each UPDATE ... WHERE active_key = 'x' below
-- touches exactly the one surviving row per active_key.

-- 1. Shea Butter (Karité)
UPDATE ingredient
SET
  virtue_weights = virtue_weights || '{"moisture": 0.90, "growth_retention": 0.40, "scalp_soothing": 0.40, "sebum_balance": 0.10, "glow_brightening": 0.20}'::jsonb,
  skin_virtue_weights = skin_virtue_weights || '{"dry_skin_moisture": 0.90, "barrier_repair": 0.95, "anti_aging_elasticity": 0.75, "sensitive_skin_soothing": 0.60, "oily_acne_sebum": 0.10}'::jsonb
WHERE active_key = 'shea_butter';

-- 2. Chébé (no 20260720000007 skin data existed for chebe)
UPDATE ingredient
SET virtue_weights = virtue_weights || '{"moisture": 0.35, "scalp_soothing": 0.20, "sebum_balance": 0.10, "glow_brightening": 0.10}'::jsonb
WHERE active_key = 'chebe';

-- 3. Aloé Véra
UPDATE ingredient
SET
  virtue_weights = virtue_weights || '{"moisture": 0.95, "glow_brightening": 0.75, "growth_retention": 0.50, "sebum_balance": 0.50, "anti_breakage": 0.30, "protective_care": 0.60}'::jsonb,
  skin_virtue_weights = skin_virtue_weights || '{"dry_skin_moisture": 0.95, "sensitive_skin_soothing": 0.90, "brightening_anti_spots": 0.75, "barrier_repair": 0.80, "anti_aging_elasticity": 0.60}'::jsonb
WHERE active_key = 'aloe_vera';

-- 4. Black Seed / Nigelle
UPDATE ingredient
SET
  virtue_weights = virtue_weights || '{"sebum_balance": 0.90, "glow_brightening": 0.65, "moisture": 0.30, "anti_breakage": 0.50, "protective_care": 0.40}'::jsonb,
  skin_virtue_weights = skin_virtue_weights || '{"oily_acne_sebum": 0.95, "sensitive_skin_soothing": 0.85, "brightening_anti_spots": 0.70, "barrier_repair": 0.60, "dry_skin_moisture": 0.30}'::jsonb
WHERE active_key = 'black_seed';

-- 5. Argan Oil
UPDATE ingredient
SET
  virtue_weights = virtue_weights || '{"moisture": 0.85, "growth_retention": 0.50, "glow_brightening": 0.60, "scalp_soothing": 0.40, "sebum_balance": 0.40, "protective_care": 0.50}'::jsonb,
  skin_virtue_weights = skin_virtue_weights || '{"dry_skin_moisture": 0.85, "barrier_repair": 0.80, "brightening_anti_spots": 0.60}'::jsonb
WHERE active_key = 'argan';

-- 6. Castor Oil (Ricin) (no 20260720000007 skin data existed for ricin)
UPDATE ingredient
SET virtue_weights = virtue_weights || '{"moisture": 0.50, "scalp_soothing": 0.45, "protective_care": 0.50, "glow_brightening": 0.30, "sebum_balance": 0.20}'::jsonb
WHERE active_key = 'ricin';

-- 7. Hibiscus / Karkadé
UPDATE ingredient
SET
  virtue_weights = virtue_weights || '{"glow_brightening": 0.90, "anti_breakage": 0.50, "moisture": 0.40, "sebum_balance": 0.40, "scalp_soothing": 0.30, "protective_care": 0.30}'::jsonb,
  skin_virtue_weights = skin_virtue_weights || '{"brightening_anti_spots": 0.95, "anti_aging_elasticity": 0.80, "dry_skin_moisture": 0.50, "sensitive_skin_soothing": 0.40}'::jsonb
WHERE active_key = 'hibiscus';

-- 8. Green / White Clay (Argile)
UPDATE ingredient
SET
  virtue_weights = virtue_weights || '{"sebum_balance": 1.00, "glow_brightening": 0.50, "moisture": 0.10, "anti_breakage": 0.20, "growth_retention": 0.20, "protective_care": 0.20}'::jsonb,
  skin_virtue_weights = skin_virtue_weights || '{"oily_acne_sebum": 1.00, "sensitive_skin_soothing": 0.60, "brightening_anti_spots": 0.50, "dry_skin_moisture": 0.10}'::jsonb
WHERE active_key = 'clay';

-- 9. Jojoba Oil
UPDATE ingredient
SET
  virtue_weights = virtue_weights || '{"sebum_balance": 0.90, "protective_care": 0.85, "moisture": 0.60, "glow_brightening": 0.50, "growth_retention": 0.40, "anti_breakage": 0.40}'::jsonb,
  skin_virtue_weights = skin_virtue_weights || '{"oily_acne_sebum": 0.90, "barrier_repair": 0.85, "dry_skin_moisture": 0.70, "sensitive_skin_soothing": 0.60}'::jsonb
WHERE active_key = 'jojoba';
