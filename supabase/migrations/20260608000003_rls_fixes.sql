-- ============================================================
-- RLS Fixes
-- 1. support_message: add INSERT policy (was missing — app broken)
-- 2. conversation: drop 2 redundant SELECT policies, keep the one
--    that also covers creator_group type discovery
-- 3. food_region: drop duplicate SELECT policy
-- ============================================================

-- 1. support_message INSERT — authenticated users may insert their own messages
DROP POLICY IF EXISTS "authenticated inserts support_message" ON public.support_message;
CREATE POLICY "authenticated inserts support_message"
  ON public.support_message
  FOR INSERT
  TO authenticated
  WITH CHECK (
    auth.uid() IS NOT NULL
    AND (user_id IS NULL OR user_id = auth.uid())
  );

-- 2. conversation — drop the two plain-participant duplicates;
--    keep "participants read own conversations" which covers both
--    participant-scoped rows AND creator_group type discovery.
DROP POLICY IF EXISTS "participant reads" ON public.conversation;
DROP POLICY IF EXISTS "participants read own conversations" ON public.conversation;

-- 3. food_region — drop the older duplicate
DROP POLICY IF EXISTS "allow_select_food_region" ON public.food_region;
