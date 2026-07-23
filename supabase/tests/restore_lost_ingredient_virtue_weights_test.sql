-- supabase/tests/restore_lost_ingredient_virtue_weights_test.sql
-- Fixes: Beauty Mode Branch Review 2026-07-23, Area A, Finding #6 (Medium).
-- 20260721000004_standardize_ingredient_virtue_vectors.sql does a full
-- virtue_weights/skin_virtue_weights JSONB replace for these 9 ingredients,
-- silently discarding keys set by 20260720000006/20260720000007.
BEGIN;
SELECT plan(25);

-- 1. Shea Butter: restored virtue_weights key, preserved current key, restored skin key.
SELECT is((SELECT (virtue_weights->>'growth_retention')::numeric FROM ingredient WHERE active_key = 'shea_butter'), 0.40::numeric, 'shea_butter: growth_retention restored');
SELECT is((SELECT (virtue_weights->>'intense_hydration')::numeric FROM ingredient WHERE active_key = 'shea_butter'), 0.95::numeric, 'shea_butter: intense_hydration (current) preserved');
SELECT is((SELECT (skin_virtue_weights->>'dry_skin_moisture')::numeric FROM ingredient WHERE active_key = 'shea_butter'), 0.90::numeric, 'shea_butter: dry_skin_moisture (skin) restored');

-- 2. Chébé: restored virtue_weights key, preserved current key (no skin data existed before).
SELECT is((SELECT (virtue_weights->>'moisture')::numeric FROM ingredient WHERE active_key = 'chebe'), 0.35::numeric, 'chebe: moisture restored');
SELECT is((SELECT (virtue_weights->>'anti_breakage')::numeric FROM ingredient WHERE active_key = 'chebe'), 0.95::numeric, 'chebe: anti_breakage (current) preserved');

-- 3. Aloé Véra
SELECT is((SELECT (virtue_weights->>'growth_retention')::numeric FROM ingredient WHERE active_key = 'aloe_vera'), 0.50::numeric, 'aloe_vera: growth_retention restored');
SELECT is((SELECT (virtue_weights->>'intense_hydration')::numeric FROM ingredient WHERE active_key = 'aloe_vera'), 0.95::numeric, 'aloe_vera: intense_hydration (current) preserved');
SELECT is((SELECT (skin_virtue_weights->>'dry_skin_moisture')::numeric FROM ingredient WHERE active_key = 'aloe_vera'), 0.95::numeric, 'aloe_vera: dry_skin_moisture (skin) restored');

-- 4. Black Seed / Nigelle
SELECT is((SELECT (virtue_weights->>'sebum_balance')::numeric FROM ingredient WHERE active_key = 'black_seed'), 0.90::numeric, 'black_seed: sebum_balance restored');
SELECT is((SELECT (virtue_weights->>'growth_retention')::numeric FROM ingredient WHERE active_key = 'black_seed'), 0.85::numeric, 'black_seed: growth_retention (current) preserved');
SELECT is((SELECT (skin_virtue_weights->>'oily_acne_sebum')::numeric FROM ingredient WHERE active_key = 'black_seed'), 0.95::numeric, 'black_seed: oily_acne_sebum (skin) restored');

-- 5. Argan Oil
SELECT is((SELECT (virtue_weights->>'growth_retention')::numeric FROM ingredient WHERE active_key = 'argan'), 0.50::numeric, 'argan: growth_retention restored');
SELECT is((SELECT (virtue_weights->>'shine_softness')::numeric FROM ingredient WHERE active_key = 'argan'), 0.95::numeric, 'argan: shine_softness (current) preserved');
SELECT is((SELECT (skin_virtue_weights->>'dry_skin_moisture')::numeric FROM ingredient WHERE active_key = 'argan'), 0.85::numeric, 'argan: dry_skin_moisture (skin) restored');

-- 6. Castor Oil (Ricin) — no skin data existed before.
SELECT is((SELECT (virtue_weights->>'moisture')::numeric FROM ingredient WHERE active_key = 'ricin'), 0.50::numeric, 'ricin: moisture restored');
SELECT is((SELECT (virtue_weights->>'growth_retention')::numeric FROM ingredient WHERE active_key = 'ricin'), 0.95::numeric, 'ricin: growth_retention (current) preserved');

-- 7. Hibiscus / Karkadé
SELECT is((SELECT (virtue_weights->>'glow_brightening')::numeric FROM ingredient WHERE active_key = 'hibiscus'), 0.90::numeric, 'hibiscus: glow_brightening restored');
SELECT is((SELECT (virtue_weights->>'growth_retention')::numeric FROM ingredient WHERE active_key = 'hibiscus'), 0.80::numeric, 'hibiscus: growth_retention (current) preserved');
SELECT is((SELECT (skin_virtue_weights->>'brightening_anti_spots')::numeric FROM ingredient WHERE active_key = 'hibiscus'), 0.95::numeric, 'hibiscus: brightening_anti_spots (skin) restored');

-- 8. Green / White Clay (Argile)
SELECT is((SELECT (virtue_weights->>'sebum_balance')::numeric FROM ingredient WHERE active_key = 'clay'), 1.00::numeric, 'clay: sebum_balance restored');
SELECT is((SELECT (virtue_weights->>'scalp_detox')::numeric FROM ingredient WHERE active_key = 'clay'), 0.95::numeric, 'clay: scalp_detox (current) preserved');
SELECT is((SELECT (skin_virtue_weights->>'oily_acne_sebum')::numeric FROM ingredient WHERE active_key = 'clay'), 1.00::numeric, 'clay: oily_acne_sebum (skin) restored');

-- 9. Jojoba Oil
SELECT is((SELECT (virtue_weights->>'sebum_balance')::numeric FROM ingredient WHERE active_key = 'jojoba'), 0.90::numeric, 'jojoba: sebum_balance restored');
SELECT is((SELECT (virtue_weights->>'scalp_soothing')::numeric FROM ingredient WHERE active_key = 'jojoba'), 0.85::numeric, 'jojoba: scalp_soothing (current) preserved');
SELECT is((SELECT (skin_virtue_weights->>'oily_acne_sebum')::numeric FROM ingredient WHERE active_key = 'jojoba'), 0.90::numeric, 'jojoba: oily_acne_sebum (skin) restored');

SELECT * FROM finish();
ROLLBACK;
