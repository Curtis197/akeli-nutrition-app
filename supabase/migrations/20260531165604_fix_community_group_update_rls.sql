-- Migration: 20260531165604_fix_community_group_update_rls.sql
-- Description: Re-add the UPDATE policy for community_group which was missing from the DB.

DROP POLICY IF EXISTS "creator updates group" ON public.community_group;

CREATE POLICY "creator updates group" ON public.community_group
FOR UPDATE USING (
  creator_id = auth.uid()
);
