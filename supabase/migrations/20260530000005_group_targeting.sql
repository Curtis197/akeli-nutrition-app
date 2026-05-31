-- Migration: add targeting columns to community_group
ALTER TABLE community_group
  ADD COLUMN region_code text REFERENCES food_region(code),
  ADD COLUMN language    text,
  ADD COLUMN topic       text CHECK (topic IN (
                           'cuisine_africaine', 'batch_cooking', 'nutrition',
                           'sport_forme', 'perte_de_poids', 'vegetarien', 'autre'
                         )),
  ADD COLUMN max_members int;  -- null = unlimited

-- Migration: member_count triggers
CREATE OR REPLACE FUNCTION _increment_group_member_count()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  UPDATE community_group SET member_count = member_count + 1 WHERE id = NEW.group_id;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION _decrement_group_member_count()
RETURNS TRIGGER LANGUAGE plpgsql AS $$
BEGIN
  UPDATE community_group SET member_count = GREATEST(member_count - 1, 0) WHERE id = OLD.group_id;
  RETURN OLD;
END;
$$;

DROP TRIGGER IF EXISTS trg_group_member_count_inc ON group_member;
CREATE TRIGGER trg_group_member_count_inc
  AFTER INSERT ON group_member
  FOR EACH ROW EXECUTE FUNCTION _increment_group_member_count();

DROP TRIGGER IF EXISTS trg_group_member_count_dec ON group_member;
CREATE TRIGGER trg_group_member_count_dec
  AFTER DELETE ON group_member
  FOR EACH ROW EXECUTE FUNCTION _decrement_group_member_count();

-- New RLS policy: instant join for public groups
CREATE POLICY "user joins public group" ON group_member
  FOR INSERT WITH CHECK (
    user_id = auth.uid() AND
    EXISTS (
      SELECT 1 FROM community_group cg
      WHERE cg.id = group_member.group_id
        AND cg.is_public = true
        AND (cg.max_members IS NULL OR cg.member_count < cg.max_members)
    )
  );
