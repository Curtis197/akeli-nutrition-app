-- ================================================================
-- AKELI APP: EXTENSIVE INGREDIENT SEED CATALOG (BEAUTY & NUTRITION)
-- ================================================================

INSERT INTO ingredient (name, mode, active_key, beauty_virtues, virtue_weights, skin_virtue_weights, micronutrients)
VALUES
-- ----------------------------------------------------------------
-- BEAUTY & NATURAL COSMETIC BIO-ACTIVES
-- ----------------------------------------------------------------
(
  'Beurre de Karité Brut', 'beauty', 'shea_butter',
  ARRAY['anti_breakage', 'intense_hydration', 'protective_care'],
  '{"moisture": 0.90, "anti_breakage": 0.85, "growth_retention": 0.40, "scalp_soothing": 0.40, "sebum_balance": 0.10, "glow_brightening": 0.20, "protective_care": 0.50}'::jsonb,
  '{"dry_skin_moisture": 0.90, "barrier_repair": 0.95, "anti_aging_elasticity": 0.75, "sensitive_skin_soothing": 0.60, "oily_acne_sebum": 0.10}'::jsonb,
  '{"vit_e_mg": 2.5, "cinnamates_pct": 5.0, "stearic_acid_pct": 40.0, "oleic_acid_pct": 45.0}'::jsonb
),
(
  'Poudre de Chébé Traditionnelle', 'beauty', 'chebe',
  ARRAY['growth_retention', 'anti_breakage', 'protective_care'],
  '{"growth_retention": 0.95, "anti_breakage": 0.90, "moisture": 0.35, "scalp_soothing": 0.20, "sebum_balance": 0.10, "glow_brightening": 0.10, "protective_care": 0.40}'::jsonb,
  '{"barrier_repair": 0.50, "dry_skin_moisture": 0.30}'::jsonb,
  '{"alkaloids_pct": 3.2, "tannins_pct": 4.5}'::jsonb
),
(
  'Gel d''Aloé Véra Pur', 'beauty', 'aloe_vera',
  ARRAY['intense_hydration', 'glow_brightening', 'scalp_soothing'],
  '{"moisture": 0.95, "scalp_soothing": 0.80, "glow_brightening": 0.75, "growth_retention": 0.50, "sebum_balance": 0.50, "anti_breakage": 0.30, "protective_care": 0.60}'::jsonb,
  '{"dry_skin_moisture": 0.95, "sensitive_skin_soothing": 0.90, "brightening_anti_spots": 0.75, "barrier_repair": 0.80, "anti_aging_elasticity": 0.60}'::jsonb,
  '{"vit_c_mg": 12.0, "vit_e_mg": 0.8, "zinc_mg": 0.4, "acemannan_pct": 15.0}'::jsonb
),
(
  'Huile de Nigelle (Cumin Noir)', 'beauty', 'black_seed',
  ARRAY['sebum_balance', 'scalp_soothing', 'glow_brightening'],
  '{"scalp_soothing": 0.95, "sebum_balance": 0.90, "glow_brightening": 0.65, "growth_retention": 0.60, "moisture": 0.30, "anti_breakage": 0.50, "protective_care": 0.40}'::jsonb,
  '{"oily_acne_sebum": 0.95, "sensitive_skin_soothing": 0.85, "brightening_anti_spots": 0.70, "barrier_repair": 0.60, "dry_skin_moisture": 0.30}'::jsonb,
  '{"thymoquinone_pct": 1.5, "omega_6_pct": 55.0, "omega_9_pct": 22.0}'::jsonb
),
(
  'Huile d''Argan Pressée à Froid', 'beauty', 'argan',
  ARRAY['intense_hydration', 'anti_breakage', 'glow_brightening'],
  '{"moisture": 0.85, "anti_breakage": 0.80, "growth_retention": 0.50, "glow_brightening": 0.60, "scalp_soothing": 0.40, "sebum_balance": 0.40, "protective_care": 0.50}'::jsonb,
  '{"anti_aging_elasticity": 0.90, "dry_skin_moisture": 0.85, "barrier_repair": 0.80, "brightening_anti_spots": 0.60}'::jsonb,
  '{"vit_e_mg": 60.0, "squalene_mg": 300.0}'::jsonb
),
(
  'Huile de Ricin Noire (Palma Christi)', 'beauty', 'ricin',
  ARRAY['growth_retention', 'anti_breakage', 'protective_care'],
  '{"growth_retention": 0.90, "anti_breakage": 0.85, "moisture": 0.50, "scalp_soothing": 0.45, "protective_care": 0.50, "glow_brightening": 0.30, "sebum_balance": 0.20}'::jsonb,
  '{"barrier_repair": 0.70, "dry_skin_moisture": 0.50}'::jsonb,
  '{"ricinoleic_acid_pct": 85.0, "vit_e_mg": 1.2}'::jsonb
),
(
  'Fleurs d''Hibiscus Séchées (Karkadé / Bissap)', 'beauty', 'hibiscus',
  ARRAY['glow_brightening', 'growth_retention', 'anti_breakage'],
  '{"glow_brightening": 0.90, "growth_retention": 0.65, "anti_breakage": 0.50, "moisture": 0.40, "sebum_balance": 0.40, "scalp_soothing": 0.30, "protective_care": 0.30}'::jsonb,
  '{"brightening_anti_spots": 0.95, "anti_aging_elasticity": 0.80, "dry_skin_moisture": 0.50, "sensitive_skin_soothing": 0.40}'::jsonb,
  '{"vit_c_mg": 45.0, "anthocyanins_pct": 8.0, "aha_pct": 3.5}'::jsonb
),
(
  'Argile Verte Surfine (Montmorillonite)', 'beauty', 'clay',
  ARRAY['sebum_balance', 'scalp_soothing', 'glow_brightening'],
  '{"sebum_balance": 1.00, "scalp_soothing": 0.75, "glow_brightening": 0.50, "moisture": 0.10, "anti_breakage": 0.20, "growth_retention": 0.20, "protective_care": 0.20}'::jsonb,
  '{"oily_acne_sebum": 1.00, "sensitive_skin_soothing": 0.60, "brightening_anti_spots": 0.50, "dry_skin_moisture": 0.10}'::jsonb,
  '{"silica_pct": 48.0, "zinc_pct": 0.5, "iron_pct": 4.2}'::jsonb
),
(
  'Huile de Jojoba Végétale', 'beauty', 'jojoba',
  ARRAY['sebum_balance', 'protective_care', 'scalp_soothing'],
  '{"sebum_balance": 0.90, "protective_care": 0.85, "moisture": 0.60, "scalp_soothing": 0.50, "glow_brightening": 0.50, "growth_retention": 0.40, "anti_breakage": 0.40}'::jsonb,
  '{"oily_acne_sebum": 0.90, "barrier_repair": 0.85, "dry_skin_moisture": 0.70, "sensitive_skin_soothing": 0.60}'::jsonb,
  '{"wax_esters_pct": 97.0, "vit_e_mg": 1.5}'::jsonb
),
(
  'Huile de Baobab Vierge', 'beauty', 'baobab_oil',
  ARRAY['intense_hydration', 'anti_breakage', 'protective_care'],
  '{"moisture": 0.90, "anti_breakage": 0.80, "protective_care": 0.75, "growth_retention": 0.60}'::jsonb,
  '{"dry_skin_moisture": 0.90, "barrier_repair": 0.90, "anti_aging_elasticity": 0.80}'::jsonb,
  '{"vit_a_iu": 450.0, "vit_e_mg": 40.0, "omega_6_pct": 32.0, "omega_9_pct": 36.0}'::jsonb
),
(
  'Poudre de Moringa BIO', 'beauty', 'moringa',
  ARRAY['growth_retention', 'glow_brightening', 'scalp_soothing'],
  '{"growth_retention": 0.80, "scalp_soothing": 0.75, "glow_brightening": 0.70}'::jsonb,
  '{"brightening_anti_spots": 0.85, "sensitive_skin_soothing": 0.80, "anti_aging_elasticity": 0.75}'::jsonb,
  '{"vit_c_mg": 220.0, "vit_a_iu": 15000.0, "calcium_mg": 2000.0, "iron_mg": 28.0}'::jsonb
),
(
  'Beurre de Cacao Pur Brut', 'beauty', 'cocoa_butter',
  ARRAY['intense_hydration', 'protective_care'],
  '{"moisture": 0.85, "protective_care": 0.80, "anti_breakage": 0.70}'::jsonb,
  '{"dry_skin_moisture": 0.90, "barrier_repair": 0.90, "anti_aging_elasticity": 0.70}'::jsonb,
  '{"stearic_acid_pct": 34.0, "oleic_acid_pct": 35.0, "polyphenols_mg": 600.0}'::jsonb
),
(
  'Huile de Coco Vierge', 'beauty', 'coconut_oil',
  ARRAY['intense_hydration', 'anti_breakage'],
  '{"moisture": 0.80, "anti_breakage": 0.75, "protective_care": 0.60}'::jsonb,
  '{"dry_skin_moisture": 0.75, "barrier_repair": 0.70}'::jsonb,
  '{"lauric_acid_pct": 49.0, "caprylic_acid_pct": 8.0}'::jsonb
),
(
  'Poudre de Shikakai Ancestrale', 'beauty', 'shikakai',
  ARRAY['scalp_soothing', 'sebum_balance', 'growth_retention'],
  '{"scalp_soothing": 0.90, "sebum_balance": 0.85, "growth_retention": 0.70}'::jsonb,
  '{"oily_acne_sebum": 0.70, "sensitive_skin_soothing": 0.70}'::jsonb,
  '{"saponins_pct": 10.0, "vit_c_mg": 30.0}'::jsonb
),
(
  'Huile d''Avocat Pure', 'beauty', 'avocado_oil',
  ARRAY['intense_hydration', 'anti_breakage'],
  '{"moisture": 0.90, "anti_breakage": 0.80, "protective_care": 0.70}'::jsonb,
  '{"dry_skin_moisture": 0.95, "barrier_repair": 0.90, "anti_aging_elasticity": 0.85}'::jsonb,
  '{"vit_e_mg": 15.0, "oleic_acid_pct": 65.0, "lutein_mg": 4.0}'::jsonb
),

