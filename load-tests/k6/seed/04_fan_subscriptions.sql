-- 04_fan_subscriptions.sql
-- Seed script for 50 fan subscriptions for a test creator

BEGIN;

DO $$
DECLARE
    i INT;
    creator_id UUID := '00000000-0000-0000-0000-000000000001'; -- fixed creator ID for test
    fan_id UUID;
BEGIN
    -- Ensure creator exists
    INSERT INTO public.profiles (id, email, display_name, is_creator)
    VALUES (creator_id, 'creator@akeli.local', 'Test Creator', true)
    ON CONFLICT (id) DO NOTHING;

    FOR i IN 1..50 LOOP
        fan_id := uuid_generate_v4();
        
        INSERT INTO public.fan_subscriptions (creator_id, fan_id, status)
        VALUES (creator_id, fan_id, 'active');
    END LOOP;
END $$;

COMMIT;
