-- ============================================================================
-- Migration 0005: Quiz Arena & Multiplayer Tournaments
-- ============================================================================

CREATE TABLE tournaments (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  domain TEXT NOT NULL CHECK (domain IN ('quiz_arena', 'debate')),
  mode quiz_mode NOT NULL DEFAULT 'tournament_8',
  category challenge_category NOT NULL DEFAULT 'general_knowledge',
  max_participants INTEGER NOT NULL CHECK (max_participants IN (2, 8, 16, 32, 64)),
  current_round INTEGER NOT NULL DEFAULT 0,
  status TEXT NOT NULL DEFAULT 'registration' CHECK (status IN ('registration', 'in_progress', 'completed', 'cancelled')),
  bracket_state JSONB NOT NULL DEFAULT '{"rounds": []}'::jsonb,
  starts_at TIMESTAMPTZ NOT NULL,
  ends_at TIMESTAMPTZ,
  is_weekly_championship BOOLEAN NOT NULL DEFAULT FALSE,
  created_by UUID NOT NULL REFERENCES profiles(id) ON DELETE RESTRICT,
  winner_user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_tournaments_status ON tournaments (status, starts_at ASC);

ALTER TABLE debate_matches
  ADD CONSTRAINT fk_debate_matches_tournament
  FOREIGN KEY (tournament_id) REFERENCES tournaments(id) ON DELETE SET NULL;

CREATE TRIGGER trg_tournaments_updated_at
  BEFORE UPDATE ON tournaments
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE tournament_participants (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tournament_id UUID NOT NULL REFERENCES tournaments(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  team_name TEXT,
  seed_number INTEGER,
  is_eliminated BOOLEAN NOT NULL DEFAULT FALSE,
  cumulative_score INTEGER NOT NULL DEFAULT 0,
  joined_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (tournament_id, user_id)
);

CREATE INDEX idx_tournament_participants_t ON tournament_participants (tournament_id, cumulative_score DESC);

CREATE TABLE quiz_questions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  category challenge_category NOT NULL,
  question_type quiz_question_type NOT NULL DEFAULT 'mcq',
  difficulty difficulty_level NOT NULL DEFAULT 'intermediate',
  question_text TEXT NOT NULL,
  options JSONB NOT NULL DEFAULT '[]'::jsonb,
  correct_option_index INTEGER,
  correct_text_answer TEXT,
  explanation TEXT NOT NULL,
  verified_references JSONB NOT NULL DEFAULT '[]'::jsonb,
  time_limit_seconds INTEGER NOT NULL DEFAULT 25 CHECK (time_limit_seconds BETWEEN 10 AND 180),
  points INTEGER NOT NULL DEFAULT 100 CHECK (points BETWEEN 10 AND 1000),
  language app_language NOT NULL DEFAULT 'fr',
  created_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  is_ai_generated BOOLEAN NOT NULL DEFAULT FALSE,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_quiz_questions_cat ON quiz_questions (category, question_type, is_active);

CREATE TABLE quiz_matches (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  tournament_id UUID REFERENCES tournaments(id) ON DELETE CASCADE,
  mode quiz_mode NOT NULL DEFAULT 'one_vs_one',
  category challenge_category NOT NULL DEFAULT 'general_knowledge',
  round_number INTEGER NOT NULL DEFAULT 1,
  question_ids UUID[] NOT NULL DEFAULT '{}',
  current_question_index INTEGER NOT NULL DEFAULT 0,
  question_started_at TIMESTAMPTZ,
  status TEXT NOT NULL DEFAULT 'waiting' CHECK (status IN ('waiting', 'countdown', 'active', 'completed', 'cancelled')),
  anti_cheat_config JSONB NOT NULL DEFAULT '{"max_focus_losses": 2, "server_time_validation": true, "shuffle_options": true}'::jsonb,
  players_state JSONB NOT NULL DEFAULT '{}'::jsonb,
  winner_user_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  created_by UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  started_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_quiz_matches_status ON quiz_matches (status, created_at DESC);

CREATE TRIGGER trg_quiz_matches_updated_at
  BEFORE UPDATE ON quiz_matches
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE quiz_answers (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  match_id UUID NOT NULL REFERENCES quiz_matches(id) ON DELETE CASCADE,
  question_id UUID NOT NULL REFERENCES quiz_questions(id) ON DELETE CASCADE,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  selected_option_index INTEGER,
  written_answer TEXT,
  is_correct BOOLEAN NOT NULL DEFAULT FALSE,
  response_time_ms INTEGER NOT NULL CHECK (response_time_ms >= 0),
  points_awarded INTEGER NOT NULL DEFAULT 0,
  focus_lost_count INTEGER NOT NULL DEFAULT 0,
  flagged_suspicious BOOLEAN NOT NULL DEFAULT FALSE,
  answered_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (match_id, question_id, user_id)
);

CREATE INDEX idx_quiz_answers_match ON quiz_answers (match_id, user_id);

-- Voluntary educational competition leaderboard view (NEVER includes Zikr/piety)
CREATE OR REPLACE VIEW educational_leaderboard AS
SELECT
  p.id AS user_id,
  p.username,
  p.full_name,
  p.avatar_url,
  COALESCE(q.total_quiz_points, 0) AS quiz_points,
  COALESCE(q.matches_won, 0) AS quiz_wins,
  COALESCE(d.debates_completed, 0) AS debates_completed,
  COALESCE(d.avg_debate_score, 0)::NUMERIC(5,2) AS avg_debate_score,
  COALESCE(c.challenges_completed, 0) AS challenges_completed,
  (COALESCE(q.total_quiz_points, 0) + COALESCE(d.debates_completed, 0) * 150 + COALESCE(c.challenges_completed, 0) * 50) AS educational_index
FROM profiles p
LEFT JOIN (
  SELECT qa.user_id,
         SUM(qa.points_awarded) AS total_quiz_points,
         COUNT(DISTINCT qm.id) FILTER (WHERE qm.winner_user_id = qa.user_id) AS matches_won
  FROM quiz_answers qa
  JOIN quiz_matches qm ON qm.id = qa.match_id
  WHERE qa.flagged_suspicious = FALSE
  GROUP BY qa.user_id
) q ON q.user_id = p.id
LEFT JOIN (
  SELECT dp.user_id,
         COUNT(*) FILTER (WHERE dp.final_score IS NOT NULL) AS debates_completed,
         AVG(dp.final_score) AS avg_debate_score
  FROM debate_participants dp
  GROUP BY dp.user_id
) d ON d.user_id = p.id
LEFT JOIN (
  SELECT cs.user_id, COUNT(*) AS challenges_completed
  FROM challenge_submissions cs
  GROUP BY cs.user_id
) c ON c.user_id = p.id
WHERE p.show_on_educational_leaderboard = TRUE
  AND p.is_suspended = FALSE;
