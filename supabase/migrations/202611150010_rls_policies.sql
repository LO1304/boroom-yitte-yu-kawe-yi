-- ============================================================================
-- Migration 0010: Row Level Security (RLS) Across ALL Tables
-- Enforces strict privacy for private_notes, zikr_participations,
-- personal_goals, habits, reading_tracker, user blocks & server-side RBAC.
-- ============================================================================

DO $$
DECLARE
  tbl TEXT;
BEGIN
  FOREACH tbl IN ARRAY ARRAY[
    'roles', 'profiles', 'user_roles', 'invitations', 'user_blocks',
    'reflections', 'saved_reflections', 'comments', 'reactions',
    'weekly_topics', 'topic_contributions', 'summaries', 'digital_library_items',
    'challenges', 'challenge_submissions', 'debate_matches', 'debate_participants',
    'voice_recordings', 'transcripts', 'ai_evaluations', 'debate_review_requests',
    'tournaments', 'tournament_participants', 'quiz_questions', 'quiz_matches', 'quiz_answers',
    'zikr_sessions', 'zikr_participations',
    'vocabulary', 'english_lessons', 'english_exercises', 'speaking_attempts', 'learning_progress',
    'career_profiles', 'career_opportunities', 'mock_interviews',
    'personal_goals', 'habits', 'reading_tracker', 'private_notes',
    'groups', 'group_members', 'voice_rooms', 'messages', 'events',
    'device_tokens', 'notifications', 'reports', 'audit_logs', 'ai_usage_logs'
  ]
  LOOP
    EXECUTE format('ALTER TABLE %I ENABLE ROW LEVEL SECURITY;', tbl);
  END LOOP;
END $$;

-- 1. Roles & Profiles
CREATE POLICY "roles_readable_by_authenticated" ON roles FOR SELECT TO authenticated USING (TRUE);

CREATE POLICY "profiles_readable_by_authenticated" ON profiles
  FOR SELECT TO authenticated
  USING (
    NOT EXISTS (
      SELECT 1 FROM user_blocks ub
      WHERE (ub.blocker_id = profiles.id AND ub.blocked_id = auth.uid())
    )
  );

CREATE POLICY "profiles_insert_own" ON profiles
  FOR INSERT TO authenticated
  WITH CHECK (id = auth.uid() AND primary_role = 'member');

CREATE POLICY "profiles_update_own_safe" ON profiles
  FOR UPDATE TO authenticated
  USING (id = auth.uid() OR is_admin_or_above())
  WITH CHECK (
    (id = auth.uid()
      AND primary_role = (SELECT p2.primary_role FROM profiles p2 WHERE p2.id = auth.uid())
      AND is_suspended = (SELECT p2.is_suspended FROM profiles p2 WHERE p2.id = auth.uid()))
    OR is_admin_or_above()
  );

-- 2. User Roles & Invitations (server-side RBAC)
CREATE POLICY "user_roles_select" ON user_roles
  FOR SELECT TO authenticated USING (user_id = auth.uid() OR is_admin_or_above());
CREATE POLICY "user_roles_admin_manage" ON user_roles
  FOR ALL TO authenticated USING (current_user_has_any_role(ARRAY['super_admin', 'admin']::app_role[]));

CREATE POLICY "invitations_select" ON invitations
  FOR SELECT TO authenticated USING (invited_by = auth.uid() OR is_admin_or_above());
CREATE POLICY "invitations_insert" ON invitations
  FOR INSERT TO authenticated WITH CHECK (invited_by = auth.uid() AND (invited_role = 'member' OR is_admin_or_above()));
CREATE POLICY "invitations_admin_update" ON invitations
  FOR UPDATE TO authenticated USING (invited_by = auth.uid() OR is_admin_or_above());

-- 3. User Blocks
CREATE POLICY "user_blocks_own" ON user_blocks
  FOR ALL TO authenticated USING (blocker_id = auth.uid()) WITH CHECK (blocker_id = auth.uid());

-- 4. Reflections, Saved, Comments, Reactions
CREATE POLICY "reflections_select" ON reflections
  FOR SELECT TO authenticated
  USING (
    (is_hidden = FALSE OR author_id = auth.uid() OR is_moderator_or_above())
    AND NOT EXISTS (
      SELECT 1 FROM user_blocks ub WHERE ub.blocker_id = auth.uid() AND ub.blocked_id = reflections.author_id
    )
  );
CREATE POLICY "reflections_insert" ON reflections
  FOR INSERT TO authenticated WITH CHECK (author_id = auth.uid());
