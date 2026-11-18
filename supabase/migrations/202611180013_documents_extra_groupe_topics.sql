-- BOROOM YITTÉ YU KAWÉ YI: Documentary Library, Faithful Summaries,
-- Structured Reflection Proposals & Extra Groupe Monthly Guest Encounters.

CREATE TABLE IF NOT EXISTS library_documents (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  title text NOT NULL,
  description text NOT NULL DEFAULT '',
  domain text NOT NULL,
  subcategory text NOT NULL,
  author_or_contributor text NOT NULL DEFAULT '',
  source_reference text NOT NULL DEFAULT '',
  published_date_label text,
  keywords text[] NOT NULL DEFAULT '{}',
  language_code text NOT NULL DEFAULT 'fr',
  file_name text NOT NULL DEFAULT '',
  file_format text NOT NULL DEFAULT 'txt',
  file_size_bytes integer NOT NULL DEFAULT 0,
  storage_path text,
  extracted_text text,
  unreadable_warning text,
  is_private boolean NOT NULL DEFAULT false,
  validation_status text NOT NULL DEFAULT 'pending' CHECK (validation_status IN ('pending', 'validated', 'rejected')),
  view_count integer NOT NULL DEFAULT 0,
  uploaded_by uuid REFERENCES profiles(id) ON DELETE SET NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS document_summaries (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  document_id uuid NOT NULL REFERENCES library_documents(id) ON DELETE CASCADE,
  general_summary text NOT NULL,
  main_ideas text[] NOT NULL DEFAULT '{}',
  important_concepts text[] NOT NULL DEFAULT '{}',
  definitions text[] NOT NULL DEFAULT '{}',
  developed_arguments text[] NOT NULL DEFAULT '{}',
  author_conclusions text[] NOT NULL DEFAULT '{}',
  cited_references text[] NOT NULL DEFAULT '{}',
  comprehension_questions text[] NOT NULL DEFAULT '{}',
  unreadable_notices text[] NOT NULL DEFAULT '{}',
  is_ai_assisted boolean NOT NULL DEFAULT true,
  status text NOT NULL DEFAULT 'draft' CHECK (status IN ('draft', 'validated')),
  reviewed_by uuid REFERENCES profiles(id) ON DELETE SET NULL,
  reviewed_at timestamptz,
  created_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT summary_requires_validation CHECK (
    status <> 'validated' OR (reviewed_by IS NOT NULL AND reviewed_at IS NOT NULL)
  )
);

CREATE TABLE IF NOT EXISTS extra_groupe_guests (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name text NOT NULL,
  title_or_role text NOT NULL DEFAULT '',
  biography text NOT NULL DEFAULT '',
  expertise_domains text[] NOT NULL DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS extra_groupe_meetings (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  guest_id uuid REFERENCES extra_groupe_guests(id) ON DELETE SET NULL,
  guest_name text NOT NULL,
  theme text NOT NULL,
  presentation_text text NOT NULL,
  context_notes text NOT NULL DEFAULT '',
  objectives text[] NOT NULL DEFAULT '{}',
  program_items text[] NOT NULL DEFAULT '{}',
  scheduled_at timestamptz NOT NULL,
  practical_info text NOT NULL DEFAULT '',
  status text NOT NULL DEFAULT 'upcoming' CHECK (status IN ('upcoming', 'live', 'archived')),
  recording_authorized boolean NOT NULL DEFAULT false,
  meeting_report text,
  linked_document_ids uuid[] NOT NULL DEFAULT '{}',
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS extra_groupe_questions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  meeting_id uuid NOT NULL REFERENCES extra_groupe_meetings(id) ON DELETE CASCADE,
  author_name text NOT NULL,
  question_text text NOT NULL,
  answer_text text,
  is_prepared boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS extra_groupe_participants (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  meeting_id uuid NOT NULL REFERENCES extra_groupe_meetings(id) ON DELETE CASCADE,
  profile_id uuid REFERENCES profiles(id) ON DELETE CASCADE,
  member_name text NOT NULL,
  roster_private boolean NOT NULL DEFAULT true,
  created_at timestamptz NOT NULL DEFAULT now()
);

DO $$
DECLARE tbl text;
BEGIN
  FOREACH tbl IN ARRAY ARRAY[
    'library_documents',
    'document_summaries',
    'extra_groupe_guests',
    'extra_groupe_meetings',
    'extra_groupe_questions',
    'extra_groupe_participants'
  ]
  LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY', tbl);
  END LOOP;
END $$;

CREATE POLICY library_documents_read_policy ON library_documents
  FOR SELECT USING (
    (NOT is_private AND validation_status = 'validated')
    OR uploaded_by = auth.uid()
    OR EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role IN ('admin', 'super_admin', 'editor'))
  );

CREATE POLICY library_documents_write_policy ON library_documents
  FOR INSERT WITH CHECK (auth.uid() IS NOT NULL);

CREATE POLICY document_summaries_read_policy ON document_summaries
  FOR SELECT USING (
    status = 'validated'
    OR EXISTS (
      SELECT 1 FROM library_documents d
      WHERE d.id = document_id AND d.uploaded_by = auth.uid()
    )
    OR EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role IN ('admin', 'super_admin', 'editor'))
  );

CREATE POLICY extra_groupe_meetings_member_read ON extra_groupe_meetings
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY extra_groupe_guests_member_read ON extra_groupe_guests
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY extra_groupe_questions_member_read ON extra_groupe_questions
  FOR SELECT USING (auth.uid() IS NOT NULL);

CREATE POLICY extra_groupe_participants_restricted ON extra_groupe_participants
  FOR SELECT USING (
    (NOT roster_private AND auth.uid() IS NOT NULL)
    OR profile_id = auth.uid()
    OR EXISTS (SELECT 1 FROM profiles p WHERE p.id = auth.uid() AND p.role IN ('admin', 'super_admin'))
  );
