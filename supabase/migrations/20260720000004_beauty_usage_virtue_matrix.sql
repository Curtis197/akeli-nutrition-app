-- ================================================================
-- AKELI BEAUTY MODE: USAGE & VIRTUE MATRIX + BEAUTY REMEDIES SEED
-- ================================================================

-- 1. ADD VIRTUES AND USAGE INSTRUCTIONS TO RECIPE TABLE
ALTER TABLE recipe
  ADD COLUMN IF NOT EXISTS virtues TEXT[] DEFAULT '{}',
  ADD COLUMN IF NOT EXISTS usage_instructions JSONB DEFAULT '{}'::jsonb;

COMMENT ON COLUMN recipe.virtues IS 'Beauty virtues / benefits (growth_retention, anti_breakage, intense_hydration, sebum_balance, scalp_soothing, glow_brightening, protective_care)';
COMMENT ON COLUMN recipe.usage_instructions IS 'Beauty application protocol (frequency, duration_min, step)';

-- 2. SEED AUTHENTIC AFRICAN BEAUTY & CARE REMEDIES
INSERT INTO recipe (
  id, title, description, mode, is_published, is_private, creator_id,
  prep_time_min, cook_time_min, difficulty, virtues, usage_instructions
)
VALUES
(
  'b0000001-0000-0000-0000-000000000001'::uuid,
  'Masque Fortifiant Karité & Poudre de Chébé',
  'Masque capillaire ancestral tchadien au beurre de karité brut et poudre de chébé. Nourrit en profondeur, renforce la fibre capillaire et prévient la casse des cheveux crépu (Type 4).',
  'beauty', true, false, '1a1b225a-1328-4d58-976f-253574410c6f'::uuid,
  15, 0, 'easy',
  ARRAY['growth_retention', 'anti_breakage', 'intense_hydration'],
  '{"frequency": "weekly", "duration_min": 30, "step": "mask_post_shampoo"}'::jsonb
),
(
  'b0000002-0000-0000-0000-000000000002'::uuid,
  'Soin Purifiant à l''Huile de Nigelle & Argile Verte',
  'Masque nettoyant et désincrustant pour peaux grasses à tendance acnéique. L''huile de nigelle apaiser les inflammations tandis que l''argile absorbe l''excès de sébum.',
  'beauty', true, false, '1a1b225a-1328-4d58-976f-253574410c6f'::uuid,
  10, 0, 'easy',
  ARRAY['sebum_balance', 'scalp_soothing'],
  '{"frequency": "weekly", "duration_min": 15, "step": "face_mask"}'::jsonb
),
(
  'b0000003-0000-0000-0000-000000000003'::uuid,
  'Lotion Tonique Hydratante Aloé Véra & Karkadé (Hibiscus)',
  'Brume tonifiante aux fleurs d''hibiscus infusées et gel d''aloé véra pur. Resserre les pores, apporte un éclat immédiat au teint et réhydrate les boucles.',
  'beauty', true, false, '1a1b225a-1328-4d58-976f-253574410c6f'::uuid,
  10, 15, 'easy',
  ARRAY['intense_hydration', 'glow_brightening'],
  '{"frequency": "daily", "duration_min": 0, "step": "leave_in_mist"}'::jsonb
),
(
  'b0000004-0000-0000-0000-000000000004'::uuid,
  'Bain d''Huiles Régénérant Argan & Ricin',
  'Soin pré-shampoing aux huiles d''argan et de ricin pressées à froid. Stimule la microcirculation du cuir chevelu et fortifie les pointes sèches.',
  'beauty', true, false, '1a1b225a-1328-4d58-976f-253574410c6f'::uuid,
  5, 0, 'easy',
  ARRAY['growth_retention', 'anti_breakage'],
  '{"frequency": "bi_weekly", "duration_min": 45, "step": "pre_shampoo"}'::jsonb
),
(
  'b0000005-0000-0000-0000-000000000005'::uuid,
  'Spray Sérum Apaisant Jojoba & Menthe Poivrée',
  'Sérum liquide rafraîchissant idéal pour soulager les démangeaisons du cuir chevelu sous tresses, braids ou dreadlocks.',
  'beauty', true, false, '1a1b225a-1328-4d58-976f-253574410c6f'::uuid,
  5, 0, 'easy',
  ARRAY['scalp_soothing', 'protective_care'],
  '{"frequency": "daily", "duration_min": 0, "step": "protective_spray"}'::jsonb
),
(
  'b0000006-0000-0000-0000-000000000006'::uuid,
  'Beurre Scellant Karité & Baobab',
  'Crème riche et onctueuse scellant l''hydratation des cheveux très poreux après la méthode L.O.C.',
  'beauty', true, false, '1a1b225a-1328-4d58-976f-253574410c6f'::uuid,
  20, 0, 'medium',
  ARRAY['anti_breakage', 'intense_hydration'],
  '{"frequency": "bi_weekly", "duration_min": 0, "step": "sealing_cream"}'::jsonb
),
(
  'b0000007-0000-0000-0000-000000000007'::uuid,
  'Masque Éclat Visage Curcuma & Aloé Véra',
  'Soin naturel unifiant anti-taches et révélateur d''éclat du teint.',
  'beauty', true, false, '1a1b225a-1328-4d58-976f-253574410c6f'::uuid,
  10, 0, 'easy',
  ARRAY['glow_brightening', 'intense_hydration'],
  '{"frequency": "weekly", "duration_min": 15, "step": "face_mask"}'::jsonb
),
(
  'b0000008-0000-0000-0000-000000000008'::uuid,
  'Huile de Massage Cuir Chevelu Nigelle & Ricin',
  'Elixir tonique d''ancrage capillaire pour stimuler la pousse des tempe et des zones clairsemées.',
  'beauty', true, false, '1a1b225a-1328-4d58-976f-253574410c6f'::uuid,
  5, 0, 'easy',
  ARRAY['growth_retention', 'scalp_soothing'],
  '{"frequency": "tri_weekly", "duration_min": 10, "step": "scalp_massage"}'::jsonb
)
ON CONFLICT (id) DO UPDATE SET
  title = EXCLUDED.title,
  description = EXCLUDED.description,
  mode = EXCLUDED.mode,
  is_published = EXCLUDED.is_published,
  virtues = EXCLUDED.virtues,
  usage_instructions = EXCLUDED.usage_instructions;
