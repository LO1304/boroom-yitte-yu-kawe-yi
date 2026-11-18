-- ============================================================================
-- Migration 0004: Challenges, Face-à-Face Voice Debates, STT & AI Rubric
-- ============================================================================

CREATE TABLE challenges (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL CHECK (char_length(title) BETWEEN 4 AND 200),
  description TEXT NOT NULL,
  category challenge_category NOT NULL,
  format challenge_format NOT NULL,
  difficulty difficulty_level NOT NULL DEFAULT 'intermediate',
  time_limit_seconds INTEGER NOT NULL DEFAULT 300 CHECK (time_limit_seconds BETWEEN 30 AND 7200),
  instructions TEXT NOT NULL,
  evaluation_criteria JSONB NOT NULL DEFAULT '[]'::jsonb,
  options JSONB, -- Used for MCQ / Yes-No-Depends options
  correct_answer TEXT, -- Kept protected or revealed post-submission
  explanation TEXT NOT NULL,
  verified_references JSONB NOT NULL DEFAULT '[]'::jsonb,
  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  scheduled_publish_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ,
  is_published BOOLEAN NOT NULL DEFAULT TRUE,
  language app_language NOT NULL DEFAULT 'fr',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_challenges_category_format ON challenges (category, format, is_published);
CREATE INDEX idx_challenges_schedule ON challenges (scheduled_publish_at DESC);

CREATE TRIGGER trg_challenges_updated_at
  BEFORE UPDATE ON challenges
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE challenge_submissions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  challenge_id UUID NOT NULL REFERENCES challenges(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  team_name TEXT,
  answer_choice TEXT,
  written_response TEXT,
  audio_storage_path TEXT,
  transcript_text TEXT,
  duration_seconds INTEGER,
  score NUMERIC(5,2) CHECK (score >= 0 AND score <= 100),
  ai_feedback JSONB,
  is_correct BOOLEAN,
  submitted_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (challenge_id, user_id)
);

CREATE INDEX idx_challenge_submissions_challenge ON challenge_submissions (challenge_id, submitted_at DESC);
CREATE INDEX idx_challenge_submissions_user ON challenge_submissions (user_id, submitted_at DESC);

-- YITTÉ FACE-À-FACE Voice Debates
CREATE TABLE debate_matches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  topic_title TEXT NOT NULL,
  topic_question TEXT NOT NULL,
  category challenge_category NOT NULL DEFAULT 'ethics',
  is_islamic_subject BOOLEAN NOT NULL DEFAULT FALSE,
  match_type TEXT NOT NULL CHECK (match_type IN ('friend_challenge', 'matchmaking', 'tournament', 'public')),
  tournament_id UUID,
  status debate_status NOT NULL DEFAULT 'matchmaking',
  preparation_seconds INTEGER NOT NULL DEFAULT 120 CHECK (preparation_seconds BETWEEN 30 AND 600),
  speech_max_seconds INTEGER NOT NULL DEFAULT 180 CHECK (speech_max_seconds BETWEEN 30 AND 180),
  created_by UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  winner_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  is_public BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_debate_matches_status ON debate_matches (status, created_at DESC);

CREATE TRIGGER trg_debate_matches_updated_at
  BEFORE UPDATE ON debate_matches
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE debate_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id UUID NOT NULL REFERENCES debate_matches(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  side TEXT NOT NULL CHECK (side IN ('A', 'B')),
  selected_position debate_position,
  invite_accepted BOOLEAN NOT NULL DEFAULT FALSE,
  prepared_notes TEXT,
  speech_submitted_at TIMESTAMPTZ,
  final_score NUMERIC(5,2) CHECK (final_score >= 0 AND final_score <= 100),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (match_id, user_id),
  UNIQUE (match_id, side)
);

CREATE INDEX idx_debate_participants_user ON debate_participants (user_id);

CREATE TABLE voice_recordings (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  context_type TEXT NOT NULL CHECK (context_type IN ('debate', 'challenge', 'english_speaking', 'mock_interview')),
  context_id UUID NOT NULL,
  storage_path TEXT NOT NULL,
  mime_type TEXT NOT NULL DEFAULT 'audio/m4a',
  duration_seconds INTEGER NOT NULL CHECK (duration_seconds > 0 AND duration_seconds <= 600),
  file_size_bytes BIGINT NOT NULL CHECK (file_size_bytes > 0),
  consent_granted BOOLEAN NOT NULL DEFAULT FALSE,
  retention_policy audio_retention_policy NOT NULL DEFAULT 'thirty_days',
  retain_until TIMESTAMPTZ,
  deleted_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_voice_recordings_user ON voice_recordings (user_id, created_at DESC);
CREATE INDEX idx_voice_recordings_retention ON voice_recordings (retain_until) WHERE deleted_at IS NULL;

CREATE TABLE transcripts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  recording_id UUID NOT NULL UNIQUE REFERENCES voice_recordings(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  stt_provider TEXT NOT NULL,
  language_detected TEXT NOT NULL DEFAULT 'fr',
  raw_text TEXT NOT NULL,
  word_timestamps JSONB DEFAULT '[]'::jsonb,
  confidence NUMERIC(4,3),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Transparent 100-point AI evaluation engine output
CREATE TABLE ai_evaluations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  agent_name TEXT NOT NULL CHECK (agent_name IN (
    'YITTE_DEBATE_AI', 'YITTE_ENGLISH_COACH', 'YITTE_QUIZ_MASTER',
    'YITTE_SPIRITUAL_ASSISTANT', 'YITTE_CAREER_COACH', 'YITTE_PERSONAL_MENTOR', 'YITTE_SUMMARIZER'
  )),
  subject_type TEXT NOT NULL CHECK (subject_type IN ('debate_participant', 'speaking_attempt', 'challenge_submission', 'mock_interview')),
  subject_id UUID NOT NULL,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  transcript_id UUID REFERENCES transcripts(id) ON DELETE SET NULL,
  ai_provider TEXT NOT NULL,
  ai_model TEXT NOT NULL,
  -- 100-point debate rubric breakdown (nullable when non-debate agent)
  score_relevance NUMERIC(4,2) CHECK (score_relevance >= 0 AND score_relevance <= 20),
  score_logical_reasoning NUMERIC(4,2) CHECK (score_logical_reasoning >= 0 AND score_logical_reasoning <= 25),
  score_depth_analysis NUMERIC(4,2) CHECK (score_depth_analysis >= 0 AND score_depth_analysis <= 20),
  score_arguments_examples NUMERIC(4,2) CHECK (score_arguments_examples >= 0 AND score_arguments_examples <= 15),
  score_critical_nuance NUMERIC(4,2) CHECK (score_critical_nuance >= 0 AND score_critical_nuance <= 10),
  score_clarity NUMERIC(4,2) CHECK (score_clarity >= 0 AND score_clarity <= 10),
  total_score NUMERIC(5,2) NOT NULL CHECK (total_score >= 0 AND total_score <= 100),
  detected_contradictions JSONB NOT NULL DEFAULT '[]'::jsonb,
  unsupported_claims JSONB NOT NULL DEFAULT '[]'::jsonb,
  logical_fallacies JSONB NOT NULL DEFAULT '[]'::jsonb,
  recognized_nuances JSONB NOT NULL DEFAULT '[]'::jsonb,
  relevant_examples JSONB NOT NULL DEFAULT '[]'::jsonb,
  score_explanation TEXT NOT NULL,
  improvement_recommendations JSONB NOT NULL DEFAULT '[]'::jsonb,
  verified_references JSONB NOT NULL DEFAULT '[]'::jsonb,
  fairness_audit JSONB NOT NULL DEFAULT '{"evaluated_reasoning_not_identity": true}'::jsonb,
  raw_structured_output JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_ai_evaluations_subject ON ai_evaluations (subject_type, subject_id);
CREATE INDEX idx_ai_evaluations_user ON ai_evaluations (user_id, created_at DESC);

CREATE TABLE debate_review_requests (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id UUID NOT NULL REFERENCES debate_matches(id) ON DELETE CASCADE,
  evaluation_id UUID NOT NULL REFERENCES ai_evaluations(id) ON DELETE CASCADE,
  requested_by UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  reason TEXT NOT NULL CHECK (char_length(reason) >= 10),
  status report_status NOT NULL DEFAULT 'open',
  reviewer_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  reviewer_notes TEXT,
  adjusted_score NUMERIC(5,2) CHECK (adjusted_score >= 0 AND adjusted_score <= 100),
  resolved_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);
