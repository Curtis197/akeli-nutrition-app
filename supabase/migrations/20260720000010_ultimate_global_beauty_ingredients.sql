-- ================================================================
-- AKELI BEAUTY MODE: ULTIMATE GLOBAL NATURAL BEAUTY & SELF-CARE INGREDIENTS
-- ================================================================

INSERT INTO ingredient (name, mode, active_key, beauty_virtues, virtue_weights, skin_virtue_weights, micronutrients)
VALUES
-- ----------------------------------------------------------------
-- 1. AFRICAN ANCESTRAL TREASURES
-- ----------------------------------------------------------------
(
  'Huile de Marula Vierge', 'beauty', 'marula_oil',
  ARRAY['intense_hydration', 'glow_brightening', 'protective_care'],
  '{"moisture": 0.90, "glow_brightening": 0.75, "protective_care": 0.80, "anti_breakage": 0.70}'::jsonb,
  '{"anti_aging_elasticity": 0.95, "dry_skin_moisture": 0.90, "barrier_repair": 0.90, "brightening_anti_spots": 0.70}'::jsonb,
  '{"vit_c_mg": 200.0, "vit_e_mg": 40.0, "oleic_acid_pct": 78.0}'::jsonb
),
(
  'Huile de Melon de Kalahari', 'beauty', 'kalahari_melon',
  ARRAY['sebum_balance', 'intense_hydration', 'scalp_soothing'],
  '{"sebum_balance": 0.90, "moisture": 0.70, "scalp_soothing": 0.60}'::jsonb,
  '{"oily_acne_sebum": 0.90, "dry_skin_moisture": 0.70, "barrier_repair": 0.85}'::jsonb,
  '{"linoleic_acid_pct": 70.0, "vit_e_mg": 55.0, "copper_mg": 1.2}'::jsonb
),
(
  'Argile Ghassoul Vraie (Rassoul du Maroc)', 'beauty', 'rhassoul_clay',
  ARRAY['sebum_balance', 'scalp_soothing', 'glow_brightening'],
  '{"sebum_balance": 0.95, "scalp_soothing": 0.85, "glow_brightening": 0.60}'::jsonb,
  '{"oily_acne_sebum": 0.95, "sensitive_skin_soothing": 0.70, "brightening_anti_spots": 0.60}'::jsonb,
  '{"silica_pct": 58.0, "magnesium_pct": 25.0, "calcium_pct": 2.3}'::jsonb
),
(
  'Savon Noir Beldi à l''Eucalyptus', 'beauty', 'black_soap',
  ARRAY['sebum_balance', 'glow_brightening'],
  '{"sebum_balance": 0.80, "glow_brightening": 0.70}'::jsonb,
  '{"oily_acne_sebum": 0.85, "brightening_anti_spots": 0.75}'::jsonb,
  '{"vit_e_mg": 30.0, "potassium_pct": 4.5}'::jsonb
),

