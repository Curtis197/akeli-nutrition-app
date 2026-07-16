-- supabase/tests/deferred_unpublish_test.sql
BEGIN;
SELECT plan(7);

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

SELECT * FROM finish();
ROLLBACK;
