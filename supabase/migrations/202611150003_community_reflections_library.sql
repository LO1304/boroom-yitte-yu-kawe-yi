-- ============================================================================
-- Migration 0003: Reflections, Comments, Reactions, Weekly Topics & Library
-- ============================================================================

CREATE TABLE reflections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  author_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL CHECK (char_length(title) BETWEEN 3 AND 180),
  body TEXT NOT NULL CHECK (char_length(body) >= 10),
  category challenge_category NOT NULL DEFAULT 'philosophy',
  language app_language NOT NULL DEFAULT 'fr',
  tags TEXT[] NOT NULL DEFAULT '{}',
  attachment_url TEXT,
  attachment_name TEXT,
  attachment_mime TEXT,
  is_pinned BOOLEAN NOT NULL DEFAULT FALSE,
  is_featured_in_library BOOLEAN NOT NULL DEFAULT FALSE,
  is_hidden BOOLEAN NOT NULL DEFAULT FALSE,
  comments_count INTEGER NOT NULL DEFAULT 0,
  reactions_count INTEGER NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_reflections_author ON reflections (author_id, created_at DESC);
CREATE INDEX idx_reflections_category ON reflections (category, created_at DESC);
CREATE INDEX idx_reflections_library ON reflections (is_featured_in_library) WHERE is_featured_in_library = TRUE;

CREATE TRIGGER trg_reflections_updated_at
  BEFORE UPDATE ON reflections
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE saved_reflections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  reflection_id UUID NOT NULL REFERENCES reflections(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, reflection_id)
);

CREATE TABLE comments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  reflection_id UUID NOT NULL REFERENCES reflections(id) ON DELETE CASCADE,
  author_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  parent_comment_id UUID REFERENCES comments(id) ON DELETE CASCADE,
  body TEXT NOT NULL CHECK (char_length(body) BETWEEN 1 AND 4000),
  is_hidden BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_comments_reflection ON comments (reflection_id, created_at ASC);
CREATE INDEX idx_comments_parent ON comments (parent_comment_id);

CREATE TRIGGER trg_comments_updated_at
  BEFORE UPDATE ON comments
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE reactions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  reflection_id UUID REFERENCES reflections(id) ON DELETE CASCADE,
  comment_id UUID REFERENCES comments(id) ON DELETE CASCADE,
  reaction_type TEXT NOT NULL CHECK (reaction_type IN ('insightful', 'beneficial', 'inspiring', 'question', 'support')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (
    (reflection_id IS NOT NULL AND comment_id IS NULL) OR
    (reflection_id IS NULL AND comment_id IS NOT NULL)
  )
);

CREATE UNIQUE INDEX uq_reactions_user_reflection ON reactions (user_id, reflection_id, reaction_type) WHERE reflection_id IS NOT NULL;
CREATE UNIQUE INDEX uq_reactions_user_comment ON reactions (user_id, comment_id, reaction_type) WHERE comment_id IS NOT NULL;

CREATE TABLE weekly_topics (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  week_number INTEGER NOT NULL,
  year INTEGER NOT NULL,
  title TEXT NOT NULL CHECK (char_length(title) BETWEEN 5 AND 200),
  introduction TEXT NOT NULL,
  guiding_questions JSONB NOT NULL DEFAULT '[]'::jsonb,
  category challenge_category NOT NULL DEFAULT 'islamic_thought',
  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  starts_at TIMESTAMPTZ NOT NULL,
  ends_at TIMESTAMPTZ NOT NULL,
  is_archived BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (ends_at > starts_at),
  UNIQUE (week_number, year)
);

CREATE INDEX idx_weekly_topics_active ON weekly_topics (is_archived, starts_at DESC);

CREATE TRIGGER trg_weekly_topics_updated_at
  BEFORE UPDATE ON weekly_topics
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE topic_contributions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  topic_id UUID NOT NULL REFERENCES weekly_topics(id) ON DELETE CASCADE,
  author_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  question_index INTEGER,
  content TEXT NOT NULL CHECK (char_length(content) >= 15),
  supporting_references TEXT[] NOT NULL DEFAULT '{}',
  is_highlighted BOOLEAN NOT NULL DEFAULT FALSE,
  is_hidden BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_topic_contributions_topic ON topic_contributions (topic_id, created_at ASC);

CREATE TRIGGER trg_topic_contributions_updated_at
  BEFORE UPDATE ON topic_contributions
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- AI-assisted summaries MUST be reviewed by an authorized editor before publication
CREATE TABLE summaries (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  weekly_topic_id UUID REFERENCES weekly_topics(id) ON DELETE CASCADE,
  reflection_id UUID REFERENCES reflections(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  summary_markdown TEXT NOT NULL,
  key_takeaways JSONB NOT NULL DEFAULT '[]'::jsonb,
  verified_references JSONB NOT NULL DEFAULT '[]'::jsonb,
  generated_by_ai BOOLEAN NOT NULL DEFAULT TRUE,
  ai_model TEXT,
  status review_status NOT NULL DEFAULT 'pending_review',
  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  reviewed_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  review_notes TEXT,
  reviewed_at TIMESTAMPTZ,
  published_at TIMESTAMPTZ,
  pdf_storage_path TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  -- Enforce invariant: published summaries must have an editor review
  CHECK (status <> 'published' OR (reviewed_by IS NOT NULL AND reviewed_at IS NOT NULL))
);

CREATE INDEX idx_summaries_status ON summaries (status, created_at DESC);
CREATE INDEX idx_summaries_topic ON summaries (weekly_topic_id);

CREATE TRIGGER trg_summaries_updated_at
  BEFORE UPDATE ON summaries
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE digital_library_items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  category challenge_category NOT NULL,
  source_reflection_id UUID REFERENCES reflections(id) ON DELETE SET NULL,
  source_summary_id UUID REFERENCES summaries(id) ON DELETE SET NULL,
  document_url TEXT,
  curated_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  language app_language NOT NULL DEFAULT 'fr',
  tags TEXT[] NOT NULL DEFAULT '{}',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_library_category ON digital_library_items (category, created_at DESC);
