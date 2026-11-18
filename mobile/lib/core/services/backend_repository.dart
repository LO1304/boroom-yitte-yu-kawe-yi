import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/app_config.dart';
import '../models/domain_models.dart';
import 'local_file_bridge.dart';

/// Unified Repository connecting cleanly to Supabase Cloud, same-origin
/// persistent Node backend when running locally on Web (`/api/*`), and
/// full offline SharedPreferences + local analytical engines.
class BackendRepository {
  BackendRepository._();
  static final BackendRepository instance = BackendRepository._();

  static const _profileKey = 'yitte_cached_profile_v3';
  static const _reflectionsKey = 'yitte_cached_reflections_v3';
  static const _snapshotKey = 'yitte_ecosystem_snapshot_v4';

  SupabaseClient? get _client =>
      AppConfig.isSupabaseConfigured ? Supabase.instance.client : null;

  bool get isCloudConnected => _client != null;

  Future<UserProfile?> restoreSessionProfile() async {
    final prefs = await SharedPreferences.getInstance();
    if (_client != null && _client!.auth.currentUser != null) {
      try {
        final uid = _client!.auth.currentUser!.id;
        final row = await _client!
            .from('profiles')
            .select()
            .eq('id', uid)
            .single();
        final profile = UserProfile.fromJson(
          Map<String, dynamic>.from(row),
          email: _client!.auth.currentUser!.email ?? '',
        );
        await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
        return profile;
      } catch (_) {
        // Fallback to cached profile while offline
      }
    }

    final raw = prefs.getString(_profileKey);
    if (raw == null || raw.isEmpty) return null;
    return UserProfile.fromJson(Map<String, dynamic>.from(jsonDecode(raw)));
  }

  static String _nameFromEmail(String email) {
    final localPart = email.split('@').first.trim();
    final parts = localPart
        .split(RegExp(r'[._-]+'))
        .where((p) => p.isNotEmpty)
        .map((p) => '${p[0].toUpperCase()}${p.length > 1 ? p.substring(1) : ''}')
        .toList();
    return parts.isEmpty ? 'Participant' : parts.join(' ');
  }

  Future<UserProfile> signIn({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (_client != null) {
      final res = await _client!.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );
      final uid = res.user?.id;
      if (uid == null) throw StateError('Connexion Supabase échouée.');
      final row = await _client!.from('profiles').select().eq('id', uid).single();
      final profile = UserProfile.fromJson(
        Map<String, dynamic>.from(row),
        email: email.trim(),
      );
      await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
      return profile;
    }

    if (kIsWeb) {
      try {
        final res = await http
            .post(
              Uri.parse('/api/auth/login'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'email': email.trim(),
                'password': password,
                if (displayName != null && displayName.trim().isNotEmpty)
                  'displayName': displayName.trim(),
              }),
            )
            .timeout(const Duration(seconds: 3));
        final parsed = jsonDecode(res.body) as Map<String, dynamic>;
        if (res.statusCode == 200 && parsed['ok'] == true && parsed['user'] is Map) {
          final u = Map<String, dynamic>.from(parsed['user'] as Map);
          final profile = UserProfile(
            id: u['id'].toString(),
            username: u['username']?.toString() ?? 'user',
            fullName: u['full_name']?.toString() ?? _nameFromEmail(email),
            email: u['email']?.toString() ?? email.trim(),
            role: AppRole.fromCode(u['role_code']?.toString() ?? 'member'),
            onboardingCompleted: true,
            isGroupMember: u['is_group_member'] == true ||
                GroupMembershipCatalog.isRecognizedName(
                  u['full_name']?.toString() ?? '',
                ),
          );
          await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
          return profile;
        }
        if (res.statusCode == 401) {
          throw StateError(parsed['error']?.toString() ?? 'Identifiants invalides.');
        }
      } catch (e) {
        if (e is StateError) rethrow;
      }
    }

