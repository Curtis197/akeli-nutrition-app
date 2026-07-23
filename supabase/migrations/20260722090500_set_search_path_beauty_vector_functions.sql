-- Migration: Set a fixed search_path on every SECURITY DEFINER function in the
-- Beauty Mode vector/recommendation area, closing the Postgres/Supabase linter's
-- function_search_path_mutable finding. Exact syntax matches the project's
-- existing precedent in 20260603000001_fix_generate_meal_plan_security_definer.sql
-- (SECURITY DEFINER SET search_path = public, pg_temp).
-- File: supabase/migrations/20260722090500_set_search_path_beauty_vector_functions.sql
-- Fixes: Beauty Mode Branch Review 2026-07-23, Area A, Finding #7 (Medium).
--
-- Run after Tasks 1-3 so every ALTER FUNCTION below targets each function's
-- final, current argument-type signature.

ALTER FUNCTION generate_routine_plan(uuid, integer) SET search_path = public, pg_temp;
ALTER FUNCTION recommend_recipes(uuid, integer, text, text, text, text) SET search_path = public, pg_temp;
ALTER FUNCTION search_recipes(text, text, text, integer, text, integer, integer) SET search_path = public, pg_temp;
ALTER FUNCTION generate_feed_personalized(uuid, integer, uuid[], text, text, integer, numeric, numeric, text, text, text, text, text, text) SET search_path = public, pg_temp;
ALTER FUNCTION generate_feed_exploration(uuid, integer, uuid[], text) SET search_path = public, pg_temp;
ALTER FUNCTION compute_recipe_virtues(uuid) SET search_path = public, pg_temp;
