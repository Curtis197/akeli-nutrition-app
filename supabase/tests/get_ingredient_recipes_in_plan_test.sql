BEGIN;
SELECT plan(5);

INSERT INTO auth.users (id, email, role, created_at, updated_at)
VALUES ('b0000000-0000-4000-8000-000000000001'::uuid, 'girip-test@akeli.test', 'authenticated', now(), now())
ON CONFLICT (id) DO NOTHING;

INSERT INTO user_profile (id, onboarding_done, is_creator, created_at, locale)
VALUES ('b0000000-0000-4000-8000-000000000001'::uuid, true, false, now(), 'fr')
ON CONFLICT (id) DO NOTHING;

INSERT INTO meal_plan (id, user_id, start_date, end_date, is_active)
VALUES ('b0000000-0000-4000-8000-000000000010'::uuid, 'b0000000-0000-4000-8000-000000000001'::uuid, CURRENT_DATE, CURRENT_DATE + 6, true);

INSERT INTO ingredient (id, name)
VALUES ('b0000000-0000-4000-8000-000000000020'::uuid, 'Test Rice');

-- Recipe A: entry component path, contains the ingredient
INSERT INTO recipe (id, title, is_published)
VALUES ('b0000000-0000-4000-8000-000000000030'::uuid, 'Recipe A', true);
INSERT INTO recipe_ingredient (recipe_id, ingredient_id, quantity, unit)
VALUES ('b0000000-0000-4000-8000-000000000030'::uuid, 'b0000000-0000-4000-8000-000000000020'::uuid, 100, 'g');

-- Recipe B: modular component path, contains the ingredient
INSERT INTO recipe (id, title, is_published)
VALUES ('b0000000-0000-4000-8000-000000000031'::uuid, 'Recipe B', true);
INSERT INTO recipe_ingredient (recipe_id, ingredient_id, quantity, unit)
VALUES ('b0000000-0000-4000-8000-000000000031'::uuid, 'b0000000-0000-4000-8000-000000000020'::uuid, 200, 'g');

-- Recipe C: batch cooking_session path, contains the ingredient
INSERT INTO recipe (id, title, is_published)
VALUES ('b0000000-0000-4000-8000-000000000032'::uuid, 'Recipe C', true);
INSERT INTO recipe_ingredient (recipe_id, ingredient_id, quantity, unit)
VALUES ('b0000000-0000-4000-8000-000000000032'::uuid, 'b0000000-0000-4000-8000-000000000020'::uuid, 300, 'g');

-- Recipe D: in the plan but does NOT contain the ingredient
INSERT INTO recipe (id, title, is_published)
VALUES ('b0000000-0000-4000-8000-000000000033'::uuid, 'Recipe D', true);

-- Recipe E: contains the ingredient but is NOT in this plan at all
INSERT INTO recipe (id, title, is_published)
VALUES ('b0000000-0000-4000-8000-000000000034'::uuid, 'Recipe E', true);
INSERT INTO recipe_ingredient (recipe_id, ingredient_id, quantity, unit)
VALUES ('b0000000-0000-4000-8000-000000000034'::uuid, 'b0000000-0000-4000-8000-000000000020'::uuid, 400, 'g');

-- Wire up plan linkage
INSERT INTO meal_plan_entry (id, meal_plan_id, scheduled_date, meal_type)
VALUES ('b0000000-0000-4000-8000-000000000040'::uuid, 'b0000000-0000-4000-8000-000000000010'::uuid, CURRENT_DATE, 'lunch');

INSERT INTO meal_plan_entry_component (meal_plan_entry_id, recipe_id, role)
VALUES ('b0000000-0000-4000-8000-000000000040'::uuid, 'b0000000-0000-4000-8000-000000000030'::uuid, 'base');

INSERT INTO meal_plan_entry (id, meal_plan_id, scheduled_date, meal_type)
VALUES ('b0000000-0000-4000-8000-000000000041'::uuid, 'b0000000-0000-4000-8000-000000000010'::uuid, CURRENT_DATE, 'dinner');

INSERT INTO meal_plan_entry_component (meal_plan_entry_id, recipe_id, role)
VALUES ('b0000000-0000-4000-8000-000000000041'::uuid, 'b0000000-0000-4000-8000-000000000031'::uuid, 'base');

INSERT INTO cooking_session (id, user_id, meal_plan_id, recipe_id, planned_date, total_portions)
VALUES ('b0000000-0000-4000-8000-000000000050'::uuid, 'b0000000-0000-4000-8000-000000000001'::uuid, 'b0000000-0000-4000-8000-000000000010'::uuid, 'b0000000-0000-4000-8000-000000000032'::uuid, CURRENT_DATE, 4);

INSERT INTO meal_plan_entry (id, meal_plan_id, scheduled_date, meal_type)
VALUES ('b0000000-0000-4000-8000-000000000042'::uuid, 'b0000000-0000-4000-8000-000000000010'::uuid, CURRENT_DATE, 'breakfast');

INSERT INTO meal_plan_entry_component (meal_plan_entry_id, recipe_id, role)
VALUES ('b0000000-0000-4000-8000-000000000042'::uuid, 'b0000000-0000-4000-8000-000000000033'::uuid, 'base');

SELECT is(
  (SELECT count(*)::int FROM get_ingredient_recipes_in_plan(
    'b0000000-0000-4000-8000-000000000010'::uuid,
    'b0000000-0000-4000-8000-000000000020'::uuid
  )),
  3,
  'T1: returns exactly 3 recipes (A, B, C) -- not D (no ingredient) or E (not in plan)'
);

SELECT ok(
  EXISTS(SELECT 1 FROM get_ingredient_recipes_in_plan(
    'b0000000-0000-4000-8000-000000000010'::uuid,
    'b0000000-0000-4000-8000-000000000020'::uuid
  ) WHERE recipe_id = 'b0000000-0000-4000-8000-000000000030'::uuid),
  'T2: Recipe A is included'
);

SELECT ok(
  EXISTS(SELECT 1 FROM get_ingredient_recipes_in_plan(
    'b0000000-0000-4000-8000-000000000010'::uuid,
    'b0000000-0000-4000-8000-000000000020'::uuid
  ) WHERE recipe_id = 'b0000000-0000-4000-8000-000000000031'::uuid),
  'T3: Recipe B is included'
);

SELECT ok(
  EXISTS(SELECT 1 FROM get_ingredient_recipes_in_plan(
    'b0000000-0000-4000-8000-000000000010'::uuid,
    'b0000000-0000-4000-8000-000000000020'::uuid
  ) WHERE recipe_id = 'b0000000-0000-4000-8000-000000000032'::uuid),
  'T4: Recipe C is included'
);

SELECT ok(
  NOT EXISTS(SELECT 1 FROM get_ingredient_recipes_in_plan(
    'b0000000-0000-4000-8000-000000000010'::uuid,
    'b0000000-0000-4000-8000-000000000020'::uuid
  ) WHERE recipe_id = 'b0000000-0000-4000-8000-000000000033'::uuid),
  'T5: Recipe D (no ingredient) is excluded'
);

SELECT * FROM finish();
ROLLBACK;
