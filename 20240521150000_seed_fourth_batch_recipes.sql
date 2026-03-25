-- supabase/migrations/YYYYMMDDHHMMSS_seed_fourth_batch_recipes.sql
--
-- This migration file seeds the database with a fourth batch of African recipes.
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
('Bicarbonate de soude'),
('Iru (Caroube africaine)'),
('Thon frais'),
('Haricots verts'),
('Anis'),
('Farine de haricots'),
('Feuilles de corète potagère (Molokhia)'),
('Semoule fine'),
('Yaourt nature'),
('Beurre'),
('Levure chimique'),
('Amandes'),
('Saucisse Boerewors'),
('Pain en miche'),
('Viande de bœuf avec os'),
('Confiture d''abricot'),
('Crème fraîche'),
('Feuilles de manioc'),
('Maïs concassé'),
('Haricots rouges'),
('Viande de porc'),
('Chorizo')
ON CONFLICT (name) DO NOTHING;

--
-- 2. Seed More Recipes
--

-- =================================================================
-- Recipe 42: Waakye (West Africa)
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
        'Waakye',
        'waakye',
        'Un plat de rue ghanéen très populaire fait de riz et de haricots cuits ensemble avec des feuilles de sorgho séchées qui lui donnent une couleur bordeaux unique.',
        15, 60, 6
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Rincer les haricots (niébé) et les faire tremper pendant quelques heures si possible.'),
    (recipe_id_var, 2, 'Dans une grande casserole, mettre les haricots, les feuilles de sorgho et une généreuse quantité d''eau. Porter à ébullition.'),
    (recipe_id_var, 3, 'Ajouter une petite pincée de bicarbonate de soude pour aider les feuilles à libérer leur couleur et attendrir les haricots. Laisser bouillir jusqu''à ce que les haricots soient à moitié cuits.'),
    (recipe_id_var, 4, 'Laver le riz jusqu''à ce que l''eau soit claire. L''ajouter dans la casserole avec les haricots (retirer les feuilles de sorgho si désiré).'),
    (recipe_id_var, 5, 'Ajouter du sel et, si nécessaire, un peu plus d''eau pour couvrir le riz. Bien mélanger.'),
    (recipe_id_var, 6, 'Couvrir hermétiquement et laisser cuire à feu très doux pendant 20-25 minutes jusqu''à ce que le riz soit tendre et le liquide absorbé.'),
    (recipe_id_var, 7, 'Servir chaud, généralement accompagné de shito (sauce pimentée), de gari, de spaghettis, d''œuf dur et de plantains frits.');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Riz long grain', 400, 'g'),
        ('Haricots (niébé)', 200, 'g'),
        ('Feuilles de sorgho', 1, 'poignée'),
        ('Bicarbonate de soude', 1, 'pincée'),
        ('Eau', 1.5, 'l'),
        ('Sel', 1, 'pincée')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 43: Efo Riro (West Africa)
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
        'Efo Riro',
        'efo-riro',
        'Un riche et savoureux ragoût d''épinards nigérian (yoruba), préparé avec de l''huile de palme, de la caroube africaine (iru) et un assortiment de viandes ou poissons.',
        20, 45, 4
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Blanchir brièvement les épinards dans de l''eau bouillante, les égoutter et presser pour enlever l''excès d''eau. Hacher grossièrement.'),
    (recipe_id_var, 2, 'Mixer grossièrement le poivron rouge, les piments et un oignon. Émincer le deuxième oignon.'),
    (recipe_id_var, 3, 'Dans une grande marmite, faire chauffer l''huile de palme pendant quelques minutes (sans la faire fumer). Ajouter l''oignon émincé et frire jusqu''à translucidité.'),
    (recipe_id_var, 4, 'Ajouter l''iru (caroube) et faire revenir 1 minute pour libérer les arômes.'),
    (recipe_id_var, 5, 'Verser la purée de poivron/piment. Cuire pendant environ 15 minutes pour réduire l''eau et frire la sauce.'),
    (recipe_id_var, 6, 'Ajouter les morceaux de bœuf préalablement cuits, le poisson fumé émietté, le cube de bouillon et un peu de bouillon de viande. Mijoter 10 minutes.'),
    (recipe_id_var, 7, 'Incorporer les épinards égouttés. Mélanger délicatement pour bien les enrober de sauce.'),
    (recipe_id_var, 8, 'Laisser mijoter à feu doux pendant 3-5 minutes (ne pas trop cuire les feuilles). Servir avec du Pounded Yam ou de l''Amala.');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Épinards', 500, 'g'),
        ('Huile de palme', 100, 'ml'),
        ('Oignon', 2, 'unité'),
        ('Poivron rouge', 2, 'unité'),
        ('Piment', 2, 'unité'),
        ('Iru (Caroube africaine)', 1, 'c.à.s.'),
        ('Poisson fumé', 150, 'g'),
        ('Bœuf', 300, 'g'),
        ('Bouillon de bœuf', 1, 'unité'),
        ('Sel', 1, 'pincée')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 44: Garba (West Africa)
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
        'Garba',
        'garba',
        'Le plat de rue par excellence d''Abidjan ! Constitué d''attiéké (semoule de manioc) servi avec des morceaux de thon frit et une garniture d''oignons, tomates et piments.',
        15, 15, 2
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Couper le thon frais en cubes de taille moyenne. Assaisonner avec un peu de sel et un demi-cube de bouillon émietté.'),
    (recipe_id_var, 2, 'Faire frire les cubes de thon dans de l''huile bien chaude jusqu''à ce qu''ils soient bien dorés et croustillants à l''extérieur. Égoutter et réserver l''huile de friture.'),
    (recipe_id_var, 3, 'Pendant ce temps, hacher finement l''oignon, la tomate et les piments frais.'),
    (recipe_id_var, 4, 'Réchauffer l''attiéké à la vapeur ou au micro-ondes. L''égrener dans un grand plat plat ou une assiette creuse.'),
    (recipe_id_var, 5, 'Arroser généreusement l''attiéké avec 2 à 3 cuillères à soupe de l''huile de friture du thon (c''est le secret du goût !). Bien mélanger.'),
    (recipe_id_var, 6, 'Émietter le reste du cube de bouillon directement sur l''attiéké (selon le goût).'),
    (recipe_id_var, 7, 'Disposer les morceaux de thon frit sur l''attiéké.'),
    (recipe_id_var, 8, 'Garnir avec le mélange d''oignons, tomates et piments hachés. Manger traditionnellement avec les mains.');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Semoule de manioc (Attiéké)', 400, 'g'),
        ('Thon frais', 300, 'g'),
        ('Oignon', 1, 'unité'),
        ('Tomate', 1, 'unité'),
        ('Piment', 2, 'unité'),
        ('Huile végétale', 150, 'ml'),
        ('Bouillon de poulet', 1, 'unité'),
        ('Sel', 1, 'pincée')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 45: Poulet DG (Central Africa)
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
        'Poulet DG',
        'poulet-dg',
        'Le Poulet "Directeur Général", un ragoût camerounais de fête avec du poulet frit, des bananes plantains, des carottes, des poivrons et une délicieuse sauce tomate.',
        30, 45, 4
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Couper le poulet en morceaux. Assaisonner avec sel, poivre, ail et gingembre. Faire dorer les morceaux dans de l''huile jusqu''à ce qu''ils soient cuits. Réserver.'),
    (recipe_id_var, 2, 'Peler les bananes plantains et les couper en rondelles. Les faire frire jusqu''à ce qu''elles soient bien dorées. Égoutter sur du papier absorbant.'),
    (recipe_id_var, 3, 'Couper les carottes, les poivrons, les tomates et les oignons en grosses lanières ou rondelles.'),
    (recipe_id_var, 4, 'Dans une grande cocotte, utiliser un peu d''huile pour faire revenir les oignons, l''ail et le gingembre.'),
    (recipe_id_var, 5, 'Ajouter les tomates et cuire environ 5 minutes. Ajouter les carottes, les poivrons et les haricots verts. Laisser mijoter 10 minutes (les légumes doivent rester un peu croquants).'),
    (recipe_id_var, 6, 'Incorporer le bouillon de poulet, le persil et le piment entier. Remettre les morceaux de poulet dans la cocotte et bien mélanger.'),
    (recipe_id_var, 7, 'En toute fin de cuisson, ajouter délicatement les bananes plantains frites. Remuer doucement pour qu''elles s''imprègnent de la sauce sans se réduire en bouillie.'),
    (recipe_id_var, 8, 'Servir chaud immédiatement, souvent en plat unique.');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Poulet', 1, 'kg'),
        ('Banane plantain mûre', 4, 'unité'),
        ('Carotte', 2, 'unité'),
        ('Poivron vert', 1, 'unité'),
        ('Poivron rouge', 1, 'unité'),
        ('Haricots verts', 150, 'g'),
        ('Oignon', 2, 'unité'),
        ('Tomate', 3, 'unité'),
        ('Ail', 3, 'gousse'),
        ('Gingembre', 1, 'c.à.s.'),
        ('Bouillon de poulet', 1, 'unité'),
        ('Huile végétale', 200, 'ml'),
        ('Persil', 1, 'botte')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 46: Kelewele (West Africa)
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
        'Kelewele',
        'kelewele',
        'Un en-cas ou accompagnement ghanéen très parfumé, composé de bananes plantains mûres frites et enrobées d''un puissant mélange d''épices et de gingembre.',
        15, 15, 4
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Peler les bananes plantains et les couper en petits dés ou en biseaux.'),
    (recipe_id_var, 2, 'Dans un petit mixeur ou un mortier, réduire en pâte fraîche le gingembre, l''ail, l''oignon, le piment, les clous de girofle, l''anis et le sel (avec un tout petit peu d''eau si nécessaire).'),
    (recipe_id_var, 3, 'Dans un grand bol, mélanger les dés de plantain avec la pâte d''épices. Bien enrober chaque morceau.'),
    (recipe_id_var, 4, 'Laisser mariner pendant 15 à 30 minutes pour que les saveurs pénètrent.'),
    (recipe_id_var, 5, 'Faire chauffer l''huile dans une poêle profonde à feu moyen-vif.'),
    (recipe_id_var, 6, 'Frire les plantains épicés par petits lots en remuant de temps en temps, jusqu''à ce qu''ils soient bien dorés et caramélisés (l''extérieur sera plus foncé que des plantains classiques à cause des épices).'),
    (recipe_id_var, 7, 'Égoutter sur du papier absorbant. Servir très chaud en accompagnement ou avec des arachides grillées.');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Banane plantain mûre', 4, 'unité'),
        ('Gingembre', 2, 'c.à.s.'),
        ('Ail', 2, 'gousse'),
        ('Oignon', 0.5, 'unité'),
        ('Piment', 1, 'unité'),
        ('Anis', 1, 'c.à.c.'),
        ('Clou de girofle', 1, 'pincée'),
        ('Sel', 1, 'c.à.c.'),
        ('Huile végétale', 300, 'ml')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 47: Moin Moin (West Africa)
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
        'Moin Moin',
        'moin-moin',
        'Un pudding de haricots nigérian savoureux, cuit à la vapeur. Riche en protéines, il est préparé avec des haricots mixés, des poivrons, des œufs et du poisson.',
        45, 60, 6
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Faire tremper les haricots, puis les peler en les frottant pour retirer la fine peau (si vous n''utilisez pas de farine de haricots prête à l''emploi). Les rincer abondamment.'),
    (recipe_id_var, 2, 'Faire cuire les œufs pour qu''ils soient durs. Les écaler et les couper en deux.'),
    (recipe_id_var, 3, 'Mixer très finement les haricots pelés avec l''oignon, le poivron rouge, le piment et un peu d''eau, jusqu''à obtenir une pâte parfaitement lisse.'),
    (recipe_id_var, 4, 'Verser la pâte dans un grand bol. Ajouter l''huile végétale, le bouillon émietté, le sel et le poisson fumé émietté. Bien mélanger au fouet pour incorporer de l''air.'),
    (recipe_id_var, 5, 'Ajouter un peu d''eau tiède si la pâte est trop épaisse ; elle doit avoir la consistance d''une pâte à gâteau légère.'),
    (recipe_id_var, 6, 'Verser la pâte dans des feuilles de bananier (méthode traditionnelle), des ramequins beurrés ou des sachets en aluminium.'),
    (recipe_id_var, 7, 'Enfoncer un demi-œuf dur au centre de chaque portion.'),
    (recipe_id_var, 8, 'Fermer les contenants et les placer dans un cuiseur vapeur ou une grande marmite avec un fond d''eau bouillante (surélever les contenants pour qu''ils ne touchent pas l''eau).'),
    (recipe_id_var, 9, 'Cuire à la vapeur pendant 45 à 60 minutes jusqu''à ce que le Moin Moin soit ferme. Servir chaud ou froid.');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Farine de haricots', 400, 'g'),
        ('Oignon', 2, 'unité'),
        ('Poivron rouge', 1, 'unité'),
        ('Piment', 1, 'unité'),
        ('Huile végétale', 150, 'ml'),
        ('Bouillon de poulet', 2, 'unité'),
        ('Poisson fumé', 100, 'g'),
        ('Oeuf', 4, 'unité'),
        ('Eau', 300, 'ml'),
        ('Sel', 1, 'pincée')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 48: Molokhia (North Africa)
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
        'Molokhia Égyptienne',
        'molokhia-egyptienne',
        'Une soupe égyptienne emblématique, extrêmement verte et légèrement visqueuse, préparée avec des feuilles de corète hachées et parfumée avec une généreuse "Taqleyah" à l''ail.',
        20, 30, 4
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Faire bouillir le poulet dans de l''eau avec un oignon, du sel et du poivre pour créer un bouillon de poulet riche. Retirer le poulet une fois cuit et filtrer le bouillon (vous avez besoin d''environ 1 litre).'),
    (recipe_id_var, 2, 'Si vous utilisez des feuilles de molokhia fraîches, les hacher très finement avec un couteau à bascule (makhrata) jusqu''à obtenir une consistance presque pâteuse. Si elles sont surgelées, les laisser dégeler.'),
    (recipe_id_var, 3, 'Porter le bouillon de poulet à ébullition. Ajouter la molokhia hachée.'),
    (recipe_id_var, 4, 'Baisser le feu et laisser mijoter doucement pendant 5-10 minutes, en écumant la mousse à la surface. Ne couvrez surtout pas la marmite, sinon les feuilles tomberont au fond !'),
    (recipe_id_var, 5, 'Préparer la "Taqleyah" : dans une petite poêle, faire chauffer le beurre ou l''huile. Ajouter l''ail écrasé et la coriandre moulue.'),
    (recipe_id_var, 6, 'Faire frire jusqu''à ce que l''ail soit juste doré et très parfumé. Attention à ne pas le brûler.'),
    (recipe_id_var, 7, 'Verser la Taqleyah crépitante directement dans la soupe de molokhia (traditionnellement, on prend une inspiration brusque, le "shahqa", à ce moment-là !). Remuer doucement une fois.'),
    (recipe_id_var, 8, 'Faire dorer les morceaux de poulet au four ou à la poêle. Servir la soupe sur du riz blanc ou avec du pain pita, accompagnée du poulet.');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Poulet', 800, 'g'),
        ('Feuilles de corète potagère (Molokhia)', 400, 'g'),
        ('Bouillon de poulet', 1, 'l'),
        ('Ail', 6, 'gousse'),
        ('Coriandre', 2, 'c.à.s.'),
        ('Beurre', 2, 'c.à.s.'),
        ('Oignon', 1, 'unité'),
        ('Sel', 1, 'pincée')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 49: Basbousa (North Africa)
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
        'Basbousa',
        'basbousa',
        'Un gâteau de semoule égyptien dense, fondant et sucré, généreusement imbibé d''un sirop parfumé à l''eau de fleur d''oranger et décoré d''amandes.',
        20, 35, 8
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Préparer le sirop : dans une casserole, mélanger 200g de sucre, 200ml d''eau et le jus d''un demi-citron. Porter à ébullition, puis laisser frémir 10 minutes. Retirer du feu, ajouter l''eau de fleur d''oranger et laisser refroidir complètement.'),
    (recipe_id_var, 2, 'Préchauffer le four à 180°C. Beurrer généreusement un plat à four (ou utiliser de la tahini pour graisser).'),
    (recipe_id_var, 3, 'Dans un grand bol, mélanger la semoule, les 100g de sucre restants et la levure chimique.'),
    (recipe_id_var, 4, 'Faire fondre le beurre et l''ajouter aux ingrédients secs. Mélanger du bout des doigts pour sabler le mélange.'),
    (recipe_id_var, 5, 'Ajouter le yaourt nature et mélanger jusqu''à obtenir une pâte épaisse, sans trop la travailler.'),
    (recipe_id_var, 6, 'Étaler la pâte uniformément dans le plat. Laisser reposer 15 minutes.'),
    (recipe_id_var, 7, 'Tracer des losanges ou des carrés à la surface avec un couteau, et enfoncer une amande émondée au centre de chaque part.'),
    (recipe_id_var, 8, 'Cuire au four pendant 30 à 40 minutes, jusqu''à ce que le gâteau soit bien doré.'),
    (recipe_id_var, 9, 'Dès la sortie du four, verser lentement le sirop FROID sur le gâteau CHAUD. Laisser absorber et refroidir complètement avant de découper.');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Semoule fine', 500, 'g'),
        ('Sucre', 300, 'g'),
        ('Yaourt nature', 250, 'g'),
        ('Beurre', 150, 'g'),
        ('Levure chimique', 1, 'c.à.c.'),
        ('Amandes', 50, 'g'),
        ('Citron', 0.5, 'unité'),
        ('Eau de fleur d''oranger', 2, 'c.à.s.'),
        ('Eau', 200, 'ml')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 50: Pap en Vleis (Southern Africa)
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
        'Pap en Vleis',
        'pap-en-vleis',
        'Le cœur culinaire du barbecue sud-africain (Braai). Du Pap (bouillie de maïs épaisse) servi avec de la viande grillée (Vleis) et une sauce tomate-oignon sucrée-salée.',
        15, 45, 4
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Préparer le Pap : faire bouillir l''eau avec une pincée de sel. Verser la farine de maïs en pluie au centre sans remuer. Couvrir, réduire le feu et laisser mijoter 10 minutes.'),
    (recipe_id_var, 2, 'Ouvrir et remuer vigoureusement avec une cuillère en bois ou une fourchette à pap pour casser les grumeaux. Remettre le couvercle et cuire à feu très doux encore 15-20 minutes jusqu''à ce que le pap soit ferme.'),
    (recipe_id_var, 3, 'Préparer la sauce (Sheba) : faire revenir un oignon haché dans de l''huile. Ajouter l''ail, les tomates en dés, un peu de sucre, sel et poivre. Laisser réduire en une sauce épaisse pendant 20 minutes.'),
    (recipe_id_var, 4, 'Faire griller les saucisses Boerewors et les steaks de bœuf au barbecue (braai) ou sur un gril très chaud, selon votre cuisson préférée.'),
    (recipe_id_var, 5, 'Servir le pap chaud, nappé de sauce tomate-oignon, avec la viande grillée à côté.');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Farine de maïs', 400, 'g'),
        ('Eau', 1, 'l'),
        ('Sel', 1, 'c.à.c.'),
        ('Saucisse Boerewors', 500, 'g'),
        ('Bœuf', 400, 'g'),
        ('Tomate', 3, 'unité'),
        ('Oignon', 1, 'unité'),
        ('Ail', 2, 'gousse'),
        ('Sucre', 1, 'c.à.c.'),
        ('Huile végétale', 2, 'c.à.s.')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 51: Bunny Chow (Southern Africa)
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
        'Bunny Chow',
        'bunny-chow',
        'Un plat de rue iconique de Durban. Une miche de pain blanc évidée et généreusement remplie d''un curry d''agneau indien épicé. Il se mange à la main !',
        20, 90, 4
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Dans une grande marmite, faire chauffer l''huile. Ajouter l''oignon haché, l''ail, le gingembre, les graines de moutarde et l''anis étoilé. Faire revenir jusqu''à ce que l''oignon soit tendre.'),
    (recipe_id_var, 2, 'Ajouter la poudre de curry et cuire 1 minute en remuant constamment.'),
    (recipe_id_var, 3, 'Ajouter les morceaux d''agneau et les faire dorer de tous les côtés.'),
    (recipe_id_var, 4, 'Incorporer les tomates pelées et le bouillon. Porter à ébullition, réduire le feu, couvrir et laisser mijoter 45 minutes.'),
    (recipe_id_var, 5, 'Ajouter les pommes de terre coupées en quartiers et cuire encore 20-30 minutes, jusqu''à ce que la viande et les pommes de terre soient tendres et la sauce épaisse.'),
    (recipe_id_var, 6, 'Couper la miche de pain en deux ou en quarts (selon la taille). Creuser l''intérieur de chaque morceau de pain en gardant la mie (le "chapeau").'),
    (recipe_id_var, 7, 'Remplir les cavités de pain à ras bord avec le curry très chaud.'),
    (recipe_id_var, 8, 'Garnir de coriandre fraîche, reposer la mie sur le dessus et servir avec une salade de carottes râpées (sambals).');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Pain en miche', 1, 'unité'),
        ('Agneau', 800, 'g'),
        ('Oignon', 2, 'unité'),
        ('Ail', 3, 'gousse'),
        ('Gingembre', 1, 'c.à.s.'),
        ('Curry en poudre', 3, 'c.à.s.'),
        ('Graines de moutarde', 1, 'c.à.c.'),
        ('Tomates pelées', 1, 'boîte'),
        ('Pomme de terre', 3, 'unité'),
        ('Bouillon de bœuf', 500, 'ml'),
        ('Coriandre', 1, 'botte'),
        ('Huile végétale', 3, 'c.à.s.')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 52: Seswaa (Southern Africa)
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
        'Seswaa',
        'seswaa',
        'Le plat national du Botswana. Une préparation extrêmement simple mais savoureuse de viande de bœuf cuite très longuement puis effilochée, servie avec du Pap.',
        10, 240, 6
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Couper la viande (idéalement des morceaux avec des os et un peu de graisse pour le goût) en gros cubes.'),
    (recipe_id_var, 2, 'Mettre la viande dans une grande marmite à fond épais (traditionnellement une marmite en fonte sur le feu).'),
    (recipe_id_var, 3, 'Ajouter l''oignon entier épluché, le sel et le poivre. Couvrir généreusement d''eau.'),
    (recipe_id_var, 4, 'Porter à ébullition, puis réduire le feu au minimum.'),
    (recipe_id_var, 5, 'Couvrir et laisser mijoter très lentement pendant 3 à 4 heures, en ajoutant un peu d''eau si nécessaire, jusqu''à ce que la viande se détache de l''os et soit extrêmement tendre.'),
    (recipe_id_var, 6, 'À la fin de la cuisson, laisser presque toute l''eau s''évaporer pour que la viande commence légèrement à frire dans sa propre graisse au fond de la marmite.'),
    (recipe_id_var, 7, 'Retirer l''oignon et les os. À l''aide d''un gros pilon en bois ou de deux fourchettes, piler et effilocher vigoureusement la viande dans la marmite.'),
    (recipe_id_var, 8, 'Servir très chaud, traditionnellement accompagné de pap (bouillie de maïs) et de légumes verts.');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Viande de bœuf avec os', 1.5, 'kg'),
        ('Oignon', 1, 'unité'),
        ('Sel', 1, 'c.à.s.'),
        ('Poivre', 1, 'c.à.c.'),
        ('Eau', 2, 'l')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 53: Malva Pudding (Southern Africa)
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
        'Malva Pudding',
        'malva-pudding',
        'Un dessert chaud sud-africain incontournable, semblable à un gâteau éponge, imbibé d''une sauce sucrée et crémeuse au beurre.',
        20, 45, 6
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Préchauffer le four à 180°C. Beurrer un plat allant au four.'),
    (recipe_id_var, 2, 'Dans un bol, battre l''œuf et le sucre jusqu''à ce que le mélange blanchisse et soit mousseux. Ajouter la confiture d''abricot et battre à nouveau.'),
    (recipe_id_var, 3, 'Faire fondre le beurre. Dans un autre récipient, dissoudre le bicarbonate de soude dans le lait tiède et ajouter le vinaigre.'),
    (recipe_id_var, 4, 'Tamiser la farine et la pincée de sel. Les incorporer délicatement au mélange d''œufs, en alternant avec le beurre fondu et le mélange de lait.'),
    (recipe_id_var, 5, 'Verser la pâte dans le plat beurré et cuire au four pendant 30 à 45 minutes, jusqu''à ce que le pudding soit gonflé et bien doré.'),
    (recipe_id_var, 6, 'Pendant la cuisson du pudding, préparer la sauce : faire chauffer la crème fraîche, le beurre, le sucre et un peu d''eau dans une casserole jusqu''à ce que tout soit fondu et chaud.'),
    (recipe_id_var, 7, 'Dès la sortie du four, piquer le pudding partout avec une brochette et verser lentement la sauce chaude par-dessus pour qu''il s''en imbibe complètement.'),
    (recipe_id_var, 8, 'Servir chaud, idéalement avec de la crème anglaise (custard) ou une boule de glace à la vanille.');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Farine de blé', 150, 'g'),
        ('Sucre', 150, 'g'),
        ('Oeuf', 1, 'unité'),
        ('Confiture d''abricot', 2, 'c.à.s.'),
        ('Beurre', 50, 'g'),
        ('Vinaigre', 1, 'c.à.s.'),
        ('Lait', 100, 'ml'),
        ('Bicarbonate de soude', 1, 'c.à.c.'),
        ('Sel', 1, 'pincée'),
        ('Crème fraîche', 200, 'ml')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 54: Saka Saka / Pondu (Central Africa)
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
        'Saka Saka (Pondu)',
        'saka-saka-pondu',
        'Plat emblématique des deux Congos, le Pondu est préparé à base de feuilles de manioc finement pilées, cuites très longuement avec de l''huile de palme.',
        30, 120, 6
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'Laver très soigneusement les feuilles de manioc. Les piler dans un mortier (ou les mixer) jusqu''à obtenir une consistance presque hachée/écrasée.'),
    (recipe_id_var, 2, 'Mettre les feuilles pilées dans une grande marmite, couvrir abondamment d''eau et faire bouillir à découvert pendant au moins 1 heure pour éliminer l''acidité et la toxicité naturelle de la plante. L''eau doit réduire.'),
    (recipe_id_var, 3, 'Pendant ce temps, piler l''oignon, l''ail et le piment.'),
    (recipe_id_var, 4, 'Quand les feuilles sont tendres, ajouter le mélange d''aromates pilés, le poisson fumé émietté, la pâte d''arachide délayée dans un peu d''eau chaude, et un bouillon de poulet.'),
    (recipe_id_var, 5, 'Verser généreusement l''huile de palme rouge.'),
    (recipe_id_var, 6, 'Couvrir et laisser mijoter à feu très doux pendant 45 minutes à 1 heure, en remuant de temps en temps, jusqu''à ce que la sauce soit bien épaisse et que l''huile remonte à la surface.'),
    (recipe_id_var, 7, 'Servir chaud, accompagné de riz, de manioc bouilli, de Chikwangue ou de bananes plantains.');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Feuilles de manioc', 500, 'g'),
        ('Huile de palme', 150, 'ml'),
        ('Oignon', 2, 'unité'),
        ('Ail', 3, 'gousse'),
        ('Poisson fumé', 200, 'g'),
        ('Pâte d''arachide', 2, 'c.à.s.'),
        ('Piment', 1, 'unité'),
        ('Bouillon de poulet', 1, 'unité')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

