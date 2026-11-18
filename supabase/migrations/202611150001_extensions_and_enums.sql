-- ============================================================================
-- Migration 0001: Extensions, Custom Enums, and Shared Utility Functions
-- BOROOM YITTÉ YU KAWÉ YI
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pg_trgm";

-- Core RBAC roles
CREATE TYPE app_role AS ENUM (
  'super_admin',
  'admin',
  'moderator',
  'content_editor',
  'member'
);

-- Supported UI & content languages
CREATE TYPE app_language AS ENUM ('fr', 'en', 'ar', 'wo');

-- Challenge categories (Section 3)
CREATE TYPE challenge_category AS ENUM (
  'islamic_thought',
  'philosophy',
  'spirituality',
  'ethics',
  'history',
  'science',
  'technology',
  'logic',
  'society',
  'general_knowledge'
);

-- Challenge formats (Section 3)
CREATE TYPE challenge_format AS ENUM (
  'yes_no_depends',
  'mcq',
  'open_ended',
  'argumentation',
  'audio_response',
  'timed_reasoning',
  'team_challenge'
);

CREATE TYPE difficulty_level AS ENUM ('beginner', 'intermediate', 'advanced', 'expert');

-- Debate statuses & positions
CREATE TYPE debate_status AS ENUM (
  'pending_invite',
  'matchmaking',
  'preparing',
  'recording',
  'transcribing',
  'evaluating',
  'completed',
  'under_review',
  'cancelled'
);

CREATE TYPE debate_position AS ENUM ('for', 'against', 'nuanced');

-- Quiz & tournament modes
CREATE TYPE quiz_mode AS ENUM (
  'one_vs_one',
  'team_vs_team',
  'tournament_8',
  'tournament_16',
  'tournament_32',
  'community_tournament',
  'weekly_championship'
);

CREATE TYPE quiz_question_type AS ENUM (
  'mcq',
  'true_false',
  'open',
  'logic_puzzle',
  'history',
  'islamic_knowledge',
  'philosophical_reasoning'
);

-- Summary review workflow (editor review required before publication)
CREATE TYPE review_status AS ENUM (
  'draft',
  'pending_review',
  'approved',
  'rejected',
  'published'
);

-- English learning
CREATE TYPE cefr_level AS ENUM ('A1', 'A2', 'B1', 'B2', 'C1', 'C2');
CREATE TYPE english_variant AS ENUM ('en-GB', 'en-US');

-- Voice recording retention policy
CREATE TYPE audio_retention_policy AS ENUM (
  'session_only',
  'thirty_days',
  'ninety_days',
  'permanent_with_consent'
);

-- Moderation & reporting
CREATE TYPE report_status AS ENUM ('open', 'in_review', 'resolved', 'dismissed');

-- Generic updated_at trigger function
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;
