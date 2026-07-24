-- Migration: Seed the base metric/count measurement units that
-- recipe_ingredient.unit (and recipe_ingredient_translation.unit) have
-- always referenced via a foreign key to measurement_unit(code), but which
-- no migration in this repo's history ever actually seeded.
-- File: supabase/migrations/20260301000003_seed_base_measurement_units.sql
--
-- Discovered running `supabase db reset` against a genuinely fresh local
-- database (Beauty Mode Branch Review 2026-07-23, Area J walkthrough
-- verification): 20260720000012_beauty_recipe_ingredients_steps_and_
-- translations.sql fails with "insert or update on table
-- recipe_ingredient violates foreign key constraint
-- recipe_ingredient_unit_fkey" because it inserts unit='g'/'ml', neither of
-- which exists in measurement_unit. A repo-wide grep confirms the ONLY
-- migration that ever inserts into measurement_unit is
-- 20260628000004_us_imperial_recipe_units.sql, and it seeds exactly three
-- codes: 'oz', 'lb', 'fl_oz' (added specifically for US-locale imperial
-- unit support) -- never the base metric/count units. This is NOT specific
-- to the beauty-mode branch: every pre-existing nutrition recipe that uses
-- unit='g'/'ml'/'piece' has the exact same unmet dependency and could only
-- ever have been inserted against the shared remote database, where these
-- codes were apparently seeded manually/out-of-band at some point (the same
-- pattern as the missing default creator account fixed by
-- 20260719235959_seed_default_beauty_creator_account.sql). A fresh
-- `supabase db reset` -- the exact command every walkthrough in this branch
-- has told the user to run -- fails on this long before reaching any
-- beauty-specific migration.
--
-- Values: measurement_unit.code's own column comment in
-- 20260301000001_initial_schema.sql literally lists 'g', 'ml', 'tbsp',
-- 'cup', 'piece' as its own intended examples. 'g', 'ml', 'unit' and
-- 'piece' are confirmed in use today (repo-wide grep across every
-- recipe_ingredient seed migration); 'kg', 'l', 'tbsp', 'tsp', 'cup',
-- 'pinch', 'clove' are seeded too as other standard recipe units the
-- table's own doc comment anticipated, in case any seed data or future
-- recipe entry uses them -- harmless if unused, ON CONFLICT DO NOTHING
-- either way.
--
-- Placed immediately after 20260301000002_rpc_functions.sql so it's
-- available to every recipe/ingredient seed migration that follows.

INSERT INTO public.measurement_unit (code, name_fr, name_en) VALUES
  ('g',     'g',              'g'),
  ('kg',    'kg',             'kg'),
  ('ml',    'ml',             'ml'),
  ('l',     'l',              'l'),
  ('unit',  'unité',          'unit'),
  ('piece', 'pièce',          'piece'),
  ('tbsp',  'cuillère à soupe', 'tbsp'),
  ('tsp',   'cuillère à café',  'tsp'),
  ('cup',   'tasse',          'cup'),
  ('pinch', 'pincée',         'pinch'),
  ('clove', 'gousse',         'clove')
ON CONFLICT (code) DO NOTHING;
