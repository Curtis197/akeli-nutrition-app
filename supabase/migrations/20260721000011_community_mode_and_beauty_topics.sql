-- Migration: Community Mode Isolation and Beauty Starter Groups
-- File: supabase/migrations/20260721000011_community_mode_and_beauty_topics.sql

-- 1. Add mode column to community_group and conversation tables
ALTER TABLE community_group ADD COLUMN IF NOT EXISTS "mode" VARCHAR(20) DEFAULT 'nutrition';
ALTER TABLE conversation ADD COLUMN IF NOT EXISTS "mode" VARCHAR(20) DEFAULT 'nutrition';

-- Index for fast mode filtering
CREATE INDEX IF NOT EXISTS idx_community_group_mode ON community_group("mode");
CREATE INDEX IF NOT EXISTS idx_conversation_mode ON conversation("mode");

-- 2. Update community_group_topic_check constraint to include beauty topics
ALTER TABLE community_group DROP CONSTRAINT IF EXISTS community_group_topic_check;
ALTER TABLE community_group ADD CONSTRAINT community_group_topic_check 
CHECK (topic = ANY (ARRAY[
    'cuisine_africaine'::text, 'batch_cooking'::text, 'nutrition'::text, 'sport_forme'::text, 'perte_de_poids'::text, 'vegetarien'::text, 'autre'::text,
    'chebe_care'::text, 'skin_routine'::text, 'hair_growth'::text, 'natural_diy'::text, 'scalp_health'::text
]));

-- 3. Re-create v_community_group view to include mode
DROP VIEW IF EXISTS v_community_group CASCADE;

CREATE VIEW v_community_group AS
SELECT 
    cg.id,
    cg.name,
    cg.description,
    cg.cover_url,
    cg.creator_id,
    cg.is_public,
    cg.member_count,
    cg.region_code,
    cg.language,
    cg.topic,
    cg."mode" AS app_mode,
    cg.created_at,
    cg.updated_at
FROM community_group cg;

-- 4. Seed Beauty Starter Groups
INSERT INTO community_group (id, name, description, "mode", topic, language, is_public, member_count)
VALUES 
    (
        'c0000001-0000-0000-0000-000000000001'::uuid,
        'Secret du Chébé & Pousse 4C',
        'Communauté dédiée à la pousse des cheveux crépus, aux recettes au beurre de karité et poudre de chébé.',
        'beauty',
        'chebe_care',
        'fr',
        true,
        142
    ),
    (
        'c0000002-0000-0000-0000-000000000002'::uuid,
        'Routine Peaux Claires & Bio DIY',
        'Échanges sur les toniques à l''aloé véra, hibiscus et masques désincrustants à l''argile verte.',
        'beauty',
        'skin_routine',
        'fr',
        true,
        98
    ),
    (
        'c0000003-0000-0000-0000-000000000003'::uuid,
        'Bains d''Huiles & Santé du Cuir Chevelu',
        'Conseils et recettes de sérums stimulants à l''huile de ricin et d''argan pressée à froid.',
        'beauty',
        'scalp_health',
        'fr',
        true,
        75
    )
ON CONFLICT (id) DO NOTHING;
