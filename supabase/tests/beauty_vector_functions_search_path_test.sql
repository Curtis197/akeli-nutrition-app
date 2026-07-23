-- supabase/tests/beauty_vector_functions_search_path_test.sql
-- Fixes: Beauty Mode Branch Review 2026-07-23, Area A, Finding #7 (Medium).
-- No SECURITY DEFINER function in this area sets search_path, which is the
-- Postgres/Supabase linter's function_search_path_mutable risk. Existing
-- project precedent: 20260603000001_fix_generate_meal_plan_security_definer.sql.
BEGIN;
SELECT plan(6);

SELECT ok(
  EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE p.proname = 'generate_routine_plan' AND n.nspname = 'public'
      AND EXISTS (SELECT 1 FROM unnest(p.proconfig) cfg WHERE cfg LIKE 'search_path=public%pg_temp%')
  ),
  'generate_routine_plan has search_path pinned to public, pg_temp'
);

SELECT ok(
  EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE p.proname = 'recommend_recipes' AND n.nspname = 'public'
      AND EXISTS (SELECT 1 FROM unnest(p.proconfig) cfg WHERE cfg LIKE 'search_path=public%pg_temp%')
  ),
  'recommend_recipes has search_path pinned to public, pg_temp'
);

SELECT ok(
  EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE p.proname = 'search_recipes' AND n.nspname = 'public'
      AND EXISTS (SELECT 1 FROM unnest(p.proconfig) cfg WHERE cfg LIKE 'search_path=public%pg_temp%')
  ),
  'search_recipes has search_path pinned to public, pg_temp'
);

SELECT ok(
  EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE p.proname = 'generate_feed_personalized' AND n.nspname = 'public'
      AND EXISTS (SELECT 1 FROM unnest(p.proconfig) cfg WHERE cfg LIKE 'search_path=public%pg_temp%')
  ),
  'generate_feed_personalized has search_path pinned to public, pg_temp'
);

SELECT ok(
  EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE p.proname = 'generate_feed_exploration' AND n.nspname = 'public'
      AND EXISTS (SELECT 1 FROM unnest(p.proconfig) cfg WHERE cfg LIKE 'search_path=public%pg_temp%')
  ),
  'generate_feed_exploration has search_path pinned to public, pg_temp'
);

SELECT ok(
  EXISTS (
    SELECT 1 FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE p.proname = 'compute_recipe_virtues' AND n.nspname = 'public'
      AND EXISTS (SELECT 1 FROM unnest(p.proconfig) cfg WHERE cfg LIKE 'search_path=public%pg_temp%')
  ),
  'compute_recipe_virtues has search_path pinned to public, pg_temp'
);

SELECT * FROM finish();
ROLLBACK;
