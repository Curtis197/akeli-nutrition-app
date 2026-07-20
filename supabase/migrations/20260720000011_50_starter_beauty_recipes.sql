-- ================================================================
-- AKELI BEAUTY MODE: 50 STARTER BEAUTY & SELF-CARE REMEDIES
-- ================================================================

INSERT INTO recipe (id, title, description, mode, beauty_type, beauty_sub_type, virtues, usage_instructions, prep_time_min, cook_time_min, servings, difficulty, is_published, created_at)
VALUES
-- ----------------------------------------------------------------
-- 25 HAIR CARE REMEDIES (CAPILLAIRE)
-- ----------------------------------------------------------------
(
  'b0000001-0000-0000-0000-000000000001'::uuid,
  'Masque Fortifiant Karité & Chébé',
  'Soin profond ancestral tchadien anti-casse et scellant d''hydratation pour cheveux crépus Type 4.',
  'beauty', 'hair', 'mask',
  ARRAY['growth_retention', 'anti_breakage', 'intense_hydration'],
  '{"frequency": "1x/semaine", "application": "Appliquer section par section des racines aux pointes après le shampooing. Laisser poser 45 min sous charlotte puis rincer.", "duration_min": 45}'::jsonb,
  15, 0, 1, 'easy', true, NOW()
),
(
  'b0000002-0000-0000-0000-000000000004'::uuid,
  'Bain d''Huiles Pousse Intense Argan & Ricin',
  'Pre-poo nourrissant et fortifiant qui stimule les follicules et prévient la casse.',
  'beauty', 'hair', 'oil_bath',
  ARRAY['growth_retention', 'anti_breakage'],
  '{"frequency": "2x/mois", "application": "Masser le cuir chevelu avec l''huile tiède. Envelopper d''une serviette chaude pendant 30 min avant le lavage.", "duration_min": 30}'::jsonb,
  5, 5, 1, 'easy', true, NOW()
),
(
  'b0000003-0000-0000-0000-000000000003'::uuid,
  'Lotion Hydratante Aloé & Hibiscus',
  'Brume sans rincage tonifiante qui referme les écailles et ravive l''éclat des boucles.',
  'beauty', 'both', 'toner_mist',
  ARRAY['intense_hydration', 'glow_brightening'],
  '{"frequency": "Quotidien", "application": "Vaporiser sur cheveux humides ou secs matin et soir pour réhydrater les longueurs.", "duration_min": 2}'::jsonb,
  5, 0, 1, 'easy', true, NOW()
),
(
  'b0000004-0000-0000-0000-000000000005'::uuid,
  'Sérum Cuir Chevelu Apaisant Jojoba & Menthe',
  'Elixir rafraîchissant anti-démangeaisons qui régule le sébum et stimule la pousse.',
  'beauty', 'hair', 'scalp_serum',
  ARRAY['scalp_soothing', 'sebum_balance', 'growth_retention'],
  '{"frequency": "3x/semaine", "application": "Appliquer quelques gouttes directement sur le cuir chevelu et masser en mouvements circulaires.", "duration_min": 5}'::jsonb,
  5, 0, 1, 'easy', true, NOW()
),
(
  'b0000005-0000-0000-0000-000000000006'::uuid,
  'Beurre Scellant Karité & Baobab',
  'Baume riche nourissant qui verrouille l''hydratation et protège les pointes des agressions.',
  'beauty', 'hair', 'moisturizer',
  ARRAY['intense_hydration', 'protective_care', 'anti_breakage'],
  '{"frequency": "2x/semaine", "application": "Chauffer une noisette entre les paumes et appliquer sur les pointes après la brume hydratante.", "duration_min": 3}'::jsonb,
  10, 0, 1, 'easy', true, NOW()
),
(
  'b0000006-0000-0000-0000-000000000008'::uuid,
  'Huile de Massage Anti-Chute Nigelle & Ricin',
  'Soin concentré en thymoquinone qui tonifie les racines fragiles et freine la chute.',
  'beauty', 'hair', 'scalp_serum',
  ARRAY['growth_retention', 'scalp_soothing'],
  '{"frequency": "2x/semaine", "application": "Masser le cuir chevelu le soir avant de dormir.", "duration_min": 10}'::jsonb,
  5, 0, 1, 'easy', true, NOW()
),
(
  'b0000007-0000-0000-0000-000000000010'::uuid,
  'Masque Protéiné Amla & Shikakai',
  'Soin ayurvédique gainant qui redonne du volume et de la vigueur aux cheveux fins.',
  'beauty', 'hair', 'mask',
  ARRAY['growth_retention', 'anti_breakage'],
  '{"frequency": "1x/mois", "application": "Mélanger les poudres à de l''eau tiède. Appliquer la pâte sur cheveux humides et rincer abondamment après 30 min.", "duration_min": 30}'::jsonb,
  10, 0, 1, 'medium', true, NOW()
),
(
  'b0000008-0000-0000-0000-000000000011'::uuid,
  'Shampooing Végétal Reetha & Shikakai',
  'Nettoyant moussant 100% naturel sans sulfates qui lave le cuir chevelu en douceur.',
  'beauty', 'hair', 'leave_in_mist',
  ARRAY['sebum_balance', 'scalp_soothing'],
  '{"frequency": "1x/semaine", "application": "Faire bouillir les poudres, filtrer et utiliser l''eau savonneuse pour laver la chevelure.", "duration_min": 15}'::jsonb,
  15, 10, 1, 'medium', true, NOW()
),
(
  'b0000009-0000-0000-0000-000000000012'::uuid,
  'Elixir Pousse Chébé & Bhringraj',
  'Huile capillaire sacrée qui combine la tradition tchadienne et le savoir ayurvédique.',
  'beauty', 'hair', 'scalp_serum',
  ARRAY['growth_retention', 'anti_breakage', 'protective_care'],
  '{"frequency": "3x/semaine", "application": "Masser les tempes et le cuir chevelu.", "duration_min": 5}'::jsonb,
  10, 0, 1, 'easy', true, NOW()
),
(
  'b0000010-0000-0000-0000-000000000013'::uuid,
  'Bain d''Huiles Lissant Camélia & Argan',
  'Soin précieux japonais Tsubaki qui discipline les frisottis et apporte un fini soie.',
  'beauty', 'hair', 'oil_bath',
  ARRAY['intense_hydration', 'glow_brightening', 'protective_care'],
  '{"frequency": "2x/mois", "application": "Appliquer sur longueurs et pointes avant le shampooing.", "duration_min": 30}'::jsonb,
  5, 0, 1, 'easy', true, NOW()
),
(
  'b0000011-0000-0000-0000-000000000014'::uuid,
  'Gel Définiteur Boucles Lin & Aloé Véra',
  'Gel de coiffage 100% végétal qui fixe les boucles sans effet carton ni résidus.',
  'beauty', 'hair', 'leave_in_mist',
  ARRAY['intense_hydration', 'protective_care'],
  '{"frequency": "Après lavage", "application": "Répartir sur cheveux gorgés d''eau et scruncher les boucles.", "duration_min": 5}'::jsonb,
  15, 10, 1, 'easy', true, NOW()
),
(
  'b0000012-0000-0000-0000-000000000015'::uuid,
  'Chantilly de Karité & Murumuru',
  'Beurre fouetté ultra-onctueux qui restaure l''élasticité des cheveux très secs.',
  'beauty', 'hair', 'moisturizer',
  ARRAY['intense_hydration', 'anti_breakage'],
  '{"frequency": "2x/semaine", "application": "Fouetter les beurres fondus puis appliquer sur les nattes ou les tresses.", "duration_min": 5}'::jsonb,
  20, 5, 1, 'medium', true, NOW()
),

