-- ============================================================================
-- Migration 0011: RPC Functions, Triggers & Server-Side Integrity
-- ============================================================================

-- Automatically create profile & default member role when auth.users is created
CREATE OR REPLACE FUNCTION handle_new_user()
RETURNS TRIGGER AS $$
DECLARE
  base_username TEXT;
  member_role_id UUID;
BEGIN
  base_username := COALESCE(
    NULLIF(TRIM(NEW.raw_user_meta_data->>'username'), ''),
    'membre_' || SUBSTRING(REPLACE(NEW.id::TEXT, '-', '') FROM 1 FOR 8)
  );

  INSERT INTO profiles (id, username, full_name, preferred_language)
  VALUES (
    NEW.id,
    LOWER(REGEXP_REPLACE(base_username, '[^a-zA-Z0-9_]', '_', 'g')),
    COALESCE(NULLIF(TRIM(NEW.raw_user_meta_data->>'full_name'), ''), 'Membre Boroom Yitté'),
    COALESCE((NEW.raw_user_meta_data->>'preferred_language')::app_language, 'fr')
  )
  ON CONFLICT (id) DO NOTHING;

  SELECT id INTO member_role_id FROM roles WHERE code = 'member' LIMIT 1;
  IF member_role_id IS NOT NULL THEN
    INSERT INTO user_roles (user_id, role_id)
    VALUES (NEW.id, member_role_id)
    ON CONFLICT DO NOTHING;
  END IF;

  INSERT INTO career_profiles (user_id)
  VALUES (NEW.id)
  ON CONFLICT (user_id) DO NOTHING;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION handle_new_user();

-- Maintain reflection counters accurately
CREATE OR REPLACE FUNCTION update_reflection_counts()
RETURNS TRIGGER AS $$
BEGIN
  IF TG_TABLE_NAME = 'comments' THEN
    IF TG_OP = 'INSERT' THEN
      UPDATE reflections SET comments_count = comments_count + 1 WHERE id = NEW.reflection_id;
    ELSIF TG_OP = 'DELETE' THEN
      UPDATE reflections SET comments_count = GREATEST(0, comments_count - 1) WHERE id = OLD.reflection_id;
    END IF;
  ELSIF TG_TABLE_NAME = 'reactions' THEN
    IF TG_OP = 'INSERT' AND NEW.reflection_id IS NOT NULL THEN
      UPDATE reflections SET reactions_count = reactions_count + 1 WHERE id = NEW.reflection_id;
    ELSIF TG_OP = 'DELETE' AND OLD.reflection_id IS NOT NULL THEN
      UPDATE reflections SET reactions_count = GREATEST(0, reactions_count - 1) WHERE id = OLD.reflection_id;
    END IF;
  END IF;
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

CREATE TRIGGER trg_comments_counter
  AFTER INSERT OR DELETE ON comments
  FOR EACH ROW EXECUTE FUNCTION update_reflection_counts();

CREATE TRIGGER trg_reactions_counter
  AFTER INSERT OR DELETE ON reactions
  FOR EACH ROW EXECUTE FUNCTION update_reflection_counts();

-- Redeem an invitation code atomically & assign role if specified
CREATE OR REPLACE FUNCTION redeem_invitation_code(p_code TEXT)
RETURNS JSONB AS $$
DECLARE
  inv RECORD;
  r_id UUID;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'Authentication required';
  END IF;

  SELECT * INTO inv FROM invitations
  WHERE code = UPPER(TRIM(p_code))
    AND is_revoked = FALSE
    AND expires_at > NOW()
    AND uses_count < max_uses
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN jsonb_build_object('valid', FALSE, 'error', 'Code d''invitation invalide ou expiré.');
  END IF;

  UPDATE invitations
  SET uses_count = uses_count + 1,
      accepted_by = COALESCE(accepted_by, auth.uid())
  WHERE id = inv.id;

  SELECT id INTO r_id FROM roles WHERE code = inv.invited_role;
  IF r_id IS NOT NULL THEN
    INSERT INTO user_roles (user_id, role_id, assigned_by)
    VALUES (auth.uid(), r_id, inv.invited_by)
    ON CONFLICT DO NOTHING;

    UPDATE profiles
    SET primary_role = inv.invited_role,
        is_verified = TRUE
    WHERE id = auth.uid();
  END IF;

  INSERT INTO audit_logs (actor_id, action, target_table, target_id, metadata)
  VALUES (auth.uid(), 'invitation_redeemed', 'invitations', inv.id, jsonb_build_object('role', inv.invited_role));

  RETURN jsonb_build_object('valid', TRUE, 'assigned_role', inv.invited_role);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Approve and publish an AI-generated summary (editor/admin only)
CREATE OR REPLACE FUNCTION publish_reviewed_summary(p_summary_id UUID, p_review_notes TEXT DEFAULT NULL)
RETURNS summaries AS $$
DECLARE
  updated_row summaries;
BEGIN
  IF NOT is_editor_or_above() THEN
    RAISE EXCEPTION 'Forbidden: editor or administrator role required';
  END IF;

  UPDATE summaries
  SET status = 'published',
      reviewed_by = auth.uid(),
      review_notes = COALESCE(p_review_notes, review_notes),
      reviewed_at = NOW(),
      published_at = NOW()
  WHERE id = p_summary_id
  RETURNING * INTO updated_row;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'Summary not found';
  END IF;

  INSERT INTO audit_logs (actor_id, action, target_table, target_id)
  VALUES (auth.uid(), 'summary_published', 'summaries', p_summary_id);

  RETURN updated_row;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- Enable Supabase Realtime publications for live interactive tables
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
    ALTER PUBLICATION supabase_realtime ADD TABLE
      reflections, comments, debate_matches, debate_participants,
      quiz_matches, quiz_answers, tournaments, messages, voice_rooms, notifications;
  END IF;
EXCEPTION WHEN OTHERS THEN
  NULL;
END $$;