-- ----------------------------------------------------------------
-- AFRICAN CULINARY INGREDIENTS (NUTRITION MODE)
-- ----------------------------------------------------------------
(
  'Riz de Brisure Parfumé (Thiéboudiène)', 'nutrition', 'rice_broken',
  NULL, '{}'::jsonb, '{}'::jsonb,
  '{"carbs_g_100g": 78.0, "protein_g_100g": 6.8, "calories_100g": 350.0}'::jsonb
),
(
  'Feuilles de Baobab Séchées (Lalo)', 'nutrition', 'lalo',
  NULL, '{}'::jsonb, '{}'::jsonb,
  '{"fiber_g_100g": 45.0, "calcium_mg": 2200.0, "iron_mg": 12.0, "protein_g_100g": 13.0}'::jsonb
),
(
  'Pâte d''Arachide Pure (Maffé)', 'nutrition', 'peanut_paste',
  NULL, '{}'::jsonb, '{}'::jsonb,
  '{"fat_g_100g": 50.0, "protein_g_100g": 25.0, "niacin_mg": 14.0, "calories_100g": 588.0}'::jsonb
),
(
  'Graines d''Egusi (Courge Africaine)', 'nutrition', 'egusi',
  NULL, '{}'::jsonb, '{}'::jsonb,
  '{"protein_g_100g": 30.0, "fat_g_100g": 48.0, "zinc_mg": 7.5, "magnesium_mg": 530.0}'::jsonb
),
(
  'Gombo Frais (Okra)', 'nutrition', 'okra',
  NULL, '{}'::jsonb, '{}'::jsonb,
  '{"fiber_g_100g": 3.2, "vit_c_mg": 23.0, "folate_mcg": 60.0, "calories_100g": 33.0}'::jsonb
),
(
  'Banane Plantain Mûre', 'nutrition', 'plantain',
  NULL, '{}'::jsonb, '{}'::jsonb,
  '{"carbs_g_100g": 32.0, "potassium_mg": 490.0, "vit_a_iu": 1100.0, "calories_100g": 122.0}'::jsonb
),
(
  'Fonio Réticulé Ancestral', 'nutrition', 'fonio',
  NULL, '{}'::jsonb, '{}'::jsonb,
  '{"carbs_g_100g": 75.0, "protein_g_100g": 7.0, "methionine_mg": 560.0, "cystine_mg": 480.0}'::jsonb
),
(
  'Haricots Niébé Rouge', 'nutrition', 'niebe',
  NULL, '{}'::jsonb, '{}'::jsonb,
  '{"protein_g_100g": 24.0, "fiber_g_100g": 10.5, "iron_mg": 8.2, "folate_mcg": 630.0}'::jsonb
)
ON CONFLICT DO NOTHING;
