-- 05_allergens.sql
-- Seed script for 10 common allergens

BEGIN;

INSERT INTO public.allergens (name, severity) VALUES
('Peanuts', 'high'),
('Tree Nuts', 'high'),
('Milk', 'medium'),
('Eggs', 'medium'),
('Wheat', 'low'),
('Soy', 'low'),
('Fish', 'high'),
('Shellfish', 'high'),
('Sesame', 'medium'),
('Gluten', 'low')
ON CONFLICT (name) DO NOTHING;

COMMIT;
