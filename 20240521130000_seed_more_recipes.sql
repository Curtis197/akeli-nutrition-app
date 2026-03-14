-- supabase/migrations/YYYYMMDDHHMMSS_seed_more_recipes.sql
--
-- This migration file seeds the database with a second batch of African recipes.
--
-- Note on table names: This script uses the correct spelling "recipe". If your schema
-- has the typo "receipe", you will need to find and replace "recipe" with "receipe"
-- throughout this file.

BEGIN;

--
-- 1. Seed MORE Master Ingredients
-- Add new ingredients needed for this batch. Idempotent using ON CONFLICT DO NOTHING.
--
INSERT INTO public.ingredient (name) VALUES
('Graines d''egusi'),
('Huile de palme'),
('Écrevisses séchées'),
('Igname'),
('Haricots (niébé)'),
('Banane plantain non mûre'),
('Feuilles de sorgho'),
('Épinards'),
('Poudre de Kankan (Suya)'),
('Arachides grillées'),
('Semoule de manioc (Attiéké)'),
('Thon à l''huile'),
('Feuilles de ndolé'),
('Viande de chèvre'),
('Épices pour Pilau'),
('Chou frisé (Sukuma)'),
('Bananes vertes (Matoke)'),
('Pois chiches en poudre (Shiro)'),
('Lait de coco'),
('Cardamome')
ON CONFLICT (name) DO NOTHING;

--
-- 2. Seed More Recipes
-- Each recipe is added in a block with its steps and ingredients.
--

-- =================================================================
-- Recipe 15: Egusi Soup (West Africa)
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
        'Soupe Egusi',
        'soupe-egusi',
        'Une soupe nigériane riche et copieuse, préparée avec des graines de melon moulues (egusi) et diverses viandes et légumes-feuilles.',
        25, 60, 6
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Moudre les graines d''egusi jusqu''à obtenir une poudre fine. Mélanger avec un peu d''eau pour former une pâte épaisse.'),
    (recipe_id_var, 2, 'Faire cuire le bœuf dans de l''eau salée jusqu''à ce qu''il soit tendre. Conserver le bouillon.'),
    (recipe_id_var, 3, 'Dans une autre marmite, chauffer l''huile de palme. Ajouter l''oignon haché et faire revenir.'),
    (recipe_id_var, 4, 'Ajouter la pâte d''egusi par cuillerées et faire frire en remuant jusqu''à ce qu''elle forme de petits morceaux brouillés.'),
    (recipe_id_var, 5, 'Verser le bouillon de bœuf, la viande cuite, le poisson fumé, les écrevisses séchées et le piment. Porter à ébullition.'),
    (recipe_id_var, 6, 'Réduire le feu et laisser mijoter pendant 20 minutes, en remuant de temps en temps.'),
    (recipe_id_var, 7, 'Ajouter les épinards hachés et cuire encore 5-10 minutes.'),
    (recipe_id_var, 8, 'Saler et poivrer au goût. Servir chaud avec de l''igname pilée ou du Gari.');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Graines d''egusi', 200, 'g'),
        ('Bœuf', 500, 'g'),
        ('Poisson fumé', 1, 'unité'),
        ('Épinards', 500, 'g'),
        ('Huile de palme', 150, 'ml'),
        ('Oignon', 1, 'unité'),
        ('Piment', 2, 'unité'),
        ('Écrevisses séchées', 50, 'g'),
        ('Sel', 1, 'pincée'),
        ('Poivre', 1, 'pincée')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 16: Pounded Yam (West Africa)
-- =================================================================
DO $$
DECLARE
    recipe_id_var UUID;
