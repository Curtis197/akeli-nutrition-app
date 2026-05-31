-- =============================================================================
-- Migration: 20260531100037_fix_community_group_rls_recursion.sql
-- Description: Fix infinite recursion (42P17) when creating a group.
--              The "member reads private groups" SELECT policy on community_group
--              queried group_member directly, which queried community_group, 
--              causing a cycle on group_member INSERTs. 
--              Fixed by reusing the existing _get_user_group_ids() function 
--              which sets row_security = off to safely break the dependency loop.
-- =============================================================================

DROP POLICY IF EXISTS "member reads private groups" ON public.community_group;

CREATE POLICY "member reads private groups" ON public.community_group
FOR SELECT USING (
  id IN (SELECT _get_user_group_ids(auth.uid()))
);
