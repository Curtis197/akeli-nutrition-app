-- =============================================================================
-- AKELI V1 — Seed : Données de référence
-- Fichier: 01_reference_data.sql
-- Ces données sont stables et ne changent pas souvent.
-- À exécuter après les migrations.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- food_region — Régions culinaires
-- ---------------------------------------------------------------------------

INSERT INTO food_region (code, name_fr, name_en, name_es, name_pt) VALUES
  ('west_africa',   'Afrique de l''Ouest',   'West Africa',    'África del Oeste',  'África Ocidental'),
  ('central_africa','Afrique Centrale',       'Central Africa', 'África Central',    'África Central'),
  ('east_africa',   'Afrique de l''Est',      'East Africa',    'África del Este',   'África Oriental'),
  ('north_africa',  'Afrique du Nord',        'North Africa',   'África del Norte',  'África do Norte'),
  ('south_africa',  'Afrique Australe',       'Southern Africa','África del Sur',    'África do Sul'),
  ('caribbean',     'Caraïbes',               'Caribbean',      'Caribe',            'Caribe'),
  ('france',        'France',                 'France',         'Francia',           'França'),
  ('mediterranean', 'Méditerranée',           'Mediterranean',  'Mediterráneo',      'Mediterrâneo'),
  ('middle_east',   'Moyen-Orient',           'Middle East',    'Oriente Medio',     'Oriente Médio'),
  ('south_asia',    'Asie du Sud',            'South Asia',     'Asia del Sur',      'Ásia do Sul'),
  ('southeast_asia','Asie du Sud-Est',        'Southeast Asia', 'Sudeste Asiático',  'Sudeste Asiático'),
  ('latin_america', 'Amérique Latine',        'Latin America',  'Latinoamérica',     'América Latina'),
  ('north_america', 'Amérique du Nord',       'North America',  'América del Norte', 'América do Norte')
ON CONFLICT (code) DO NOTHING;

-- ---------------------------------------------------------------------------
-- ingredient_category — Catégories d'ingrédients
-- ---------------------------------------------------------------------------

INSERT INTO ingredient_category (code, name_fr, name_en) VALUES
  ('protein',       'Protéines',          'Protein'),
  ('vegetable',     'Légumes',            'Vegetables'),
  ('fruit',         'Fruits',             'Fruits'),
  ('grain',         'Céréales & Féculents','Grains & Starches'),
  ('legume',        'Légumineuses',       'Legumes'),
  ('dairy',         'Produits laitiers',  'Dairy'),
  ('fat_oil',       'Graisses & Huiles',  'Fats & Oils'),
  ('spice_herb',    'Épices & Herbes',    'Spices & Herbs'),
  ('sauce_condiment','Sauces & Condiments','Sauces & Condiments'),
  ('nut_seed',      'Noix & Graines',     'Nuts & Seeds'),
  ('seafood',       'Fruits de mer & Poisson','Seafood & Fish'),
  ('beverage',      'Boissons',           'Beverages'),
  ('sweetener',     'Sucrants',           'Sweeteners'),
  ('other',         'Autre',              'Other')
ON CONFLICT (code) DO NOTHING;

-- ---------------------------------------------------------------------------
-- measurement_unit — Unités de mesure
-- ---------------------------------------------------------------------------

INSERT INTO measurement_unit (code, name_fr, name_en, name_es, name_pt) VALUES
  -- Masse
  ('g',     'grammes',        'grams',         'gramos',         'gramas'),
  ('kg',    'kilogrammes',    'kilograms',      'kilogramos',     'quilogramas'),
  ('mg',    'milligrammes',   'milligrams',     'miligramos',     'miligramas'),
  -- Volume
  ('ml',    'millilitres',    'milliliters',    'mililitros',     'mililitros'),
  ('cl',    'centilitres',    'centiliters',    'centilitros',    'centilitros'),
  ('l',     'litres',         'liters',         'litros',         'litros'),
  -- Cuisine impériale / commune
  ('tsp',   'cuillère à café','teaspoon',       'cucharadita',    'colher de chá'),
  ('tbsp',  'cuillère à soupe','tablespoon',    'cucharada',      'colher de sopa'),
  ('cup',   'tasse',          'cup',            'taza',           'xícara'),
  -- Pièces
  ('piece', 'pièce',          'piece',          'pieza',          'peça'),
  ('slice', 'tranche',        'slice',          'rebanada',       'fatia'),
  ('bunch', 'bouquet',        'bunch',          'manojo',         'maço'),
  ('pinch', 'pincée',         'pinch',          'pizca',          'pitada'),
  ('to_taste','à goût',       'to taste',       'al gusto',       'a gosto')
ON CONFLICT (code) DO NOTHING;

-- ---------------------------------------------------------------------------
-- tag — Tags recettes
-- ---------------------------------------------------------------------------

INSERT INTO tag (name, name_fr, name_en, name_es, name_pt) VALUES
  -- Régimes
  ('vegetarian',    'Végétarien',     'Vegetarian',    'Vegetariano',   'Vegetariano'),
  ('vegan',         'Vegan',          'Vegan',         'Vegano',        'Vegano'),
  ('halal',         'Halal',          'Halal',         'Halal',         'Halal'),
  ('gluten_free',   'Sans gluten',    'Gluten-free',   'Sin gluten',    'Sem glúten'),
  ('lactose_free',  'Sans lactose',   'Lactose-free',  'Sin lactosa',   'Sem lactose'),
  ('low_carb',      'Faible en glucides','Low-carb',   'Bajo en carbohidratos','Low-carb'),
  ('high_protein',  'Riche en protéines','High protein','Alto en proteínas','Rico em proteínas'),
  -- Repas
  ('quick',         'Rapide',         'Quick',         'Rápido',        'Rápido'),
  ('meal_prep',     'Meal prep',      'Meal prep',     'Meal prep',     'Meal prep'),
  ('family',        'En famille',     'Family',        'Familiar',      'Família'),
  ('budget',        'Économique',     'Budget',        'Económico',     'Económico'),
  -- Occasions
  ('festive',       'Festif',         'Festive',       'Festivo',       'Festivo'),
  ('street_food',   'Street food',    'Street food',   'Comida callejera','Street food'),
  -- Saveurs
  ('spicy',         'Épicé',          'Spicy',         'Picante',       'Picante'),
  ('sweet',         'Sucré',          'Sweet',         'Dulce',         'Doce'),
  ('savory',        'Salé',           'Savory',        'Salado',        'Salgado'),
  -- Technique
  ('fried',         'Frit',           'Fried',         'Frito',         'Frito'),
  ('grilled',       'Grillé',         'Grilled',       'A la parrilla', 'Grelhado'),
  ('baked',         'Au four',        'Baked',         'Al horno',      'Assado'),
  ('raw',           'Cru',            'Raw',           'Crudo',         'Cru'),
  ('one_pot',       'One pot',        'One pot',       'Un solo recipiente','One pot')
ON CONFLICT (name) DO NOTHING;
