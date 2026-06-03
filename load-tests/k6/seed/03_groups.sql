-- 03_groups.sql
-- Seeds 20 community groups with 25 members each.
-- Correct schema: community_group / group_member (not groups / group_members).
-- community_group.creator_id references user_profile.id.
-- group_member.user_id references user_profile.id.
--
-- First group gets a known deterministic UUID so community.js can reference it:
--   '00000000-0000-0000-0000-000000000010'

BEGIN;

DO $$
DECLARE
  g           INT;
  m           INT;
  group_id    uuid;
  known_group uuid := '00000000-0000-0000-0000-000000000010';
  owner_id    uuid;
  member_id   uuid;
BEGIN
  -- Use first available user_profile as group creator
  SELECT id INTO owner_id FROM user_profile LIMIT 1;

  IF owner_id IS NULL THEN
    RAISE EXCEPTION '02_users.sql must run before 03_groups.sql';
  END IF;

  FOR g IN 1..20 LOOP
    group_id := CASE WHEN g = 1 THEN known_group ELSE gen_random_uuid() END;

    INSERT INTO community_group (id, name, description, creator_id, is_public)
    VALUES (
      group_id,
      'Load Test Group ' || g,
      'Synthetic group for load testing',
      owner_id,
      true
    )
    ON CONFLICT (id) DO NOTHING;

    -- Add 25 members using real user_profile rows (required FK)
    FOR m IN 1..25 LOOP
      SELECT id INTO member_id
      FROM user_profile
      ORDER BY created_at
      OFFSET ((g - 1) * 25 + m - 1) % 500
      LIMIT 1;

      IF member_id IS NOT NULL THEN
        INSERT INTO group_member (group_id, user_id, role)
        VALUES (group_id, member_id, 'member')
        ON CONFLICT (group_id, user_id) DO NOTHING;
      END IF;
    END LOOP;
  END LOOP;
END $$;

COMMIT;
