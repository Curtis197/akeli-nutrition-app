-- Tag existing recipes with their preferred meal slot.
-- Unrecognised titles keep the default 'any'.

UPDATE public.recipe SET preferred_meal_type = 'breakfast'
WHERE title IN ('Fondé', 'Pap en Vleis');

UPDATE public.recipe SET preferred_meal_type = 'lunch'
WHERE title IN (
  'Soupe du Pêcheur — Atiéké',
  'Sauce Arachide — Riz Blanc',
  'Sauce Noix de Cajou — Riz Blanc',
  'Bawoin — Riz Blanc',
  'Ewa Aganyin',
  'Bunny Chow'
);

UPDATE public.recipe SET preferred_meal_type = 'dinner'
WHERE title IN (
  'Sauce Pistache — Fufu d''Ignames',
  'Sauce Gouagouassou — Foutou',
  'Sauce Aubergine — Riz',
  'Bouillon de Pieds de Porc — Riz Blanc',
  'Nyama Choma',
  'Sauce Pklala — Riz'
);
