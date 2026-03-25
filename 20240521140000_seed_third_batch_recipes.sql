-- supabase/migrations/YYYYMMDDHHMMSS_seed_third_batch_recipes.sql
--
-- This migration file seeds the database with a third batch of African recipes.
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
('Feuilles de brick'), ('Lentilles corail'), ('Clou de girofle'), ('Graines de moutarde'),
('Raisins secs'), ('Safran'),
('Mitmita'), ('Kororima'),
('Maïs en grains'),
('Ghee'),
('Semoule de couscous'), ('Saucisse Merguez'), ('Pois chiches'), ('Courgette'),
('Macaroni'), ('Lentilles brunes'), ('Vinaigre de vin blanc'),
('Pigeon'), ('Sucre glace'), ('Eau de fleur d''oranger'),
('Lentilles vertes'), ('Vermicelles'),
('Fèves'), ('Tahini'),
('Thon en conserve'), ('Câpres'),
('Haricots blancs en conserve'), ('Poivron jaune')
ON CONFLICT (name) DO NOTHING;

--
-- 2. Seed More Recipes
-- Each recipe is added in a block with its steps and ingredients.
--

-- =================================================================
-- Recipe 28: Samosas (East Africa)
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
        'Samosas à la Viande',
        'samosas-a-la-viande',
        'Des triangles de pâte croustillants et frits, farcis d''un mélange savoureux de viande hachée épicée, un en-cas populaire sur la côte swahilie.',
        40, 20, 12
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Faire revenir l''oignon haché dans l''huile. Ajouter l''ail et le gingembre, puis la viande hachée. Cuire jusqu''à ce qu''elle soit dorée.'),
    (recipe_id_var, 2, 'Ajouter le curry, le cumin, la coriandre, le sel et le poivre. Bien mélanger.'),
    (recipe_id_var, 3, 'Incorporer le persil ou la coriandre fraîche hachée. Laisser refroidir la farce.'),
    (recipe_id_var, 4, 'Couper les feuilles de brick en deux. Plier chaque moitié pour former un cornet.'),
    (recipe_id_var, 5, 'Remplir le cornet avec la farce à la viande.'),
    (recipe_id_var, 6, 'Replier la feuille de brick pour former un triangle, en scellant le bord avec un peu d''eau ou un mélange farine-eau.'),
    (recipe_id_var, 7, 'Faire frire les samosas dans l''huile chaude jusqu''à ce qu''ils soient dorés et croustillants.'),
    (recipe_id_var, 8, 'Égoutter sur du papier absorbant et servir chaud.');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Viande hachée', 300, 'g'),
        ('Feuilles de brick', 6, 'feuille'),
        ('Oignon', 1, 'unité'),
        ('Ail', 2, 'gousse'),
        ('Gingembre', 1, 'c.à.c.'),
        ('Curry en poudre', 1, 'c.à.s.'),
        ('Cumin', 1, 'c.à.c.'),
        ('Coriandre', 1, 'botte'),
        ('Huile végétale', 1, 'l'),
        ('Sel', 1, 'pincée'),
        ('Poivre', 1, 'pincée')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 29: Bariis Iskukaris (Somalia)
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
        'Bariis Iskukaris',
        'bariis-iskukaris',
        'Un plat de riz somalien parfumé et coloré, cuit avec un mélange d''épices (xawaash), des légumes et souvent de la viande, servi traditionnellement avec une banane.',
        20, 50, 6
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Faire dorer les morceaux d''agneau dans l''huile. Ajouter l''oignon et l''ail et faire revenir.'),
    (recipe_id_var, 2, 'Ajouter les épices (xawaash/pilau), le concentré de tomate et les tomates. Cuire 5 minutes.'),
    (recipe_id_var, 3, 'Ajouter l''eau et porter à ébullition. Laisser mijoter jusqu''à ce que la viande soit tendre.'),
    (recipe_id_var, 4, 'Ajouter les carottes et les pommes de terre en dés.'),
    (recipe_id_var, 5, 'Laver le riz et l''ajouter à la marmite. Saler.'),
    (recipe_id_var, 6, 'Cuire à feu moyen jusqu''à ce que le liquide soit presque absorbé.'),
    (recipe_id_var, 7, 'Ajouter les raisins secs. Couvrir hermétiquement et laisser cuire à la vapeur à feu très doux pendant 15-20 minutes.'),
    (recipe_id_var, 8, 'Servir le riz garni de persil frais, avec une banane entière à côté.');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Riz long grain', 500, 'g'),
        ('Agneau', 500, 'g'),
        ('Oignon', 1, 'unité'),
        ('Ail', 3, 'gousse'),
        ('Carotte', 2, 'unité'),
        ('Pomme de terre', 2, 'unité'),
        ('Épices pour Pilau', 2, 'c.à.s.'),
        ('Tomate', 2, 'unité'),
        ('Concentré de tomate', 1, 'c.à.s.'),
        ('Raisins secs', 50, 'g'),
        ('Huile végétale', 50, 'ml'),
        ('Sel', 1, 'pincée')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 30: Kitfo (Ethiopia)
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
        'Kitfo',
        'kitfo',
        'Un plat éthiopien très apprécié, composé de bœuf haché cru mariné dans du beurre clarifié épicé (niter kibbeh) et de la poudre de piment mitmita.',
        15, 5, 4
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Hacher très finement le bœuf (sans gras) au couteau pour obtenir une texture de tartare.'),
    (recipe_id_var, 2, 'Dans une poêle, faire fondre doucement le niter kibbeh (beurre clarifié épicé). Ne pas le faire bouillir.'),
    (recipe_id_var, 3, 'Retirer la poêle du feu. Ajouter le mitmita et la kororima au beurre chaud.'),
    (recipe_id_var, 4, 'Verser le bœuf haché dans le beurre épicé et mélanger rapidement et soigneusement.'),
    (recipe_id_var, 5, 'Le plat est traditionnellement servi cru ("tere") ou très légèrement chauffé ("lebleb"). Pour la version "lebleb", remettre sur feu très doux 30 secondes.'),
    (recipe_id_var, 6, 'Saler au goût.'),
    (recipe_id_var, 7, 'Servir immédiatement avec du fromage frais éthiopien (ayib) et des épinards pour équilibrer le piquant, accompagné d''injera.');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Bœuf', 500, 'g'),
        ('Beurre clarifié (Niter Kibbeh)', 4, 'c.à.s.'),
        ('Mitmita', 2, 'c.à.s.'),
        ('Kororima', 1, 'c.à.c.'),
        ('Sel', 1, 'pincée')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 31: Githeri (Kenya)
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
        'Githeri',
        'githeri',
        'Un plat kényan simple et nutritif, composé d''un mélange de maïs et de haricots bouillis, souvent enrichi d''oignons et de tomates.',
        10, 60, 6
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Faire bouillir le maïs et les haricots dans de l''eau salée jusqu''à ce qu''ils soient tendres. Égoutter.'),
    (recipe_id_var, 2, 'Dans une autre casserole, faire revenir l''oignon dans l''huile jusqu''à ce qu''il soit translucide.'),
    (recipe_id_var, 3, 'Ajouter l''ail, les tomates en dés et le curry en poudre. Cuire jusqu''à obtenir une sauce épaisse.'),
    (recipe_id_var, 4, 'Ajouter le mélange de maïs et de haricots cuits à la sauce.'),
    (recipe_id_var, 5, 'Incorporer les pommes de terre en dés et un peu d''eau ou de bouillon.'),
    (recipe_id_var, 6, 'Laisser mijoter 15-20 minutes, jusqu''à ce que les pommes de terre soient cuites et la sauce bien mélangée.'),
    (recipe_id_var, 7, 'Ajouter la coriandre fraîche hachée avant de servir.');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Maïs en grains', 400, 'g'),
        ('Haricots (niébé)', 400, 'g'),
        ('Oignon', 1, 'unité'),
        ('Tomate', 3, 'unité'),
        ('Pomme de terre', 2, 'unité'),
        ('Ail', 2, 'gousse'),
        ('Curry en poudre', 1, 'c.à.c.'),
        ('Coriandre', 1, 'botte'),
        ('Huile végétale', 3, 'c.à.s.'),
        ('Sel', 1, 'pincée')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 32: Misir Wat (Ethiopia)
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
        'Misir Wat',
        'misir-wat',
        'Un ragoût de lentilles corail éthiopien végétalien, richement épicé avec du berbéré, de l''ail et du gingembre. Un pilier de la cuisine éthiopienne.',
        10, 40, 4
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Faire revenir l''oignon haché dans l''huile jusqu''à ce qu''il soit bien doré.'),
    (recipe_id_var, 2, 'Ajouter l''ail, le gingembre et la poudre de berbéré. Cuire 2 minutes en remuant.'),
    (recipe_id_var, 3, 'Ajouter le concentré de tomate et cuire encore 2 minutes.'),
    (recipe_id_var, 4, 'Rincer les lentilles corail à l''eau froide.'),
    (recipe_id_var, 5, 'Ajouter les lentilles rincées et l''eau dans la casserole. Porter à ébullition.'),
    (recipe_id_var, 6, 'Réduire le feu, couvrir et laisser mijoter pendant 25-30 minutes, jusqu''à ce que les lentilles soient tendres et que le ragoût ait épaissi.'),
    (recipe_id_var, 7, 'Saler au goût. Servir chaud avec de l''injera.');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Lentilles corail', 250, 'g'),
        ('Oignon', 1, 'unité'),
        ('Ail', 3, 'gousse'),
        ('Gingembre', 1, 'c.à.s.'),
        ('Poudre de Berbéré', 3, 'c.à.s.'),
        ('Concentré de tomate', 1, 'c.à.s.'),
        ('Huile végétale', 50, 'ml'),
        ('Eau', 1, 'l'),
        ('Sel', 1, 'pincée')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 33: Chapati (East Africa)
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
        'Chapati',
        'chapati',
        'Un pain plat, souple et feuilleté, d''influence indienne, très populaire en Afrique de l''Est. Parfait pour saucer les ragoûts.',
        30, 20, 8
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Dans un bol, mélanger la farine et le sel. Ajouter l''eau chaude petit à petit et pétrir pour former une pâte souple.'),
    (recipe_id_var, 2, 'Pétrir la pâte sur un plan de travail fariné pendant 5-10 minutes. Couvrir et laisser reposer 20 minutes.'),
    (recipe_id_var, 3, 'Diviser la pâte en 8 boules égales.'),
    (recipe_id_var, 4, 'Étaler une boule en un cercle fin. Badigeonner d''huile ou de ghee fondu.'),
    (recipe_id_var, 5, 'Rouler le cercle sur lui-même pour former un "cigare". Enrouler ce cigare en spirale pour former un "escargot".'),
    (recipe_id_var, 6, 'Aplatir l''escargot et l''étaler à nouveau en un cercle fin.'),
    (recipe_id_var, 7, 'Faire cuire le chapati dans une poêle chaude et sèche pendant environ 1 minute de chaque côté, jusqu''à l''apparition de taches brunes.'),
    (recipe_id_var, 8, 'Badigeonner légèrement d''huile pendant la cuisson. Garder les chapatis au chaud dans un linge propre.');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Farine de blé', 500, 'g'),
        ('Eau', 300, 'ml'),
        ('Sel', 1, 'c.à.c.'),
        ('Huile végétale', 50, 'ml')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 34: Rolex (Uganda)
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
        'Rolex Ougandais',
        'rolex-ougandais',
        'Un plat de rue populaire en Ouganda, consistant en une omelette aux légumes enroulée dans un chapati chaud. Le nom est un jeu de mots sur "rolled eggs".',
        5, 10, 1
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Dans un bol, battre les œufs avec le sel et le poivre.'),
    (recipe_id_var, 2, 'Ajouter l''oignon, la tomate et le chou finement hachés aux œufs battus.'),
    (recipe_id_var, 3, 'Faire chauffer un peu d''huile dans une poêle.'),
    (recipe_id_var, 4, 'Verser le mélange d''œufs dans la poêle et cuire comme une omelette fine.'),
    (recipe_id_var, 5, 'Pendant que l''omelette cuit, réchauffer le chapati.'),
    (recipe_id_var, 6, 'Placer l''omelette cuite sur le chapati chaud.'),
    (recipe_id_var, 7, 'Rouler fermement le chapati autour de l''omelette.'),
    (recipe_id_var, 8, 'Servir immédiatement, tel quel ou coupé en deux.');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Chapati', 1, 'unité'),
        ('Oeuf', 2, 'unité'),
        ('Oignon', 0.25, 'unité'),
        ('Tomate', 0.5, 'unité'),
        ('Chou blanc', 50, 'g'),
        ('Huile végétale', 1, 'c.à.s.'),
        ('Sel', 1, 'pincée'),
        ('Poivre', 1, 'pincée')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 35: Couscous Royal (North Africa)
