-- ============================================================================
-- Migration 0006: YITTÉ ZIKR — Collective Spiritual Sessions
-- STRICT ETHICAL INVARIANT:
--   No piety rankings, no spiritual scores, no religious comparison badges.
--   Personal history & optional stats remain strictly private to the user.
-- ============================================================================

CREATE TABLE zikr_sessions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT NOT NULL,
  program_details TEXT NOT NULL,
  scheduled_at TIMESTAMPTZ NOT NULL,
  duration_minutes INTEGER NOT NULL DEFAULT 45 CHECK (duration_minutes BETWEEN 10 AND 240),
  is_recurring BOOLEAN NOT NULL DEFAULT FALSE,
  recurrence_rule TEXT, -- e.g. 'WEEKLY;BYDAY=SA;BYHOUR=20;BYMINUTE=0;TZ=UTC' (Saturday 20:00 GMT)
  livekit_room_name TEXT,
  arabic_text TEXT NOT NULL,
  transliteration TEXT NOT NULL,
  french_translation TEXT NOT NULL,
  verified_references JSONB NOT NULL DEFAULT '[]'::jsonb,
  recommended_repetitions INTEGER CHECK (recommended_repetitions IS NULL OR recommended_repetitions > 0),
  organizer_id UUID REFERENCES profiles(id) ON DELETE SET NULL,
  status TEXT NOT NULL DEFAULT 'scheduled' CHECK (status IN ('scheduled', 'live', 'completed', 'cancelled')),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_zikr_sessions_scheduled ON zikr_sessions (scheduled_at ASC, status);

CREATE TRIGGER trg_zikr_sessions_updated_at
  BEFORE UPDATE ON zikr_sessions
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

-- Strictly personal participation record (private to user via RLS)
CREATE TABLE zikr_participations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  session_id UUID REFERENCES zikr_sessions(id) ON DELETE SET NULL,
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  personal_tasbih_count INTEGER NOT NULL DEFAULT 0 CHECK (personal_tasbih_count >= 0),
  dhikr_phrase_label TEXT,
  reminder_enabled BOOLEAN NOT NULL DEFAULT TRUE,
  joined_live_room BOOLEAN NOT NULL DEFAULT FALSE,
  share_optional_stats BOOLEAN NOT NULL DEFAULT FALSE,
  session_date DATE NOT NULL DEFAULT CURRENT_DATE,
  notes TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_zikr_participations_user ON zikr_participations (user_id, session_date DESC);

CREATE TRIGGER trg_zikr_participations_updated_at
  BEFORE UPDATE ON zikr_participations
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