CREATE POLICY "reflections_update" ON reflections
  FOR UPDATE TO authenticated USING (author_id = auth.uid() OR is_moderator_or_above());
CREATE POLICY "reflections_delete" ON reflections
  FOR DELETE TO authenticated USING (author_id = auth.uid() OR is_moderator_or_above());

CREATE POLICY "saved_reflections_own" ON saved_reflections
  FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "comments_select" ON comments
  FOR SELECT TO authenticated
  USING (is_hidden = FALSE OR author_id = auth.uid() OR is_moderator_or_above());
CREATE POLICY "comments_insert" ON comments
  FOR INSERT TO authenticated WITH CHECK (author_id = auth.uid());
CREATE POLICY "comments_update_delete" ON comments
  FOR ALL TO authenticated USING (author_id = auth.uid() OR is_moderator_or_above());

CREATE POLICY "reactions_select" ON reactions FOR SELECT TO authenticated USING (TRUE);
CREATE POLICY "reactions_own" ON reactions
  FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- 5. Weekly Topics, Contributions, Summaries (Editor-reviewed before publish) & Digital Library
CREATE POLICY "weekly_topics_select" ON weekly_topics FOR SELECT TO authenticated USING (TRUE);
CREATE POLICY "weekly_topics_manage" ON weekly_topics FOR ALL TO authenticated USING (is_editor_or_above());

CREATE POLICY "topic_contributions_select" ON topic_contributions
  FOR SELECT TO authenticated USING (is_hidden = FALSE OR author_id = auth.uid() OR is_moderator_or_above());
CREATE POLICY "topic_contributions_insert" ON topic_contributions
  FOR INSERT TO authenticated WITH CHECK (author_id = auth.uid());
CREATE POLICY "topic_contributions_update" ON topic_contributions
  FOR UPDATE TO authenticated USING (author_id = auth.uid() OR is_moderator_or_above());

CREATE POLICY "summaries_select" ON summaries
  FOR SELECT TO authenticated USING (status = 'published' OR is_editor_or_above());
CREATE POLICY "summaries_editor_manage" ON summaries
  FOR ALL TO authenticated USING (is_editor_or_above())
  WITH CHECK (is_editor_or_above());

CREATE POLICY "library_select" ON digital_library_items FOR SELECT TO authenticated USING (TRUE);
CREATE POLICY "library_editor_manage" ON digital_library_items FOR ALL TO authenticated USING (is_editor_or_above());

-- 6. Challenges & Submissions
CREATE POLICY "challenges_select" ON challenges
  FOR SELECT TO authenticated
  USING ((is_published = TRUE AND scheduled_publish_at <= NOW()) OR is_admin_or_above() OR is_editor_or_above());
CREATE POLICY "challenges_admin_manage" ON challenges
  FOR ALL TO authenticated USING (is_admin_or_above() OR is_editor_or_above());

CREATE POLICY "challenge_submissions_select" ON challenge_submissions
  FOR SELECT TO authenticated USING (user_id = auth.uid() OR is_moderator_or_above());
CREATE POLICY "challenge_submissions_insert" ON challenge_submissions
  FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

-- 7. Debates, Voice Recordings, Transcripts, AI Evaluations, Review Requests
CREATE POLICY "debate_matches_select" ON debate_matches
  FOR SELECT TO authenticated
  USING (
    is_public = TRUE OR created_by = auth.uid() OR is_moderator_or_above()
    OR EXISTS (SELECT 1 FROM debate_participants dp WHERE dp.match_id = debate_matches.id AND dp.user_id = auth.uid())
  );
CREATE POLICY "debate_matches_insert" ON debate_matches
  FOR INSERT TO authenticated WITH CHECK (created_by = auth.uid());
CREATE POLICY "debate_matches_update" ON debate_matches
  FOR UPDATE TO authenticated
  USING (
    created_by = auth.uid() OR is_moderator_or_above()
    OR EXISTS (SELECT 1 FROM debate_participants dp WHERE dp.match_id = debate_matches.id AND dp.user_id = auth.uid())
  );

CREATE POLICY "debate_participants_select" ON debate_participants FOR SELECT TO authenticated USING (TRUE);
CREATE POLICY "debate_participants_insert" ON debate_participants
  FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid() OR EXISTS (SELECT 1 FROM debate_matches dm WHERE dm.id = match_id AND dm.created_by = auth.uid()));
