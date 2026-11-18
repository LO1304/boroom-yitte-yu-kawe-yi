-- ============================================================================
-- Migration 0012: Storage Buckets & Policies
-- Private audio recordings (consent-gated), avatars, community documents & PDFs
-- ============================================================================

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES
  ('voice-recordings', 'voice-recordings', FALSE, 52428800, ARRAY['audio/mp4', 'audio/m4a', 'audio/aac', 'audio/mpeg', 'audio/wav', 'audio/webm', 'audio/ogg']),
  ('community-documents', 'community-documents', FALSE, 26214400, ARRAY['application/pdf', 'text/plain', 'text/markdown', 'image/png', 'image/jpeg']),
  ('avatars', 'avatars', TRUE, 5242880, ARRAY['image/png', 'image/jpeg', 'image/webp']),
  ('summary-pdfs', 'summary-pdfs', TRUE, 15728640, ARRAY['application/pdf'])
ON CONFLICT (id) DO NOTHING;

CREATE POLICY "voice_recordings_owner_upload" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'voice-recordings' AND auth.uid()::TEXT = (storage.foldername(name))[1]);

CREATE POLICY "voice_recordings_owner_read" ON storage.objects
  FOR SELECT TO authenticated
  USING (bucket_id = 'voice-recordings' AND (auth.uid()::TEXT = (storage.foldername(name))[1] OR is_moderator_or_above()));

CREATE POLICY "voice_recordings_owner_delete" ON storage.objects
  FOR DELETE TO authenticated
  USING (bucket_id = 'voice-recordings' AND (auth.uid()::TEXT = (storage.foldername(name))[1] OR is_admin_or_above()));

CREATE POLICY "community_docs_read" ON storage.objects
  FOR SELECT TO authenticated
  USING (bucket_id = 'community-documents');

CREATE POLICY "community_docs_upload" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'community-documents' AND auth.uid()::TEXT = (storage.foldername(name))[1]);

CREATE POLICY "avatars_public_read" ON storage.objects
  FOR SELECT TO public USING (bucket_id = 'avatars');

CREATE POLICY "avatars_owner_write" ON storage.objects
  FOR INSERT TO authenticated
  WITH CHECK (bucket_id = 'avatars' AND auth.uid()::TEXT = (storage.foldername(name))[1]);

CREATE POLICY "summary_pdfs_public_read" ON storage.objects
  FOR SELECT TO public USING (bucket_id = 'summary-pdfs');
