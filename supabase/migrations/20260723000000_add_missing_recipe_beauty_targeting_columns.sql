-- Migration: Add missing recipe targeting columns + persist the real
-- onboarding scalp_type value instead of collapsing it to a boolean.
-- File: supabase/migrations/20260723000000_add_missing_recipe_beauty_targeting_columns.sql
--
-- Fixes two bugs found while closing out the Area D (Python vectorization)
-- fix pass's flagged DIM_SCALP_TYPE gap (docs/superpowers/plans/2026-07-23-beauty-fix-d-python-vectorization.md,
-- Task 3's own Coverage Checklist note: "requires a DB schema task ...
-- out of scope for this Python-only plan"):
--
-- 1. [Critical, newly discovered] python/engine/database.py's get_recipe_data()
--    selects r.suitable_hair_type, r.skin_target, and r.formulation directly
--    from `recipe` — but none of those three columns exist anywhere in this
--    schema (confirmed: zero hits for any of the three across every migration
--    in supabase/migrations/, and `recipe` was created in
--    20260301000001_initial_schema.sql with no such columns, never altered
--    to add them since). This means get_recipe_data() — and therefore
--    compute_recipe_vector() for EVERY recipe, nutrition or beauty — has been
--    throwing `column "suitable_hair_type" of relation "recipe" does not
--    exist` on every call. lib/shared/models/recipe.dart already expects
--    these three as nullable String? read-only fields (fromJson, lines
--    285-287), so this migration adds them as plain nullable TEXT columns
--    matching that expectation — no backfill, no default targeting values
--    invented for existing seed recipes (that's an editorial/content
--    decision for creators, not something to fabricate here).
--
-- 2. [Medium] complete_beauty_onboarding's p_scalp_type parameter (the real
--    4-way selection from beauty_onboarding_page.dart: normal/dry/oily/
--    sensitive) is collapsed into user_health_profile.sensitive_scalp
--    (`p_scalp_type = 'sensitive'`) and the dry/oily/normal distinction is
--    discarded — never persisted anywhere. python/engine/vectorization.py's
--    DIM_SCALP_TYPE fix reads profile.get("scalp_type"), a key that could
--    never be populated as a result. This adds a real scalp_type TEXT column
--    and updates complete_beauty_onboarding to persist the raw value there
--    too, alongside (not instead of) the existing sensitive_scalp boolean,
--    which lib/features/settings/models/health_profile_model.dart and the
--    Settings UI still read/write independently.

ALTER TABLE recipe
  ADD COLUMN IF NOT EXISTS suitable_hair_type TEXT,
  ADD COLUMN IF NOT EXISTS skin_target TEXT,
  ADD COLUMN IF NOT EXISTS formulation TEXT,
  ADD COLUMN IF NOT EXISTS scalp_target TEXT;

ALTER TABLE user_health_profile
  ADD COLUMN IF NOT EXISTS scalp_type TEXT DEFAULT 'normal';

-- CREATE OR REPLACE targeting the exact 14-parameter signature made
-- authoritative by 20260722110000_fix_complete_beauty_onboarding_authorization.sql
-- (the only migration to touch this function since). Every line is
-- unchanged except the two marked additions.
CREATE OR REPLACE FUNCTION complete_beauty_onboarding(
  p_user_id              uuid,
  p_hair_type            text,
  p_porosity             text,
  p_skin_type            text,
  p_scalp_type           text,
  p_beauty_goals         text[],
  p_skin_concerns        text[] DEFAULT '{}',
  p_hair_length_cm       numeric DEFAULT 15,
  p_hair_strength_score   numeric DEFAULT 7,
  p_hair_thickness_score  numeric DEFAULT 7,
  p_hair_shedding_rate   text DEFAULT 'moderate',
  p_skin_hydration_level numeric DEFAULT 7,
  p_skin_clarity_score   numeric DEFAULT 7,
  p_checkin_notes        text DEFAULT 'Premier journal de bord initial'
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  IF auth.uid() IS DISTINCT FROM p_user_id THEN
    RAISE EXCEPTION 'Unauthorized';
  END IF;

  -- 1. Upsert user_health_profile
  INSERT INTO user_health_profile (
    user_id, hair_type, porosity, skin_type, sensitive_scalp, scalp_type, beauty_goals, skin_concerns, updated_at
  )
  VALUES (
    p_user_id, p_hair_type, p_porosity, p_skin_type, (p_scalp_type = 'sensitive'), p_scalp_type, p_beauty_goals, p_skin_concerns, NOW()
  )
  ON CONFLICT (user_id) DO UPDATE SET
    hair_type = EXCLUDED.hair_type,
    porosity = EXCLUDED.porosity,
    skin_type = EXCLUDED.skin_type,
    sensitive_scalp = EXCLUDED.sensitive_scalp,
    scalp_type = EXCLUDED.scalp_type,
    beauty_goals = EXCLUDED.beauty_goals,
    skin_concerns = EXCLUDED.skin_concerns,
    updated_at = NOW();

  -- 2. Mark beauty_onboarding_done = true on user_profile
  UPDATE user_profile
  SET beauty_onboarding_done = true
  WHERE id = p_user_id;

  -- 3. Insert initial baseline beauty_log checkin
  INSERT INTO beauty_log (
    user_id,
    hair_length_cm,
    hair_strength_score,
    hair_thickness_score,
    hair_shedding_rate,
    skin_hydration_level,
    skin_clarity_score,
    checkin_notes,
    logged_at
  )
  VALUES (
    p_user_id,
    p_hair_length_cm,
    p_hair_strength_score,
    p_hair_thickness_score,
    p_hair_shedding_rate,
    p_skin_hydration_level,
    p_skin_clarity_score,
    p_checkin_notes,
    NOW()
  );

  -- 4. Generate initial Beauty Plan for remainder of current week until Sunday (matching Nutrition mode parity)
  PERFORM generate_initial_beauty_plan(p_user_id);

  RETURN true;
END;
$$;
