-- Fix: update_group_member_count runs inside a trigger without an auth JWT context,
-- so auth.uid() is NULL and RLS filters out all group_member rows, making COUNT(*) = 0.
-- Making the function SECURITY DEFINER lets it bypass RLS and count correctly.

CREATE OR REPLACE FUNCTION update_group_member_count()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  target_group_id uuid;
BEGIN
  target_group_id := COALESCE(NEW.group_id, OLD.group_id);

  UPDATE community_group SET member_count = (
    SELECT COUNT(*) FROM group_member WHERE group_id = target_group_id
  ) WHERE id = target_group_id;

  RETURN COALESCE(NEW, OLD);
END;
$$;
