-- Per-ingredient rounding overrides.
-- Only rows that differ from the unit_rounding_config default are inserted.
-- unit defaults: unit=0.5, piece=0.5, g=5, ml=5, kg=0.1, l=0.1
-- Wrapped in DO block: on a fresh local DB the ingredient table is empty,
-- so FK violations are silently skipped.
DO $seed$ BEGIN

INSERT INTO public.ingredient_rounding_rule (ingredient_id, unit, rounding_step) VALUES

-- ── Whole-only: unit & piece that cannot be fractioned ─────────────────────
-- Eggs
('3a4aa70b-a57b-47ff-bfd0-dcfa39f19938', 'unit',  1),
('3a4aa70b-a57b-47ff-bfd0-dcfa39f19938', 'piece', 1),

-- Bouillon cubes / seasoning cubes
('47e224bf-e343-4913-b554-dd055ec46b69', 'unit',  1),  -- Cube d'assaisonnement
('d968708f-8577-47e0-ba57-e8df7c86650e', 'unit',  1),  -- Bouillon de bœuf
('56256ed5-4fb7-4c43-b3d4-d63e047a2696', 'unit',  1),  -- Bouillon de poulet

-- Bay leaves
('903f01c4-4773-4b57-85be-34589e9acdb7', 'unit',  1),
('903f01c4-4773-4b57-85be-34589e9acdb7', 'piece', 1),

-- Whole spices: cinnamon sticks, cardamom pods, cloves
('42065998-c8b0-4eff-b804-b18e5039666e', 'piece', 1),  -- Cannelle (bâton)
('20fbc5e5-665c-4037-85cb-4c55951d198c', 'piece', 1),  -- Cardamome (gousse)
('20fbc5e5-665c-4037-85cb-4c55951d198c', 'unit',  1),  -- Cardamome (unité)
('a1b2c3d4-1111-4aaa-8888-000000000003', 'piece', 1),  -- Clou de girofle
('4fad7094-e1dc-4557-a3a1-eb249779bda0', 'piece', 1),  -- Thym (branche)

-- Whole chilis
('60c9b4c8-bba7-4986-b297-38a6cfde6613', 'unit',  1),  -- Piment oiseau
('126ab536-b38a-4553-885e-d789b79bc23d', 'unit',  1),  -- Piment frais
('126ab536-b38a-4553-885e-d789b79bc23d', 'piece', 1),
('6b64c0ab-f3a3-4a93-9ea6-4dac5367002c', 'unit',  1),  -- Piment antillais frais
('20f9c17c-6f0c-4ea6-9597-421d0b2209be', 'unit',  1),  -- Gros piment
('760e194b-7928-442a-893f-a5171ad33e4a', 'piece', 1),  -- Piment sec

-- Dried fish & shellfish used whole
('577f503c-0134-4236-b831-ed70bcd30347', 'unit',  1),  -- Yet (mollusque séché)
('e44776ac-66a8-46ec-a27d-4f2e51e63fc8', 'piece', 1),  -- Poisson fermenté (Adjovan)
('3428f263-2d25-4f29-b1ba-c1cd5ee8e357', 'unit',  1),  -- Poisson séché (Guedj)

-- Whole fresh fish & seafood
('da6a2d9a-de80-4800-b7ef-eeb29a6061f1', 'unit',  1),  -- Poisson (Thiof)
('ad32a0e5-4882-47cc-8d57-f0d9e7c26704', 'unit',  1),  -- Poisson frais
('ec120eb3-b357-4a3f-8668-4ec08ecca3bd', 'unit',  1),  -- Crabe
('79fbd745-185b-429f-a637-e2e4e00a9fdf', 'unit',  1),  -- Thon à l'huile (boîte)

-- Sausage / meat pieces
('68090810-2346-4808-b319-3fcc5f7e854a', 'unit',  1),  -- Saucisse fumée

-- Vegetables used whole
('f7690223-9651-42b3-a81b-f284c6fd32ef', 'unit',  1),  -- Feuilles de bananier
('49ab348f-df65-4c4e-bc5a-05239fddd53b', 'unit',  1),  -- Navet

-- ── Fine precision spices — g step=1 instead of default 5 ─────────────────
('aceeabe6-c657-4c45-a6f6-d59815c6cd97', 'g',    1),   -- Bicarbonate de soude
('1b894f69-8c77-40a1-9a17-9b19ebb79e25', 'g',    1),   -- Sel
('d31ab33f-f895-4781-8c78-fbf81098feb5', 'g',    1),   -- Muscade moulue
('030f2b81-b413-436d-aa6a-316f61250bb9', 'g',    1),   -- Apki

-- ── Starches — g step=25 ───────────────────────────────────────────────────
('5361030d-01e0-49dd-b763-722cdb0c520d', 'g',   25),   -- Riz
('6a15717c-d541-4fe2-8c5a-e2ce9c6241cd', 'g',   25),   -- Riz brisé
('85abe029-b02d-4fe5-b7cf-7a1bd280ba02', 'g',   25),   -- Riz long grain
('0dbbe89c-6328-4baf-9ba4-d1c55cf5524f', 'g',   25),   -- Couscous
('0bb80446-58e5-43b2-92a0-dba5a0e2914c', 'g',   25),   -- Farine de blé
('16496886-5655-4372-a41a-56198d46e62b', 'g',   25),   -- Farine de maïs
('8c3eff4b-1ed8-42ce-a867-975df2f5e648', 'g',   25),   -- Semoule fine
('7f1ac124-4c33-4cd3-9336-e55791d1af7d', 'g',   25),   -- Atiéké
('447e1f54-7513-41d9-89e3-319caee3b21a', 'g',   25),   -- Farine de teff
('10e1c90f-d3f6-4671-8d9e-66de83de5a4f', 'g',   25),   -- Farine de manioc

-- ── Proteins — g step=50 ──────────────────────────────────────────────────
('d635c1cc-138d-4446-afcb-ccc2ef9e7fce', 'g',   50),   -- Agneau
('4fe5a8d8-cdf9-4da2-b1ce-0fadd3660831', 'g',   50),   -- Bœuf
('ebb40465-7ba1-4568-870e-2fbcf0061911', 'g',   50),   -- Poulet
('317f6b5e-cc83-4e19-b7cf-cd8f66f2249b', 'g',   50),   -- Poulet entier
('7a070ae2-62da-4300-826b-bd0064762e48', 'g',   50),   -- Poulet fumé
('f0106e5b-5e34-4a35-8b6a-39695a7d7825', 'g',   50),   -- Viande hachée
('a1b2c3d4-1111-4aaa-8888-000000000002', 'g',   50),   -- Porc
('6b031477-b9a5-4add-82dc-873e35e31295', 'g',   50),   -- Porc fumé
('7de555b3-1ee2-48ef-b4cd-f2f96a87bb3a', 'g',   50),   -- Merguez
('6cbfb86e-27fb-4e33-99d0-faf173b9b5c3', 'g',   25),   -- Crevettes
('ad32a0e5-4882-47cc-8d57-f0d9e7c26704', 'g',   50),   -- Poisson frais (g)
('036fa17b-7abf-4846-bd9f-a4d31ef09cdd', 'g',   25)    -- Poisson fumé (g)

ON CONFLICT (ingredient_id, unit) DO UPDATE SET rounding_step = EXCLUDED.rounding_step;

EXCEPTION WHEN foreign_key_violation THEN
  RAISE WARNING 'seed_ingredient_rounding_rules: skipped — ingredient table not populated locally';
END $seed$;
