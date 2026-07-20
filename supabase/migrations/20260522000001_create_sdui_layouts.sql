-- SDUI Layouts Table Migration
-- Enables remote configuration of UI layouts per mode (Nutrition, Beauty, etc.)

CREATE TABLE IF NOT EXISTS layouts (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    mode VARCHAR(50) NOT NULL, -- e.g., 'nutrition', 'beauty', 'health'
    version VARCHAR(20) NOT NULL, -- Semantic versioning e.g., '1.0.0'
    platform VARCHAR(20) DEFAULT 'all', -- 'ios', 'android', 'all'
    is_active BOOLEAN DEFAULT true,
    layout_json JSONB NOT NULL, -- The actual SDUI structure
    culture_tags TEXT[], -- e.g., ['west_african', 'natural_hair']
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- Ensure only one active layout per mode/version/platform
    UNIQUE(mode, version, platform)
);

-- Index for fast lookups by mode and active status
CREATE INDEX IF NOT EXISTS idx_layouts_mode_active ON layouts(mode, is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_layouts_culture ON layouts USING GIN(culture_tags);

-- Enable Row Level Security (RLS)
ALTER TABLE layouts ENABLE ROW LEVEL SECURITY;

-- Policy: Allow public read access (layouts are not sensitive)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_policies WHERE tablename = 'layouts' AND policyname = 'Allow public read access'
    ) THEN
        CREATE POLICY "Allow public read access" ON layouts FOR SELECT USING (true);
    END IF;
END $$;

-- Insert Default Nutrition Layout
INSERT INTO layouts (mode, version, platform, is_active, layout_json, culture_tags)
VALUES (
    'nutrition',
    '1.0.0',
    'all',
    true,
    $json$[
        {"type": "header", "config": {"title": "Welcome Back", "subtitle": "Ready for your wellness journey?"}},
        {"type": "weight_tracker_card", "config": {"title": "Weight Progress", "show_graph": true}},
        {"type": "calories_graph", "config": {"title": "Daily Calorie Intake", "target": 2500}},
        {"type": "meal_log", "config": {"title": "Today's Meals", "slots": ["breakfast", "lunch", "dinner", "snack"]}},
        {"type": "shopping_list", "config": {"title": "Shopping List", "categories": ["all", "vegetables", "spices"]}},
        {"type": "cultural_spotlight", "config": {"title": "Ingredient of the Day", "item": "Fonio"}}
    ]$json$::jsonb,
    ARRAY['global', 'west_african']
)
ON CONFLICT (mode, version, platform) DO UPDATE 
SET layout_json = EXCLUDED.layout_json, updated_at = NOW();

-- Insert Grounded Beauty Layout
INSERT INTO layouts (mode, version, platform, is_active, layout_json, culture_tags)
VALUES (
    'beauty',
    '1.0.0',
    'all',
    true,
    $json$[
        {"type": "header", "config": {"title": "Beauty & Care", "subtitle": "Nourish your natural glow"}},
        {"type": "skin_hair_status", "config": {"title": "Current Focus", "metric": "Hydration", "value": "Good"}},
        {"type": "routine_progress", "config": {"title": "Weekly Routine", "completed": 3, "total": 5}},
        {"type": "routine_grid", "config": {"title": "Today's Routines", "slots": ["morning_care", "evening_care", "weekly_mask"]}},
        {"type": "product_tracker", "config": {"title": "Products & Care Ingredients", "categories": ["all", "face", "hair", "body"]}},
        {"type": "cultural_spotlight", "config": {"title": "Traditional Remedy", "item": "Shea Butter"}}
    ]$json$::jsonb,
    ARRAY['global', 'natural_hair']
)
ON CONFLICT (mode, version, platform) DO UPDATE 
SET layout_json = EXCLUDED.layout_json, updated_at = NOW();
