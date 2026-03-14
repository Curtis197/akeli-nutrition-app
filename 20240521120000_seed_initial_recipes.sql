-- supabase/migrations/YYYYMMDDHHMMSS_seed_initial_recipes.sql
--
-- This migration file seeds the database with an initial set of African recipes.
-- It populates reference tables and then adds recipes with their ingredients and steps.
--
-- Note on table names: This script uses the correct spelling "recipe". If your schema
-- has the typo "receipe", you will need to find and replace "recipe" with "receipe"
-- throughout this file.

BEGIN;

--
-- 1. Seed Reference Data
-- These inserts are idempotent using ON CONFLICT DO NOTHING.
--

-- Food Regions
INSERT INTO public.food_region (name) VALUES
('AFRIQUE DE L''OUEST'),
('AFRIQUE DE L''EST'),
('AFRIQUE DU NORD'),
('AFRIQUE AUSTRALE'),
('AFRIQUE CENTRALE'),
('ÎLES ET CÔTES'),
('RECETTES COMPLÉMENTAIRES')
ON CONFLICT (name) DO NOTHING;

-- Difficulty Levels
INSERT INTO public.difficulty (name) VALUES
('Facile'),
('Moyen'),
('Difficile')
ON CONFLICT (name) DO NOTHING;

-- Measurement Units
INSERT INTO public.measurement_unit (name, abbreviation) VALUES
('gramme', 'g'),
('kilogramme', 'kg'),
('millilitre', 'ml'),
('litre', 'l'),
('cuillère à soupe', 'c.à.s.'),
('cuillère à café', 'c.à.c.'),
('pincée', 'pincée'),
('tasse', 'tasse'),
('unité', 'unité'),
('gousse', 'gousse'),
('filet', 'filet'),
('botte', 'botte'),
('boîte', 'boîte'),
('tranche', 'tranche'),
('feuille', 'feuille')
ON CONFLICT (name) DO NOTHING;

--
-- 2. Seed Creator
-- Insert the default creator for the initial recipes.
--
INSERT INTO public.creator (id, display_name, username) VALUES
('f1414791-8f57-4bf4-a730-42f3c89dad95', 'Akeli Kitchen', 'akeli_kitchen')
ON CONFLICT (id) DO UPDATE SET display_name = EXCLUDED.display_name;

--
-- 3. Seed Master Ingredient List
-- A master list of all ingredients used in this seed file.
--
INSERT INTO public.ingredient (name) VALUES
('Riz long grain'), ('Tomate'), ('Poivron rouge'), ('Oignon'), ('Ail'), ('Piment'), ('Concentré de tomate'), ('Huile végétale'), ('Bouillon de poulet'), ('Thym'), ('Curry en poudre'), ('Sel'), ('Poivre'), ('Eau'),
('Poisson (Thiof ou Capitaine)'), ('Riz brisé'), ('Poisson séché (Guedj)'), ('Yet (mollusque séché)'), ('Carotte'), ('Chou blanc'), ('Manioc'), ('Aubergine'), ('Navet'), ('Persil'), ('Huile d''arachide'),
('Bœuf'), ('Pâte d''arachide'), ('Tomates pelées'), ('Pomme de terre'), ('Patate douce'), ('Bouillon de bœuf'),
('Poulet'), ('Citron'), ('Moutarde de Dijon'), ('Vinaigre'),
('Oeuf'), ('Poudre de Berbéré'), ('Beurre clarifié (Niter Kibbeh)'),
('Farine de teff'), ('Levure'),
('Farine de maïs'),
('Couscous'), ('Agneau'), ('Pruneaux'), ('Amandes effilées'), ('Miel'), ('Cannelle'), ('Gingembre'), ('Ras el hanout'), ('Coriandre'),
('Poivron vert'), ('Cumin'), ('Paprika'), ('Harissa'),
('Viande hachée'), ('Chapelure'), ('Lait'), ('Noix de muscade'), ('Feuille de laurier'), ('Curcuma'),
('Noix de palme'), ('Poisson fumé'),
('Saucisse fumée'), ('Gros piment'),
('Banane plantain mûre'),
('Farine de blé'), ('Sucre'), ('Levure de boulanger'), ('Sucre vanillé')
ON CONFLICT (name) DO NOTHING;

--
-- 4. Seed Recipes
-- Each recipe is added in a block with its steps and ingredients.
--

-- =================================================================
-- Recipe 1: Riz Jollof (West Africa)
-- =================================================================
DO $$
DECLARE
    recipe_id_var UUID;
