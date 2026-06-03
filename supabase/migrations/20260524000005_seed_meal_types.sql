UPDATE recipe SET meal_types = ARRAY['breakfast', 'lunch', 'dinner', 'snack']::text[] WHERE meal_types IS NULL OR array_length(meal_types, 1) IS NULL;
