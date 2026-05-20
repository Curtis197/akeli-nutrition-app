-- Migration: Add multimedia support for ingredients and recipe steps
-- Date: 2026-03-01
-- Description: 
--   1. Add image columns to ingredient table
--   2. Restructure recipe instructions into discrete steps
--   3. Add media support (images/videos) to steps
--   4. Create storage buckets and policies

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ==========================================
-- 1. INGREDIENT IMAGES
-- ==========================================

-- Add image columns to existing ingredient table
ALTER TABLE ingredient 
ADD COLUMN IF NOT EXISTS image_url TEXT,
ADD COLUMN IF NOT EXISTS image_thumbnail_url TEXT,
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ DEFAULT NOW();

-- Index for faster lookups of ingredients with images
CREATE INDEX IF NOT EXISTS idx_ingredient_has_image ON ingredient (image_url) WHERE image_url IS NOT NULL;

-- ==========================================
-- 2. RECIPE STEPS RESTRUCTURE
-- ==========================================

-- Create new recipe_step table to replace monolithic instructions
CREATE TABLE IF NOT EXISTS recipe_step (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    recipe_id UUID NOT NULL REFERENCES recipe(id) ON DELETE CASCADE,
    step_number INTEGER NOT NULL CHECK (step_number > 0),
    instruction_text TEXT NOT NULL,
    instruction_text_fr TEXT,
    instruction_text_en TEXT,
    instruction_text_es TEXT,
    instruction_text_pt TEXT,
    duration_seconds INTEGER, -- Optional time estimate for this step
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(recipe_id, step_number)
);

-- Index for ordering steps
CREATE INDEX IF NOT EXISTS idx_recipe_step_order ON recipe_step (recipe_id, step_number);

-- ==========================================
-- 3. RECIPE STEP MEDIA
-- ==========================================

-- Create table for step-specific media (images and videos)
CREATE TABLE IF NOT EXISTS recipe_step_media (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    step_id UUID NOT NULL REFERENCES recipe_step(id) ON DELETE CASCADE,
    media_type TEXT NOT NULL CHECK (media_type IN ('image', 'video')),
    media_url TEXT NOT NULL,
    thumbnail_url TEXT, -- For video previews or image thumbnails
    alt_text TEXT, -- Accessibility description
    display_order INTEGER NOT NULL DEFAULT 0,
    is_primary BOOLEAN DEFAULT FALSE, -- Primary image/video for this step
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    UNIQUE(step_id, display_order)
);

-- Index for fetching media by step
CREATE INDEX IF NOT EXISTS idx_step_media ON recipe_step_media (step_id, display_order);

-- ==========================================
-- 4. HELPER FUNCTIONS
-- ==========================================

-- Function to migrate existing recipe instructions to steps
-- Splits by common delimiters: newlines, numbered lists (1., 2.), or bullet points
CREATE OR REPLACE FUNCTION migrate_recipe_instructions_to_steps()
RETURNS void AS $$
DECLARE
    rec RECORD;
    steps TEXT[];
    step_text TEXT;
    step_index INTEGER;
BEGIN
    -- Loop through all recipes that have instructions but no steps yet
    FOR rec IN 
        SELECT id, instructions 
        FROM recipe 
        WHERE instructions IS NOT NULL 
          AND instructions != ''
          AND NOT EXISTS (SELECT 1 FROM recipe_step WHERE recipe_id = recipe.id)
    LOOP
        -- Simple splitting strategy: split by double newline or numbered lines
        -- In production, you might want more sophisticated NLP-based splitting
        steps := regexp_split_to_array(rec.instructions, E'\\n\\s*\\n|\\n\\s*\\d+\\.\\s*');
        
        step_index := 0;
        FOREACH step_text IN ARRAY steps
        LOOP
            step_index := step_index + 1;
            -- Clean up the step text
            step_text := trim(step_text);
            -- Remove leading numbers if present (e.g., "1. Preheat oven" -> "Preheat oven")
            step_text := regexp_replace(step_text, '^\\d+\\.\\s*', '');
            
            IF length(step_text) > 0 THEN
                INSERT INTO recipe_step (recipe_id, step_number, instruction_text)
                VALUES (rec.id, step_index, step_text);
            END IF;
        END LOOP;
        
        RAISE NOTICE 'Migrated recipe % to % steps', rec.id, step_index;
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Function to get a recipe with its steps and media
CREATE OR REPLACE FUNCTION get_recipe_with_steps(p_recipe_id UUID, p_lang TEXT DEFAULT 'fr')
RETURNS TABLE (
    step_number INTEGER,
    instruction TEXT,
    media JSONB
) AS $$
BEGIN
    RETURN QUERY
    SELECT 
        rs.step_number,
        CASE p_lang
            WHEN 'en' THEN COALESCE(rs.instruction_text_en, rs.instruction_text)
            WHEN 'es' THEN COALESCE(rs.instruction_text_es, rs.instruction_text)
            WHEN 'pt' THEN COALESCE(rs.instruction_text_pt, rs.instruction_text)
            ELSE COALESCE(rs.instruction_text_fr, rs.instruction_text)
        END as instruction,
        COALESCE(
            jsonb_agg(
                jsonb_build_object(
                    'id', rsm.id,
                    'media_type', rsm.media_type,
                    'media_url', rsm.media_url,
                    'thumbnail_url', rsm.thumbnail_url,
                    'alt_text', rsm.alt_text,
                    'is_primary', rsm.is_primary
                ) ORDER BY rsm.display_order
            ) FILTER (WHERE rsm.id IS NOT NULL),
            '[]'::jsonb
        ) as media
    FROM recipe_step rs
    LEFT JOIN recipe_step_media rsm ON rs.id = rsm.step_id
    WHERE rs.recipe_id = p_recipe_id
    GROUP BY rs.id, rs.step_number, rs.instruction_text, rs.instruction_text_fr, 
             rs.instruction_text_en, rs.instruction_text_es, rs.instruction_text_pt
    ORDER BY rs.step_number;