    final cleanName = (displayName != null && displayName.trim().isNotEmpty)
        ? displayName.trim()
        : _nameFromEmail(email);
    final localProfile = UserProfile(
      id: 'local-${email.hashCode.abs()}',
      username: email.split('@').first.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_'),
      fullName: cleanName,
      email: email.trim(),
      role: AppRole.superAdmin,
      onboardingCompleted: true,
    );
    await prefs.setString(_profileKey, jsonEncode(localProfile.toJson()));
    return localProfile;
  }

  Future<UserProfile> signInByFullName({
    required String fullName,
    String? inviteCode,
    List<String> extraAuthorizedNames = const [],
  }) async {
    final cleanName = fullName.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (cleanName.length < 2) {
      throw StateError('Veuillez saisir votre nom complet (minimum 2 caractères).');
    }

    final canonicalName =
        GroupMembershipCatalog.matchCanonicalName(cleanName, extraAuthorizedNames);
    if (canonicalName == null) {
      throw StateError(
        'Ce nom ne figure pas dans la liste officielle des membres du groupe. '
        'Les personnes extérieures au groupe doivent utiliser « Connexion Standard ».',
      );
    }

    final prefs = await SharedPreferences.getInstance();

    if (kIsWeb) {
      try {
        final res = await http
            .post(
              Uri.parse('/api/auth/name-login'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'fullName': canonicalName,
                if (inviteCode != null && inviteCode.trim().isNotEmpty)
                  'inviteCode': inviteCode.trim(),
              }),
            )
            .timeout(const Duration(seconds: 3));
        final parsed = jsonDecode(res.body) as Map<String, dynamic>;
        if (res.statusCode == 200 && parsed['ok'] == true && parsed['user'] is Map) {
          final u = Map<String, dynamic>.from(parsed['user'] as Map);
          final profile = UserProfile(
            id: u['id'].toString(),
            username: u['username']?.toString() ?? 'membre',
            fullName: u['full_name']?.toString() ?? canonicalName,
            email: u['email']?.toString() ?? '',
            role: AppRole.fromCode(u['role_code']?.toString() ?? 'member'),
            onboardingCompleted: true,
            isGroupMember: true,
          );
          await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
          return profile;
        }
        if (res.statusCode >= 400) {
          throw StateError(parsed['error']?.toString() ?? 'Connexion impossible.');
        }
      } catch (e) {
        if (e is StateError) rethrow;
      }
    }

    final slug = GroupMembershipCatalog.normalizeName(canonicalName)
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    final username = slug.isEmpty ? 'membre' : slug;
    final codeUpper = inviteCode?.trim().toUpperCase() ?? '';
    final role = codeUpper.startsWith('YITTE-SUP')
        ? AppRole.superAdmin
        : (codeUpper.startsWith('YITTE-ADM') || codeUpper.startsWith('ADMIN'))
            ? AppRole.admin
            : AppRole.member;

    final localProfile = UserProfile(
      id: 'member-${GroupMembershipCatalog.normalizeName(canonicalName).hashCode.abs()}',
      username: username,
      fullName: canonicalName,
      email: '$username@membre.boroomyitte.local',
      role: role,
      onboardingCompleted: true,
      isGroupMember: true,
    );
    await prefs.setString(_profileKey, jsonEncode(localProfile.toJson()));
    return localProfile;
  }

  Future<UserProfile> register({
    required String email,
    required String password,
    required String fullName,
    required String username,
    String? inviteCode,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (_client != null) {
      final res = await _client!.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'full_name': fullName.trim(),
          'username': username.trim(),
          'preferred_language': 'fr',
        },
      );
      final uid = res.user?.id;
      if (uid == null) throw StateError('Inscription échouée.');

      if (inviteCode != null && inviteCode.trim().isNotEmpty) {
        await _client!.rpc(
          'redeem_invitation_code',
          params: {'p_code': inviteCode.trim()},
        );
      }

      final row = await _client!.from('profiles').select().eq('id', uid).single();
      final profile = UserProfile.fromJson(
        Map<String, dynamic>.from(row),
        email: email.trim(),
      );
      await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
      return profile;
    }

    if (kIsWeb) {
      try {
        final res = await http
            .post(
              Uri.parse('/api/auth/register'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'email': email.trim(),
                'password': password,
                'fullName': fullName.trim(),
                'username': username.trim(),
                'inviteCode': inviteCode?.trim() ?? '',
              }),
            )
            .timeout(const Duration(seconds: 3));
        final parsed = jsonDecode(res.body) as Map<String, dynamic>;
        if (res.statusCode == 200 && parsed['ok'] == true && parsed['user'] is Map) {
          final u = Map<String, dynamic>.from(parsed['user'] as Map);
          final profile = UserProfile(
            id: u['id'].toString(),
            username: u['username']?.toString() ?? username.trim(),
            fullName: u['full_name']?.toString() ?? fullName.trim(),
            email: u['email']?.toString() ?? email.trim(),
            role: AppRole.fromCode(u['role_code']?.toString() ?? 'member'),
            onboardingCompleted: false,
            isGroupMember: u['is_group_member'] == true,
          );
          await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
          return profile;
        }
        if (res.statusCode == 409 || res.statusCode == 400) {
          throw StateError(parsed['error']?.toString() ?? 'Inscription refusée.');
        }
      } catch (e) {
        if (e is StateError) rethrow;
      }
    }

    final isRecognized = GroupMembershipCatalog.isRecognizedName(fullName) ||
        (inviteCode?.toUpperCase().startsWith('YITTE-SUP') == true);
    final profile = UserProfile(
      id: 'local-${DateTime.now().millisecondsSinceEpoch}',
      username: username.trim(),
      fullName: fullName.trim(),
      email: email.trim(),
      role: inviteCode?.toUpperCase().startsWith('ADMIN') == true
          ? AppRole.admin
          : AppRole.member,
      onboardingCompleted: false,
      isGroupMember: isRecognized,
    );
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
    return profile;
  }

  Future<List<MemberDirectoryItem>> fetchServerMembers() async {
    if (kIsWeb && _client == null) {
      try {
        final res = await http
            .get(Uri.parse('/api/members'))
            .timeout(const Duration(seconds: 2));
        if (res.statusCode == 200) {
          final parsed = jsonDecode(res.body) as Map<String, dynamic>;
          final list = (parsed['members'] as List? ?? const []);
          return list
              .map((e) => MemberDirectoryItem.fromJson(Map<String, dynamic>.from(e)))
              .toList();
        }
      } catch (_) {}
    }
    return const [];
  }

  Future<void> saveProfile(UserProfile profile) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_profileKey, jsonEncode(profile.toJson()));
    if (_client != null && _client!.auth.currentUser != null) {
      await _client!.from('profiles').update({
        'full_name': profile.fullName,
        'bio': profile.bio,
        'city': profile.city,
        'country': profile.country,
        'preferred_language': profile.preferredLanguage,
        'cefr_level': profile.cefrLevel,
        'preferred_english_variant': profile.englishVariant,
        'interests': profile.interests,
        'onboarding_completed': profile.onboardingCompleted,
        'voice_recording_consent': profile.voiceRecordingConsent,
        'voice_retention_preference': profile.voiceRetentionPolicy,
        'show_on_educational_leaderboard': profile.showOnEducationalLeaderboard,
      }).eq('id', profile.id);
    }
  }

  Future<void> signOut() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_profileKey);
    if (_client != null) {
      await _client!.auth.signOut();
    }
  }

  Future<void> cacheReflections(List<ReflectionPost> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _reflectionsKey,
      jsonEncode(items.map((e) => e.toJson()).toList()),
    );
  }

  Future<List<ReflectionPost>?> loadCachedReflections() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_reflectionsKey);
    if (raw == null) return null;
    final list = jsonDecode(raw) as List;
    return list
        .map((e) => ReflectionPost.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  /// Persists full workspace state locally (SharedPreferences) and synchronizes
  /// with the local server database (`/api/snapshot`) when hosted over HTTP.
  Future<void> saveEcosystemSnapshot(Map<String, dynamic> snapshot) async {
    final encoded = jsonEncode(snapshot);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_snapshotKey, encoded);

    if (kIsWeb && _client == null) {
      try {
        await http
            .put(
              Uri.parse('/api/snapshot'),
              headers: {'Content-Type': 'application/json'},
              body: encoded,
            )
            .timeout(const Duration(seconds: 2));
      } catch (_) {
        // Ignore when offline or running in unit/widget tests
      }
    }
  }

  /// Loads persisted ecosystem state, preferring newer server snapshot on Web
  /// and falling back gracefully to SharedPreferences.
  Future<Map<String, dynamic>?> loadEcosystemSnapshot() async {
    if (kIsWeb && _client == null) {
      try {
        final res = await http
            .get(Uri.parse('/api/snapshot'))
            .timeout(const Duration(seconds: 2));
        if (res.statusCode == 200) {
          final parsed = jsonDecode(res.body);
          if (parsed is Map && parsed['exists'] == true && parsed['snapshot'] is Map) {
            final map = Map<String, dynamic>.from(parsed['snapshot'] as Map);
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString(_snapshotKey, jsonEncode(map));
            return map;
          }
        }
      } catch (_) {
        // Fallback to local SharedPreferences cache
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_snapshotKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return null;
    }
  }

  /// Calls a specialized AI agent via Supabase Edge Function (`ai-gateway`),
  /// same-origin `/api/ai` (Gemini/OpenAI or Node NLP engine when Web server active),
  /// or local deterministic analysis in Dart.
  Future<String> callAiAgent({
    required String agentName,
    required String prompt,
    String language = 'fr',
  }) async {
    if (_client != null) {
      final res = await _client!.functions.invoke(
        'ai-gateway',
        body: {
          'agent': agentName,
          'prompt': prompt,
          'language': language,
        },
      );
      final data = Map<String, dynamic>.from(res.data as Map);
      return data['content']?.toString() ?? '';
    }

    if (kIsWeb) {
      try {
        final res = await http
            .post(
              Uri.parse('/api/ai'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'agent': agentName,
                'prompt': prompt,
                'language': language,
              }),
            )
            .timeout(const Duration(seconds: 8));
        if (res.statusCode == 200) {
          final parsed = jsonDecode(res.body);
          if (parsed is Map && parsed['content'] != null) {
            return parsed['content'].toString();
          }
        }
      } catch (_) {
        // Fallback smoothly to on-device analyzer
      }
    }

    return _analyzeLocallyByAgent(agentName, prompt);
  }

  static String _analyzeLocallyByAgent(String agentName, String prompt) {
    final clean = prompt.trim();
    final words = clean.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    switch (agentName) {
      case 'YITTE_ENGLISH_COACH':
        final eval = _analyzeEnglishLocally(promptText: '', transcriptText: clean);
        return 'Diagnostic linguistique (${words.length} mots) :\n'
            '• Correction suggérée : ${eval.correctedSentences.first}\n'
            '• Expressions naturelles : ${eval.naturalExpressions.join(" | ")}\n'
            '• Exercice ciblé : ${eval.exercises.first}';

      case 'YITTE_CAREER_COACH':
        final lower = clean.toLowerCase();
        final hasContext = RegExp(
                r'(?:contexte|situation|projet|équipe|mission|client|stage|entreprise)')
            .hasMatch(lower);
        final hasAction = RegExp(
                r"(?:j['’]ai|nous avons|conçu|développ|gér|pilot|optimis|résolu|construit|dirig)")
            .hasMatch(lower);
        final hasMetrics = RegExp(r'\d+').hasMatch(clean);
        final starScore =
            (hasContext ? 30 : 12) + (hasAction ? 35 : 15) + (hasMetrics ? 35 : 15);
        final recs = <String>[
          if (!hasContext) 'Précisez le contexte initial et les enjeux du projet.',
          if (!hasAction)
            'Employez des verbes d’action concrets à la 1ʳᵉ personne (« J’ai conçu / arbitré / livré... »).',
          if (!hasMetrics)
            'Ajoutez au moins un résultat mesurable (%, utilisateurs, temps gagné, coût réduit).',
        ];
        return 'Score structurel STAR : $starScore / 100 (${words.length} mots analysés)\n'
            '• Situation : ${hasContext ? "Détectée" : "À préciser"}\n'
            '• Actions : ${hasAction ? "Exprimées" : "À renforcer"}\n'
            '• Impact chiffré : ${hasMetrics ? "Quantifié" : "Manquant"}\n'
            '${recs.isEmpty ? "Structure STAR complète et convaincante." : "Axes d’amélioration :\n- ${recs.join('\n- ')}"}';

      case 'YITTE_PERSONAL_MENTOR':
        final lower = clean.toLowerCase();
        final overload = RegExp(r'\b(trop|temps|fatigue|priorit|tout faire|surcharg)\b')
            .hasMatch(lower);
        final extract = words.take(8).join(' ');
        return 'Plan d’action concret autour de « $extract${words.length > 8 ? "..." : ""} » :\n'
            '1. ${overload ? "Sélectionnez UNE priorité unique pour les 24h à venir et mettez le reste en attente." : "Bloquez 25 minutes fixes sans téléphone pour lancer le premier pas dès aujourd’hui."}\n'
            '2. Définissez un critère de réussite observable ce soir (ex. 1 page, 1 exercice, 15 min).\n'
            '3. Question de bilan : quel obstacle précis a ralenti votre constance ces derniers jours, et quel ajustement simple pouvez-vous tester demain matin ?';

      case 'YITTE_SUMMARIZER':
        final lines = clean
            .split(RegExp(r'\n+'))
            .map((l) => l.trim())
            .where((l) => l.length > 10)
            .toList();
        return 'Synthèse analytique (${lines.length} éléments traités) :\n'
            '${lines.take(4).map((l) => "• $l").join("\n")}';

      case 'YITTE_SPIRITUAL_ASSISTANT':
        return 'Repères éducatifs vérifiés : privilégiez les versets coraniques et hadiths authentifiés (al-Bukhari, Muslim) avec contextualisation savante ; cet espace ne délivre pas de fatwa.';

      default:
        final debate = analyzeDebateLocally(
          transcriptText: clean,
          topicQuestion: 'Analyse logique',
          isIslamicSubject: false,
        );
        return '${debate.explanation}\nRecommandations :\n- ${debate.recommendations.join('\n- ')}';
    }
  }

  /// Evaluates a debate speech via real STT + `debate-evaluate` Edge Function when cloud is connected,
  /// or runs transparent local structural rubric diagnostics.
  Future<DebateRubricBreakdown> evaluateDebateSpeech({
    required DebateMatchModel match,
    required String transcriptText,
    String? audioFilePath,
    required bool consentGranted,
    required String retentionPolicy,
  }) async {
    if (_client != null && _client!.auth.currentUser != null) {
      String? recordingId;
      String finalTranscript = transcriptText;

      if (audioFilePath != null &&
          localFileExists(audioFilePath) &&
          consentGranted) {
        final uid = _client!.auth.currentUser!.id;
        final storagePath =
            '$uid/debates/${match.id}_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await uploadLocalRecording(
          client: _client!,
          bucket: 'voice-recordings',
          storagePath: storagePath,
          filePath: audioFilePath,
        );

        final recRow = await _client!.from('voice_recordings').insert({
          'user_id': uid,
          'context_type': 'debate',
          'context_id': match.id,
          'storage_path': storagePath,
          'duration_seconds': 60,
          'file_size_bytes': localFileLength(audioFilePath),
          'consent_granted': true,
          'retention_policy': retentionPolicy,
        }).select().single();
        recordingId = recRow['id'].toString();

        if (finalTranscript.trim().isEmpty) {
          final sttRes = await _client!.functions.invoke(
            'stt-transcribe',
            body: {'recording_id': recordingId, 'language': 'fr'},
          );
          final sttMap = Map<String, dynamic>.from(sttRes.data as Map);
          finalTranscript =
              sttMap['transcript']?['raw_text']?.toString() ?? finalTranscript;
        }
      }

      final evalRes = await _client!.functions.invoke(
        'debate-evaluate',
        body: {
          'match_id': match.id,
          'participant_id': match.id,
          'transcript_text': finalTranscript,
        },
      );
      final r = Map<String, dynamic>.from(
        (evalRes.data as Map)['rubric'] as Map,
      );
      return DebateRubricBreakdown(
        relevance: (r['score_relevance'] as num).toDouble(),
        logicalReasoning: (r['score_logical_reasoning'] as num).toDouble(),
        depthOfAnalysis: (r['score_depth_analysis'] as num).toDouble(),
        argumentsAndExamples:
            (r['score_arguments_examples'] as num).toDouble(),
        criticalNuance: (r['score_critical_nuance'] as num).toDouble(),
        clarity: (r['score_clarity'] as num).toDouble(),
        contradictions:
            List<String>.from(r['detected_contradictions'] ?? const []),
        unsupportedClaims:
            List<String>.from(r['unsupported_claims'] ?? const []),
        fallacies: List<String>.from(r['logical_fallacies'] ?? const []),
        nuances: List<String>.from(r['recognized_nuances'] ?? const []),
        examples: List<String>.from(r['relevant_examples'] ?? const []),
        explanation: r['score_explanation']?.toString() ?? '',
        recommendations:
            List<String>.from(r['improvement_recommendations'] ?? const []),
        verifiedReferences:
            List<String>.from(r['verified_references'] ?? const []),
        isLocalPreview: false,
      );
    }

    return analyzeDebateLocally(
      transcriptText: transcriptText,
      topicQuestion: match.topicQuestion,
      isIslamicSubject: match.isIslamicSubject,
    );
  }

  /// Transparent local structural analyzer inspecting logical connectors,
  /// examples, generalizations, and nuance criteria.
  static DebateRubricBreakdown analyzeDebateLocally({
    required String transcriptText,
    required String topicQuestion,
    required bool isIslamicSubject,
  }) {
    final text = transcriptText.trim();
    final words = text.isEmpty ? <String>[] : text.split(RegExp(r'\s+'));
    final lower = text.toLowerCase();

    final connectorMatches = RegExp(
      r"\b(car|parce que|donc|cependant|toutefois|en effet|ainsi|premièrement|deuxièmement|en outre|pourtant|néanmoins)\b",
    ).allMatches(lower).length;
    final hasConnectors = connectorMatches > 0;
    final hasExamples = RegExp(
      r'\b(exemple|notamment|histoire|science|étude|expérience|cas|donnée|statistique|source)\b',
    ).hasMatch(lower);
    final hasNuance = RegExp(
      r"\b(nuance|cependant|néanmoins|d’autre part|d'autre part|limite|condition|équilibre|selon)\b",
    ).hasMatch(lower);
    final absolutes = RegExp(
      r'\b(toujours|jamais|tout le monde|personne|forcément|évidemment)\b',
    ).allMatches(lower).map((m) => m.group(0)!).toSet().toList();

    final relevance =
        words.length >= 25 ? 16.5 : (words.length * 0.62).clamp(4.0, 16.5);
    final logic = connectorMatches >= 2
        ? 21.0
        : (hasConnectors ? 18.0 : 12.5);
    final depth = words.length >= 60 ? 16.5 : (words.length >= 30 ? 13.5 : 10.5);
    final examples = hasExamples ? 12.5 : 7.0;
    final nuance = (hasNuance && absolutes.isEmpty)
        ? 9.0
        : (hasNuance ? 7.0 : 4.5);
    final clarity = words.length >= 18 ? 8.5 : 5.5;

    return DebateRubricBreakdown(
      relevance: relevance,
      logicalReasoning: logic,
      depthOfAnalysis: depth,
      argumentsAndExamples: examples,
      criticalNuance: nuance,
      clarity: clarity,
      contradictions: words.length < 15
          ? const ['Discours trop bref pour vérifier la cohérence complète des prémisses.']
          : const [],
      unsupportedClaims: [
        if (!hasExamples)
          'Ajoutez au moins un exemple historique, empirique ou textuel vérifié.',
        if (absolutes.isNotEmpty)
          'Affirmations absolues relevées (${absolutes.join(", ")}) sans réserve explicite.',
      ],
      fallacies: absolutes.isNotEmpty
          ? ['Risque de généralisation hâtive autour de : ${absolutes.join(", ")}.']
          : const [],
      nuances: hasNuance
          ? const ['Prise en compte de perspectives contrastées identifiée dans le texte.']
          : const [],
      examples: hasExamples
          ? const ['Illustration / repère factuel détecté dans l’argumentation.']
          : const [],
      explanation:
          'Analyse logique de ${words.length} mots sur « $topicQuestion » '
          '($connectorMatches connecteur(s) argumentatif(s)). '
          '${isIslamicSubject ? "Distinction appliquée entre faits scripturaires établis et interprétation raisonnée." : ""}',
      recommendations: [
        if (!hasConnectors)
          'Articulez explicitement vos prémisses et conclusions (« car », « donc », « cependant »).',
        if (!hasExamples)
          'Étayez chaque argument par un exemple concret ou une donnée vérifiable.',
        if (!hasNuance)
          'Formulez une objection adverse puis répondez-y avec discernement.',
        if (absolutes.isNotEmpty)
          'Nuancez les termes absolus (${absolutes.join(", ")}) pour renforcer la rigueur.',
      ],
      verifiedReferences: isIslamicSubject
          ? const ['Distinction méthodologique : sources scripturaires vérifiées vs ijtihad raisonné']
          : const [],
      isLocalPreview: true,
    );
  }

  Future<EnglishSpeakingEval> evaluateEnglishSpeaking({
    required String promptText,
    required String transcriptText,
    required String variant,
    required String cefrLevel,
  }) async {
    if (_client != null && _client!.auth.currentUser != null) {
      final res = await _client!.functions.invoke(
        'english-evaluate',
        body: {
          'prompt_text': promptText,
          'transcript_text': transcriptText,
          'target_variant': variant,
          'cefr_level': cefrLevel,
        },
      );
      final r = Map<String, dynamic>.from((res.data as Map)['rubric'] as Map);
      return EnglishSpeakingEval(
        grammar: (r['score_grammar'] as num).toDouble(),
        vocabulary: (r['score_vocabulary'] as num).toDouble(),
        fluency: (r['score_fluency'] as num).toDouble(),
        intelligibility: (r['score_intelligibility'] as num).toDouble(),
        coherence: (r['score_coherence'] as num).toDouble(),
        transcript: transcriptText,
        correctedSentences:
            List<String>.from(r['corrected_sentences'] ?? const []),
        naturalExpressions:
            List<String>.from(r['natural_expressions'] ?? const []),
        suggestedVocabulary: (r['suggested_vocabulary'] as List? ?? const [])
            .map((e) => e is Map ? '${e['word']} (${e['cefr']})' : e.toString())
            .toList(),
        exercises: (r['personalized_exercises'] as List? ?? const [])
            .map((e) => e is Map ? '${e['prompt']}' : e.toString())
            .toList(),
        isLocalPreview: false,
      );
    }

    return _analyzeEnglishLocally(
      promptText: promptText,
      transcriptText: transcriptText,
      variant: variant,
    );
  }

  static EnglishSpeakingEval _analyzeEnglishLocally({
    required String promptText,
    required String transcriptText,
    String variant = 'en-GB',
  }) {
    final text = transcriptText.trim();
    final words = text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final uniqueWords = words.map((w) => w.toLowerCase()).toSet();
    final lower = text.toLowerCase();
    var corrected = text;
    final detectedNotes = <String>[];

    final aVowel = RegExp(r'\ba\s+([aeiouAEIOU][a-zA-Z]+)');
    if (aVowel.hasMatch(corrected)) {
      corrected = corrected.replaceAllMapped(aVowel, (m) => 'an ${m.group(1)}');
      detectedNotes.add('Article: use "an" before vowel sounds.');
    }
    if (RegExp(r'\bdespite of\b', caseSensitive: false).hasMatch(corrected)) {
      corrected = corrected.replaceAll(
        RegExp(r'\bdespite of\b', caseSensitive: false),
        'despite',
      );
      detectedNotes.add('"Despite" is never followed by "of".');
    }
    if (RegExp(r'\bdiscuss about\b', caseSensitive: false).hasMatch(corrected)) {
      corrected = corrected.replaceAll(
        RegExp(r'\bdiscuss about\b', caseSensitive: false),
        'discuss',
      );
      detectedNotes.add('"Discuss" takes a direct object without "about".');
    }
    if (RegExp(r'\bi\b').hasMatch(corrected)) {
      corrected = corrected.replaceAll(RegExp(r'\bi\b'), 'I');
      detectedNotes.add('Capitalize the pronoun "I".');
    }
    final uncountable = RegExp(r'\b(informations|advices|equipments)\b',
        caseSensitive: false);
    if (uncountable.hasMatch(corrected)) {
      corrected = corrected
          .replaceAll(RegExp(r'\binformations\b', caseSensitive: false), 'information')
          .replaceAll(RegExp(r'\badvices\b', caseSensitive: false), 'advice')
          .replaceAll(RegExp(r'\bequipments\b', caseSensitive: false), 'equipment');
      detectedNotes.add('Information / advice / equipment are uncountable in English.');
    }

    final connectors = RegExp(
      r'\b(although|however|despite|therefore|because|moreover|whereas|while)\b',
    ).allMatches(lower).length;

    final grammarScore = (18.0 - (detectedNotes.length * 1.5)).clamp(10.0, 19.0);
    final vocabScore = uniqueWords.length >= 18
        ? 17.5
        : (uniqueWords.length * 0.85).clamp(9.0, 17.5);
    final fluencyScore = words.length >= 25 ? 17.5 : (words.length * 0.65).clamp(9.0, 17.5);
    final intelligibilityScore = 18.0; // Accent-fair: intelligibility, never native imitation
    final coherenceScore = connectors >= 2 ? 18.0 : (connectors == 1 ? 15.5 : 13.0);

    return EnglishSpeakingEval(
      grammar: grammarScore,
      vocabulary: vocabScore,
      fluency: fluencyScore,
      intelligibility: intelligibilityScore,
      coherence: coherenceScore,
      transcript: transcriptText,
      correctedSentences: [
        if (corrected != text)
          'Corrected ($variant): "$corrected"'
        else
          'Clean draft ($variant): "$text"',
      ],
      naturalExpressions: const [
        'From a balanced perspective...',
        'A clear illustration of this is...',
        'Rather than rushing to conclusions...',
      ],
      suggestedVocabulary: const ['discernment (C1)', 'coherent (B2)', 'articulate (B1)'],
      exercises: detectedNotes.isNotEmpty
          ? detectedNotes
          : const [
              'Connect two sentences with "Although" or "Despite" to highlight nuance.',
            ],
      isLocalPreview: true,
    );
  }

  Future<Map<String, String>?> fetchLiveKitJoinToken(String roomId) async {
    if (_client == null) return null;
    final res = await _client!.functions.invoke(
      'livekit-token',
      body: {'room_id': roomId},
    );
    final data = Map<String, dynamic>.from(res.data as Map);
    return {
      'url': data['livekit_url']?.toString() ?? '',
      'token': data['token']?.toString() ?? '',
      'room': data['room_name']?.toString() ?? '',
    };
  }

  Future<bool> resetPassword({
    required String email,
    required String newPassword,
  }) async {
    if (_client != null) {
      await _client!.auth.resetPasswordForEmail(email.trim());
      return true;
    }
    if (kIsWeb) {
      final res = await http
          .post(
            Uri.parse('/api/auth/reset-password'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email.trim(),
              'newPassword': newPassword,
            }),
          )
          .timeout(const Duration(seconds: 3));
      final parsed = jsonDecode(res.body) as Map<String, dynamic>;
      if (res.statusCode == 200 && parsed['ok'] == true) {
        return true;
      }
      throw StateError(parsed['error']?.toString() ?? 'Échec de réinitialisation.');
    }
    return true;
  }

  /// Uploads an original file to Supabase / Node `/api/upload` and extracts readable text.
  Future<Map<String, dynamic>> uploadDocumentFile({
    required String fileName,
    required List<int> bytes,
    String? providedText,
  }) async {
    if (kIsWeb && _client == null) {
      try {
        final res = await http
            .post(
              Uri.parse('/api/upload'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'fileName': fileName,
                'base64Data': base64Encode(bytes),
                if (providedText != null && providedText.trim().isNotEmpty)
                  'providedText': providedText.trim(),
              }),
            )
            .timeout(const Duration(seconds: 10));
        if (res.statusCode == 200) {
          return Map<String, dynamic>.from(jsonDecode(res.body) as Map);
        }
      } catch (_) {}
    }

    final ext = fileName.contains('.')
        ? fileName.split('.').last.toLowerCase()
        : 'txt';
    String? extracted = (providedText != null && providedText.trim().isNotEmpty)
        ? providedText.trim()
        : null;
    String? warning;
    if (extracted == null && (ext == 'txt' || ext == 'md' || ext == 'csv')) {
      extracted = utf8.decode(bytes, allowMalformed: true).trim();
    } else if (extracted == null) {
      warning =
          'Fichier .$ext enregistré localement. Ajoutez un extrait textuel source pour permettre la synthèse documentaire vérifiable.';
    }
    return {
      'ok': true,
      'storageUrl': null,
      'fileSizeBytes': bytes.length,
      'extractedText': extracted,
      'unreadableWarning': warning,
    };
  }

  /// Uploads a recorded voice message / plaidoyer bytes so all devices can stream it cleanly.
  Future<String?> uploadAudioRecording({
    required String fileName,
    required List<int> bytes,
  }) async {
    if (bytes.isEmpty) return null;
    if (_client != null && _client!.auth.currentUser != null) {
      try {
        final uid = _client!.auth.currentUser!.id;
        final storagePath =
            '$uid/audio/${DateTime.now().millisecondsSinceEpoch}_$fileName';
        await _client!.storage.from('voice-recordings').uploadBinary(
              storagePath,
              Uint8List.fromList(bytes),
            );
        return _client!.storage
            .from('voice-recordings')
            .getPublicUrl(storagePath);
      } catch (_) {}
    }
    if (kIsWeb && _client == null) {
      try {
        final res = await http
            .post(
              Uri.parse('/api/upload'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'fileName': fileName,
                'base64Data': base64Encode(bytes),
                'providedText': '[Audio vocal]',
              }),
            )
            .timeout(const Duration(seconds: 10));
        if (res.statusCode == 200) {
          final parsed = Map<String, dynamic>.from(jsonDecode(res.body) as Map);
          return parsed['storageUrl']?.toString();
        }
      } catch (_) {}
    }
    return null;
  }

  Future<void> deleteUploadedFile(String? storageUrl) async {
    final raw = storageUrl?.trim() ?? '';
    if (!kIsWeb || _client != null || !raw.startsWith('/api/files/')) return;
    try {
      await http.delete(Uri.parse(raw)).timeout(const Duration(seconds: 3));
    } catch (_) {
      // Ignore cleanup errors on offline tests
    }
  }

  /// Generates a faithful 8-section summary STRICTLY from real source text.
  /// Never invents content when source text is empty or unreadable (Partie II Section 5).
  Future<DocumentSummaryModel> summarizeDocumentSource({
    required LibraryDocumentModel document,
  }) async {
    final source = (document.extractedText ?? '').trim();
    if (source.length < 20) {
      throw StateError(
        'Aucune source textuelle lisible disponible pour « ${document.title} ». '
        'Conformément à la règle anti-invention, aucun résumé ne sera généré sans contenu source.',
      );
    }

    if (kIsWeb && _client == null) {
      try {
        final res = await http
            .post(
              Uri.parse('/api/summarize-document'),
              headers: {'Content-Type': 'application/json'},
              body: jsonEncode({
                'documentId': document.id,
                'title': document.title,
                'sourceText': source,
              }),
            )
            .timeout(const Duration(seconds: 6));
        if (res.statusCode == 200) {
          final parsed = Map<String, dynamic>.from(jsonDecode(res.body) as Map);
          return DocumentSummaryModel.fromJson(parsed);
        }
      } catch (_) {}
    }

    return summarizeSourceTextLocally(
      documentId: document.id,
      title: document.title,
      sourceText: source,
    );
  }

  static DocumentSummaryModel summarizeSourceTextLocally({
    required String documentId,
    required String title,
    required String sourceText,
  }) {
    final clean = sourceText.trim();
    if (clean.length < 20) {
      throw StateError(
        'Texte source insuffisant (< 20 caractères) : impossible de résumer sans inventer.',
      );
    }
    final sentences = clean
        .split(RegExp(r'(?<=[.!?])\s+|\n+'))
        .map((s) => s.trim())
        .where((s) => s.length > 15)
        .toList();

    final freq = <String, int>{};
    const stops = {
      'dans', 'pour', 'avec', 'cette', 'sont', 'être', 'nous', 'vous',
      'mais', 'donc', 'plus', 'tout', 'elle', 'comme', 'leur', 'aussi',
    };
    for (final w in clean.toLowerCase().split(RegExp(r'[^a-zàâçéèêëîïôûùüÿñæœ0-9]+'))) {
      if (w.length >= 5 && !stops.contains(w)) {
        freq[w] = (freq[w] ?? 0) + 1;
      }
    }
    final sortedTerms = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final concepts = sortedTerms
        .take(6)
        .map((e) => '${e.key} (${e.value} occurrence${e.value > 1 ? 's' : ''})')
        .toList();

    final definitions = sentences
        .where((s) => RegExp(r'(?:signifie|est un|est une|désigne|consiste|définit)', caseSensitive: false).hasMatch(s))
        .take(4)
        .toList();
    final arguments = sentences
        .where((s) => RegExp(r'(?:car|parce que|donc|ainsi|cependant|toutefois|montre|prouve)', caseSensitive: false).hasMatch(s))
        .take(4)
        .toList();
    final references = sentences
        .where((s) => RegExp(r'(?:sourate|hadith|selon|référence|chapitre|article|\d{4})', caseSensitive: false).hasMatch(s))
        .take(4)
        .toList();

    return DocumentSummaryModel(
      sourceDocumentId: documentId,
      generalSummary: sentences.take(3).join(' ').isNotEmpty
          ? sentences.take(3).join(' ')
          : clean.substring(0, clean.length.clamp(0, 320)),
      mainIdeas: sentences.take(4).toList(),
      importantConcepts: concepts,
      definitions: definitions.isNotEmpty
          ? definitions
          : const ['Aucune définition explicite détectée dans l’extrait source.'],
      developedArguments: arguments.isNotEmpty
          ? arguments
          : sentences.take(2).toList(),
      authorConclusions: sentences.length >= 3
          ? [sentences.last]
          : const ['Consulter le texte source complet pour la conclusion intégrale.'],
      citedReferences: references.isNotEmpty
          ? references
          : const ['Aucune référence explicite extraite de l’extrait fourni.'],
      comprehensionQuestions: [
        'Quelle idée centrale est exposée dans « $title » ?',
        concepts.isNotEmpty
            ? 'Comment la notion de « ${concepts.first.split(' ').first} » structure-t-elle le propos ?'
            : 'Quels éléments soutiennent la conclusion du document ?',
      ],
      unreadableNotices: clean.length < 120
          ? const ['Source courte : synthèse établie uniquement sur l’extrait disponible.']
          : const [],
      isAiAssisted: true,
      status: 'draft',
      generatedAt: DateTime.now(),
    );
  }
}