-- =================================================================
-- Recipe 55: Cachupa (Islands)
-- =================================================================
DO $$
DECLARE
    recipe_id_var UUID;
BEGIN
    INSERT INTO public.recipe (creator_id, region_id, difficulty_id, title, slug, description, prep_time_min, cook_time_min, servings)
    VALUES (
        'f1414791-8f57-4bf4-a730-42f3c89dad95',
        (SELECT id FROM public.food_region WHERE name = 'ÎLES ET CÔTES'),
        (SELECT id FROM public.difficulty WHERE name = 'Difficile'),
        'Cachupa',
        'cachupa',
        'Le plat national du Cap-Vert, un ragoût très riche et réconfortant à base de maïs concassé (hominy), de haricots et d''une variété de viandes et de charcuteries.',
        30, 180, 8
    ) RETURNING id INTO recipe_id_var;

    INSERT INTO public.recipe_step (recipe_id, step_number, description) VALUES
    (recipe_id_var, 1, 'La veille, faire tremper le maïs concassé et les haricots rouges dans de l''eau froide.'),
    (recipe_id_var, 2, 'Égoutter le maïs et les haricots. Les mettre dans une très grande marmite, couvrir largement d''eau, ajouter un filet d''huile, et porter à ébullition. Laisser cuire environ 1h30, jusqu''à ce qu''ils commencent à s''attendrir.'),
    (recipe_id_var, 3, 'Dans une poêle séparée, faire revenir les morceaux de porc et les rondelles de chorizo (ou linguiça). Réserver.'),
    (recipe_id_var, 4, 'Dans la même poêle, faire un sofrito : faire revenir l''oignon, l''ail et la tomate hachés. Ajouter la feuille de laurier et un peu de paprika.'),
    (recipe_id_var, 5, 'Ajouter les viandes poêlées et le sofrito dans la grande marmite contenant le maïs et les haricots.'),
    (recipe_id_var, 6, 'Couper le chou blanc et les carottes en gros morceaux et les ajouter au ragoût.'),
    (recipe_id_var, 7, 'Saler, poivrer, et laisser mijoter doucement pendant encore 1h à 1h30. Le bouillon doit devenir épais et riche, et les viandes très tendres.'),
    (recipe_id_var, 8, 'Servir chaud. (Le lendemain, les restes sautés à la poêle avec un œuf au plat s''appellent la "Cachupa Refogada" !).');

    INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, unit_id, quantity)
    SELECT recipe_id_var, i.id, u.id, ri.quantity
    FROM (VALUES
        ('Maïs concassé', 400, 'g'),
        ('Haricots rouges', 300, 'g'),
        ('Viande de porc', 400, 'g'),
        ('Chorizo', 200, 'g'),
        ('Oignon', 2, 'unité'),
        ('Ail', 3, 'gousse'),
        ('Tomate', 3, 'unité'),
        ('Chou blanc', 0.5, 'unité'),
        ('Carotte', 2, 'unité'),
        ('Feuille de laurier', 2, 'feuille'),
        ('Paprika', 1, 'c.à.c.'),
        ('Huile végétale', 3, 'c.à.s.')
    ) AS ri(ingredient_name, quantity, unit_abbrev)
    JOIN public.ingredient i ON i.name = ri.ingredient_name
    JOIN public.measurement_unit u ON u.abbreviation = ri.unit_abbrev;
END $$;

COMMIT;

-- End of migration file
