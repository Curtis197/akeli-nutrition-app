-- Replace the incremental trigger with a live-computed member_count view.
-- The trigger approach drifts when rows are deleted outside its scope.

-- 1. Drop old trigger and maintenance function
DROP TRIGGER IF EXISTS tr_group_member_count ON public.group_member;
DROP FUNCTION IF EXISTS public.update_community_group_member_count();

-- 2. SECURITY DEFINER helper: always returns the true count regardless of
--    the caller's group_member RLS (needed for non-members viewing public groups)
CREATE OR REPLACE FUNCTION public.get_group_member_count(p_group_id uuid)
RETURNS int
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT COUNT(*)::int FROM group_member WHERE group_id = p_group_id;
$$;

REVOKE ALL ON FUNCTION public.get_group_member_count(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.get_group_member_count(uuid) TO authenticated, anon;

-- 3. View: same shape as the table but member_count is always live
CREATE OR REPLACE VIEW public.v_community_group
WITH (security_invoker = on)
AS
SELECT
  id,
  name,
  description,
  cover_url,
  creator_id,
  is_public,
  created_at,
  updated_at,
  region_code,
  language,
  topic,
  max_members,
  public.get_group_member_count(id) AS member_count
FROM public.community_group;

GRANT SELECT ON public.v_community_group TO authenticated, anon;
REVOKE INSERT, UPDATE, DELETE, TRUNCATE, REFERENCES, TRIGGER
  ON public.v_community_group FROM authenticated, anon;
