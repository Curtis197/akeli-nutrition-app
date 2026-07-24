-- Migration: Seed the default "Akeli Beauté" system creator account that
-- 20260720000004_beauty_usage_virtue_matrix.sql (and the later starter-
-- recipe seed migrations) assume already exists.
-- File: supabase/migrations/20260719235959_seed_default_beauty_creator_account.sql
--
-- Discovered running `supabase db reset` against a genuinely fresh local
-- database (Beauty Mode Branch Review 2026-07-23, Area J walkthrough
-- verification): 20260720000004 INSERTs recipe rows with
-- creator_id = '1a1b225a-1328-4d58-976f-253574410c6f', but no migration
-- anywhere in this repo ever creates a `creator` row with that id — a
-- repo-wide grep for both "1a1b225a-1328-4d58-976f-253574410c6f" and
-- "INSERT INTO creator (" confirms this. The shared/remote Supabase project
-- has apparently had this row seeded manually (outside any migration, e.g.
-- via the dashboard), which is why this FK violation was never caught
-- before: every `supabase db push`/local dev session up to now happened
-- against a database that already had it. `supabase db reset` — the exact
-- command every prior walkthrough in this branch has told the user to run
-- to execute the new pgTAP tests — fails immediately on a fresh database
-- without this migration, before a single pgTAP test can run.
--
-- Timestamped to sort immediately before 20260720000001 (the first beauty
-- migration), so it runs ahead of every migration that depends on it.
-- ON CONFLICT DO NOTHING throughout so this is a no-op (not a duplicate/
-- error) on any environment where the row already exists, e.g. the shared
-- remote project.

DO $$
BEGIN
  INSERT INTO auth.users (id, email, role, created_at, updated_at, raw_app_meta_data, raw_user_meta_data, aud, instance_id)
  VALUES (
    '1a1b225a-1328-4d58-976f-253574410c6f'::uuid,
    'beaute-akeli@akeli.app',
    'authenticated',
    now(),
    now(),
    '{"provider": "system", "providers": ["system"]}'::jsonb,
    '{}'::jsonb,
    'authenticated',
    '00000000-0000-0000-0000-000000000000'::uuid
  )
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO user_profile (id, username, first_name, last_name, locale, is_creator, onboarding_done, created_at, updated_at)
  VALUES (
    '1a1b225a-1328-4d58-976f-253574410c6f'::uuid,
    'akeli_beaute',
    'Akeli',
    'Beauté',
    'fr',
    true,
    true,
    now(),
    now()
  )
  ON CONFLICT (id) DO NOTHING;

  INSERT INTO creator (id, user_id, display_name, bio, is_verified, created_at, updated_at)
  VALUES (
    '1a1b225a-1328-4d58-976f-253574410c6f'::uuid,
    '1a1b225a-1328-4d58-976f-253574410c6f'::uuid,
    'Akeli Beauté',
    'Compte créateur officiel Akeli pour les remèdes et rituels beauté de la catégorie de départ.',
    true,
    now(),
    now()
  )
  ON CONFLICT (id) DO NOTHING;
END $$;