END;
$$ LANGUAGE plpgsql STABLE;

-- ==========================================
-- 5. STORAGE BUCKETS (Commented - Run in Supabase Dashboard or via API)
-- ==========================================
-- Note: Storage buckets must be created via Supabase Dashboard or Admin API
-- Run these commands in your Supabase project's SQL editor with dashboard privileges:
/*
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES 
    ('ingredient-images', 'ingredient-images', true, 5242880, ARRAY['image/jpeg', 'image/png', 'image/webp']),
    ('recipe-step-media', 'recipe-step-media', true, 52428800, ARRAY['image/jpeg', 'image/png', 'image/webp', 'video/mp4', 'video/quicktime']);
*/

-- ==========================================
-- 6. ROW LEVEL SECURITY POLICIES
-- ==========================================

-- Enable RLS on new tables
ALTER TABLE recipe_step ENABLE ROW LEVEL SECURITY;
ALTER TABLE recipe_step_media ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can read recipe steps
CREATE POLICY "Public can view recipe steps"
ON recipe_step FOR SELECT
USING (true);

-- Policy: Authenticated users can insert/update/delete steps (for recipe creators)
CREATE POLICY "Authenticated users can manage recipe steps"
ON recipe_step FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM recipe r 
        WHERE r.id = recipe_step.recipe_id 
        AND r.user_id = auth.uid()
    )
);

-- Policy: Anyone can read step media
CREATE POLICY "Public can view step media"
ON recipe_step_media FOR SELECT
USING (true);

-- Policy: Authenticated users can manage step media
CREATE POLICY "Authenticated users can manage step media"
ON recipe_step_media FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM recipe_step rs
        JOIN recipe r ON r.id = rs.recipe_id
        WHERE rs.id = recipe_step_media.step_id
        AND r.user_id = auth.uid()
    )
);

-- Policy: Public can read ingredient images
CREATE POLICY "Public can view ingredient images"
ON ingredient FOR SELECT
USING (true);

-- Policy: Authenticated users can update ingredient images
CREATE POLICY "Authenticated users can manage ingredient images"
ON ingredient FOR UPDATE
TO authenticated
USING (true); -- Could be refined to only admins or specific roles

-- ==========================================
-- 7. TRIGGERS FOR UPDATED_AT
-- ==========================================

-- Trigger function for updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to ingredient
DROP TRIGGER IF EXISTS update_ingredient_updated_at ON ingredient;
CREATE TRIGGER update_ingredient_updated_at
    BEFORE UPDATE ON ingredient
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Apply trigger to recipe_step
DROP TRIGGER IF EXISTS update_recipe_step_updated_at ON recipe_step;
CREATE TRIGGER update_recipe_step_updated_at
    BEFORE UPDATE ON recipe_step
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

COMMENT ON TABLE recipe_step IS 'Discrete steps for recipe instructions, replacing the monolithic instructions column';
COMMENT ON TABLE recipe_step_media IS 'Images and videos attached to specific recipe steps';
COMMENT ON FUNCTION migrate_recipe_instructions_to_steps() IS 'One-time migration to split existing recipe instructions into discrete steps';
COMMENT ON FUNCTION get_recipe_with_steps(UUID, TEXT) IS 'Fetch recipe steps with localized instructions and associated media';
