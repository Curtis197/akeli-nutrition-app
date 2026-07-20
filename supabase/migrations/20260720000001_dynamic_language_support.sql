-- =============================================================================
-- AKELI V1 — Dynamic Language Registry & Translation Support
-- Migration: 20260720000001_dynamic_language_support.sql
-- Purpose: Add supported_language registry table, get_supported_languages RPC,
--          and remove rigid CHECK constraints to support arbitrary dynamic languages.
-- =============================================================================

-- ---------------------------------------------------------------------------
-- SECTION 1 — LANGUAGE REGISTRY TABLE
-- ---------------------------------------------------------------------------

CREATE TABLE IF NOT EXISTS supported_language (
  code          text PRIMARY KEY,               -- e.g. 'fr', 'en', 'wo', 'bm', 'sw', 'vi'
  name          text NOT NULL,                  -- English/Standard name e.g. 'Wolof'
  native_name   text NOT NULL,                  -- Native name e.g. 'Wolof' or '中文'
  flag_emoji    text NOT NULL DEFAULT '🌐',      -- Flag or icon
  region_group  text NOT NULL DEFAULT 'Global',  -- 'Global', 'African', 'Asian', etc.
  is_active     boolean DEFAULT true,           -- Toggle active availability
  is_beta       boolean DEFAULT false,          -- AI/Community translation badge
  created_at    timestamptz DEFAULT now()
);

ALTER TABLE supported_language ENABLE ROW LEVEL SECURITY;
DO $$ BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE tablename = 'supported_language' AND policyname = 'public reads supported_language') THEN
    CREATE POLICY "public reads supported_language" ON supported_language FOR SELECT USING (true);
  END IF;
END $$;

-- Populate initial supported languages (African, Asian, European, Global)
INSERT INTO supported_language (code, name, native_name, flag_emoji, region_group, is_active, is_beta)
VALUES
  ('fr', 'French', 'Français', '🇫🇷', 'Global', true, false),
  ('en', 'English', 'English', '🇬🇧', 'Global', true, false),
  ('es', 'Spanish', 'Español', '🇪🇸', 'Global', true, false),
  ('pt', 'Portuguese', 'Português', '🇵🇹', 'Global', true, false),
  ('ar', 'Arabic', 'العربية', '🇲🇦', 'Global', true, false),
  ('wo', 'Wolof', 'Wolof', '🇸🇳', 'African', true, false),
  ('bm', 'Bambara', 'Bamanankan', '🇲🇱', 'African', true, false),
  ('ln', 'Lingala', 'Lingála', '🇨🇩', 'African', true, false),
  ('sw', 'Swahili', 'Kiswahili', '🇰🇪', 'African', true, true),
  ('yo', 'Yoruba', 'Èdè Yorùbá', '🇳🇬', 'African', true, true),
  ('ha', 'Hausa', 'Harshen Hausa', '🇳🇬', 'African', true, true),
  ('am', 'Amharic', 'አማርኛ', '🇪🇹', 'African', true, true),
  ('vi', 'Vietnamese', 'Tiếng Việt', '🇻🇳', 'Asian', true, true),
  ('th', 'Thai', 'ไทย', '🇹🇭', 'Asian', true, true),
  ('hi', 'Hindi', 'हिन्दी', '🇮🇳', 'Asian', true, true),
  ('ja', 'Japanese', '日本語', '🇯🇵', 'Asian', true, true),
  ('zh', 'Chinese', '中文', '🇨🇳', 'Asian', true, true)
ON CONFLICT (code) DO UPDATE SET
  name = EXCLUDED.name,
  native_name = EXCLUDED.native_name,
  flag_emoji = EXCLUDED.flag_emoji,
  region_group = EXCLUDED.region_group,
  is_active = EXCLUDED.is_active,
  is_beta = EXCLUDED.is_beta;

-- Remove rigid CHECK constraints on language_code in app_translation if present
ALTER TABLE app_translation DROP CONSTRAINT IF EXISTS app_translation_language_code_check;
ALTER TABLE recipe_translation DROP CONSTRAINT IF EXISTS recipe_translation_language_code_check;

-- ---------------------------------------------------------------------------
-- SECTION 2 — RPC FUNCTIONS
-- ---------------------------------------------------------------------------

-- RPC to list all active supported languages
CREATE OR REPLACE FUNCTION get_supported_languages()
RETURNS TABLE (
  code         text,
  name         text,
  native_name  text,
  flag_emoji   text,
  region_group text,
  is_beta      boolean
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  SELECT sl.code, sl.name, sl.native_name, sl.flag_emoji, sl.region_group, sl.is_beta
  FROM supported_language sl
  WHERE sl.is_active = true
  ORDER BY 
    CASE WHEN sl.region_group = 'Global' THEN 1 WHEN sl.region_group = 'African' THEN 2 ELSE 3 END,
    sl.name;
END;
$$;

-- RPC to get UI translations for any language with automatic multi-tiered fallback (Requested -> fr -> en)
CREATE OR REPLACE FUNCTION get_all_ui_translations(p_language_code text DEFAULT 'fr')
RETURNS TABLE (
  key_name text,
  value    text
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
  RETURN QUERY
  WITH req_trans AS (
    SELECT atk.key_name, at.value
    FROM app_translation_key atk
    JOIN app_translation at ON atk.id = at.translation_key_id
    WHERE at.language_code = p_language_code
  ),
  fr_trans AS (
    SELECT atk.key_name, at.value
    FROM app_translation_key atk
    JOIN app_translation at ON atk.id = at.translation_key_id
    WHERE at.language_code = 'fr'
  ),
  en_trans AS (
    SELECT atk.key_name, at.value
    FROM app_translation_key atk
    JOIN app_translation at ON atk.id = at.translation_key_id
    WHERE at.language_code = 'en'
  )
  SELECT 
    atk.key_name,
    COALESCE(r.value, fr.value, en.value, atk.key_name) AS value
  FROM app_translation_key atk
  LEFT JOIN req_trans r ON atk.key_name = r.key_name
  LEFT JOIN fr_trans fr ON atk.key_name = fr.key_name
  LEFT JOIN en_trans en ON atk.key_name = en.key_name
  ORDER BY atk.key_name;
END;
$$;