CREATE POLICY "debate_participants_update" ON debate_participants
  FOR UPDATE TO authenticated USING (user_id = auth.uid() OR is_moderator_or_above());

CREATE POLICY "voice_recordings_own" ON voice_recordings
  FOR ALL TO authenticated
  USING (user_id = auth.uid() OR is_moderator_or_above())
  WITH CHECK (user_id = auth.uid() AND consent_granted = TRUE);

CREATE POLICY "transcripts_select" ON transcripts
  FOR SELECT TO authenticated
  USING (
    user_id = auth.uid() OR is_moderator_or_above()
    OR EXISTS (
      SELECT 1 FROM voice_recordings vr
      JOIN debate_matches dm ON dm.id = vr.context_id AND vr.context_type = 'debate'
      WHERE vr.id = transcripts.recording_id AND dm.is_public = TRUE
    )
  );

CREATE POLICY "ai_evaluations_select" ON ai_evaluations
  FOR SELECT TO authenticated
  USING (user_id = auth.uid() OR subject_type = 'debate_participant' OR is_moderator_or_above());

CREATE POLICY "debate_review_requests_own_or_mod" ON debate_review_requests
  FOR ALL TO authenticated
  USING (requested_by = auth.uid() OR is_moderator_or_above())
  WITH CHECK (requested_by = auth.uid());

-- 8. Quiz Arena & Tournaments
CREATE POLICY "tournaments_select" ON tournaments FOR SELECT TO authenticated USING (TRUE);
CREATE POLICY "tournaments_manage" ON tournaments FOR ALL TO authenticated USING (is_admin_or_above());

CREATE POLICY "tournament_participants_select" ON tournament_participants FOR SELECT TO authenticated USING (TRUE);
CREATE POLICY "tournament_participants_join" ON tournament_participants
  FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

CREATE POLICY "quiz_questions_select" ON quiz_questions FOR SELECT TO authenticated USING (is_active = TRUE OR is_editor_or_above());
CREATE POLICY "quiz_questions_manage" ON quiz_questions FOR ALL TO authenticated USING (is_admin_or_above() OR is_editor_or_above());

CREATE POLICY "quiz_matches_select" ON quiz_matches FOR SELECT TO authenticated USING (TRUE);
CREATE POLICY "quiz_matches_insert" ON quiz_matches FOR INSERT TO authenticated WITH CHECK (created_by = auth.uid());
CREATE POLICY "quiz_matches_update" ON quiz_matches FOR UPDATE TO authenticated USING (created_by = auth.uid() OR is_moderator_or_above());

CREATE POLICY "quiz_answers_select" ON quiz_answers FOR SELECT TO authenticated USING (user_id = auth.uid() OR is_moderator_or_above());
CREATE POLICY "quiz_answers_insert" ON quiz_answers FOR INSERT TO authenticated WITH CHECK (user_id = auth.uid());

-- 9. ZIKR (Strictly private personal participation — NO piety rankings)
CREATE POLICY "zikr_sessions_select" ON zikr_sessions FOR SELECT TO authenticated USING (TRUE);
CREATE POLICY "zikr_sessions_admin" ON zikr_sessions FOR ALL TO authenticated USING (is_admin_or_above() OR is_editor_or_above());

CREATE POLICY "zikr_participations_strict_private" ON zikr_participations
  FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- 10. English Club
CREATE POLICY "vocabulary_select" ON vocabulary FOR SELECT TO authenticated USING (TRUE);
CREATE POLICY "vocabulary_manage" ON vocabulary FOR ALL TO authenticated USING (is_admin_or_above() OR is_editor_or_above());

CREATE POLICY "english_lessons_select" ON english_lessons FOR SELECT TO authenticated USING (is_published = TRUE OR is_editor_or_above());
CREATE POLICY "english_lessons_manage" ON english_lessons FOR ALL TO authenticated USING (is_admin_or_above() OR is_editor_or_above());

CREATE POLICY "english_exercises_select" ON english_exercises FOR SELECT TO authenticated USING (TRUE);
CREATE POLICY "english_exercises_manage" ON english_exercises FOR ALL TO authenticated USING (is_admin_or_above() OR is_editor_or_above());

CREATE POLICY "speaking_attempts_own" ON speaking_attempts
  FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "learning_progress_own" ON learning_progress
  FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- 11. Professional & Personal Growth (strict privacy for personal growth!)
CREATE POLICY "career_profiles_select" ON career_profiles
  FOR SELECT TO authenticated USING (user_id = auth.uid() OR open_to_opportunities = TRUE);
