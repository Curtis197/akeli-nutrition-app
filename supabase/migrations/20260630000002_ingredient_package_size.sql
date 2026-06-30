-- 1. Add package size columns to ingredient_market_price
ALTER TABLE public.ingredient_market_price ADD COLUMN IF NOT EXISTS package_size NUMERIC(10,2);
ALTER TABLE public.ingredient_market_price ADD COLUMN IF NOT EXISTS package_unit TEXT;

-- 2. Populate defaults based on categories and unit types
-- Eggs
UPDATE public.ingredient_market_price imp
SET package_size = 6, package_unit = 'unit'
FROM public.ingredient i
WHERE i.id = imp.ingredient_id
  AND (i.name_fr ILIKE '%oeuf%' OR i.name_en ILIKE '%egg%');

-- Spices / Herbs / Condiments (typically sold in 50g small jars)
UPDATE public.ingredient_market_price imp
SET package_size = 50, package_unit = 'g'
FROM public.ingredient i
WHERE i.id = imp.ingredient_id
  AND (i.category IN ('condiment', 'spice', 'herb', 'spices') OR i.name_fr ILIKE '%sel%' OR i.name_fr ILIKE '%poivre%' OR i.name_fr ILIKE '%cumin%' OR i.name_fr ILIKE '%akpi%')
  AND imp.package_size IS NULL;

-- Liquid-based ingredients (milk, oil, water, juice, etc., sold in 1L / 1000ml)
UPDATE public.ingredient_market_price imp
SET package_size = 1000, package_unit = 'ml'
FROM public.ingredient i
WHERE i.id = imp.ingredient_id
  AND (i.category IN ('liquid', 'frying_oil') OR i.default_metric_unit = 'ml' OR i.name_fr ILIKE '%eau%' OR i.name_fr ILIKE '%lait%' OR i.name_fr ILIKE '%huile%')
  AND imp.package_size IS NULL;

-- Gram-based ingredients (meat, rice, flour, etc., sold in 1kg / 1000g)
UPDATE public.ingredient_market_price imp
SET package_size = 1000, package_unit = 'g'
FROM public.ingredient i
WHERE i.id = imp.ingredient_id
  AND (i.default_metric_unit = 'g' OR i.category IN ('protein', 'starch', 'fish', 'dairy', 'legume'))
  AND imp.package_size IS NULL;

-- General fallback for unit-based items (vegetables, fruits, etc., sold individually)
UPDATE public.ingredient_market_price imp
SET package_size = 1, package_unit = 'unit'
WHERE imp.package_size IS NULL;
