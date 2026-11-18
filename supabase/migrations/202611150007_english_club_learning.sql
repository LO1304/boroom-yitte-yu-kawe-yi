-- ============================================================================
-- Migration 0007: YITTÉ ENGLISH CLUB — Complete English Learning Platform
-- Supports Modules A-J, CEFR A1-C2, en-GB & en-US, Accent-Fair Evaluation
-- ============================================================================

CREATE TABLE vocabulary (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  word TEXT NOT NULL,
  phonetic_uk TEXT NOT NULL,
  phonetic_us TEXT NOT NULL,
  part_of_speech TEXT NOT NULL,
  cefr_level cefr_level NOT NULL DEFAULT 'B1',
  definition_en TEXT NOT NULL,
  definition_fr TEXT NOT NULL,
  example_sentence_en TEXT NOT NULL,
  example_sentence_fr TEXT NOT NULL,
  audio_uk_url TEXT,
  audio_us_url TEXT,
  scheduled_date DATE, -- 5 words assigned per day
  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_vocabulary_date ON vocabulary (scheduled_date DESC);
CREATE INDEX idx_vocabulary_cefr ON vocabulary (cefr_level);

CREATE TABLE english_lessons (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  module_type TEXT NOT NULL CHECK (module_type IN (
    'daily_vocabulary', 'speaking_practice', 'ai_coach', 'pronunciation_lab',
    'listening', 'grammar', 'english_debate', 'conversation_room',
    'vocabulary_battle', 'weekly_speaking_challenge'
  )),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  cefr_level cefr_level NOT NULL DEFAULT 'B1',
  english_variant english_variant NOT NULL DEFAULT 'en-GB',
  content_markdown TEXT NOT NULL,
  audio_prompt_url TEXT,
  transcript_reference TEXT,
  order_index INTEGER NOT NULL DEFAULT 0,
  is_weekly_challenge BOOLEAN NOT NULL DEFAULT FALSE,
  week_start_date DATE,
  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  is_published BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_english_lessons_module ON english_lessons (module_type, cefr_level, is_published);

CREATE TRIGGER trg_english_lessons_updated_at
  BEFORE UPDATE ON english_lessons
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE english_exercises (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  lesson_id UUID NOT NULL REFERENCES english_lessons(id) ON DELETE CASCADE,
  exercise_type TEXT NOT NULL CHECK (exercise_type IN ('grammar_quiz', 'listening_mcq', 'pronunciation_drill', 'vocab_battle', 'speaking_prompt')),
  prompt TEXT NOT NULL,
  options JSONB NOT NULL DEFAULT '[]'::jsonb,
  correct_answer TEXT,
  explanation TEXT NOT NULL,
  cefr_level cefr_level NOT NULL DEFAULT 'B1',
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_english_exercises_lesson ON english_exercises (lesson_id);

CREATE TABLE speaking_attempts (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  lesson_id UUID REFERENCES english_lessons(id) ON DELETE SET NULL,
  recording_id UUID REFERENCES voice_recordings(id) ON DELETE SET NULL,
  prompt_text TEXT NOT NULL,
  target_variant english_variant NOT NULL DEFAULT 'en-GB',
  cefr_level cefr_level NOT NULL DEFAULT 'B1',
  transcript_text TEXT,
  -- 100-pt breakdown (accent-fair intelligibility, not native imitation)
  score_grammar NUMERIC(4,2) CHECK (score_grammar >= 0 AND score_grammar <= 20),
  score_vocabulary NUMERIC(4,2) CHECK (score_vocabulary >= 0 AND score_vocabulary <= 20),
  score_fluency NUMERIC(4,2) CHECK (score_fluency >= 0 AND score_fluency <= 20),
  score_intelligibility NUMERIC(4,2) CHECK (score_intelligibility >= 0 AND score_intelligibility <= 20),
  score_coherence NUMERIC(4,2) CHECK (score_coherence >= 0 AND score_coherence <= 20),
  total_score NUMERIC(5,2) CHECK (total_score >= 0 AND total_score <= 100),
  identified_errors JSONB NOT NULL DEFAULT '[]'::jsonb,
  corrected_sentences JSONB NOT NULL DEFAULT '[]'::jsonb,
  natural_expressions JSONB NOT NULL DEFAULT '[]'::jsonb,
  suggested_vocabulary JSONB NOT NULL DEFAULT '[]'::jsonb,
  personalized_exercises JSONB NOT NULL DEFAULT '[]'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_speaking_attempts_user ON speaking_attempts (user_id, created_at DESC);

CREATE TABLE learning_progress (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  lesson_id UUID REFERENCES english_lessons(id) ON DELETE CASCADE,
  vocabulary_id UUID REFERENCES vocabulary(id) ON DELETE CASCADE,
  status TEXT NOT NULL DEFAULT 'in_progress' CHECK (status IN ('not_started', 'in_progress', 'completed', 'mastered')),
  score NUMERIC(5,2),
  streak_days INTEGER NOT NULL DEFAULT 0,
  last_practiced_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, lesson_id),
  UNIQUE (user_id, vocabulary_id)
);

CREATE INDEX idx_learning_progress_user ON learning_progress (user_id, last_practiced_at DESC);
