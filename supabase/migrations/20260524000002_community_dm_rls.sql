-- supabase/migrations/20260524000002_community_dm_rls.sql
-- Fix RLS gaps required by the Community DM feature.
-- Uses SECURITY DEFINER helpers to avoid RLS infinite recursion on self-referencing tables.

-- ── Helper functions (SECURITY DEFINER bypasses RLS in subqueries) ───────────

CREATE OR REPLACE FUNCTION _get_user_conversation_ids(uid uuid)
RETURNS SETOF uuid
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT conversation_id FROM conversation_participant WHERE user_id = uid;
$$;

CREATE OR REPLACE FUNCTION _get_user_group_ids(uid uuid)
RETURNS SETOF uuid
LANGUAGE sql
SECURITY DEFINER
STABLE
SET search_path = public
AS $$
  SELECT group_id FROM group_member WHERE user_id = uid;
$$;

-- ── Policies ─────────────────────────────────────────────────────────────────

-- 1. conversation: allow participants to SELECT conversations they belong to
DROP POLICY IF EXISTS "participant reads own conversations" ON conversation;
CREATE POLICY "participant reads own conversations" ON conversation
  FOR SELECT
  USING (
    id IN (SELECT _get_user_conversation_ids(auth.uid()))
  );

-- 2. conversation: allow authenticated users to INSERT new conversations
DROP POLICY IF EXISTS "authenticated user creates conversation" ON conversation;
CREATE POLICY "authenticated user creates conversation" ON conversation
  FOR INSERT
  WITH CHECK (auth.uid() = created_by);

-- 3. conversation_participant: allow participants to see ALL rows in
--    conversations they belong to (SECURITY DEFINER helper avoids recursion)
DROP POLICY IF EXISTS "participants read all rows in shared conversations" ON conversation_participant;
CREATE POLICY "participants read all rows in shared conversations" ON conversation_participant
  FOR SELECT
  USING (
    conversation_id IN (SELECT _get_user_conversation_ids(auth.uid()))
  );

-- 4. group_member: allow members to read other members of their groups
--    (SECURITY DEFINER helper avoids recursion)
DROP POLICY IF EXISTS "group members read other members" ON group_member;
CREATE POLICY "group members read other members" ON group_member
  FOR SELECT
  USING (
    group_id IN (SELECT _get_user_group_ids(auth.uid()))
  );

-- 5. conversation_request: fix wrong column names from previous policy,
--    split into per-operation policies with correct checks
DROP POLICY IF EXISTS "participant reads conversation_request" ON conversation_request;
DROP POLICY IF EXISTS "requester inserts conversation_request" ON conversation_request;
DROP POLICY IF EXISTS "participant updates conversation_request" ON conversation_request;

CREATE POLICY "participant reads conversation_request" ON conversation_request
  FOR SELECT
  USING (auth.uid() = requester_id OR auth.uid() = recipient_id);

CREATE POLICY "requester inserts conversation_request" ON conversation_request
  FOR INSERT
  WITH CHECK (auth.uid() = requester_id);

CREATE POLICY "participant updates conversation_request" ON conversation_request
  FOR UPDATE
  USING (auth.uid() = requester_id OR auth.uid() = recipient_id);
