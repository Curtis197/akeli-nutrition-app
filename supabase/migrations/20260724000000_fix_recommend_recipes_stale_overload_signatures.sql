-- Migration: Correct Area A's DROP FUNCTION signatures for recommend_recipes,
-- which silently no-op'd because they didn't match any live overload.
-- File: supabase/migrations/20260724000000_fix_recommend_recipes_stale_overload_signatures.sql
--
-- Discovered running `supabase test db` against a genuinely fresh, fully
-- migrated local database (Beauty Mode Branch Review 2026-07-23, Area J
-- walkthrough verification) -- the pgTAP test added by Area A's own plan
-- (recommend_recipes_auth_overloads_clamp_test.sql) asserts exactly 1
-- overload exists and fails with "have: 3, want: 1".
--
-- 20260722090100_fix_recommend_recipes_auth_overloads_clamp.sql (Area A
-- Task 2) tried:
--   DROP FUNCTION IF EXISTS recommend_recipes(uuid, int, int, text, text, int, text);
--   DROP FUNCTION IF EXISTS recommend_recipes(uuid, int, int, text, text, int, text, text, text);
-- Both are 7-arg/9-arg signatures inferred from a static read of
-- 20260720000002 and 20260720000008. Querying the actual live pg_proc
-- catalog (`SELECT oid::regprocedure FROM pg_proc WHERE proname =
-- 'recommend_recipes'`) shows neither of those signatures has ever existed
-- as an overload -- both DROP statements were silent no-ops (DROP FUNCTION
-- IF EXISTS does not error on a non-matching signature). The 3 overloads
-- actually live today are all 6-arg:
--   recommend_recipes(uuid,integer,integer,text,text,integer)               -- stale
--   recommend_recipes(uuid,integer,text,text,text,text)                    -- current, correct (has auth check + clamp)
--   recommend_recipes(uuid,integer,character varying,character varying,character varying,character varying) -- stale VARCHAR variant
--
-- This migration drops the 2 genuinely stale overloads using their real,
-- verified signatures, leaving only the current TEXT-typed one.

DROP FUNCTION IF EXISTS recommend_recipes(uuid, integer, integer, text, text, integer);
DROP FUNCTION IF EXISTS recommend_recipes(uuid, integer, character varying, character varying, character varying, character varying);