BEGIN
    INSERT INTO public.recipe (creator_id, region_id, difficulty_id, title, slug, description, prep_time_min, cook_time_min, servings)
    VALUES (
        'f1414791-8f57-4bf4-a730-42f3c89dad95',
        (SELECT id FROM public.food_region WHERE name = 'RECETTES COMPLÉMENTAIRES'),
        (SELECT id FROM public.difficulty WHERE name = 'Moyen'),
        'Igname Pilée (Pounded Yam)',
        'igname-pilee-pounded-yam',
        'Un "swallow" classique en Afrique de l''Ouest, une pâte lisse et élastique faite d''ignames bouillies et pilées, parfaite pour accompagner les soupes.',
        10, 25, 4
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Peler les ignames, les laver et les couper en morceaux de taille égale.'),
    (recipe_id_var, 2, 'Mettre les morceaux d''igname dans une casserole et couvrir d''eau. Porter à ébullition.'),
    (recipe_id_var, 3, 'Cuire pendant 15-20 minutes ou jusqu''à ce que les ignames soient très tendres (une fourchette doit y entrer facilement).'),
    (recipe_id_var, 4, 'Égoutter les ignames.'),
    (recipe_id_var, 5, 'Transférer les ignames chaudes dans un grand mortier.'),
    (recipe_id_var, 6, 'Piler vigoureusement avec un pilon, en tournant et en ajoutant un peu d''eau chaude si nécessaire, jusqu''à obtenir une pâte lisse et sans grumeaux.'),
    (recipe_id_var, 7, 'Former des boules et servir immédiatement avec votre soupe préférée (comme la soupe Egusi).');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Igname', 1, 'kg'),
        ('Eau', 1, 'l')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 17: Red Red (West Africa)
-- =================================================================
DO $$
DECLARE
    recipe_id_var UUID;
BEGIN
    INSERT INTO public.recipe (creator_id, region_id, difficulty_id, title, slug, description, prep_time_min, cook_time_min, servings)
    VALUES (
        'f1414791-8f57-4bf4-a730-42f3c89dad95',
        (SELECT id FROM public.food_region WHERE name = 'AFRIQUE DE L''OUEST'),
        (SELECT id FROM public.difficulty WHERE name = 'Facile'),
        'Red Red',
        'red-red',
        'Un plat ghanéen végétarien populaire, composé d''un ragoût de haricots à l''huile de palme, servi avec des bananes plantains frites.',
        15, 45, 4
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Faire chauffer l''huile de palme dans une casserole. Ajouter l''oignon émincé et faire revenir.'),
    (recipe_id_var, 2, 'Ajouter l''ail, le gingembre et le piment. Cuire 1 minute.'),
    (recipe_id_var, 3, 'Incorporer les tomates en dés et le concentré de tomate. Laisser mijoter 10 minutes.'),
    (recipe_id_var, 4, 'Ajouter les haricots (niébé) cuits et un peu d''eau. Saler et poivrer. Laisser mijoter 15-20 minutes.'),
    (recipe_id_var, 5, 'Pendant ce temps, peler et couper les bananes plantains en rondelles.'),
    (recipe_id_var, 6, 'Faire frire les plantains dans de l''huile végétale jusqu''à ce qu''elles soient dorées. Égoutter sur du papier absorbant.'),
    (recipe_id_var, 7, 'Servir le ragoût de haricots chaud, garni de bananes plantains frites.');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Haricots (niébé)', 500, 'g'),
        ('Banane plantain mûre', 3, 'unité'),
        ('Huile de palme', 100, 'ml'),
        ('Tomate', 3, 'unité'),
        ('Oignon', 1, 'unité'),
        ('Ail', 2, 'gousse'),
        ('Gingembre', 1, 'c.à.c.'),
        ('Piment', 1, 'unité'),
        ('Concentré de tomate', 1, 'c.à.s.'),
        ('Sel', 1, 'pincée')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 18: Suya (West Africa)
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
        'Suya',
        'suya',
        'Des brochettes de viande de bœuf finement tranchée, généreusement enrobées d''un mélange d''épices aux arachides (Kankan), puis grillées à la perfection.',
        120, 15, 4
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Couper le bœuf en tranches très fines.'),
    (recipe_id_var, 2, 'Dans un bol, mélanger la poudre de Kankan (Suya) avec un peu d''huile pour former une pâte.'),
    (recipe_id_var, 3, 'Enrober généreusement chaque tranche de bœuf avec la pâte d''épices.'),
    (recipe_id_var, 4, 'Enfiler la viande sur des brochettes en bois (préalablement trempées dans l''eau).'),
    (recipe_id_var, 5, 'Laisser mariner au moins 2 heures.'),
    (recipe_id_var, 6, 'Préchauffer un gril ou un barbecue à feu vif.'),
    (recipe_id_var, 7, 'Griller les brochettes quelques minutes de chaque côté, jusqu''à ce que la viande soit cuite mais encore juteuse.'),
    (recipe_id_var, 8, 'Servir immédiatement avec des tranches d''oignon frais et de tomate.');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Bœuf', 500, 'g'),
        ('Poudre de Kankan (Suya)', 100, 'g'),
        ('Huile végétale', 50, 'ml'),
        ('Sel', 1, 'pincée'),
        ('Oignon', 1, 'unité'),
        ('Tomate', 1, 'unité')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 19: Attiéké & Poisson Grillé (West Africa)
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
        'Attiéké & Poisson Grillé',
        'attieke-poisson-grille',
        'Un plat phare de la Côte d''Ivoire, associant de la semoule de manioc fermentée (Attiéké) à du poisson entier mariné et grillé.',
        30, 30, 4
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Nettoyer et écailler le poisson. Faire des incisions sur les côtés.'),
    (recipe_id_var, 2, 'Préparer la marinade: mixer l''oignon, l''ail, le gingembre, le persil, le piment et le cube de bouillon avec un peu d''huile.'),
    (recipe_id_var, 3, 'Frotter le poisson avec la marinade, en insistant dans les incisions. Laisser mariner 30 minutes.'),
    (recipe_id_var, 4, 'Griller le poisson au barbecue ou au four jusqu''à ce qu''il soit bien cuit et doré.'),
    (recipe_id_var, 5, 'Pendant ce temps, réchauffer l''attiéké à la vapeur ou au micro-ondes. Égrener avec une fourchette et un filet d''huile.'),
    (recipe_id_var, 6, 'Servir le poisson grillé sur un lit d''attiéké, accompagné d''une salade de tomates, oignons et concombres.'),
    (recipe_id_var, 7, 'Accompagner de sauces pimentées et de mayonnaise.');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Poisson (Thiof ou Capitaine)', 1, 'unité'),
        ('Semoule de manioc (Attiéké)', 500, 'g'),
        ('Oignon', 2, 'unité'),
        ('Ail', 3, 'gousse'),
        ('Gingembre', 1, 'c.à.c.'),
        ('Persil', 0.5, 'botte'),
        ('Piment', 1, 'unité'),
        ('Huile végétale', 100, 'ml'),
        ('Bouillon de poulet', 1, 'unité'),
        ('Tomate', 2, 'unité')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 20: Kedjenou (West Africa)
-- =================================================================
DO $$
DECLARE
    recipe_id_var UUID;
BEGIN
    INSERT INTO public.recipe (creator_id, region_id, difficulty_id, title, slug, description, prep_time_min, cook_time_min, servings)
    VALUES (
        'f1414791-8f57-4bf4-a730-42f3c89dad95',
        (SELECT id FROM public.food_region WHERE name = 'AFRIQUE DE L''OUEST'),
        (SELECT id FROM public.difficulty WHERE name = 'Facile'),
        'Kedjenou de Poulet',
        'kedjenou-de-poulet',
        'Un ragoût ivoirien où le poulet et les légumes sont cuits à l''étouffée dans leur propre jus, sans ajout d''eau, pour une saveur concentrée.',
        15, 60, 4
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Couper le poulet en morceaux. Hacher grossièrement les oignons, les tomates et l''ail.'),
    (recipe_id_var, 2, 'Dans une marmite hermétique (canari ou cocotte), déposer une couche d''oignons.'),
    (recipe_id_var, 3, 'Ajouter les morceaux de poulet, les tomates, l''ail, le gingembre, le thym et les feuilles de laurier.'),
    (recipe_id_var, 4, 'Saler, poivrer et ajouter le piment entier.'),
    (recipe_id_var, 5, 'Couvrir hermétiquement la marmite. Ne pas ajouter d''eau.'),
    (recipe_id_var, 6, 'Cuire à feu très doux pendant environ 1 heure. Secouer la marmite de temps en temps pour éviter que ça n''attache, sans l''ouvrir.'),
    (recipe_id_var, 7, 'Le poulet et les légumes vont rendre leur eau et cuire à l''étouffée. Servir chaud avec de l''attiéké ou du riz.');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Poulet', 1, 'kg'),
        ('Oignon', 3, 'unité'),
        ('Tomate', 4, 'unité'),
        ('Ail', 3, 'gousse'),
        ('Gingembre', 1, 'c.à.s.'),
        ('Thym', 1, 'branche'),
        ('Feuille de laurier', 2, 'feuille'),
        ('Piment', 1, 'unité'),
        ('Sel', 1, 'pincée'),
        ('Poivre', 1, 'pincée')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 21: Ndolé (Central Africa)
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
        'Ndolé',
        'ndole',
        'Plat national du Cameroun, un ragoût onctueux de feuilles amères (ndolé) cuites avec des arachides, de la viande et/ou des crevettes.',
        30, 90, 6
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Laver plusieurs fois les feuilles de ndolé pour en réduire l''amertume. Les faire bouillir 20 minutes puis égoutter.'),
    (recipe_id_var, 2, 'Faire cuire la viande de bœuf jusqu''à ce qu''elle soit tendre. Réserver le bouillon.'),
    (recipe_id_var, 3, 'Mixer les arachides grillées avec l''oignon et l''ail pour obtenir une pâte lisse.'),
    (recipe_id_var, 4, 'Dans une grande marmite, mélanger la pâte d''arachide avec le bouillon de viande. Porter à ébullition et laisser épaissir 15 minutes.'),
    (recipe_id_var, 5, 'Ajouter les feuilles de ndolé, la viande, les écrevisses et le piment.'),
    (recipe_id_var, 6, 'Verser l''huile végétale, saler, poivrer et laisser mijoter à feu doux pendant 30-40 minutes.'),
    (recipe_id_var, 7, 'Servir chaud avec des bananes plantains frites, du riz ou du manioc.');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Feuilles de ndolé', 1, 'kg'),
        ('Arachides grillées', 300, 'g'),
        ('Bœuf', 500, 'g'),
        ('Écrevisses séchées', 100, 'g'),
        ('Oignon', 2, 'unité'),
        ('Ail', 3, 'gousse'),
        ('Huile végétale', 150, 'ml'),
        ('Piment', 1, 'unité'),
        ('Sel', 1, 'pincée')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 22: Nyama Choma (East Africa)
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
        'Nyama Choma',
        'nyama-choma',
        'Un plat social emblématique au Kenya, signifiant "viande grillée" en swahili. Il s''agit généralement de viande de chèvre lentement rôtie au charbon de bois.',
        10, 60, 6
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Couper la viande de chèvre en gros morceaux (côtes, épaule, etc.).'),
    (recipe_id_var, 2, 'Saler généreusement la viande sur toutes ses faces.'),
    (recipe_id_var, 3, 'Préparer un barbecue au charbon de bois à chaleur moyenne.'),
    (recipe_id_var, 4, 'Placer la viande sur la grille et la faire rôtir lentement, en la retournant régulièrement.'),
    (recipe_id_var, 5, 'La cuisson peut prendre de 45 minutes à plus d''une heure, selon la taille des morceaux. La viande doit être bien cuite mais rester juteuse.'),
    (recipe_id_var, 6, 'Une fois cuite, retirer la viande du gril et la laisser reposer quelques minutes.'),
    (recipe_id_var, 7, 'Couper la viande en petits morceaux sur une planche à découper en bois.'),
    (recipe_id_var, 8, 'Servir immédiatement avec du sel, du piment, et des accompagnements comme l''ugali et le kachumbari (salade de tomates et oignons).');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Viande de chèvre', 2, 'kg'),
        ('Sel', 2, 'c.à.s.')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 23: Pilau (East Africa)
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
        'Pilau',
        'pilau',
        'Un plat de riz parfumé de la côte swahilie, cuit dans un bouillon riche en épices entières comme la cannelle, la cardamome et les clous de girofle.',
        15, 45, 6
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Faire revenir l''oignon émincé dans l''huile jusqu''à ce qu''il soit bien caramélisé.'),
    (recipe_id_var, 2, 'Ajouter l''ail, le gingembre et les épices pour Pilau (ou les épices entières). Faire revenir 1 minute.'),
    (recipe_id_var, 3, 'Ajouter les morceaux de bœuf et les faire dorer.'),
    (recipe_id_var, 4, 'Ajouter les tomates et cuire jusqu''à ce qu''elles se décomposent.'),
    (recipe_id_var, 5, 'Ajouter l''eau ou le bouillon et porter à ébullition. Laisser mijoter jusqu''à ce que le bœuf soit tendre.'),
    (recipe_id_var, 6, 'Laver le riz et l''ajouter à la marmite. Saler.'),
    (recipe_id_var, 7, 'Cuire à feu moyen jusqu''à ce que le liquide soit presque absorbé.'),
    (recipe_id_var, 8, 'Réduire le feu au minimum, couvrir hermétiquement et laisser cuire à la vapeur pendant 15-20 minutes.'),
    (recipe_id_var, 9, 'Égrener avec une fourchette avant de servir.');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Riz long grain', 500, 'g'),
        ('Bœuf', 400, 'g'),
        ('Oignon', 2, 'unité'),
        ('Ail', 3, 'gousse'),
        ('Gingembre', 1, 'c.à.s.'),
        ('Épices pour Pilau', 2, 'c.à.s.'),
        ('Tomate', 2, 'unité'),
        ('Huile végétale', 50, 'ml'),
        ('Eau', 1, 'l'),
        ('Sel', 1, 'pincée')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 24: Sukuma Wiki (East Africa)
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
        'Sukuma Wiki',
        'sukuma-wiki',
        'Un accompagnement simple et nutritif du Kenya, signifiant "pousser la semaine". Il s''agit de chou frisé sauté avec des oignons et des tomates.',
        10, 15, 4
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Laver le chou frisé et le hacher finement.'),
    (recipe_id_var, 2, 'Faire chauffer l''huile dans une poêle. Ajouter l''oignon émincé et faire revenir jusqu''à ce qu''il soit translucide.'),
    (recipe_id_var, 3, 'Ajouter les tomates en dés et cuire jusqu''à ce qu''elles ramollissent.'),
    (recipe_id_var, 4, 'Ajouter le chou frisé haché et bien mélanger.'),
    (recipe_id_var, 5, 'Saler et ajouter le cube de bouillon si utilisé. Cuire pendant 5-10 minutes, jusqu''à ce que le chou soit tendre mais encore croquant.'),
    (recipe_id_var, 6, 'Servir immédiatement comme accompagnement, traditionnellement avec de l''Ugali.');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Chou frisé (Sukuma)', 1, 'botte'),
        ('Oignon', 1, 'unité'),
        ('Tomate', 2, 'unité'),
        ('Huile végétale', 2, 'c.à.s.'),
        ('Sel', 1, 'pincée'),
        ('Bouillon de poulet', 0.5, 'unité')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 25: Matoke (East Africa)
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
        'Matoke',
        'matoke',
        'Un plat de base ougandais fait de bananes vertes (matoke) cuites à la vapeur et écrasées, souvent servies en ragoût avec de la viande ou des arachides.',
        20, 40, 4
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Peler les bananes vertes sous l''eau pour éviter de tacher les mains. Les laisser entières.'),
    (recipe_id_var, 2, 'Faire revenir l''oignon dans l''huile. Ajouter l''ail et le bœuf, et faire dorer.'),
    (recipe_id_var, 3, 'Ajouter les tomates, le poivron et le curry. Cuire 5 minutes.'),
    (recipe_id_var, 4, 'Déposer les bananes vertes sur le mélange de viande.'),
    (recipe_id_var, 5, 'Ajouter le bouillon de bœuf, juste assez pour couvrir à moitié les bananes.'),
    (recipe_id_var, 6, 'Saler et poivrer. Porter à ébullition, puis réduire le feu.'),
    (recipe_id_var, 7, 'Couvrir et laisser mijoter 20-30 minutes, jusqu''à ce que les bananes soient très tendres.'),
    (recipe_id_var, 8, 'Écraser légèrement quelques bananes pour épaissir la sauce. Servir chaud.');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Bananes vertes (Matoke)', 10, 'unité'),
        ('Bœuf', 500, 'g'),
        ('Oignon', 1, 'unité'),
        ('Tomate', 3, 'unité'),
        ('Poivron vert', 1, 'unité'),
        ('Ail', 2, 'gousse'),
        ('Curry en poudre', 1, 'c.à.s.'),
        ('Bouillon de bœuf', 500, 'ml'),
        ('Huile végétale', 3, 'c.à.s.')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 26: Shiro Wat (East Africa)
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
        'Shiro Wat',
        'shiro-wat',
        'Un ragoût végétalien éthiopien essentiel, crémeux et savoureux, à base de poudre de pois chiches ou de fèves (shiro) et d''épices berbéré.',
        5, 30, 4
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Faire revenir l''oignon et l''ail hachés dans l''huile jusqu''à ce qu''ils soient tendres.'),
    (recipe_id_var, 2, 'Ajouter le berbéré et cuire 1 minute en remuant.'),
    (recipe_id_var, 3, 'Dans un bol, délayer la poudre de shiro avec de l''eau froide pour former une pâte lisse.'),
    (recipe_id_var, 4, 'Verser progressivement le mélange de shiro dans la marmite en fouettant constamment pour éviter les grumeaux.'),
    (recipe_id_var, 5, 'Ajouter le reste de l''eau, porter à frémissement.'),
    (recipe_id_var, 6, 'Réduire le feu et laisser mijoter doucement pendant 15-20 minutes, jusqu''à ce que le ragoût épaississe et que le goût de farine crue ait disparu.'),
    (recipe_id_var, 7, 'Incorporer une touche de beurre clarifié (optionnel) à la fin. Servir chaud avec de l''injera.');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Pois chiches en poudre (Shiro)', 150, 'g'),
        ('Oignon', 1, 'unité'),
        ('Ail', 3, 'gousse'),
        ('Poudre de Berbéré', 2, 'c.à.s.'),
        ('Huile végétale', 3, 'c.à.s.'),
        ('Eau', 750, 'ml'),
        ('Sel', 1, 'pincée')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 27: Mandazi (East Africa)
-- =================================================================
DO $$
DECLARE
    recipe_id_var UUID;
BEGIN
    INSERT INTO public.recipe (creator_id, region_id, difficulty_id, title, slug, description, prep_time_min, cook_time_min, servings)
    VALUES (
        'f1414791-8f57-4bf4-a730-42f3c89dad95',
        (SELECT id FROM public.food_region WHERE name = 'RECETTES COMPLÉMENTAIRES'),
        (SELECT id FROM public.difficulty WHERE name = 'Moyen'),
        'Mandazi',
        'mandazi',
        'Des beignets d''Afrique de l''Est légèrement sucrés, souvent parfumés à la cardamome et au lait de coco, parfaits pour le petit-déjeuner ou le goûter.',
        90, 15, 8
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Dans un grand bol, mélanger la farine, le sucre, la levure et la cardamome moulue.'),
    (recipe_id_var, 2, 'Dans un autre bol, mélanger le lait de coco tiède, l''œuf battu et le beurre fondu.'),
    (recipe_id_var, 3, 'Verser le mélange liquide dans les ingrédients secs et pétrir jusqu''à obtenir une pâte lisse et souple.'),
    (recipe_id_var, 4, 'Couvrir la pâte et la laisser lever dans un endroit chaud pendant 1 à 1h30, jusqu''à ce qu''elle double de volume.'),
    (recipe_id_var, 5, 'Dégazer la pâte et l''étaler sur une surface farinée sur une épaisseur d''environ 1 cm.'),
    (recipe_id_var, 6, 'Couper la pâte en triangles ou en carrés.'),
    (recipe_id_var, 7, 'Faire chauffer l''huile de friture. Frire les mandazi par lots jusqu''à ce qu''ils soient dorés et gonflés des deux côtés.'),
    (recipe_id_var, 8, 'Égoutter sur du papier absorbant et servir chaud, saupoudré de sucre glace si désiré.');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Farine de blé', 500, 'g'),
        ('Lait de coco', 250, 'ml'),
        ('Sucre', 100, 'g'),
        ('Levure de boulanger', 2, 'c.à.c.'),
        ('Cardamome', 1, 'c.à.c.'),
        ('Oeuf', 1, 'unité'),
        ('Huile végétale', 1, 'l')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

COMMIT;

-- End of migration file