-- Add screenshot_url column
ALTER TABLE support_message ADD COLUMN screenshot_url text;

-- Create support-screenshots bucket (public so support staff can view via URL)
INSERT INTO storage.buckets (id, name, public)
VALUES ('support-screenshots', 'support-screenshots', true)
ON CONFLICT (id) DO NOTHING;

-- Authenticated users can upload only into their own user_id subfolder
CREATE POLICY "users upload own support screenshots"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (
  bucket_id = 'support-screenshots'
  AND (storage.foldername(name))[1] = (auth.uid())::text
);

-- Public can read (bucket is public, support staff need the URL)
CREATE POLICY "public reads support screenshots"
ON storage.objects FOR SELECT
USING (bucket_id = 'support-screenshots');
