-- ============================================================================
-- Migration 0008: YITTÉ PROFESSIONAL & YITTÉ PERSONAL GROWTH
-- Private personal growth entities are strictly isolated to owner_id via RLS.
-- ============================================================================

CREATE TABLE career_profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL UNIQUE REFERENCES profiles(id) ON DELETE CASCADE,
  headline TEXT DEFAULT '',
  target_role TEXT DEFAULT '',
  career_domain TEXT DEFAULT 'technology',
  skills TEXT[] NOT NULL DEFAULT '{}',
  certifications JSONB NOT NULL DEFAULT '[]'::jsonb,
  cv_summary_text TEXT DEFAULT '',
  cv_ai_feedback JSONB,
  cover_letter_draft TEXT DEFAULT '',
  cover_letter_feedback JSONB,
  portfolio_projects JSONB NOT NULL DEFAULT '[]'::jsonb,
  open_to_opportunities BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TRIGGER trg_career_profiles_updated_at
  BEFORE UPDATE ON career_profiles
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE career_opportunities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  organization TEXT NOT NULL,
  opportunity_type TEXT NOT NULL CHECK (opportunity_type IN ('job', 'internship', 'certification', 'mentorship', 'workshop')),
  domain TEXT NOT NULL,
  location TEXT NOT NULL DEFAULT 'Remote / Hybrid',
  description TEXT NOT NULL,
  apply_url TEXT,
  deadline TIMESTAMPTZ,
  posted_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE mock_interviews (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  target_role TEXT NOT NULL,
  focus_domain TEXT NOT NULL,
  language app_language NOT NULL DEFAULT 'fr',
  interview_turns JSONB NOT NULL DEFAULT '[]'::jsonb,
  recording_id UUID REFERENCES voice_recordings(id) ON DELETE SET NULL,
  overall_score NUMERIC(5,2) CHECK (overall_score >= 0 AND overall_score <= 100),
  ai_feedback JSONB,
  status TEXT NOT NULL DEFAULT 'in_progress' CHECK (status IN ('in_progress', 'completed')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_mock_interviews_user ON mock_interviews (user_id, created_at DESC);

CREATE TRIGGER trg_mock_interviews_updated_at
  BEFORE UPDATE ON mock_interviews
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Personal Growth (strictly private to user_id)
CREATE TABLE personal_goals (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT DEFAULT '',
  horizon TEXT NOT NULL DEFAULT 'weekly' CHECK (horizon IN ('daily', 'weekly', 'monthly', 'quarterly')),
  category TEXT NOT NULL DEFAULT 'discipline',
  target_date DATE,
  progress_percent INTEGER NOT NULL DEFAULT 0 CHECK (progress_percent BETWEEN 0 AND 100),
  status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'completed', 'paused')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_personal_goals_user ON personal_goals (user_id, status);

CREATE TRIGGER trg_personal_goals_updated_at
  BEFORE UPDATE ON personal_goals
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE habits (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  name TEXT NOT NULL,
  frequency TEXT NOT NULL DEFAULT 'daily' CHECK (frequency IN ('daily', 'weekly')),
  target_per_period INTEGER NOT NULL DEFAULT 1 CHECK (target_per_period >= 1),
  current_streak INTEGER NOT NULL DEFAULT 0,
  best_streak INTEGER NOT NULL DEFAULT 0,
  completed_dates DATE[] NOT NULL DEFAULT '{}',
  is_archived BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_habits_user ON habits (user_id, is_archived);

CREATE TRIGGER trg_habits_updated_at
  BEFORE UPDATE ON habits
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE reading_tracker (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  book_title TEXT NOT NULL,
  author TEXT DEFAULT '',
  total_pages INTEGER NOT NULL DEFAULT 100 CHECK (total_pages > 0),
  current_page INTEGER NOT NULL DEFAULT 0 CHECK (current_page >= 0),
  status TEXT NOT NULL DEFAULT 'reading' CHECK (status IN ('to_read', 'reading', 'completed')),
  key_insights TEXT DEFAULT '',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_reading_tracker_user ON reading_tracker (user_id);

CREATE TRIGGER trg_reading_tracker_updated_at
  BEFORE UPDATE ON reading_tracker
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Strictly private notes, journals & daily self-reflections
CREATE TABLE private_notes (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  note_type TEXT NOT NULL DEFAULT 'journal' CHECK (note_type IN ('journal', 'daily_reflection', 'self_assessment', 'time_block', 'mentor_session')),
  title TEXT NOT NULL,
  content TEXT NOT NULL,
  mood_tag TEXT,
  ai_mentor_questions JSONB NOT NULL DEFAULT '[]'::jsonb,
  note_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_private_notes_user ON private_notes (user_id, note_date DESC);

CREATE TRIGGER trg_private_notes_updated_at
  BEFORE UPDATE ON private_notes
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
