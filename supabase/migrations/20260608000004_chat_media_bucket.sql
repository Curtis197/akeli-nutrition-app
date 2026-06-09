-- ============================================================
-- chat_media storage bucket
-- Public read, user-scoped write (path must start with auth.uid())
-- File size limit: 10 MB, images only
-- ============================================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'chat_media',
  'chat_media',
  true,
  10485760,
  ARRAY['image/jpeg','image/png','image/webp','image/gif']
)
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "authenticated upload chat_media"
  ON storage.objects FOR INSERT TO authenticated
  WITH CHECK (
    bucket_id = 'chat_media'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );

CREATE POLICY "public read chat_media"
  ON storage.objects FOR SELECT
  USING (bucket_id = 'chat_media');

CREATE POLICY "owner delete chat_media"
  ON storage.objects FOR DELETE TO authenticated
  USING (
    bucket_id = 'chat_media'
    AND (storage.foldername(name))[1] = auth.uid()::text
  );
