-- supabase/tests/beauty_shopping_list_authorization_test.sql
-- Finding #10 (Area C, Medium): generate_beauty_shopping_list has no
-- auth.uid() check on p_beauty_plan_id — same IDOR pattern as Finding #1.
BEGIN;
SELECT plan(3);

INSERT INTO auth.users (id, email, role, created_at, updated_at) VALUES
  ('c1000001-0000-0000-0000-000000000001'::uuid, 'shopowner10@test.local', 'authenticated', now(), now()),
  ('c1000001-0000-0000-0000-000000000002'::uuid, 'shopattacker10@test.local', 'authenticated', now(), now())
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.user_profile (id, first_name) VALUES
  ('c1000001-0000-0000-0000-000000000001'::uuid, 'ShopOwnerUser10'),
  ('c1000001-0000-0000-0000-000000000002'::uuid, 'ShopAttackerUser10')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.recipe (id, title, mode, is_published)
VALUES ('c1000001-0000-0000-0000-000000000020'::uuid, 'Test Shopping Recipe Ten', 'beauty', true)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.ingredient (id, name, name_fr)
VALUES ('c1000001-0000-0000-0000-000000000021'::uuid, 'Shea Butter Test Ten', 'Beurre de Karité Test Dix')
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.recipe_ingredient (recipe_id, ingredient_id, quantity)
VALUES ('c1000001-0000-0000-0000-000000000020'::uuid, 'c1000001-0000-0000-0000-000000000021'::uuid, 2.0);

INSERT INTO public.beauty_plan (id, user_id, start_date, end_date)
VALUES (
  'c1000001-0000-0000-0000-000000000030'::uuid,
  'c1000001-0000-0000-0000-000000000001'::uuid,
  current_date, current_date + 6
)
ON CONFLICT (id) DO NOTHING;

INSERT INTO public.beauty_plan_slot (plan_id, day_of_week, routine_category, step_stage, recipe_id)
VALUES ('c1000001-0000-0000-0000-000000000030'::uuid, 1, 'hair', 'daily_hydration', 'c1000001-0000-0000-0000-000000000020'::uuid);

-- Attacker cannot generate a shopping list for someone else's beauty plan.
SET LOCAL "request.jwt.claims" TO '{"sub": "c1000001-0000-0000-0000-000000000002"}';

SELECT throws_ok(
  $$ SELECT * FROM generate_beauty_shopping_list('c1000001-0000-0000-0000-000000000030'::uuid) $$,
  'Unauthorized',
  'attacker cannot generate a shopping list for another user''s beauty plan'
);

-- Owner can still generate their own shopping list.
SET LOCAL "request.jwt.claims" TO '{"sub": "c1000001-0000-0000-0000-000000000001"}';

SELECT lives_ok(
  $$ SELECT * FROM generate_beauty_shopping_list('c1000001-0000-0000-0000-000000000030'::uuid) $$,
  'owner can still generate their own beauty shopping list'
);

SELECT is(
  (SELECT ingredient_name FROM generate_beauty_shopping_list('c1000001-0000-0000-0000-000000000030'::uuid) LIMIT 1),
  'Beurre de Karité Test Dix',
  'owner''s shopping list still aggregates the recipe''s ingredient correctly'
);

SELECT * FROM finish();
ROLLBACK;
