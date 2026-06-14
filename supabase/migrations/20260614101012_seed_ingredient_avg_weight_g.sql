-- Seed avg_weight_g for unit/piece/bunch/can/pot ingredients used in published
-- recipes that currently have NULL avg_weight_g.
--
-- Without avg_weight_g, ingredient_quantity_to_grams() returns NULL for these
-- units, so refresh_recipe_per_100g() skips them entirely — causing systematic
-- calorie undercounts in recipe_macro (e.g. dried fish, palm nuts, whole fish).
--
-- After each UPDATE the trigger trg_ingredient_refresh_recipes fires
-- refresh_recipe_per_100g() for every recipe containing that ingredient,
-- so recipe_macro.total_weight_g and the per-100g columns auto-correct.

-- ── Aromatics / spices ────────────────────────────────────────────────────────
-- Cardamome — 1 pod ≈ 2 g
UPDATE public.ingredient SET avg_weight_g = 2
WHERE id = '20fbc5e5-665c-4037-85cb-4c55951d198c';

-- Feuille de laurier — 1 bay leaf ≈ 0.5 g
UPDATE public.ingredient SET avg_weight_g = 0.5
WHERE id = '903f01c4-4773-4b57-85be-34589e9acdb7';

-- Clou de girofle (Cloves) — 1 whole clove ≈ 0.3 g
UPDATE public.ingredient SET avg_weight_g = 0.3
WHERE id = 'a1b2c3d4-1111-4aaa-8888-000000000003';

-- Cannelle (cinnamon stick) — 1 stick ≈ 3 g
UPDATE public.ingredient SET avg_weight_g = 3
WHERE id = '42065998-c8b0-4eff-b804-b18e5039666e';

-- Thym (thyme sprig) — 1 sprig ≈ 5 g
UPDATE public.ingredient SET avg_weight_g = 5
WHERE id = '4fad7094-e1dc-4557-a3a1-eb249779bda0';

-- ── Peppers / chilis ─────────────────────────────────────────────────────────
-- Piment antillais frais (Scotch bonnet) — 1 pepper ≈ 15 g
UPDATE public.ingredient SET avg_weight_g = 15
WHERE id = '6b64c0ab-f3a3-4a93-9ea6-4dac5367002c';

-- Piment sec (dried chili) — 1 piece ≈ 3 g
UPDATE public.ingredient SET avg_weight_g = 3
WHERE id = '760e194b-7928-442a-893f-a5171ad33e4a';

-- Piment oiseau (bird's eye chili) — 1 chili ≈ 3 g
UPDATE public.ingredient SET avg_weight_g = 3
WHERE id = '60c9b4c8-bba7-4986-b297-38a6cfde6613';

-- Gros piment (large bell pepper) — 1 pepper ≈ 150 g
UPDATE public.ingredient SET avg_weight_g = 150
WHERE id = '20f9c17c-6f0c-4ea6-9597-421d0b2209be';

-- ── Vegetables ───────────────────────────────────────────────────────────────
-- Céleri (celery stalk) — 1 stalk ≈ 80 g
UPDATE public.ingredient SET avg_weight_g = 80
WHERE id = 'b0995b26-533b-4273-95b0-b37fcaf55c7d';

-- ── Protein / fish ───────────────────────────────────────────────────────────
-- Poisson (Thiof / grouper) — 1 whole fish ≈ 800 g (dressed weight)
UPDATE public.ingredient SET avg_weight_g = 800
WHERE id = 'da6a2d9a-de80-4800-b7ef-eeb29a6061f1';

-- Poisson séché (Guedj) — 1 piece ≈ 80 g (salted dried fish chunk)
UPDATE public.ingredient SET avg_weight_g = 80
WHERE id = '3428f263-2d25-4f29-b1ba-c1cd5ee8e357';

-- Yet (mollusque séché) — 1 unit ≈ 30 g (dried sea snail)
UPDATE public.ingredient SET avg_weight_g = 30
WHERE id = '577f503c-0134-4236-b831-ed70bcd30347';

-- Poisson fermenté (Adjovan) — 1 piece ≈ 80 g
UPDATE public.ingredient SET avg_weight_g = 80
WHERE id = 'e44776ac-66a8-46ec-a27d-4f2e51e63fc8';

-- Crabe (crab) — 1 unit ≈ 200 g
UPDATE public.ingredient SET avg_weight_g = 200
WHERE id = 'ec120eb3-b357-4a3f-8668-4ec08ecca3bd';

-- Saucisse fumée (smoked sausage) — 1 unit ≈ 100 g
UPDATE public.ingredient SET avg_weight_g = 100
WHERE id = '68090810-2346-4808-b319-3fcc5f7e854a';

-- ── Palm products (cans) ─────────────────────────────────────────────────────
-- Graine de palme (palm kernels, can) — 1 can ≈ 400 g net drained
UPDATE public.ingredient SET avg_weight_g = 400
WHERE id = 'a2707fda-62de-4ba3-a790-83e2a3c4d779';

-- Noix de palme (palm nuts, can) — 1 can ≈ 400 g net drained
UPDATE public.ingredient SET avg_weight_g = 400
WHERE id = '1434c6f7-3985-4ff5-b3b9-795e8cb748e6';

-- ── Dairy ────────────────────────────────────────────────────────────────────
-- Yaourt (yogurt pot) — 1 individual pot ≈ 125 g
UPDATE public.ingredient SET avg_weight_g = 125
WHERE id = '1b4b908b-5d21-4416-8cd9-5b152e6bbf85';
