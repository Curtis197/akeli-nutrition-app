
-- Create the group_covers bucket
INSERT INTO storage.buckets (id, name, public) 
VALUES ('group_covers', 'group_covers', true)
ON CONFLICT (id) DO NOTHING;

-- Storage Policy: Public Read
CREATE POLICY "public reads group_covers" ON storage.objects
FOR SELECT USING (bucket_id = 'group_covers');

-- Storage Policy: Authenticated Upload
CREATE POLICY "authenticated inserts group_covers" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'group_covers' AND auth.uid() = owner
);

-- Storage Policy: Owner Update
CREATE POLICY "owner updates group_covers" ON storage.objects
FOR UPDATE USING (
  bucket_id = 'group_covers' AND auth.uid() = owner
);

-- Storage Policy: Owner Delete
CREATE POLICY "owner deletes group_covers" ON storage.objects
FOR DELETE USING (
  bucket_id = 'group_covers' AND auth.uid() = owner
);
