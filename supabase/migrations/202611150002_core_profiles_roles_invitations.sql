-- ============================================================================
-- Migration 0002: Profiles, Roles, Invitations & User Safety Blocks
-- ============================================================================

CREATE TABLE roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code app_role NOT NULL UNIQUE,
  display_name_fr TEXT NOT NULL,
  display_name_en TEXT NOT NULL,
  description TEXT NOT NULL,
  hierarchy_rank INTEGER NOT NULL UNIQUE,
  permissions JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

INSERT INTO roles (code, display_name_fr, display_name_en, description, hierarchy_rank, permissions) VALUES
  ('super_admin', 'Super Administrateur', 'Super Administrator', 'Full platform governance, role assignment, AI provider keys & audit access', 100, '{"all": true}'::jsonb),
  ('admin', 'Administrateur', 'Administrator', 'Manage members, invitations, challenges, tournaments, Zikr, English lessons & broadcasts', 80, '{"manage_members": true, "manage_content": true, "manage_events": true, "broadcast": true}'::jsonb),
  ('moderator', 'Modérateur', 'Moderator', 'Moderate reflections, voice rooms, quiz anti-cheat, reports & user blocks', 60, '{"moderate_content": true, "moderate_rooms": true, "handle_reports": true}'::jsonb),
  ('content_editor', 'Éditeur de Contenu', 'Content Editor', 'Review & validate AI-generated summaries, curate digital library, publish educational tracks', 40, '{"review_summaries": true, "curate_library": true, "publish_lessons": true}'::jsonb),
  ('member', 'Membre', 'Member', 'Standard community member with full learning, challenge, debate & personal tools', 10, '{"participate": true}'::jsonb)
ON CONFLICT (code) DO NOTHING;

CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  username TEXT UNIQUE NOT NULL CHECK (char_length(username) BETWEEN 3 AND 32),
  full_name TEXT NOT NULL CHECK (char_length(full_name) BETWEEN 2 AND 100),
  avatar_url TEXT,
  bio TEXT DEFAULT '',
  city TEXT DEFAULT '',
  country TEXT DEFAULT '',
  preferred_language app_language NOT NULL DEFAULT 'fr',
  theme_preference TEXT NOT NULL DEFAULT 'system' CHECK (theme_preference IN ('light', 'dark', 'system')),
  cefr_level cefr_level NOT NULL DEFAULT 'B1',
  preferred_english_variant english_variant NOT NULL DEFAULT 'en-GB',
  primary_role app_role NOT NULL DEFAULT 'member',
  interests TEXT[] NOT NULL DEFAULT '{}',
  is_verified BOOLEAN NOT NULL DEFAULT FALSE,
  is_suspended BOOLEAN NOT NULL DEFAULT FALSE,
  suspended_reason TEXT,
  onboarding_completed BOOLEAN NOT NULL DEFAULT FALSE,
  voice_recording_consent BOOLEAN NOT NULL DEFAULT FALSE,
  voice_retention_preference audio_retention_policy NOT NULL DEFAULT 'thirty_days',
  show_on_educational_leaderboard BOOLEAN NOT NULL DEFAULT TRUE,
  last_active_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_profiles_username ON profiles (username);
CREATE INDEX idx_profiles_role ON profiles (primary_role);
CREATE INDEX idx_profiles_cefr ON profiles (cefr_level);

CREATE TRIGGER trg_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TABLE user_roles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  role_id UUID NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
  assigned_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  assigned_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE (user_id, role_id)
);

CREATE INDEX idx_user_roles_user ON user_roles (user_id);

CREATE TABLE invitations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT NOT NULL UNIQUE CHECK (char_length(code) BETWEEN 6 AND 32),
  invited_email TEXT,
  invited_role app_role NOT NULL DEFAULT 'member',
  invited_by UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  accepted_by UUID REFERENCES profiles(id) ON DELETE SET NULL,
  max_uses INTEGER NOT NULL DEFAULT 1 CHECK (max_uses >= 1),
  uses_count INTEGER NOT NULL DEFAULT 0 CHECK (uses_count >= 0 AND uses_count <= max_uses),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '14 days'),
  is_revoked BOOLEAN NOT NULL DEFAULT FALSE,
  note TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX idx_invitations_code ON invitations (code);
CREATE INDEX idx_invitations_invited_by ON invitations (invited_by);

CREATE TABLE user_blocks (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  blocker_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  blocked_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
  reason TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  CHECK (blocker_id <> blocked_id),
  UNIQUE (blocker_id, blocked_id)
);

CREATE INDEX idx_user_blocks_blocker ON user_blocks (blocker_id);
CREATE INDEX idx_user_blocks_blocked ON user_blocks (blocked_id);

-- Server-side RBAC helper functions (used by RLS policies and RPCs)
CREATE OR REPLACE FUNCTION current_user_has_any_role(allowed_roles app_role[])
RETURNS BOOLEAN AS $$
DECLARE
  has_perm BOOLEAN;
BEGIN
  IF auth.uid() IS NULL THEN
    RETURN FALSE;
  END IF;

  SELECT EXISTS (
    SELECT 1 FROM profiles p
    WHERE p.id = auth.uid()
      AND p.is_suspended = FALSE
      AND p.primary_role = ANY(allowed_roles)
  ) OR EXISTS (
    SELECT 1
    FROM user_roles ur
    JOIN roles r ON r.id = ur.role_id
    JOIN profiles p ON p.id = ur.user_id
    WHERE ur.user_id = auth.uid()
      AND p.is_suspended = FALSE
      AND r.code = ANY(allowed_roles)
  ) INTO has_perm;

  RETURN COALESCE(has_perm, FALSE);
END;
$$ LANGUAGE plpgsql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION is_admin_or_above()
RETURNS BOOLEAN AS $$
  SELECT current_user_has_any_role(ARRAY['super_admin', 'admin']::app_role[]);
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION is_moderator_or_above()
RETURNS BOOLEAN AS $$
  SELECT current_user_has_any_role(ARRAY['super_admin', 'admin', 'moderator']::app_role[]);
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;

CREATE OR REPLACE FUNCTION is_editor_or_above()
RETURNS BOOLEAN AS $$
  SELECT current_user_has_any_role(ARRAY['super_admin', 'admin', 'content_editor']::app_role[]);
$$ LANGUAGE sql STABLE SECURITY DEFINER SET search_path = public;