-- =================================================================
DO $$
DECLARE
    recipe_id_var UUID;
BEGIN
    INSERT INTO public.recipe (creator_id, region_id, difficulty_id, title, slug, description, prep_time_min, cook_time_min, servings)
    VALUES (
        'f1414791-8f57-4bf4-a730-42f3c89dad95',
        (SELECT id FROM public.food_region WHERE name = 'AFRIQUE DU NORD'),
        (SELECT id FROM public.difficulty WHERE name = 'Difficile'),
        'Couscous Royal',
        'couscous-royal',
        'Un plat de fête somptueux du Maghreb, composé de semoule de couscous fine, d''un bouillon de légumes parfumé et d''un assortiment de plusieurs viandes.',
        45, 120, 8
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Dans un grand faitout, faire dorer les morceaux d''agneau et de poulet dans l''huile. Ajouter l''oignon et l''ail.'),
    (recipe_id_var, 2, 'Ajouter les tomates, le concentré de tomate, les épices (ras el hanout, curcuma, gingembre), sel et poivre. Couvrir d''eau et porter à ébullition.'),
    (recipe_id_var, 3, 'Ajouter les carottes, navets et pois chiches. Laisser mijoter 1h30.'),
    (recipe_id_var, 4, 'Ajouter les courgettes 20 minutes avant la fin de la cuisson.'),
    (recipe_id_var, 5, 'Pendant ce temps, préparer la semoule selon les instructions du paquet, traditionnellement en la cuisant à la vapeur au-dessus du bouillon.'),
    (recipe_id_var, 6, 'Griller les merguez à la poêle ou au barbecue.'),
    (recipe_id_var, 7, 'Servir la semoule dans un grand plat, creuser un puits au centre, y verser les légumes et le bouillon. Disposer les viandes par-dessus. Servir avec de la harissa.');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Semoule de couscous', 1, 'kg'),
        ('Agneau', 500, 'g'),
        ('Poulet', 500, 'g'),
        ('Saucisse Merguez', 8, 'unité'),
        ('Oignon', 2, 'unité'),
        ('Carotte', 4, 'unité'),
        ('Courgette', 3, 'unité'),
        ('Navet', 2, 'unité'),
        ('Pois chiches', 1, 'boîte'),
        ('Tomates pelées', 1, 'boîte'),
        ('Ras el hanout', 2, 'c.à.s.'),
        ('Harissa', 1, 'c.à.s.')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 36: Koshary (Egypt)
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
        'Koshary',
        'koshary',
        'Le plat national égyptien, un mélange réconfortant et économique de riz, de macaroni et de lentilles, garni d''une sauce tomate à l''ail et d''oignons frits.',
        20, 40, 6
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Cuire le riz, les lentilles et les macaronis séparément selon les instructions des paquets. Égoutter et réserver.'),
    (recipe_id_var, 2, 'Préparer la sauce tomate : faire revenir l''ail haché dans l''huile, ajouter les tomates, le vinaigre, le cumin, sel et poivre. Laisser mijoter 15 minutes.'),
    (recipe_id_var, 3, 'Préparer les oignons frits : émincer finement les oignons et les faire frire dans une bonne quantité d''huile jusqu''à ce qu''ils soient croustillants et dorés. Égoutter.'),
    (recipe_id_var, 4, 'Pour assembler, déposer une couche de riz dans une assiette, suivie d''une couche de lentilles, puis de macaronis.'),
    (recipe_id_var, 5, 'Napper généreusement de sauce tomate chaude.'),
    (recipe_id_var, 6, 'Garnir avec les pois chiches et une grande quantité d''oignons frits.'),
    (recipe_id_var, 7, 'Servir avec une sauce pimentée (shatta) à part.');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Riz long grain', 200, 'g'),
        ('Macaroni', 200, 'g'),
        ('Lentilles brunes', 200, 'g'),
        ('Pois chiches', 1, 'boîte'),
        ('Oignon', 3, 'unité'),
        ('Tomates pelées', 1, 'boîte'),
        ('Ail', 4, 'gousse'),
        ('Vinaigre de vin blanc', 3, 'c.à.s.'),
        ('Cumin', 1, 'c.à.s.'),
        ('Huile végétale', 200, 'ml')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 37: Pastilla (Morocco)
-- =================================================================
DO $$
DECLARE
    recipe_id_var UUID;
BEGIN
    INSERT INTO public.recipe (creator_id, region_id, difficulty_id, title, slug, description, prep_time_min, cook_time_min, servings)
    VALUES (
        'f1414791-8f57-4bf4-a730-42f3c89dad95',
        (SELECT id FROM public.food_region WHERE name = 'AFRIQUE DU NORD'),
        (SELECT id FROM public.difficulty WHERE name = 'Difficile'),
        'Pastilla au Poulet et Amandes',
        'pastilla-poulet-amandes',
        'Une tourte marocaine sucrée-salée spectaculaire, faite de fines feuilles de brick croustillantes, farcie de poulet effiloché aux épices et d''amandes concassées.',
        45, 75, 8
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Faire cuire le poulet avec les oignons, l''ail, le persil, la coriandre, les épices et un peu d''eau. Une fois cuit, retirer le poulet, l''effilocher et réduire la sauce.'),
    (recipe_id_var, 2, 'Battre les œufs et les ajouter à la sauce réduite en remuant pour obtenir des œufs brouillés. Laisser refroidir.'),
    (recipe_id_var, 3, 'Frire les amandes, les concasser et les mélanger avec du sucre et de la cannelle.'),
    (recipe_id_var, 4, 'Beurrer un moule rond. Superposer plusieurs feuilles de brick beurrées en les laissant déborder.'),
    (recipe_id_var, 5, 'Étaler une couche d''amandes, puis une couche d''œufs brouillés, puis le poulet effiloché.'),
    (recipe_id_var, 6, 'Rabattre les feuilles de brick pour fermer la tourte. Couvrir avec une ou deux autres feuilles beurrées.'),
    (recipe_id_var, 7, 'Cuire au four à 180°C pendant 20-30 minutes, jusqu''à ce qu''elle soit dorée.'),
    (recipe_id_var, 8, 'Décorer de sucre glace et de cannelle avant de servir.');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Poulet', 1, 'kg'),
        ('Feuilles de brick', 10, 'feuille'),
        ('Amandes effilées', 200, 'g'),
        ('Oeuf', 4, 'unité'),
        ('Oignon', 2, 'unité'),
        ('Sucre', 100, 'g'),
        ('Sucre glace', 2, 'c.à.s.'),
        ('Cannelle', 2, 'c.à.c.'),
        ('Gingembre', 1, 'c.à.c.'),
        ('Curcuma', 1, 'c.à.c.'),
        ('Persil', 1, 'botte')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 38: Harira (Morocco)
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
        'Harira',
        'harira',
        'Une soupe marocaine traditionnelle, riche et complète, à base de tomates, lentilles, pois chiches et vermicelles, souvent servie pour rompre le jeûne du Ramadan.',
        20, 60, 6
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Dans une grande marmite, faire revenir la viande (optionnel) avec l''oignon, le céleri, le persil et la coriandre.'),
    (recipe_id_var, 2, 'Ajouter les tomates mixées, le concentré de tomate, les lentilles, les pois chiches et les épices.'),
    (recipe_id_var, 3, 'Couvrir généreusement d''eau et porter à ébullition. Laisser mijoter 45 minutes.'),
    (recipe_id_var, 4, 'Préparer le "tadouira" : délayer la farine dans un peu d''eau froide pour obtenir un mélange lisse.'),
    (recipe_id_var, 5, 'Verser le tadouira dans la soupe en remuant pour l''épaissir. Laisser cuire 10 minutes.'),
    (recipe_id_var, 6, 'Ajouter les vermicelles et cuire encore 5 minutes.'),
    (recipe_id_var, 7, 'Juste avant de servir, ajouter un filet de jus de citron. Servir chaud avec des dattes et des chebakia.');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Tomate', 500, 'g'),
        ('Lentilles vertes', 100, 'g'),
        ('Pois chiches', 150, 'g'),
        ('Vermicelles', 50, 'g'),
        ('Bœuf', 200, 'g'),
        ('Oignon', 1, 'unité'),
        ('Concentré de tomate', 2, 'c.à.s.'),
        ('Coriandre', 1, 'botte'),
        ('Farine de blé', 3, 'c.à.s.'),
        ('Citron', 1, 'unité'),
        ('Gingembre', 1, 'c.à.c.'),
        ('Curcuma', 1, 'c.à.c.')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 39: Ful Medames (Egypt)
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
        'Ful Medames',
        'ful-medames',
        'Un plat de petit-déjeuner égyptien emblématique, composé de fèves cuites lentement, écrasées et assaisonnées d''ail, de citron et d''huile d''olive.',
        5, 15, 4
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Rincer et égoutter les fèves en conserve.'),
    (recipe_id_var, 2, 'Chauffer les fèves dans une casserole avec un peu de leur liquide.'),
    (recipe_id_var, 3, 'Écraser grossièrement les fèves avec une fourchette ou un presse-purée.'),
    (recipe_id_var, 4, 'Retirer du feu et ajouter l''ail haché, le jus de citron, le cumin, le sel et le poivre.'),
    (recipe_id_var, 5, 'Bien mélanger et transférer dans un plat de service.'),
    (recipe_id_var, 6, 'Arroser généreusement d''huile d''olive.'),
    (recipe_id_var, 7, 'Garnir de persil frais haché, de dés de tomate et d''oignon. Servir chaud avec du pain pita.');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Fèves', 1, 'boîte'),
        ('Ail', 2, 'gousse'),
        ('Citron', 1, 'unité'),
        ('Huile végétale', 4, 'c.à.s.'),
        ('Cumin', 1, 'c.à.c.'),
        ('Persil', 1, 'botte'),
        ('Tomate', 1, 'unité'),
        ('Sel', 1, 'pincée'),
        ('Poivre', 1, 'pincée')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 40: Brik à l'oeuf (Tunisia)
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
        'Brik à l''oeuf',
        'brik-a-loeuf',
        'Une entrée tunisienne croustillante et délicieuse : une fine feuille de brick pliée en deux, renfermant un œuf au jaune coulant et une farce au thon.',
        10, 5, 1
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Étaler une feuille de brick. Placer une cuillère de thon émietté, un peu de persil haché et quelques câpres au centre.'),
    (recipe_id_var, 2, 'Creuser un petit puits dans la farce.'),
    (recipe_id_var, 3, 'Casser délicatement l''œuf dans le puits, en veillant à ne pas percer le jaune.'),
    (recipe_id_var, 4, 'Saler et poivrer.'),
    (recipe_id_var, 5, 'Replier rapidement la feuille de brick en deux pour former un demi-cercle.'),
    (recipe_id_var, 6, 'Plonger délicatement le brik dans un bain d''huile chaude.'),
    (recipe_id_var, 7, 'Frire 1 à 2 minutes de chaque côté. Le blanc doit être cuit et le jaune encore liquide.'),
    (recipe_id_var, 8, 'Égoutter et servir immédiatement avec un quartier de citron.');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Feuilles de brick', 1, 'feuille'),
        ('Oeuf', 1, 'unité'),
        ('Thon en conserve', 50, 'g'),
        ('Persil', 1, 'c.à.s.'),
        ('Câpres', 1, 'c.à.c.'),
        ('Huile végétale', 250, 'ml'),
        ('Citron', 0.25, 'unité'),
        ('Sel', 1, 'pincée'),
        ('Poivre', 1, 'pincée')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 41: Chakalaka (South Africa)
-- =================================================================
DO $$
DECLARE
    recipe_id_var UUID;
BEGIN
    INSERT INTO public.recipe (creator_id, region_id, difficulty_id, title, slug, description, prep_time_min, cook_time_min, servings)
    VALUES (
        'f1414791-8f57-4bf4-a730-42f3c89dad95',
        (SELECT id FROM public.food_region WHERE name = 'AFRIQUE AUSTRALE'),
        (SELECT id FROM public.difficulty WHERE name = 'Facile'),
        'Chakalaka',
        'chakalaka',
        'Un relish de légumes sud-africain épicé et coloré, à base de tomates, oignons, poivrons et haricots. Un accompagnement essentiel pour tout "braai" (barbecue).',
        15, 25, 6
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Faire revenir l''oignon, l''ail et le gingembre dans l''huile.'),
    (recipe_id_var, 2, 'Ajouter les poivrons et les carottes râpées. Cuire 5 minutes.'),
    (recipe_id_var, 3, 'Incorporer les tomates en dés, le curry en poudre, le piment et le sel.'),
    (recipe_id_var, 4, 'Laisser mijoter 10-15 minutes, jusqu''à ce que les légumes soient tendres.'),
    (recipe_id_var, 5, 'Ajouter les haricots en conserve égouttés et réchauffer le tout.'),
    (recipe_id_var, 6, 'Servir chaud ou froid en accompagnement de viande grillée, de pap ou de pain.');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Oignon', 1, 'unité'),
        ('Poivron rouge', 1, 'unité'),
        ('Poivron vert', 1, 'unité'),
        ('Poivron jaune', 1, 'unité'),
        ('Carotte', 2, 'unité'),
        ('Tomate', 1, 'boîte'),
        ('Haricots blancs en conserve', 1, 'boîte'),
        ('Ail', 2, 'gousse'),
        ('Gingembre', 1, 'c.à.c.'),
        ('Curry en poudre', 2, 'c.à.s.'),
        ('Piment', 1, 'unité'),
        ('Huile végétale', 3, 'c.à.s.')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

COMMIT;

-- End of migration file
