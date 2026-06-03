CREATE TABLE group_invite (
  id           uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id     uuid NOT NULL REFERENCES community_group(id) ON DELETE CASCADE,
  inviter_id   uuid NOT NULL REFERENCES user_profile(id),
  invitee_id   uuid NOT NULL REFERENCES user_profile(id),
  status       text NOT NULL DEFAULT 'pending'
               CHECK (status IN ('pending', 'accepted', 'declined')),
  created_at   timestamptz DEFAULT now(),
  UNIQUE (group_id, invitee_id)
);

ALTER TABLE group_invite ENABLE ROW LEVEL SECURITY;

-- Admin can insert invites for groups they manage
CREATE POLICY "admin inserts invites" ON group_invite
  FOR INSERT WITH CHECK (
    inviter_id = auth.uid() AND
    EXISTS (
      SELECT 1 FROM group_member
      WHERE group_member.group_id = group_invite.group_id
        AND group_member.user_id = auth.uid()
        AND group_member.role = 'admin'
    )
  );

-- Invitee and inviter can read their rows
CREATE POLICY "participant reads invites" ON group_invite
  FOR SELECT USING (
    invitee_id = auth.uid() OR inviter_id = auth.uid()
  );

-- Invitee can update status of their pending invite
CREATE POLICY "invitee updates invite" ON group_invite
  FOR UPDATE USING (invitee_id = auth.uid());

-- RPC to accept invite
CREATE OR REPLACE FUNCTION accept_group_invite(p_invite_id uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_invite RECORD;
  v_conversation_id uuid;
BEGIN
  -- 1. Validate invite
  SELECT * INTO v_invite
  FROM group_invite
  WHERE id = p_invite_id AND invitee_id = auth.uid() AND status = 'pending';

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Invite not found, already processed, or permission denied';
  END IF;

  -- 2. Update status
  UPDATE group_invite
  SET status = 'accepted'
  WHERE id = p_invite_id;

  -- 3. Insert into group_member (idempotent ON CONFLICT)
  INSERT INTO group_member(group_id, user_id, role)
  VALUES (v_invite.group_id, auth.uid(), 'member')
  ON CONFLICT (group_id, user_id) DO NOTHING;

  -- 4. Get conversation ID
  SELECT id INTO v_conversation_id
  FROM conversation
  WHERE community_group_id = v_invite.group_id;

  -- 5. Insert into conversation_participant
  IF v_conversation_id IS NOT NULL THEN
    INSERT INTO conversation_participant(conversation_id, user_id)
    VALUES (v_conversation_id, auth.uid())
    ON CONFLICT (conversation_id, user_id) DO NOTHING;
  END IF;

  -- 6. Return group_id for navigation
  RETURN v_invite.group_id;
END;
$$;