CREATE POLICY "career_profiles_own" ON career_profiles
  FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "career_opportunities_select" ON career_opportunities FOR SELECT TO authenticated USING (is_active = TRUE OR is_admin_or_above());
CREATE POLICY "career_opportunities_manage" ON career_opportunities FOR ALL TO authenticated USING (posted_by = auth.uid() OR is_admin_or_above());

CREATE POLICY "mock_interviews_own" ON mock_interviews
  FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- STRICT PRIVACY: not even administrators can read a member's private personal growth data
CREATE POLICY "personal_goals_strict_private" ON personal_goals
  FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "habits_strict_private" ON habits
  FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "reading_tracker_strict_private" ON reading_tracker
  FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());
CREATE POLICY "private_notes_strict_private" ON private_notes
  FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

-- 12. Groups, Voice Rooms, Messages, Events, Notifications, Reports, Audit, AI Usage
CREATE POLICY "groups_select" ON groups
  FOR SELECT TO authenticated
  USING (is_private = FALSE OR created_by = auth.uid() OR EXISTS (SELECT 1 FROM group_members gm WHERE gm.group_id = groups.id AND gm.user_id = auth.uid()));
CREATE POLICY "groups_insert" ON groups FOR INSERT TO authenticated WITH CHECK (created_by = auth.uid());
CREATE POLICY "groups_update" ON groups FOR UPDATE TO authenticated USING (created_by = auth.uid() OR is_moderator_or_above());

CREATE POLICY "group_members_select" ON group_members FOR SELECT TO authenticated USING (TRUE);
CREATE POLICY "group_members_manage" ON group_members FOR ALL TO authenticated USING (user_id = auth.uid() OR is_moderator_or_above());

CREATE POLICY "voice_rooms_select" ON voice_rooms FOR SELECT TO authenticated USING (TRUE);
CREATE POLICY "voice_rooms_insert" ON voice_rooms FOR INSERT TO authenticated WITH CHECK (host_id = auth.uid());
CREATE POLICY "voice_rooms_update" ON voice_rooms FOR UPDATE TO authenticated USING (host_id = auth.uid() OR is_moderator_or_above());

CREATE POLICY "messages_select" ON messages
  FOR SELECT TO authenticated
  USING (
    is_deleted = FALSE AND (
      sender_id = auth.uid()
      OR recipient_id = auth.uid()
      OR (group_id IS NOT NULL AND EXISTS (SELECT 1 FROM group_members gm WHERE gm.group_id = messages.group_id AND gm.user_id = auth.uid()))
      OR voice_room_id IS NOT NULL
    )
    AND NOT EXISTS (SELECT 1 FROM user_blocks ub WHERE ub.blocker_id = auth.uid() AND ub.blocked_id = messages.sender_id)
  );
CREATE POLICY "messages_insert" ON messages
  FOR INSERT TO authenticated
  WITH CHECK (
    sender_id = auth.uid()
    AND NOT EXISTS (SELECT 1 FROM user_blocks ub WHERE ub.blocker_id = recipient_id AND ub.blocked_id = auth.uid())
  );

CREATE POLICY "events_select" ON events FOR SELECT TO authenticated USING (TRUE);
CREATE POLICY "events_manage" ON events FOR ALL TO authenticated USING (organizer_id = auth.uid() OR is_admin_or_above());

CREATE POLICY "device_tokens_own" ON device_tokens
  FOR ALL TO authenticated USING (user_id = auth.uid()) WITH CHECK (user_id = auth.uid());

CREATE POLICY "notifications_own" ON notifications
  FOR SELECT TO authenticated USING (user_id = auth.uid());
CREATE POLICY "notifications_update_own" ON notifications
  FOR UPDATE TO authenticated USING (user_id = auth.uid());

CREATE POLICY "reports_insert" ON reports FOR INSERT TO authenticated WITH CHECK (reporter_id = auth.uid());
CREATE POLICY "reports_select_own_or_mod" ON reports FOR SELECT TO authenticated USING (reporter_id = auth.uid() OR is_moderator_or_above());
CREATE POLICY "reports_mod_update" ON reports FOR UPDATE TO authenticated USING (is_moderator_or_above());

CREATE POLICY "audit_logs_admin_only" ON audit_logs FOR SELECT TO authenticated USING (is_admin_or_above());
CREATE POLICY "ai_usage_logs_own_or_admin" ON ai_usage_logs FOR SELECT TO authenticated USING (user_id = auth.uid() OR is_admin_or_above());
