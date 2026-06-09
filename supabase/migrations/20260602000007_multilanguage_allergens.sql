-- ---------------------------------------------------------------------------
-- Multilanguage Allergens
-- ---------------------------------------------------------------------------

ALTER TABLE allergen RENAME COLUMN label TO label_fr;
ALTER TABLE allergen ADD COLUMN label_en text;

UPDATE allergen SET label_en = 'Tree Nuts' WHERE slug = 'nuts';
UPDATE allergen SET label_en = 'Peanuts' WHERE slug = 'peanuts';
UPDATE allergen SET label_en = 'Dairy & Lactose' WHERE slug = 'dairy';
UPDATE allergen SET label_en = 'Gluten' WHERE slug = 'gluten';
UPDATE allergen SET label_en = 'Eggs' WHERE slug = 'eggs';
UPDATE allergen SET label_en = 'Shellfish' WHERE slug = 'shellfish';
UPDATE allergen SET label_en = 'Fish' WHERE slug = 'fish';
UPDATE allergen SET label_en = 'Soy & Soya' WHERE slug = 'soy';
UPDATE allergen SET label_en = 'Sesame' WHERE slug = 'sesame';
UPDATE allergen SET label_en = 'Berries' WHERE slug = 'berries';
UPDATE allergen SET label_en = 'Citrus' WHERE slug = 'citrus';
UPDATE allergen SET label_en = 'Nightshades' WHERE slug = 'nightshades';
UPDATE allergen SET label_en = 'Stone Fruits' WHERE slug = 'stone_fruits';
UPDATE allergen SET label_en = 'Legumes' WHERE slug = 'legumes';
UPDATE allergen SET label_en = 'Corn & Maize' WHERE slug = 'corn';
UPDATE allergen SET label_en = 'Sulfites' WHERE slug = 'sulfites';
UPDATE allergen SET label_en = 'Mustard' WHERE slug = 'mustard';
UPDATE allergen SET label_en = 'Celery' WHERE slug = 'celery';
UPDATE allergen SET label_en = 'Lupin' WHERE slug = 'lupin';
UPDATE allergen SET label_en = 'Molluscs' WHERE slug = 'molluscs';

ALTER TABLE allergen ALTER COLUMN label_en SET NOT NULL;

-- Drop and recreate the search_allergens function to return both languages
DROP FUNCTION IF EXISTS search_allergens(text);

CREATE OR REPLACE FUNCTION search_allergens(p_query text)
RETURNS TABLE(id uuid, slug text, label_fr text, label_en text) AS $$
  SELECT id, slug, label_fr, label_en
  FROM allergen
  WHERE is_active = true
    AND (label_fr ILIKE '%' || p_query || '%' OR label_en ILIKE '%' || p_query || '%')
  ORDER BY label_fr
  LIMIT 10;
$$ LANGUAGE sql STABLE SECURITY DEFINER;