-- ----------------------------------------------------------------
-- 2. AYURVEDIC & ASIAN BOTANICAL BEAUTIFIERS
-- ----------------------------------------------------------------
(
  'Poudre de Reetha (Noix de Lavage)', 'beauty', 'reetha',
  ARRAY['sebum_balance', 'scalp_soothing'],
  '{"sebum_balance": 0.90, "scalp_soothing": 0.80}'::jsonb,
  '{"oily_acne_sebum": 0.80}'::jsonb,
  '{"saponins_pct": 12.0}'::jsonb
),
(
  'Poudre de Bhringraj (Roi des Cheveux)', 'beauty', 'bhringraj',
  ARRAY['growth_retention', 'anti_breakage', 'scalp_soothing'],
  '{"growth_retention": 0.98, "anti_breakage": 0.90, "scalp_soothing": 0.85}'::jsonb,
  '{"sensitive_skin_soothing": 0.75, "anti_aging_elasticity": 0.60}'::jsonb,
  '{"wedelolactone_pct": 2.5, "eclalbasaponins_pct": 3.0, "iron_mg": 18.0}'::jsonb
),
(
  'Poudre d''Amla BIO (Groseille Indienne)', 'beauty', 'amla',
  ARRAY['growth_retention', 'glow_brightening', 'anti_breakage'],
  '{"growth_retention": 0.85, "glow_brightening": 0.80, "anti_breakage": 0.75}'::jsonb,
  '{"brightening_anti_spots": 0.90, "anti_aging_elasticity": 0.85}'::jsonb,
  '{"vit_c_mg": 600.0, "gallates_pct": 5.0, "tannins_pct": 10.0}'::jsonb
),
(
  'Huile de Neem Pure (Margousier)', 'beauty', 'neem_oil',
  ARRAY['sebum_balance', 'scalp_soothing'],
  '{"scalp_soothing": 0.95, "sebum_balance": 0.95}'::jsonb,
  '{"oily_acne_sebum": 0.98, "sensitive_skin_soothing": 0.85}'::jsonb,
  '{"azadirachtin_pct": 0.4, "nimbin_pct": 1.2}'::jsonb
),
(
  'Poudre de Brahmi BIO', 'beauty', 'brahmi',
  ARRAY['growth_retention', 'scalp_soothing'],
  '{"growth_retention": 0.85, "scalp_soothing": 0.85}'::jsonb,
  '{"sensitive_skin_soothing": 0.80}'::jsonb,
  '{"bacosides_pct": 20.0, "alkaloids_pct": 1.5}'::jsonb
),
(
  'Huile de Camélia Japonais (Tsubaki)', 'beauty', 'camellia_oil',
  ARRAY['intense_hydration', 'glow_brightening', 'protective_care'],
  '{"moisture": 0.90, "glow_brightening": 0.80, "protective_care": 0.85}'::jsonb,
  '{"anti_aging_elasticity": 0.90, "dry_skin_moisture": 0.85, "barrier_repair": 0.85}'::jsonb,
  '{"oleic_acid_pct": 82.0, "vit_e_mg": 25.0, "squalene_mg": 150.0}'::jsonb
),
(
  'Eau de Riz Fermentée & Protéines de Riz', 'beauty', 'rice_water',
  ARRAY['growth_retention', 'anti_breakage', 'glow_brightening'],
  '{"growth_retention": 0.85, "anti_breakage": 0.85, "glow_brightening": 0.70}'::jsonb,
  '{"brightening_anti_spots": 0.75, "sensitive_skin_soothing": 0.70}'::jsonb,
  '{"inositols_mg": 85.0, "amino_acids_pct": 8.0, "vit_b_mg": 12.0}'::jsonb
),

-- ----------------------------------------------------------------
-- 3. MEDITERRANEAN & ORIENTAL ELIXIRS
-- ----------------------------------------------------------------
(
  'Eau Florale de Fleur d''Oranger (Néroli)', 'beauty', 'orange_blossom',
  ARRAY['scalp_soothing', 'glow_brightening'],
  '{"scalp_soothing": 0.75, "glow_brightening": 0.70}'::jsonb,
  '{"sensitive_skin_soothing": 0.90, "brightening_anti_spots": 0.80, "dry_skin_moisture": 0.60}'::jsonb,
  '{"linalool_pct": 35.0, "flavanones_pct": 4.0}'::jsonb
),
(
  'Huile d''Olive Vierge Extra', 'beauty', 'olive_oil',
  ARRAY['intense_hydration', 'protective_care'],
  '{"moisture": 0.85, "protective_care": 0.80}'::jsonb,
  '{"dry_skin_moisture": 0.85, "barrier_repair": 0.85}'::jsonb,
  '{"oleic_acid_pct": 75.0, "polyphenols_mg": 300.0, "vit_e_mg": 14.0}'::jsonb
),
(
  'Huile de Pépins de Figue de Barbarie BIO', 'beauty', 'prickly_pear',
  ARRAY['glow_brightening', 'intense_hydration'],
  '{"glow_brightening": 0.90, "moisture": 0.85}'::jsonb,
  '{"anti_aging_elasticity": 1.00, "brightening_anti_spots": 0.95, "dry_skin_moisture": 0.90, "barrier_repair": 0.90}'::jsonb,
  '{"vit_e_mg": 1000.0, "linoleic_acid_pct": 62.0, "sterols_mg": 1000.0}'::jsonb
),
(
  'Argile Rose Kaolin', 'beauty', 'pink_clay',
  ARRAY['glow_brightening', 'scalp_soothing'],
  '{"scalp_soothing": 0.80, "glow_brightening": 0.75}'::jsonb,
  '{"sensitive_skin_soothing": 0.90, "brightening_anti_spots": 0.80, "oily_acne_sebum": 0.60}'::jsonb,
  '{"silica_pct": 65.0, "iron_oxide_pct": 2.5}'::jsonb
),
(
  'Huile Essentielle de Lavande Vraie', 'beauty', 'lavender_eo',
  ARRAY['scalp_soothing'],
  '{"scalp_soothing": 0.95}'::jsonb,
  '{"sensitive_skin_soothing": 0.95, "barrier_repair": 0.70}'::jsonb,
  '{"linalyl_acetate_pct": 40.0, "linalool_pct": 30.0}'::jsonb
),
(
  'Huile Essentielle d''Arbre à Thé (Tea Tree)', 'beauty', 'tea_tree_eo',
  ARRAY['sebum_balance', 'scalp_soothing'],
  '{"sebum_balance": 0.95, "scalp_soothing": 0.90}'::jsonb,
  '{"oily_acne_sebum": 0.95, "sensitive_skin_soothing": 0.80}'::jsonb,
  '{"terpinen_4_ol_pct": 42.0}'::jsonb
),
(
  'Huile Essentielle de Menthe Poivrée', 'beauty', 'peppermint_eo',
  ARRAY['growth_retention', 'scalp_soothing'],
  '{"growth_retention": 0.90, "scalp_soothing": 0.85}'::jsonb,
  '{"sensitive_skin_soothing": 0.70}'::jsonb,
  '{"menthol_pct": 45.0, "menthone_pct": 20.0}'::jsonb
),
(
  'Miel Brut Sauvage', 'beauty', 'raw_honey',
  ARRAY['intense_hydration', 'glow_brightening', 'scalp_soothing'],
  '{"moisture": 0.95, "scalp_soothing": 0.85, "glow_brightening": 0.80}'::jsonb,
  '{"dry_skin_moisture": 0.95, "sensitive_skin_soothing": 0.90, "brightening_anti_spots": 0.80, "barrier_repair": 0.85}'::jsonb,
  '{"enzymes_pct": 2.0, "flavonoids_mg": 250.0, "fructose_pct": 38.0}'::jsonb
),

