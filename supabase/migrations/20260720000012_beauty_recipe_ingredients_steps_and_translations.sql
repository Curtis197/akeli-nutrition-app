-- ================================================================
-- AKELI BEAUTY MODE: INGREDIENTS, STEPS & MULTILINGUAL TRANSLATIONS (FR/EN/ES)
-- ================================================================

-- 1. POPULATE MULTILINGUAL INGREDIENT NAMES
UPDATE ingredient SET name_fr = 'Beurre de Karité Brut', name_en = 'Raw Shea Butter', name_es = 'Manteca de Karité Cruda' WHERE active_key = 'shea_butter';
UPDATE ingredient SET name_fr = 'Poudre de Chébé Traditionnelle', name_en = 'Traditional Chebe Powder', name_es = 'Polvo de Chebe Tradicional' WHERE active_key = 'chebe';
UPDATE ingredient SET name_fr = 'Gel d''Aloé Véra Pur', name_en = 'Pure Aloe Vera Gel', name_es = 'Gel de Aloe Vera Puro' WHERE active_key = 'aloe_vera';
UPDATE ingredient SET name_fr = 'Huile de Nigelle (Cumin Noir)', name_en = 'Black Seed Oil (Nigella)', name_es = 'Aceite de Semilla Negra' WHERE active_key = 'black_seed';
UPDATE ingredient SET name_fr = 'Huile d''Argan Pressée à Froid', name_en = 'Cold-Pressed Argan Oil', name_es = 'Aceite de Argán Prensado en Frío' WHERE active_key = 'argan';
UPDATE ingredient SET name_fr = 'Huile de Ricin Noire', name_en = 'Jamaican Black Castor Oil', name_es = 'Aceite de Ricino Negro' WHERE active_key = 'ricin';
UPDATE ingredient SET name_fr = 'Fleurs d''Hibiscus Séchées (Karkadé)', name_en = 'Dried Hibiscus Flowers (Karkadeh)', name_es = 'Flores de Jamaica Secas' WHERE active_key = 'hibiscus';
UPDATE ingredient SET name_fr = 'Argile Verte Surfine', name_en = 'Superfine Green Clay', name_es = 'Arcilla Verde Superfina' WHERE active_key = 'clay';
UPDATE ingredient SET name_fr = 'Huile de Jojoba Végétale', name_en = 'Golden Jojoba Oil', name_es = 'Aceite de Jojoba Dorado' WHERE active_key = 'jojoba';

-- 2. LINK RECIPE INGREDIENTS WITH QUANTITIES AND UNITS
INSERT INTO recipe_ingredient (recipe_id, ingredient_id, quantity, unit, sort_order)
SELECT 
  r.id AS recipe_id, 
  i.id AS ingredient_id, 
  50.0 AS quantity, 
  'g' AS unit, 
  1 AS sort_order
FROM recipe r
JOIN ingredient i ON i.active_key = 'shea_butter'
WHERE r.id = 'b0000001-0000-0000-0000-000000000001'::uuid
ON CONFLICT DO NOTHING;

INSERT INTO recipe_ingredient (recipe_id, ingredient_id, quantity, unit, sort_order)
SELECT 
  r.id AS recipe_id, 
  i.id AS ingredient_id, 
  15.0 AS quantity, 
  'g' AS unit, 
  2 AS sort_order
FROM recipe r
JOIN ingredient i ON i.active_key = 'chebe'
WHERE r.id = 'b0000001-0000-0000-0000-000000000001'::uuid
ON CONFLICT DO NOTHING;

INSERT INTO recipe_ingredient (recipe_id, ingredient_id, quantity, unit, sort_order)
SELECT 
  r.id AS recipe_id, 
  i.id AS ingredient_id, 
  30.0 AS quantity, 
  'g' AS unit, 
  1 AS sort_order
FROM recipe r
JOIN ingredient i ON i.active_key = 'clay'
WHERE r.id = 'b0000002-0000-0000-0000-000000000002'::uuid
ON CONFLICT DO NOTHING;

INSERT INTO recipe_ingredient (recipe_id, ingredient_id, quantity, unit, sort_order)
SELECT 
  r.id AS recipe_id, 
  i.id AS ingredient_id, 
  15.0 AS quantity, 
  'ml' AS unit, 
  2 AS sort_order
FROM recipe r
JOIN ingredient i ON i.active_key = 'black_seed'
WHERE r.id = 'b0000002-0000-0000-0000-000000000002'::uuid
ON CONFLICT DO NOTHING;