BEGIN
    INSERT INTO public.recipe (creator_id, region_id, difficulty_id, title, slug, description, prep_time_min, cook_time_min, servings)
    VALUES (
        'f1414791-8f57-4bf4-a730-42f3c89dad95',
        (SELECT id FROM public.food_region WHERE name = 'AFRIQUE DE L''OUEST'),
        (SELECT id FROM public.difficulty WHERE name = 'Moyen'),
        'Riz Jollof',
        'riz-jollof',
        'Un plat de riz emblématique cuit dans une sauce tomate riche et épicée, populaire dans toute l''Afrique de l''Ouest.',
        20, 40, 6
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Mixer les tomates, le poivron, un oignon, l''ail et le piment pour obtenir une purée lisse.'),
    (recipe_id_var, 2, 'Faire chauffer l''huile dans une grande marmite. Hacher le deuxième oignon et le faire revenir jusqu''à ce qu''il soit translucide.'),
    (recipe_id_var, 3, 'Ajouter le concentré de tomate et faire frire pendant 5 minutes en remuant.'),
    (recipe_id_var, 4, 'Verser la purée de légumes, le thym, le curry, le cube de bouillon, le sel et le poivre. Laisser mijoter 15-20 minutes.'),
    (recipe_id_var, 5, 'Pendant ce temps, laver le riz à l''eau froide jusqu''à ce que l''eau soit claire.'),
    (recipe_id_var, 6, 'Ajouter le riz lavé à la sauce et bien mélanger.'),
    (recipe_id_var, 7, 'Ajouter l''eau ou le bouillon. Le liquide doit juste couvrir le riz. Porter à ébullition.'),
    (recipe_id_var, 8, 'Réduire le feu au minimum, couvrir hermétiquement et laisser cuire à la vapeur pendant 20-25 minutes.'),
    (recipe_id_var, 9, 'Égrener délicatement avec une fourchette avant de servir.');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Riz long grain', 500, 'g'),
        ('Tomate', 4, 'unité'),
        ('Poivron rouge', 1, 'unité'),
        ('Oignon', 2, 'unité'),
        ('Ail', 2, 'gousse'),
        ('Piment', 1, 'unité'),
        ('Concentré de tomate', 70, 'g'),
        ('Huile végétale', 100, 'ml'),
        ('Bouillon de poulet', 1, 'unité'),
        ('Thym', 1, 'c.à.c.'),
        ('Curry en poudre', 1, 'c.à.c.'),
        ('Sel', 1, 'pincée'),
        ('Poivre', 1, 'pincée'),
        ('Eau', 1.2, 'l')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 2: Thieboudienne (West Africa)
-- =================================================================
DO $$
DECLARE
    recipe_id_var UUID;
BEGIN
    INSERT INTO public.recipe (creator_id, region_id, difficulty_id, title, slug, description, prep_time_min, cook_time_min, servings)
    VALUES (
        'f1414791-8f57-4bf4-a730-42f3c89dad95',
        (SELECT id FROM public.food_region WHERE name = 'AFRIQUE DE L''OUEST'),
        (SELECT id FROM public.difficulty WHERE name = 'Difficile'),
        'Thieboudienne',
        'thieboudienne',
        'Le plat national du Sénégal, un riz savoureux cuit dans une sauce tomate riche avec du poisson et une variété de légumes.',
        45, 90, 6
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Préparer la farce ("rof"): piler l''ail, le persil, un piment, sel et poivre. Farcir les morceaux de poisson avec.'),
    (recipe_id_var, 2, 'Faire chauffer l''huile et dorer les morceaux de poisson. Retirer et réserver.'),
    (recipe_id_var, 3, 'Dans la même huile, faire revenir les oignons hachés. Ajouter le concentré de tomate dilué et cuire 10 minutes.'),
    (recipe_id_var, 4, 'Ajouter 2 litres d''eau, le poisson séché (guedj) et le yet. Porter à ébullition.'),
    (recipe_id_var, 5, 'Plonger les légumes coupés en gros morceaux dans le bouillon. Laisser mijoter 30-40 minutes.'),
    (recipe_id_var, 6, 'Ajouter le poisson farci et un piment entier. Cuire 15 minutes.'),
    (recipe_id_var, 7, 'Retirer le poisson et les légumes, les garder au chaud. Filtrer le bouillon.'),
    (recipe_id_var, 8, 'Laver le riz brisé et le précuire à la vapeur 15 minutes.'),
    (recipe_id_var, 9, 'Verser le riz dans le bouillon filtré. Cuire à feu doux jusqu''à absorption complète.'),
    (recipe_id_var, 10, 'Servir le riz dans un grand plat, garni avec le poisson et les légumes.');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Poisson (Thiof ou Capitaine)', 1, 'kg'),
        ('Riz brisé', 1, 'kg'),
        ('Concentré de tomate', 150, 'g'),
        ('Poisson séché (Guedj)', 50, 'g'),
        ('Yet (mollusque séché)', 1, 'unité'),
        ('Carotte', 1, 'unité'),
        ('Chou blanc', 0.5, 'unité'),
        ('Manioc', 1, 'unité'),
        ('Aubergine', 1, 'unité'),
        ('Navet', 1, 'unité'),
        ('Oignon', 2, 'unité'),
        ('Ail', 4, 'gousse'),
        ('Persil', 1, 'botte'),
        ('Piment', 2, 'unité'),
        ('Huile d''arachide', 200, 'ml'),
        ('Sel', 1, 'pincée'),
        ('Poivre', 1, 'pincée')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 3: Maafe (West Africa)
-- =================================================================
DO $$
DECLARE
    recipe_id_var UUID;
BEGIN
    INSERT INTO public.recipe (creator_id, region_id, difficulty_id, title, slug, description, prep_time_min, cook_time_min, servings)
    VALUES (
        'f1414791-8f57-4bf4-a730-42f3c89dad95',
        (SELECT id FROM public.food_region WHERE name = 'AFRIQUE DE L''OUEST'),
        (SELECT id FROM public.difficulty WHERE name = 'Moyen'),
        'Maafe (Ragoût d''Arachide)',
        'maafe-ragout-arachide',
        'Un ragoût onctueux et réconfortant à base de pâte d''arachide, de viande et de légumes, servi avec du riz blanc.',
        20, 60, 4
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Couper la viande en morceaux. Hacher les oignons et l''ail.'),
    (recipe_id_var, 2, 'Dans une cocotte, faire dorer la viande dans l''huile. Retirer et réserver.'),
    (recipe_id_var, 3, 'Faire revenir les oignons et l''ail. Ajouter le concentré de tomate et cuire 2 minutes.'),
    (recipe_id_var, 4, 'Ajouter les tomates pelées, le cube de bouillon et 1 litre d''eau. Porter à ébullition.'),
    (recipe_id_var, 5, 'Remettre la viande et laisser mijoter 30 minutes.'),
    (recipe_id_var, 6, 'Peler et couper les carottes, pommes de terre et patate douce en gros morceaux.'),
    (recipe_id_var, 7, 'Délayer la pâte d''arachide avec un peu de bouillon chaud jusqu''à obtenir une crème lisse.'),
    (recipe_id_var, 8, 'Verser la crème d''arachide dans la cocotte en remuant bien.'),
    (recipe_id_var, 9, 'Ajouter les légumes et le piment. Saler, poivrer.'),
    (recipe_id_var, 10, 'Laisser mijoter à feu très doux 30-40 minutes, jusqu''à ce que la sauce épaississe.');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Bœuf', 500, 'g'),
        ('Pâte d''arachide', 200, 'g'),
        ('Oignon', 2, 'unité'),
        ('Ail', 3, 'gousse'),
        ('Tomates pelées', 1, 'boîte'),
        ('Carotte', 2, 'unité'),
        ('Pomme de terre', 2, 'unité'),
        ('Patate douce', 1, 'unité'),
        ('Huile végétale', 100, 'ml'),
        ('Bouillon de bœuf', 1, 'unité'),
        ('Concentré de tomate', 1, 'c.à.s.'),
        ('Piment', 1, 'unité'),
        ('Sel', 1, 'pincée'),
        ('Poivre', 1, 'pincée')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 4: Poulet Yassa (West Africa)
-- =================================================================
DO $$
DECLARE
    recipe_id_var UUID;
BEGIN
    INSERT INTO public.recipe (creator_id, region_id, difficulty_id, title, slug, description, prep_time_min, cook_time_min, servings)
    VALUES (
        'f1414791-8f57-4bf4-a730-42f3c89dad95',
        (SELECT id FROM public.food_region WHERE name = 'AFRIQUE DE L''OUEST'),
        (SELECT id FROM public.difficulty WHERE name = 'Moyen'),
        'Poulet Yassa',
        'poulet-yassa',
        'Un plat sénégalais classique de poulet mariné dans une abondance d''oignons, de citron et de moutarde, puis grillé et mijoté.',
        240, 60, 4
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Couper le poulet en morceaux. Émincer finement les oignons.'),
    (recipe_id_var, 2, 'Dans un grand bol, préparer la marinade: mélanger les oignons, le jus des citrons, la moutarde, l''huile, l''ail haché, sel et poivre.'),
    (recipe_id_var, 3, 'Ajouter les morceaux de poulet à la marinade, bien enrober. Couvrir et laisser mariner au réfrigérateur au moins 4 heures (idéalement toute une nuit).'),
    (recipe_id_var, 4, 'Retirer les morceaux de poulet de la marinade (réserver la marinade). Faire griller le poulet au barbecue, au four ou à la poêle jusqu''à ce qu''il soit bien doré.'),
    (recipe_id_var, 5, 'Pendant ce temps, verser toute la marinade (avec les oignons) dans une grande cocotte et faire cuire à feu moyen pendant 15-20 minutes jusqu''à ce que les oignons soient fondants.'),
    (recipe_id_var, 6, 'Ajouter les morceaux de poulet grillés dans la sauce aux oignons.'),
    (recipe_id_var, 7, 'Ajouter un verre d''eau ou de bouillon, le piment entier, et laisser mijoter à couvert pendant 20-30 minutes.'),
    (recipe_id_var, 8, 'Servir très chaud avec du riz blanc.');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Poulet', 1, 'kg'),
        ('Oignon', 4, 'unité'),
        ('Citron', 3, 'unité'),
        ('Moutarde de Dijon', 3, 'c.à.s.'),
        ('Huile végétale', 50, 'ml'),
        ('Ail', 4, 'gousse'),
        ('Piment', 1, 'unité'),
        ('Sel', 1, 'pincée'),
        ('Poivre', 1, 'pincée')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 5: Doro Wat (East Africa)
-- =================================================================
DO $$
DECLARE
    recipe_id_var UUID;
BEGIN
    INSERT INTO public.recipe (creator_id, region_id, difficulty_id, title, slug, description, prep_time_min, cook_time_min, servings)
    VALUES (
        'f1414791-8f57-4bf4-a730-42f3c89dad95',
        (SELECT id FROM public.food_region WHERE name = 'AFRIQUE DE L''EST'),
        (SELECT id FROM public.difficulty WHERE name = 'Difficile'),
        'Doro Wat',
        'doro-wat',
        'Un ragoût de poulet éthiopien emblématique, intensément savoureux et épicé, mijoté lentement avec des oignons caramélisés et du berbéré.',
        30, 120, 6
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Hacher très finement les oignons (presque en purée).'),
    (recipe_id_var, 2, 'Dans une cocotte à sec (sans huile), faire cuire les oignons à feu doux en remuant constamment pendant 30-40 minutes jusqu''à ce qu''ils soient dorés et réduits.'),
    (recipe_id_var, 3, 'Ajouter le beurre clarifié (Niter Kibbeh) et le berbéré. Faire revenir 5 minutes.'),
    (recipe_id_var, 4, 'Ajouter les morceaux de poulet et bien les enrober de sauce. Cuire 5 minutes.'),
    (recipe_id_var, 5, 'Ajouter l''ail, le gingembre et un peu d''eau. Couvrir et laisser mijoter à feu très doux pendant au moins 1 heure.'),
    (recipe_id_var, 6, 'Pendant ce temps, faire cuire les œufs durs, les écaler et les piquer avec une fourchette.'),
    (recipe_id_var, 7, 'Ajouter les œufs durs dans le ragoût 15 minutes avant la fin de la cuisson.'),
    (recipe_id_var, 8, 'La sauce doit être épaisse et riche. Servir chaud avec de l''injera.');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Poulet', 1, 'kg'),
        ('Oignon', 5, 'unité'),
        ('Poudre de Berbéré', 4, 'c.à.s.'),
        ('Beurre clarifié (Niter Kibbeh)', 100, 'g'),
        ('Ail', 4, 'gousse'),
        ('Gingembre', 1, 'c.à.s.'),
        ('Oeuf', 6, 'unité'),
        ('Sel', 1, 'pincée')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 6: Injera (East Africa)
-- =================================================================
DO $$
DECLARE
    recipe_id_var UUID;
BEGIN
    INSERT INTO public.recipe (creator_id, region_id, difficulty_id, title, slug, description, prep_time_min, cook_time_min, servings)
    VALUES (
        'f1414791-8f57-4bf4-a730-42f3c89dad95',
        (SELECT id FROM public.food_region WHERE name = 'AFRIQUE DE L''EST'),
        (SELECT id FROM public.difficulty WHERE name = 'Moyen'),
        'Injera',
        'injera',
        'La galette spongieuse et acidulée, à base de farine de teff fermentée, qui sert de base à la plupart des repas éthiopiens et érythréens.',
        4320, 20, 8
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Jour 1: Dans un grand récipient, mélanger la farine de teff avec l''eau. La consistance doit être celle d''une pâte à crêpes épaisse. Couvrir avec un linge et laisser fermenter à température ambiante.'),
    (recipe_id_var, 2, 'Jour 2 & 3: Remuer la pâte une fois par jour. Des bulles devraient commencer à apparaître et une odeur aigre se développer.'),
    (recipe_id_var, 3, 'Jour 4: La pâte est prête. Retirer le liquide qui a pu se former à la surface. La consistance doit être celle d''une pâte à crêpes.'),
    (recipe_id_var, 4, 'Faire chauffer une grande poêle antiadhésive (ou un "mogogo") à feu moyen-vif.'),
    (recipe_id_var, 5, 'Verser une louche de pâte en commençant par l''extérieur et en allant vers le centre en spirale.'),
    (recipe_id_var, 6, 'Laisser cuire jusqu''à ce que des "yeux" (petits trous) se forment sur toute la surface (environ 1 minute).'),
    (recipe_id_var, 7, 'Couvrir la poêle et laisser cuire à la vapeur pendant 1-2 minutes. Ne pas retourner la galette.'),
    (recipe_id_var, 8, 'Faire glisser l''injera sur un plat. Laisser refroidir avant d''empiler.');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Farine de teff', 500, 'g'),
        ('Eau', 1, 'l'),
        ('Levure', 0.5, 'c.à.c.')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 7: Ugali (East Africa)
-- =================================================================
DO $$
DECLARE
    recipe_id_var UUID;
BEGIN
    INSERT INTO public.recipe (creator_id, region_id, difficulty_id, title, slug, description, prep_time_min, cook_time_min, servings)
    VALUES (
        'f1414791-8f57-4bf4-a730-42f3c89dad95',
        (SELECT id FROM public.food_region WHERE name = 'AFRIQUE DE L''EST'),
        (SELECT id FROM public.difficulty WHERE name = 'Facile'),
        'Ugali',
        'ugali',
        'Un aliment de base dans une grande partie de l''Afrique, une bouillie de farine de maïs épaisse et ferme, parfaite pour accompagner les ragoûts.',
        5, 15, 4
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Porter l''eau à ébullition dans une casserole.'),
    (recipe_id_var, 2, 'Réduire le feu et verser lentement la farine de maïs en pluie tout en remuant vigoureusement avec une cuillère en bois pour éviter les grumeaux.'),
    (recipe_id_var, 3, 'Continuer à remuer et à "pousser" la pâte contre les parois de la casserole pendant 10-15 minutes.'),
    (recipe_id_var, 4, 'La pâte doit devenir très épaisse, lisse et se détacher des parois.'),
    (recipe_id_var, 5, 'Former une boule avec la cuillère.'),
    (recipe_id_var, 6, 'Servir immédiatement, chaud, en accompagnement de ragoûts de viande ou de légumes (comme le Sukuma Wiki).');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Farine de maïs', 500, 'g'),
        ('Eau', 1, 'l'),
        ('Sel', 0.5, 'c.à.c.')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 8: Tagine d'Agneau aux Pruneaux (North Africa)
-- =================================================================
DO $$
DECLARE
    recipe_id_var UUID;
BEGIN
    INSERT INTO public.recipe (creator_id, region_id, difficulty_id, title, slug, description, prep_time_min, cook_time_min, servings)
    VALUES (
        'f1414791-8f57-4bf4-a730-42f3c89dad95',
        (SELECT id FROM public.food_region WHERE name = 'AFRIQUE DU NORD'),
        (SELECT id FROM public.difficulty WHERE name = 'Moyen'),
        'Tagine d''Agneau aux Pruneaux',
        'tagine-agneau-pruneaux',
        'Un plat marocain sucré-salé classique, où l''agneau tendre est mijoté avec des épices chaudes, des oignons, et garni de pruneaux caramélisés.',
        20, 120, 4
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Dans un plat à tagine ou une cocotte, mélanger les morceaux d''agneau avec l''oignon haché, l''ail, le gingembre, le curcuma, la cannelle, sel et poivre.'),
    (recipe_id_var, 2, 'Ajouter l''huile et faire dorer la viande sur toutes ses faces.'),
    (recipe_id_var, 3, 'Couvrir d''eau à hauteur, ajouter le bouquet de coriandre, couvrir et laisser mijoter à feu très doux pendant 1h30.'),
    (recipe_id_var, 4, 'Pendant ce temps, dans une petite casserole, mettre les pruneaux, le miel, une pincée de cannelle et une louche de bouillon du tagine. Laisser confire à feu doux 15 minutes.'),
    (recipe_id_var, 5, 'Faire dorer les amandes effilées à sec dans une poêle.'),
    (recipe_id_var, 6, 'Pour servir, disposer la viande dans un plat, napper de sauce, et garnir avec les pruneaux confits et les amandes grillées.');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Agneau', 1, 'kg'),
        ('Pruneaux', 250, 'g'),
        ('Oignon', 2, 'unité'),
        ('Ail', 2, 'gousse'),
        ('Amandes effilées', 50, 'g'),
        ('Miel', 2, 'c.à.s.'),
        ('Huile végétale', 3, 'c.à.s.'),
        ('Gingembre', 1, 'c.à.c.'),
        ('Curcuma', 1, 'c.à.c.'),
        ('Cannelle', 1, 'c.à.c.'),
        ('Coriandre', 1, 'botte'),
        ('Sel', 1, 'pincée'),
        ('Poivre', 1, 'pincée')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 9: Shakshuka (North Africa)
-- =================================================================
DO $$
DECLARE
    recipe_id_var UUID;
BEGIN
    INSERT INTO public.recipe (creator_id, region_id, difficulty_id, title, slug, description, prep_time_min, cook_time_min, servings)
    VALUES (
        'f1414791-8f57-4bf4-a730-42f3c89dad95',
        (SELECT id FROM public.food_region WHERE name = 'AFRIQUE DU NORD'),
        (SELECT id FROM public.difficulty WHERE name = 'Facile'),
        'Shakshuka',
        'shakshuka',
        'Un plat réconfortant d''œufs pochés dans une sauce tomate épicée aux poivrons et oignons, parfait pour le brunch ou un dîner rapide.',
        10, 25, 2
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Hacher l''oignon et l''ail, couper les poivrons en lanières.'),
    (recipe_id_var, 2, 'Faire chauffer l''huile dans une grande poêle. Faire revenir l''oignon et les poivrons jusqu''à ce qu''ils soient tendres.'),
    (recipe_id_var, 3, 'Ajouter l''ail, le cumin, le paprika, la harissa, le sel et le poivre. Cuire 1 minute.'),
    (recipe_id_var, 4, 'Verser les tomates pelées et écraser les avec une cuillère. Laisser mijoter 10-15 minutes jusqu''à ce que la sauce épaississe.'),
    (recipe_id_var, 5, 'Avec le dos d''une cuillère, créer des petits puits dans la sauce.'),
    (recipe_id_var, 6, 'Casser un œuf dans chaque puits.'),
    (recipe_id_var, 7, 'Couvrir la poêle et laisser cuire 5-8 minutes, jusqu''à ce que les blancs d''œufs soient pris mais les jaunes encore coulants.'),
    (recipe_id_var, 8, 'Parsemer de coriandre fraîche et servir immédiatement avec du pain frais.');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Oeuf', 4, 'unité'),
        ('Tomates pelées', 1, 'boîte'),
        ('Oignon', 1, 'unité'),
        ('Poivron rouge', 1, 'unité'),
        ('Poivron vert', 1, 'unité'),
        ('Ail', 2, 'gousse'),
        ('Huile végétale', 2, 'c.à.s.'),
        ('Cumin', 1, 'c.à.c.'),
        ('Paprika', 1, 'c.à.c.'),
        ('Harissa', 0.5, 'c.à.c.'),
        ('Coriandre', 1, 'botte'),
        ('Sel', 1, 'pincée'),
        ('Poivre', 1, 'pincée')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 10: Bobotie (Southern Africa)
-- =================================================================
DO $$
DECLARE
    recipe_id_var UUID;
BEGIN
    INSERT INTO public.recipe (creator_id, region_id, difficulty_id, title, slug, description, prep_time_min, cook_time_min, servings)
    VALUES (
        'f1414791-8f57-4bf4-a730-42f3c89dad95',
        (SELECT id FROM public.food_region WHERE name = 'AFRIQUE AUSTRALE'),
        (SELECT id FROM public.difficulty WHERE name = 'Moyen'),
        'Bobotie',
        'bobotie',
        'Le plat national sud-africain, un hachis de viande épicé et sucré-salé, cuit au four avec une garniture crémeuse aux œufs.',
        25, 50, 6
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Préchauffer le four à 180°C. Faire tremper le pain dans le lait.'),
    (recipe_id_var, 2, 'Faire revenir l''oignon haché dans l''huile. Ajouter la viande hachée et la faire dorer.'),
    (recipe_id_var, 3, 'Ajouter l''ail, le curry, le curcuma, le sel et le poivre. Cuire 2 minutes.'),
    (recipe_id_var, 4, 'Essorer le pain et l''émietter dans la viande. Ajouter le chutney, le vinaigre et la moitié des amandes. Bien mélanger.'),
    (recipe_id_var, 5, 'Transférer le mélange dans un plat allant au four et bien tasser.'),
    (recipe_id_var, 6, 'Dans un bol, battre les œufs avec le reste du lait. Verser ce mélange sur la viande.'),
    (recipe_id_var, 7, 'Garnir avec les feuilles de laurier et le reste des amandes.'),
    (recipe_id_var, 8, 'Enfourner pour 30-35 minutes, jusqu''à ce que la garniture soit dorée et prise.'),
    (recipe_id_var, 9, 'Servir chaud avec du riz jaune et des sambals.');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Viande hachée', 1, 'kg'),
        ('Oignon', 1, 'unité'),
        ('Lait', 250, 'ml'),
        ('Chapelure', 2, 'tranche'),
        ('Oeuf', 2, 'unité'),
        ('Curry en poudre', 2, 'c.à.s.'),
        ('Curcuma', 1, 'c.à.c.'),
        ('Amandes effilées', 50, 'g'),
        ('Vinaigre', 2, 'c.à.s.'),
        ('Sucre', 1, 'c.à.s.'),
        ('Feuille de laurier', 2, 'feuille'),
        ('Sel', 1, 'pincée'),
        ('Poivre', 1, 'pincée')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 11: Poulet Moambé (Central Africa)
-- =================================================================
DO $$
DECLARE
    recipe_id_var UUID;
BEGIN
    INSERT INTO public.recipe (creator_id, region_id, difficulty_id, title, slug, description, prep_time_min, cook_time_min, servings)
    VALUES (
        'f1414791-8f57-4bf4-a730-42f3c89dad95',
        (SELECT id FROM public.food_region WHERE name = 'AFRIQUE CENTRALE'),
        (SELECT id FROM public.difficulty WHERE name = 'Moyen'),
        'Poulet Moambé',
        'poulet-moambe',
        'Un plat riche et savoureux, considéré comme le plat national dans plusieurs pays d''Afrique Centrale, fait de poulet mijoté dans une sauce onctueuse à la noix de palme.',
        15, 60, 4
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Faire dorer les morceaux de poulet dans une cocotte avec un peu d''huile.'),
    (recipe_id_var, 2, 'Ajouter l''oignon et l''ail hachés et faire revenir.'),
    (recipe_id_var, 3, 'Incorporer la purée de noix de palme (sauce graine) et les tomates.'),
    (recipe_id_var, 4, 'Ajouter de l''eau ou du bouillon pour obtenir la consistance désirée.'),
    (recipe_id_var, 5, 'Ajouter le piment entier, saler et poivrer.'),
    (recipe_id_var, 6, 'Couvrir et laisser mijoter à feu doux pendant 45-60 minutes, jusqu''à ce que le poulet soit tendre et la sauce épaissie.'),
    (recipe_id_var, 7, 'Servir chaud avec du riz, du foufou ou de la chikwangue.');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Poulet', 1, 'kg'),
        ('Noix de palme', 1, 'boîte'),
        ('Oignon', 2, 'unité'),
        ('Ail', 3, 'gousse'),
        ('Tomate', 2, 'unité'),
        ('Piment', 1, 'unité'),
        ('Sel', 1, 'pincée'),
        ('Poivre', 1, 'pincée')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 12: Rougail Saucisse (Islands)
-- =================================================================
DO $$
DECLARE
    recipe_id_var UUID;
BEGIN
    INSERT INTO public.recipe (creator_id, region_id, difficulty_id, title, slug, description, prep_time_min, cook_time_min, servings)
    VALUES (
        'f1414791-8f57-4bf4-a730-42f3c89dad95',
        (SELECT id FROM public.food_region WHERE name = 'ÎLES ET CÔTES'),
        (SELECT id FROM public.difficulty WHERE name = 'Facile'),
        'Rougail Saucisse',
        'rougail-saucisse',
        'Un plat emblématique de l''île de la Réunion, composé de saucisses fumées mijotées dans une sauce tomate épicée aux oignons, ail et gingembre.',
        15, 30, 4
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Piquer les saucisses et les faire blanchir 10 minutes dans l''eau bouillante. Les égoutter et les couper en rondelles.'),
    (recipe_id_var, 2, 'Faire revenir les rondelles de saucisse dans une marmite avec un peu d''huile jusqu''à ce qu''elles soient bien dorées.'),
    (recipe_id_var, 3, 'Ajouter les oignons émincés et faire revenir.'),
    (recipe_id_var, 4, 'Ajouter l''ail et le gingembre pilés, le curcuma et le thym. Cuire 1 minute.'),
    (recipe_id_var, 5, 'Incorporer les tomates coupées en dés et le piment.'),
    (recipe_id_var, 6, 'Saler, poivrer, et laisser mijoter à feu doux et à couvert pendant 20 minutes.'),
    (recipe_id_var, 7, 'Servir très chaud avec du riz blanc et des haricots rouges.');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Saucisse fumée', 6, 'unité'),
        ('Tomate', 4, 'unité'),
        ('Oignon', 2, 'unité'),
        ('Ail', 3, 'gousse'),
        ('Gingembre', 1, 'c.à.s.'),
        ('Curcuma', 1, 'c.à.c.'),
        ('Thym', 1, 'branche'),
        ('Gros piment', 1, 'unité'),
        ('Huile végétale', 2, 'c.à.s.')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 13: Alloco (Complementary)
-- =================================================================
DO $$
DECLARE
    recipe_id_var UUID;
BEGIN
    INSERT INTO public.recipe (creator_id, region_id, difficulty_id, title, slug, description, prep_time_min, cook_time_min, servings)
    VALUES (
        'f1414791-8f57-4bf4-a730-42f3c89dad95',
        (SELECT id FROM public.food_region WHERE name = 'RECETTES COMPLÉMENTAIRES'),
        (SELECT id FROM public.difficulty WHERE name = 'Facile'),
        'Alloco',
        'alloco',
        'Un accompagnement ou en-cas populaire en Afrique de l''Ouest, composé de bananes plantains mûres coupées en morceaux et frites jusqu''à caramélisation.',
        5, 10, 4
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Peler les bananes plantains et les couper en rondelles ou en biais.'),
    (recipe_id_var, 2, 'Faire chauffer une bonne quantité d''huile dans une poêle profonde.'),
    (recipe_id_var, 3, 'Frire les morceaux de plantain par lots jusqu''à ce qu''ils soient bien dorés et caramélisés de tous les côtés.'),
    (recipe_id_var, 4, 'Retirer avec une écumoire et égoutter sur du papier absorbant.'),
    (recipe_id_var, 5, 'Saler légèrement et servir immédiatement, souvent avec une sauce pimentée.');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Banane plantain mûre', 4, 'unité'),
        ('Huile végétale', 500, 'ml'),
        ('Sel', 1, 'pincée')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 14: Puff Puff (Complementary)
-- =================================================================
DO $$
DECLARE
    recipe_id_var UUID;
BEGIN
    INSERT INTO public.recipe (creator_id, region_id, difficulty_id, title, slug, description, prep_time_min, cook_time_min, servings)
    VALUES (
        'f1414791-8f57-4bf4-a730-42f3c89dad95',
        (SELECT id FROM public.food_region WHERE name = 'RECETTES COMPLÉMENTAIRES'),
        (SELECT id FROM public.difficulty WHERE name = 'Facile'),
        'Puff Puff',
        'puff-puff',
        'Des beignets africains incroyablement légers, moelleux et sucrés, parfaits pour le dessert, le goûter ou comme nourriture de rue.',
        75, 15, 6
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Dans un bol, mélanger la farine, le sucre, la levure, la noix de muscade et le sel.'),
    (recipe_id_var, 2, 'Ajouter progressivement l''eau tiède en mélangeant pour former une pâte lisse et collante, sans grumeaux.'),
    (recipe_id_var, 3, 'Couvrir le bol avec un linge humide et laisser la pâte lever dans un endroit chaud pendant environ 1 heure, ou jusqu''à ce qu''elle ait doublé de volume.'),
    (recipe_id_var, 4, 'Faire chauffer l''huile pour friture dans une casserole profonde.'),
    (recipe_id_var, 5, 'Avec les mains mouillées ou une cuillère, prélever des petites boules de pâte et les déposer délicatement dans l''huile chaude.'),
    (recipe_id_var, 6, 'Frire les beignets par lots, en les retournant, jusqu''à ce qu''ils soient bien dorés de tous les côtés.'),
    (recipe_id_var, 7, 'Retirer avec une écumoire et égoutter sur du papier absorbant.'),
    (recipe_id_var, 8, 'Saupoudrer de sucre glace si désiré et servir chaud.');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Farine de blé', 250, 'g'),
        ('Sucre', 50, 'g'),
        ('Levure de boulanger', 1, 'c.à.c.'),
        ('Eau', 200, 'ml'),
        ('Noix de muscade', 0.5, 'c.à.c.'),
        ('Sel', 1, 'pincée'),
        ('Huile végétale', 1, 'l')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

COMMIT;

-- End of migration file