-- ----------------------------------------------------------------
-- 4. AMAZONIAN, CARIBBEAN & TROPICAL BEAUTIFIERS
-- ----------------------------------------------------------------
(
  'Beurre de Murumuru de l''Amazonie', 'beauty', 'murumuru_butter',
  ARRAY['intense_hydration', 'anti_breakage', 'protective_care'],
  '{"moisture": 0.95, "anti_breakage": 0.90, "protective_care": 0.85}'::jsonb,
  '{"dry_skin_moisture": 0.90, "barrier_repair": 0.90}'::jsonb,
  '{"lauric_acid_pct": 47.0, "myristic_acid_pct": 26.0}'::jsonb
),
(
  'Huile de Buriti Pur (Riche en Béta-Carotène)', 'beauty', 'buriti_oil',
  ARRAY['glow_brightening', 'protective_care'],
  '{"glow_brightening": 0.90, "protective_care": 0.85}'::jsonb,
  '{"brightening_anti_spots": 0.95, "anti_aging_elasticity": 0.90, "barrier_repair": 0.80}'::jsonb,
  '{"beta_carotene_mg": 350.0, "vit_e_mg": 50.0, "oleic_acid_pct": 72.0}'::jsonb
),
(
  'Beurre de Cupuaçu Sauvage', 'beauty', 'cupuacu_butter',
  ARRAY['intense_hydration', 'anti_breakage'],
  '{"moisture": 0.98, "anti_breakage": 0.85}'::jsonb,
  '{"dry_skin_moisture": 0.98, "barrier_repair": 0.95, "anti_aging_elasticity": 0.80}'::jsonb,
  '{"phytosterols_mg": 1200.0, "oleic_acid_pct": 44.0, "stearic_acid_pct": 35.0}'::jsonb
),
(
  'Huile de Maracuja (Fruit de la Passion)', 'beauty', 'maracuja_oil',
  ARRAY['sebum_balance', 'glow_brightening'],
  '{"sebum_balance": 0.85, "glow_brightening": 0.80}'::jsonb,
  '{"oily_acne_sebum": 0.90, "brightening_anti_spots": 0.85, "sensitive_skin_soothing": 0.80}'::jsonb,
  '{"linoleic_acid_pct": 77.0, "vit_c_mg": 25.0}'::jsonb
),
(
  'Macérat Huileux de Carotte (Béta-Carotène)', 'beauty', 'carrot_oil',
  ARRAY['glow_brightening', 'protective_care'],
  '{"glow_brightening": 0.85}'::jsonb,
  '{"brightening_anti_spots": 0.95, "anti_aging_elasticity": 0.85}'::jsonb,
  '{"beta_carotene_mg": 200.0, "vit_e_mg": 20.0}'::jsonb
),
(
  'Gel de Graine de Lin Végétal (Mucilage)', 'beauty', 'flaxseed_gel',
  ARRAY['intense_hydration', 'anti_breakage', 'protective_care'],
  '{"moisture": 0.95, "anti_breakage": 0.85, "protective_care": 0.90, "growth_retention": 0.60}'::jsonb,
  '{"dry_skin_moisture": 0.90, "sensitive_skin_soothing": 0.85}'::jsonb,
  '{"mucilage_pct": 12.0, "alpha_linolenic_acid_pct": 55.0, "lignans_mg": 300.0}'::jsonb
)
ON CONFLICT DO NOTHING;
