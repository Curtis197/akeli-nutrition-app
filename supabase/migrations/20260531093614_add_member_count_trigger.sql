-- Create trigger function to update community_group.member_count
CREATE OR REPLACE FUNCTION public.update_community_group_member_count()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE public.community_group
    SET member_count = COALESCE(member_count, 0) + 1
    WHERE id = NEW.group_id;
    RETURN NEW;
  ELSIF TG_OP = 'DELETE' THEN
    UPDATE public.community_group
    SET member_count = GREATEST(COALESCE(member_count, 0) - 1, 0)
    WHERE id = OLD.group_id;
    RETURN OLD;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Secure the function
REVOKE ALL ON FUNCTION public.update_community_group_member_count() FROM PUBLIC;

-- Create the trigger
DROP TRIGGER IF EXISTS tr_group_member_count ON public.group_member;
CREATE TRIGGER tr_group_member_count
AFTER INSERT OR DELETE ON public.group_member
FOR EACH ROW EXECUTE FUNCTION public.update_community_group_member_count();

-- Backfill existing counts
UPDATE public.community_group cg
SET member_count = (
  SELECT count(*)
  FROM public.group_member gm
  WHERE gm.group_id = cg.id
);
