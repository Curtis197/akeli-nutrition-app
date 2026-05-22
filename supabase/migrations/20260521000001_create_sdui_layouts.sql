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
CREATE INDEX idx_layouts_mode_active ON layouts(mode, is_active) WHERE is_active = true;
CREATE INDEX idx_layouts_culture ON layouts USING GIN(culture_tags);

-- Enable Row Level Security (RLS)
ALTER TABLE layouts ENABLE ROW LEVEL SECURITY;

-- Policy: Allow public read access (layouts are not sensitive)
CREATE POLICY "Allow public read access" 
ON layouts FOR SELECT 
USING (true);

-- Policy: Allow authenticated users (admins) to insert/update (Optional: restrict to specific roles)
-- For now, we assume service key usage for writes, so no write policy needed for general users
-- If you have admin roles, uncomment below:
-- CREATE POLICY "Allow admin write access" 
-- ON layouts FOR ALL 
-- USING (auth.jwt()->>'role' = 'admin');

-- Insert Default Nutrition Layout (Fallback)
INSERT INTO layouts (mode, version, platform, is_active, layout_json, culture_tags)
VALUES (
    'nutrition',
    '1.0.0',
    'all',
    true,
    '[
        {"type": "header", "config": {"title": "Welcome Back", "subtitle": "Ready for your wellness journey?"}},
        {"type": "weight_tracker_card", "config": {"title": "Weight Progress", "show_graph": true}},
        {"type": "calorie_summary", "config": {"title": "Today's Intake", "target": 2500}},
        {"type": "quick_actions", "config": {"items": ["log_meal", "scan_product", "view_plan"]}},
        {"type": "cultural_spotlight", "config": {"title": "Ingredient of the Day", "item": "Fonio"}}
    ]'::jsonb,
    ARRAY['global', 'urban']
);

-- Insert Default Beauty Layout (Fallback for V1)
INSERT INTO layouts (mode, version, platform, is_active, layout_json, culture_tags)
VALUES (
    'beauty',
    '1.0.0',
    'all',
    true,
    '[
        {"type": "header", "config": {"title": "Beauty & Care", "subtitle": "Nourish your natural glow"}},
        {"type": "routine_progress", "config": {"title": "Weekly Routine", "completed": 3, "total": 5}},
        {"type": "skin_hair_status", "config": {"title": "Current Focus", "metric": "Hydration", "value": "Good"}},
        {"type": "quick_actions", "config": {"items": ["log_routine", "scan_product", "remedy_finder"]}},
        {"type": "cultural_spotlight", "config": {"title": "Traditional Remedy", "item": "Shea Butter"}}
    ]'::jsonb,
    ARRAY['global', 'natural_hair']
);
