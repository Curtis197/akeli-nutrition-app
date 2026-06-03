-- community_group: authenticated users can create groups
CREATE POLICY "authenticated user creates group" ON community_group
  FOR INSERT WITH CHECK (creator_id = auth.uid() AND auth.uid() IS NOT NULL);

-- community_group: creator can update their own groups
CREATE POLICY "creator updates group" ON community_group
  FOR UPDATE USING (creator_id = auth.uid());

-- group_member: users can insert their own membership
CREATE POLICY "user inserts own membership" ON group_member
  FOR INSERT WITH CHECK (user_id = auth.uid());