-- 3. SEED PREPARATION STEPS FOR REMEDIES (title = NULL for regular steps)
INSERT INTO recipe_step (id, recipe_id, step_number, title, content, timer_seconds, sort_order)
VALUES
(
  'c0000001-0000-0000-0000-000000000001'::uuid,
  'b0000001-0000-0000-0000-000000000001'::uuid,
  1,
  NULL,
  'Faire ramollir le beurre de karité au bain-marie. Incorporer la poudre de chébé et mélanger jusqu''à obtenir une pâte homogène et onctueuse.',
  300,
  1
),
(
  'c0000001-0000-0000-0000-000000000002'::uuid,
  'b0000001-0000-0000-0000-000000000001'::uuid,
  2,
  NULL,
  'Séparer la chevelure en 4 sections. Appliquer généreusement des longueurs aux pointes en évitant le cuir chevelu. Couvrir d''une charlotte chauffante pendant 45 minutes.',
  2700,
  2
),
(
  'c0000002-0000-0000-0000-000000000001'::uuid,
  'b0000002-0000-0000-0000-000000000002'::uuid,
  1,
  NULL,
  'Mélanger l''argile verte et l''huile de nigelle dans un bol en bois ou verre avec un peu d''eau tiède pour former une pâte fluide.',
  180,
  1
),
(
  'c0000002-0000-0000-0000-000000000002'::uuid,
  'b0000002-0000-0000-0000-000000000002'::uuid,
  2,
  NULL,
  'Appliquer au pinceau sur le visage propre en évitant le contour des yeux. Laisser poser 10 minutes sans laisser sécher complètement, puis rincer à l''eau tiède.',
  600,
  2
)
ON CONFLICT DO NOTHING;

-- 4. SEED RECIPE MULTILINGUAL TRANSLATIONS (FR / EN / ES)
INSERT INTO recipe_translation (recipe_id, locale, title, description)
VALUES
(
  'b0000001-0000-0000-0000-000000000001'::uuid, 'fr',
  'Masque Fortifiant Karité & Chébé',
  'Soin profond ancestral tchadien anti-casse et scellant d''hydratation pour cheveux crépus Type 4.'
),
(
  'b0000002-0000-0000-0000-000000000002'::uuid, 'fr',
  'Soin Purifiant Nigelle & Argile Verte',
  'Masque nettoyant détoxifiant anti-imperfections pour peaux mixtes à grasses.'
),
(
  'b0000001-0000-0000-0000-000000000001'::uuid, 'en',
  'Fortifying Shea & Chebe Mask',
  'Ancestral Chadian deep treatment for moisture retention and anti-breakage on Type 4 hair.'
),
(
  'b0000002-0000-0000-0000-000000000002'::uuid, 'en',
  'Purifying Black Seed & Green Clay Treatment',
  'Detoxifying and clarifying face mask for oily and acne-prone skin.'
),
(
  'b0000001-0000-0000-0000-000000000001'::uuid, 'es',
  'Mascarilla Fortalecedora de Karité y Chebe',
  'Tratamiento profundo ancestral chadiano anti-rotura para cabello rizado Tipo 4.'
),
(
  'b0000002-0000-0000-0000-000000000002'::uuid, 'es',
  'Tratamiento Purificante de Semilla Negra y Arcilla Verde',
  'Mascarilla desintoxicante y purificante para pieles mixtas a grasas.'
)
ON CONFLICT DO NOTHING;

-- 5. SEED RECIPE STEP MULTILINGUAL TRANSLATIONS (FR / EN / ES)
INSERT INTO recipe_step_translation (step_id, locale, title, content)
VALUES
(
  'c0000001-0000-0000-0000-000000000001'::uuid, 'fr',
  NULL,
  'Faire ramollir le beurre de karité au bain-marie. Incorporer la poudre de chébé et mélanger jusqu''à obtenir une pâte homogène et onctueuse.'
),
(
  'c0000001-0000-0000-0000-000000000002'::uuid, 'fr',
  NULL,
  'Séparer la chevelure en 4 sections. Appliquer généreusement des longueurs aux pointes en évitant le cuir chevelu. Couvrir d''une charlotte chauffante pendant 45 minutes.'
),
(
  'c0000001-0000-0000-0000-000000000001'::uuid, 'en',
  NULL,
  'Slightly melt the shea butter in a double boiler. Whisk in the chebe powder until smooth and creamy.'
),
(
  'c0000001-0000-0000-0000-000000000002'::uuid, 'en',
  NULL,
  'Section hair into 4 parts. Apply generously from mid-lengths to ends avoiding the scalp. Cover with a warm conditioning cap for 45 minutes.'
),
(
  'c0000001-0000-0000-0000-000000000001'::uuid, 'es',
  NULL,
  'Derretir ligeramente la manteca de karité a baño María. Mezclar con el polvo de chebe hasta obtener una crema suave.'
),
(
  'c0000001-0000-0000-0000-000000000002'::uuid, 'es',
  NULL,
  'Dividir el cabello en 4 secciones. Aplicar desde el medio hasta las puntas. Cubrir con un gorro térmico durante 45 minutos.'
)
ON CONFLICT DO NOTHING;
