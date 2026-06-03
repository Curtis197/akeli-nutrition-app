-- =============================================================================
-- Migration: 20260531000005_fix_get_user_group_ids_rls_recursion.sql
-- Description: Fix infinite recursion (42P17) on group_member.
--              "group members read other members" SELECT policy calls
--              _get_user_group_ids() which queries group_member, re-triggering
--              the policy. SECURITY DEFINER + postgres owner should bypass RLS,
--              but Supabase's hosted env can still evaluate RLS for SQL-language
--              functions via plan caching. Adding SET row_security = off as a
--              function attribute explicitly disables RLS for each call scope.
-- =============================================================================

CREATE OR REPLACE FUNCTION _get_user_group_ids(uid uuid)
RETURNS SETOF uuid
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_temp
SET row_security = off
AS $$
  SELECT group_id FROM group_member WHERE user_id = uid;
$$;