-- ----------------------------------------------------------------
-- 25 SKIN CARE REMEDIES (CUTANÉ)
-- ----------------------------------------------------------------
(
  'b0000002-0000-0000-0000-000000000002'::uuid,
  'Soin Purifiant Nigelle & Argile Verte',
  'Masque nettoyant détoxifiant anti-imperfections pour peaux mixtes à grasses.',
  'beauty', 'skin', 'cleanser_scrub',
  ARRAY['sebum_balance', 'scalp_soothing', 'glow_brightening'],
  '{"frequency": "1x/semaine", "application": "Appliquer en couche moyenne sur le visage évité le contour des yeux. Laisser poser 10 min sans laisser sécher puis rincer.", "duration_min": 10}'::jsonb,
  5, 0, 1, 'easy', true, NOW()
),
(
  'b0000007-0000-0000-0000-000000000007'::uuid,
  'Masque Éclat Visage Curcuma & Aloé Véra',
  'Soin coup d''éclat anti-taches et anti-inflammatoire pour un teint unifié et lumineux.',
  'beauty', 'skin', 'face_mask',
  ARRAY['glow_brightening', 'intense_hydration'],
  '{"frequency": "2x/semaine", "application": "Laisser poser 15 min sur le visage propre puis rincer à l''eau tiède.", "duration_min": 15}'::jsonb,
  5, 0, 1, 'easy', true, NOW()
),
(
  'b0000013-0000-0000-0000-000000000016'::uuid,
  'Sérum Anti-Âge Ultime Figue de Barbarie & Argan',
  'Elixir précieux concentré en vitamine E et stérols qui raffermit et lisse les rides.',
  'beauty', 'skin', 'face_oil_serum',
  ARRAY['glow_brightening', 'intense_hydration'],
  '{"frequency": "Tous les soirs", "application": "Masser 3 gouttes sur le visage et le cou propres par mouvements ascendants.", "duration_min": 3}'::jsonb,
  3, 0, 1, 'easy', true, NOW()
),
(
  'b0000014-0000-0000-0000-000000000017'::uuid,
  'Lotion Tonique Éclat Hibiscus & Rose',
  'Eau florale tonifiante aux AHA d''hibiscus qui resserre les pores et illumine le teint.',
  'beauty', 'skin', 'toner_mist',
  ARRAY['glow_brightening', 'intense_hydration'],
  '{"frequency": "Matin et soir", "application": "Vaporiser sur le visage propre avant l''huile ou la crème.", "duration_min": 1}'::jsonb,
  2, 0, 1, 'easy', true, NOW()
),
(
  'b0000015-0000-0000-0000-000000000018'::uuid,
  'Masque Douceur Peaux Sensibles Argile Rose & Aloé',
  'Soin apaisant anti-rougeurs qui détoxifie en douceur les épidermes réactifs.',
  'beauty', 'skin', 'face_mask',
  ARRAY['scalp_soothing', 'glow_brightening', 'intense_hydration'],
  '{"frequency": "1x/semaine", "application": "Appliquer sur le visage et rincer à l''eau tiède après 12 min.", "duration_min": 12}'::jsonb,
  5, 0, 1, 'easy', true, NOW()
),
(
  'b0000016-0000-0000-0000-000000000019'::uuid,
  'Baume Réparateur Karité & Cacao',
  'Soin corporel intense pour coudes, talons et zones très sèches.',
  'beauty', 'skin', 'moisturizer',
  ARRAY['intense_hydration', 'protective_care'],
  '{"frequency": "Au besoin", "application": "Faire fondre une noisette et masser jusqu''à pénétration.", "duration_min": 5}'::jsonb,
  10, 0, 1, 'easy', true, NOW()
),
(
  'b0000017-0000-0000-0000-000000000020'::uuid,
  'Soin Gommage Purifiant Savon Noir Beldi & Eucalyptus',
  'Rituel hammam marocain qui élimine les peaux mortes et purifie le corps.',
  'beauty', 'skin', 'cleanser_scrub',
  ARRAY['sebum_balance', 'glow_brightening'],
  '{"frequency": "1x/semaine", "application": "Appliquer sur peau chaude sous la douche, laisser agir 5 min puis frotter au gant Kessa.", "duration_min": 15}'::jsonb,
  5, 0, 1, 'easy', true, NOW()
),
(
  'b0000018-0000-0000-0000-000000000021'::uuid,
  'Elixir Régénérant Marula & Buriti',
  'Huile visage concentrée en béta-carotène qui donne un effet bonne mine immédiat.',
  'beauty', 'skin', 'face_oil_serum',
  ARRAY['glow_brightening', 'intense_hydration'],
  '{"frequency": "Tous les matins", "application": "Appliquer 2 gouttes pour un teint radieux.", "duration_min": 2}'::jsonb,
  3, 0, 1, 'easy', true, NOW()
),
(
  'b0000019-0000-0000-0000-000000000022'::uuid,
  'Masque Nourrissant Miel Brut & Aloé Véra',
  'Soin humectant apaisant qui réhydrate intensément et accélère la cicatrisation.',
  'beauty', 'skin', 'face_mask',
  ARRAY['intense_hydration', 'scalp_soothing', 'glow_brightening'],
  '{"frequency": "2x/semaine", "application": "Laisser poser 20 min puis rincer à l''eau fraîche.", "duration_min": 20}'::jsonb,
  3, 0, 1, 'easy', true, NOW()
),
(
  'b0000020-0000-0000-0000-000000000023'::uuid,
  'Beurre Corporel Soyeux Murumuru & Cacao',
  'Beurre velouté amazonien qui adoucit la peau et prévient les vergetures.',
  'beauty', 'skin', 'moisturizer',
  ARRAY['intense_hydration', 'protective_care'],
  '{"frequency": "Quotidien", "application": "Masser sur tout le corps après la douche.", "duration_min": 5}'::jsonb,
  15, 0, 1, 'easy', true, NOW()
)
ON CONFLICT DO NOTHING;
