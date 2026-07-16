-- supabase/tests/deferred_unpublish_test.sql
BEGIN;
SELECT plan(10);

SELECT has_column('public', 'recipe', 'unpublish_requested_at', 'recipe.unpublish_requested_at exists');
SELECT has_function('public', 'finalize_pending_unpublish', 'finalize_pending_unpublish() exists');

-- Flag one seeded published recipe as pending-unpublish
UPDATE recipe SET unpublish_requested_at = now()
WHERE id = (SELECT id FROM recipe WHERE is_published = true LIMIT 1);

SELECT is(
  (SELECT count(*)::int FROM recipe WHERE unpublish_requested_at IS NOT NULL),
  1, 'exactly one recipe flagged');

-- Flagged recipe is still readable (is_published untouched by flagging)
SELECT is(
  (SELECT is_published FROM recipe WHERE unpublish_requested_at IS NOT NULL),
  true, 'pending recipe stays published until finalizer runs');

SELECT is((SELECT public.finalize_pending_unpublish()), 1, 'finalizer reports 1 recipe flipped');

SELECT is(
  (SELECT count(*)::int FROM recipe WHERE unpublish_requested_at IS NOT NULL),
  0, 'flag cleared after finalize');

SELECT is((SELECT public.finalize_pending_unpublish()), 0, 'finalizer is a no-op when nothing pending');

-- Exclusion filters present at every selection site
SELECT is(
  (SELECT count(*)::int FROM regexp_matches(
     (SELECT prosrc FROM pg_proc WHERE proname = 'generate_meal_plan' LIMIT 1),
     'unpublish_requested_at IS NULL', 'g')),
  5, 'generate_meal_plan: 5 selection sites exclude pending recipes');

SELECT is(
  (SELECT count(*)::int FROM regexp_matches(
     (SELECT prosrc FROM pg_proc WHERE proname = 'generate_feed_personalized' LIMIT 1),
     'unpublish_requested_at IS NULL', 'g')),
  2, 'generate_feed_personalized: 2 selection sites exclude pending recipes');

-- Behavioral: a flagged recipe never appears in a fresh feed
UPDATE recipe SET unpublish_requested_at = now()
WHERE id = (SELECT id FROM recipe WHERE is_published = true LIMIT 1);

-- generate_feed_personalized enforces `auth.uid() IS DISTINCT FROM p_user_id`.
-- Deviation from brief: the brief's snippet calls it with no auth context, which
-- raises 'Unauthorized' locally (auth.uid() is NULL without a JWT claim set).
-- Impersonate the seeded pgTAP test user for this call only, same pattern as
-- generate_meal_plan_custom_schedule_test.sql. No auth.users/user_profile row is
-- required for this user id: the function only reads user_vector/user_allergy
-- (both tolerate zero matching rows) and is SECURITY DEFINER, so table RLS does
-- not apply.
SET LOCAL "request.jwt.claims" TO '{"sub": "00000000-0000-0000-0000-000000000001"}';

SELECT is(
  (SELECT count(*)::int
   FROM generate_feed_personalized(
     '00000000-0000-0000-0000-000000000001'::uuid, 500, '{}'::uuid[])
   WHERE recipe_id IN (SELECT id FROM recipe WHERE unpublish_requested_at IS NOT NULL)),
  0, 'feed never returns a pending-unpublish recipe');

SELECT * FROM finish();
ROLLBACK;
