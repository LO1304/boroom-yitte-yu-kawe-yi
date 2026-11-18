import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/models/domain_models.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/backend_repository.dart';
import '../../core/services/livekit_service.dart';
import '../../core/services/notification_service.dart';
import '../../core/services/speech_bridge.dart';
import '../../core/services/whatsapp_bridge_service.dart';
import '../../core/theme/app_theme.dart';

const _uuid = Uuid();

final audioServiceProvider = Provider<AudioService>((ref) {
  final service = AudioService();
  ref.onDispose(service.dispose);
  return service;
});

final liveKitServiceProvider = Provider<LiveKitVoiceService>((ref) {
  final service = LiveKitVoiceService();
  ref.onDispose(service.disconnect);
  return service;
});

// Theme Mode
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('yitte_theme_mode');
    if (saved == 'light') state = ThemeMode.light;
    if (saved == 'dark') state = ThemeMode.dark;
  }

  Future<void> setMode(ThemeMode mode) async {
    state = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('yitte_theme_mode', mode.name);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});

// Sanctuary Color Palette (4 curated color harmonies, Light & Dark aware)
class ThemePaletteNotifier extends StateNotifier<SanctuaryPalette> {
  ThemePaletteNotifier() : super(SanctuaryPalette.emeraldGold) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('yitte_theme_palette');
    if (saved != null) state = SanctuaryPalette.fromCode(saved);
  }

  Future<void> setPalette(SanctuaryPalette palette) async {
    state = palette;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('yitte_theme_palette', palette.code);
  }
}

final themePaletteProvider =
    StateNotifierProvider<ThemePaletteNotifier, SanctuaryPalette>((ref) {
  return ThemePaletteNotifier();
});

// UI Visual & Layout Model (4 selectable structural aesthetics)
class UiVisualModelNotifier extends StateNotifier<UiVisualModel> {
  UiVisualModelNotifier() : super(UiVisualModel.glassLuxe) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('yitte_ui_visual_model');
    if (saved != null) state = UiVisualModel.fromCode(saved);
  }

  Future<void> setModel(UiVisualModel model) async {
    state = model;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('yitte_ui_visual_model', model.code);
  }
}

final uiVisualModelProvider =
    StateNotifierProvider<UiVisualModelNotifier, UiVisualModel>((ref) {
  return UiVisualModelNotifier();
});

// Language (FR primary, EN, AR RTL, WO ready)
class LanguageNotifier extends StateNotifier<AppLanguage> {
  LanguageNotifier() : super(AppLanguage.fr) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('yitte_language');
    if (code != null) state = AppLanguage.fromCode(code);
  }

  Future<void> setLanguage(AppLanguage lang) async {
    state = lang;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('yitte_language', lang.code);
  }
}

final languageProvider =
    StateNotifierProvider<LanguageNotifier, AppLanguage>((ref) {
  return LanguageNotifier();
});

// Auth & User Profile State
class AuthNotifier extends StateNotifier<UserProfile?> {
  AuthNotifier() : super(null) {
    restore();
  }

  Future<void> restore() async {
    final profile = await BackendRepository.instance.restoreSessionProfile();
    if (mounted) state = profile;
  }

  Future<void> signIn(
    String email,
    String password, {
    String? displayName,
  }) async {
    final p = await BackendRepository.instance.signIn(
      email: email,
      password: password,
      displayName: displayName,
    );
    state = p;
  }

  Future<void> signInByFullName({
    required String fullName,
    String? inviteCode,
    List<String> extraAuthorizedNames = const [],
  }) async {
    final p = await BackendRepository.instance.signInByFullName(
      fullName: fullName,
      inviteCode: inviteCode,
      extraAuthorizedNames: extraAuthorizedNames,
    );
    state = p;
  }

  Future<void> register({
    required String email,
    required String password,
    required String fullName,
    required String username,
    String? inviteCode,
  }) async {
    final p = await BackendRepository.instance.register(
      email: email,
      password: password,
      fullName: fullName,
      username: username,
      inviteCode: inviteCode,
    );
    state = p;
  }

  Future<void> updateProfile(UserProfile updated) async {
    state = updated;
    await BackendRepository.instance.saveProfile(updated);
  }

  Future<void> signOut() async {
    await BackendRepository.instance.signOut();
    state = null;
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, UserProfile?>((ref) {
  return AuthNotifier();
});

// Main Ecosystem State Controller across all functional modules
class EcosystemState {
  final List<ReflectionPost> reflections;
  final WeeklyTopicModel weeklyTopic;
  final List<ChallengeItem> challenges;
  final List<DebateMatchModel> debates;
  final List<QuizQuestionModel> quizQuestions;
  final int quizScoreTotal;
  final int quizMatchesPlayed;
  final List<ZikrSessionModel> zikrSessions;
  final int personalTasbihCount;
  final int personalZikrSessionsCount;
  final bool zikrReminderEnabled;
  final int salawatMonthlyTarget;
  final int salawatDurationDays;
  final String salawatCustomTitle;
  final int salawatMonthlyCount;
  final int salawatTodayCount;
  final String salawatLastDayIso;
  final String salawatCycleStartIso;
  final bool dailyTasbihReminderEnabled;
  final bool openTasbihOnLaunch;
  final List<VocabularyWordModel> dailyVocab;
  final List<EnglishLessonModel> englishLessons;
  final EnglishSpeakingEval? lastEnglishEval;
  final List<CareerOpportunityModel> careerOpportunities;
  final List<String> portfolioProjects;
  final String cvDraft;
  final String coverLetterDraft;
  final List<PersonalGoalModel> personalGoals;
  final List<HabitModel> habits;
  final List<ReadingBookModel> books;
  final List<PrivateNoteModel> privateNotes;
  final List<VoiceRoomModel> voiceRooms;
  final List<ChatMessageModel> messages;
  final Set<String> blockedUsers;
  final List<ModerationReportModel> reports;
  final List<String> generatedInvites;
  final List<String> auditLogs;
  final List<AnnouncementModel> announcements;
  final List<MemberDirectoryItem> members;
  final List<LeaderboardEntryModel> quizLeaderboard;
  final List<LibraryDocumentModel> libraryDocuments;
  final List<ExtraGroupeMeetingModel> extraGroupeMeetings;
  final List<AppNotificationItem> notifications;
  final String? validatedDailyThought;
  final String whatsappGroupName;
  final String? whatsappInviteUrl;
  final String? whatsappWebhookUrl;
  final List<String> authorizedGroupMembers;
  final bool restrictAppToGroupOnly;
  final List<String> deletedReflectionIds;

  const EcosystemState({
    required this.reflections,
    required this.weeklyTopic,
    required this.challenges,
    required this.debates,
    required this.quizQuestions,
    required this.quizScoreTotal,
    required this.quizMatchesPlayed,
    required this.zikrSessions,
    required this.personalTasbihCount,
    required this.personalZikrSessionsCount,
    required this.zikrReminderEnabled,
    required this.salawatMonthlyTarget,
    required this.salawatDurationDays,
    required this.salawatCustomTitle,
    required this.salawatMonthlyCount,
    required this.salawatTodayCount,
    required this.salawatLastDayIso,
    required this.salawatCycleStartIso,
    required this.dailyTasbihReminderEnabled,
    required this.openTasbihOnLaunch,
    required this.dailyVocab,
    required this.englishLessons,
    this.lastEnglishEval,
    required this.careerOpportunities,
    required this.portfolioProjects,
    required this.cvDraft,
    required this.coverLetterDraft,
    required this.personalGoals,
    required this.habits,
    required this.books,
    required this.privateNotes,
    required this.voiceRooms,
    required this.messages,
    required this.blockedUsers,
    required this.reports,
    required this.generatedInvites,
    required this.auditLogs,
    this.announcements = const [],
    this.members = const [],
    this.quizLeaderboard = const [],
    this.libraryDocuments = const [],
    this.extraGroupeMeetings = const [],
    this.notifications = const [],
    this.validatedDailyThought,
    this.whatsappGroupName = 'BOROOM YITTÉ YU KAWÉ YI — Groupe WhatsApp',
    this.whatsappInviteUrl =
        'https://chat.whatsapp.com/Ioa04LfRCvvFdTtCE6Hj7V?s=cl&p=a&iam=2',
    this.whatsappWebhookUrl,
    this.authorizedGroupMembers = GroupMembershipCatalog.officialMembers,
    this.restrictAppToGroupOnly = true,
    this.deletedReflectionIds = const [],
  });

  EcosystemState copyWith({
    List<ReflectionPost>? reflections,
    WeeklyTopicModel? weeklyTopic,
    List<ChallengeItem>? challenges,
    List<DebateMatchModel>? debates,
    List<QuizQuestionModel>? quizQuestions,
    int? quizScoreTotal,
    int? quizMatchesPlayed,
    List<ZikrSessionModel>? zikrSessions,
    int? personalTasbihCount,
    int? personalZikrSessionsCount,
    bool? zikrReminderEnabled,
    int? salawatMonthlyTarget,
    int? salawatDurationDays,
    String? salawatCustomTitle,
    int? salawatMonthlyCount,
    int? salawatTodayCount,
    String? salawatLastDayIso,
    String? salawatCycleStartIso,
    bool? dailyTasbihReminderEnabled,
    bool? openTasbihOnLaunch,
    List<VocabularyWordModel>? dailyVocab,
    List<EnglishLessonModel>? englishLessons,
    EnglishSpeakingEval? lastEnglishEval,
    List<CareerOpportunityModel>? careerOpportunities,
    List<String>? portfolioProjects,
    String? cvDraft,
    String? coverLetterDraft,
    List<PersonalGoalModel>? personalGoals,
    List<HabitModel>? habits,
    List<ReadingBookModel>? books,
    List<PrivateNoteModel>? privateNotes,
    List<VoiceRoomModel>? voiceRooms,
    List<ChatMessageModel>? messages,
    Set<String>? blockedUsers,
    List<ModerationReportModel>? reports,
    List<String>? generatedInvites,
    List<String>? auditLogs,
    List<AnnouncementModel>? announcements,
    List<MemberDirectoryItem>? members,
    List<LeaderboardEntryModel>? quizLeaderboard,
    List<LibraryDocumentModel>? libraryDocuments,
    List<ExtraGroupeMeetingModel>? extraGroupeMeetings,
    List<AppNotificationItem>? notifications,
    String? validatedDailyThought,
    bool clearDailyThought = false,
    String? whatsappGroupName,
    String? whatsappInviteUrl,
    bool clearWhatsappInviteUrl = false,
    String? whatsappWebhookUrl,
    bool clearWhatsappWebhookUrl = false,
    List<String>? authorizedGroupMembers,
    bool? restrictAppToGroupOnly,
    List<String>? deletedReflectionIds,
  }) {
    return EcosystemState(
      reflections: reflections ?? this.reflections,
      weeklyTopic: weeklyTopic ?? this.weeklyTopic,
      challenges: challenges ?? this.challenges,
      debates: debates ?? this.debates,
      quizQuestions: quizQuestions ?? this.quizQuestions,
      quizScoreTotal: quizScoreTotal ?? this.quizScoreTotal,
      quizMatchesPlayed: quizMatchesPlayed ?? this.quizMatchesPlayed,
      zikrSessions: zikrSessions ?? this.zikrSessions,
      personalTasbihCount: personalTasbihCount ?? this.personalTasbihCount,
      personalZikrSessionsCount:
          personalZikrSessionsCount ?? this.personalZikrSessionsCount,
      zikrReminderEnabled: zikrReminderEnabled ?? this.zikrReminderEnabled,
      salawatMonthlyTarget: salawatMonthlyTarget ?? this.salawatMonthlyTarget,
      salawatDurationDays: salawatDurationDays ?? this.salawatDurationDays,
      salawatCustomTitle: salawatCustomTitle ?? this.salawatCustomTitle,
      salawatMonthlyCount: salawatMonthlyCount ?? this.salawatMonthlyCount,
      salawatTodayCount: salawatTodayCount ?? this.salawatTodayCount,
      salawatLastDayIso: salawatLastDayIso ?? this.salawatLastDayIso,
      salawatCycleStartIso: salawatCycleStartIso ?? this.salawatCycleStartIso,
      dailyTasbihReminderEnabled:
          dailyTasbihReminderEnabled ?? this.dailyTasbihReminderEnabled,
      openTasbihOnLaunch: openTasbihOnLaunch ?? this.openTasbihOnLaunch,
      dailyVocab: dailyVocab ?? this.dailyVocab,
      englishLessons: englishLessons ?? this.englishLessons,
      lastEnglishEval: lastEnglishEval ?? this.lastEnglishEval,
      careerOpportunities: careerOpportunities ?? this.careerOpportunities,
      portfolioProjects: portfolioProjects ?? this.portfolioProjects,
      cvDraft: cvDraft ?? this.cvDraft,
      coverLetterDraft: coverLetterDraft ?? this.coverLetterDraft,
      personalGoals: personalGoals ?? this.personalGoals,
      habits: habits ?? this.habits,
      books: books ?? this.books,
      privateNotes: privateNotes ?? this.privateNotes,
      voiceRooms: voiceRooms ?? this.voiceRooms,
      messages: messages ?? this.messages,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      reports: reports ?? this.reports,
      generatedInvites: generatedInvites ?? this.generatedInvites,
      auditLogs: auditLogs ?? this.auditLogs,
      announcements: announcements ?? this.announcements,
      members: members ?? this.members,
      quizLeaderboard: quizLeaderboard ?? this.quizLeaderboard,
      libraryDocuments: libraryDocuments ?? this.libraryDocuments,
      extraGroupeMeetings: extraGroupeMeetings ?? this.extraGroupeMeetings,
      notifications: notifications ?? this.notifications,
      validatedDailyThought: clearDailyThought
          ? null
          : (validatedDailyThought ?? this.validatedDailyThought),
      whatsappGroupName: whatsappGroupName ?? this.whatsappGroupName,
      whatsappInviteUrl: clearWhatsappInviteUrl
          ? null
          : (whatsappInviteUrl ?? this.whatsappInviteUrl),
      whatsappWebhookUrl: clearWhatsappWebhookUrl
          ? null
          : (whatsappWebhookUrl ?? this.whatsappWebhookUrl),
      authorizedGroupMembers:
          authorizedGroupMembers ?? this.authorizedGroupMembers,
      restrictAppToGroupOnly:
          restrictAppToGroupOnly ?? this.restrictAppToGroupOnly,
      deletedReflectionIds: deletedReflectionIds ?? this.deletedReflectionIds,
    );
  }
}

class EcosystemNotifier extends StateNotifier<EcosystemState> {
  EcosystemNotifier() : super(_buildInitialState()) {
    _hydrateOfflineCache();
    _sseSub = SpeechBridge.subscribeLiveEvents(() {
      _hydrateOfflineCache();
    });
  }

  StreamSubscription<void>? _sseSub;

  @override
  void dispose() {
    _sseSub?.cancel();
    super.dispose();
  }

  static String _todayIso() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  void _persistSnapshot() {
    BackendRepository.instance.saveEcosystemSnapshot({
      'reflections': state.reflections.map((e) => e.toJson()).toList(),
      'weekly_topic': state.weeklyTopic.toJson(),
      'challenges': state.challenges.map((e) => e.toJson()).toList(),
      'debates': state.debates.map((e) => e.toJson()).toList(),
      'quiz_score_total': state.quizScoreTotal,
      'quiz_matches_played': state.quizMatchesPlayed,
      'daily_vocab': state.dailyVocab.map((e) => e.toJson()).toList(),
      'cv_draft': state.cvDraft,
      'cover_letter_draft': state.coverLetterDraft,
      'portfolio_projects': state.portfolioProjects,
      'personal_goals': state.personalGoals.map((e) => e.toJson()).toList(),
      'habits': state.habits.map((e) => e.toJson()).toList(),
      'books': state.books.map((e) => e.toJson()).toList(),
      'private_notes': state.privateNotes.map((e) => e.toJson()).toList(),
      'voice_rooms': state.voiceRooms.map((e) => e.toJson()).toList(),
      'messages': state.messages.map((e) => e.toJson()).toList(),
      'blocked_users': state.blockedUsers.toList(),
      'reports': state.reports.map((e) => e.toJson()).toList(),
      'generated_invites': state.generatedInvites,
      'audit_logs': state.auditLogs,
      'announcements': state.announcements.map((e) => e.toJson()).toList(),
      'members': state.members.map((e) => e.toJson()).toList(),
      'quiz_leaderboard': state.quizLeaderboard.map((e) => e.toJson()).toList(),
      'library_documents':
          state.libraryDocuments.map((e) => e.toJson()).toList(),
      'extra_groupe_meetings':
          state.extraGroupeMeetings.map((e) => e.toJson()).toList(),
      'notifications': state.notifications.map((e) => e.toJson()).toList(),
      'validated_daily_thought': state.validatedDailyThought,
      'whatsapp_group_name': state.whatsappGroupName,
      'whatsapp_invite_url': state.whatsappInviteUrl,
      'whatsapp_webhook_url': state.whatsappWebhookUrl,
      'authorized_group_members': state.authorizedGroupMembers,
      'restrict_app_to_group_only': state.restrictAppToGroupOnly,
      'deleted_reflection_ids': state.deletedReflectionIds,
    });
  }

  Future<void> _hydrateOfflineCache() async {
    final snap = await BackendRepository.instance.loadEcosystemSnapshot();
    final serverMembers = await BackendRepository.instance.fetchServerMembers();
    if (snap != null && mounted) {
      final deletedIds = snap['deleted_reflection_ids'] is List
          ? (snap['deleted_reflection_ids'] as List)
              .map((e) => e.toString())
              .toList()
          : state.deletedReflectionIds;
      final loadedReflections = snap['reflections'] is List
          ? (snap['reflections'] as List)
              .map((e) => ReflectionPost.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : state.reflections;
      final mergedReflections = _mergeHistoricalArchives(
        loadedReflections,
        state.reflections,
        deletedIds: deletedIds.toSet(),
      );
      final loadedMeetings = snap['extra_groupe_meetings'] is List
          ? (snap['extra_groupe_meetings'] as List)
              .map((e) => ExtraGroupeMeetingModel.fromJson(Map<String, dynamic>.from(e)))
              .toList()
          : state.extraGroupeMeetings;
      state = state.copyWith(
        reflections: mergedReflections,
        weeklyTopic: snap['weekly_topic'] is Map
            ? WeeklyTopicModel.fromJson(
                Map<String, dynamic>.from(snap['weekly_topic']))
            : state.weeklyTopic,
        challenges: snap['challenges'] is List
            ? (snap['challenges'] as List)
                .map((e) => ChallengeItem.fromJson(Map<String, dynamic>.from(e)))
                .toList()
            : state.challenges,
        debates: snap['debates'] is List
            ? (snap['debates'] as List)
                .map((e) => DebateMatchModel.fromJson(Map<String, dynamic>.from(e)))
                .toList()
            : state.debates,
        quizScoreTotal:
            (snap['quiz_score_total'] as num?)?.toInt() ?? state.quizScoreTotal,
        quizMatchesPlayed: (snap['quiz_matches_played'] as num?)?.toInt() ??
            state.quizMatchesPlayed,
        dailyVocab: snap['daily_vocab'] is List
            ? _mergeVocabularyBank(
                (snap['daily_vocab'] as List)
                    .map((e) => VocabularyWordModel.fromJson(
                        Map<String, dynamic>.from(e)))
                    .toList(),
                state.dailyVocab,
              )
            : state.dailyVocab,
        cvDraft: snap['cv_draft']?.toString() ?? state.cvDraft,
        coverLetterDraft:
            snap['cover_letter_draft']?.toString() ?? state.coverLetterDraft,
        portfolioProjects: snap['portfolio_projects'] is List
            ? (snap['portfolio_projects'] as List).map((e) => e.toString()).toList()
            : state.portfolioProjects,
        personalGoals: snap['personal_goals'] is List
            ? (snap['personal_goals'] as List)
                .map((e) => PersonalGoalModel.fromJson(Map<String, dynamic>.from(e)))
                .toList()
            : state.personalGoals,
        habits: snap['habits'] is List
            ? (snap['habits'] as List)
                .map((e) => HabitModel.fromJson(Map<String, dynamic>.from(e)))
                .toList()
            : state.habits,
        books: snap['books'] is List
            ? (snap['books'] as List)
                .map((e) => ReadingBookModel.fromJson(Map<String, dynamic>.from(e)))
                .toList()
            : state.books,
        privateNotes: snap['private_notes'] is List
            ? (snap['private_notes'] as List)
                .map((e) => PrivateNoteModel.fromJson(Map<String, dynamic>.from(e)))
                .toList()
            : state.privateNotes,
        voiceRooms: snap['voice_rooms'] is List
            ? (snap['voice_rooms'] as List)
                .map((e) => VoiceRoomModel.fromJson(Map<String, dynamic>.from(e)))
                .toList()
            : state.voiceRooms,
        messages: snap['messages'] is List
            ? (snap['messages'] as List)
                .map((e) => ChatMessageModel.fromJson(Map<String, dynamic>.from(e)))
                .toList()
            : state.messages,
        blockedUsers: snap['blocked_users'] is List
            ? (snap['blocked_users'] as List).map((e) => e.toString()).toSet()
            : state.blockedUsers,
        reports: snap['reports'] is List
            ? (snap['reports'] as List)
                .map((e) => ModerationReportModel.fromJson(Map<String, dynamic>.from(e)))
                .toList()
            : state.reports,
        generatedInvites: snap['generated_invites'] is List
            ? (snap['generated_invites'] as List).map((e) => e.toString()).toList()
            : state.generatedInvites,
        auditLogs: snap['audit_logs'] is List
            ? (snap['audit_logs'] as List).map((e) => e.toString()).toList()
            : state.auditLogs,
        announcements: snap['announcements'] is List
            ? (snap['announcements'] as List)
                .map((e) => AnnouncementModel.fromJson(Map<String, dynamic>.from(e)))
                .toList()
            : state.announcements,
        members: serverMembers.isNotEmpty
            ? serverMembers
            : (snap['members'] is List
                ? (snap['members'] as List)
                    .map((e) => MemberDirectoryItem.fromJson(Map<String, dynamic>.from(e)))
                    .toList()
                : state.members),
        quizLeaderboard: snap['quiz_leaderboard'] is List
            ? (snap['quiz_leaderboard'] as List)
                .map((e) => LeaderboardEntryModel.fromJson(Map<String, dynamic>.from(e)))
                .toList()
            : state.quizLeaderboard,
        libraryDocuments: snap['library_documents'] is List
            ? (snap['library_documents'] as List)
                .map((e) => LibraryDocumentModel.fromJson(Map<String, dynamic>.from(e)))
                .toList()
            : state.libraryDocuments,
        extraGroupeMeetings: loadedMeetings.isNotEmpty
            ? loadedMeetings
            : state.extraGroupeMeetings,
        notifications: snap['notifications'] is List
            ? (snap['notifications'] as List)
                .map((e) => AppNotificationItem.fromJson(Map<String, dynamic>.from(e)))
                .toList()
            : state.notifications,
        validatedDailyThought: snap['validated_daily_thought']?.toString(),
        whatsappGroupName: snap['whatsapp_group_name']?.toString().trim().isNotEmpty == true
            ? snap['whatsapp_group_name'].toString()
            : state.whatsappGroupName,
        whatsappInviteUrl: snap.containsKey('whatsapp_invite_url')
            ? (snap['whatsapp_invite_url']?.toString().trim().isNotEmpty == true
                ? snap['whatsapp_invite_url'].toString()
                : state.whatsappInviteUrl)
            : state.whatsappInviteUrl,
        whatsappWebhookUrl: snap['whatsapp_webhook_url']?.toString(),
        authorizedGroupMembers: snap['authorized_group_members'] is List
            ? (snap['authorized_group_members'] as List)
                .map((e) => e.toString())
                .toList()
            : state.authorizedGroupMembers,
        restrictAppToGroupOnly: snap['restrict_app_to_group_only'] != false,
        deletedReflectionIds: deletedIds,
      );
    } else {
      if (serverMembers.isNotEmpty && mounted) {
        state = state.copyWith(members: serverMembers);
      }
      final cached = await BackendRepository.instance.loadCachedReflections();
      if (cached != null && cached.isNotEmpty && mounted) {
        state = state.copyWith(
          reflections: _mergeHistoricalArchives(cached, state.reflections),
        );
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final savedTasbih = prefs.getInt('yitte_tasbih_count');
    final savedTarget = prefs.getInt('yitte_salawat_target');
    final savedDuration = prefs.getInt('yitte_salawat_duration_days');
    final savedTitle = prefs.getString('yitte_salawat_title');
    final savedSalawatMonth = prefs.getInt('yitte_salawat_monthly');
    final savedDayIso = prefs.getString('yitte_salawat_day');
    final todayIso = _todayIso();
    // Auto-rollover daily count when opening on a new calendar day
    final savedToday =
        (savedDayIso == todayIso) ? (prefs.getInt('yitte_salawat_today') ?? 0) : 0;
    final savedCycleStart = prefs.getString('yitte_salawat_cycle_start');
    final savedDailyRem = prefs.getBool('yitte_daily_tasbih_reminder');
    final savedOpenOnLaunch = prefs.getBool('yitte_open_tasbih_launch');

    if (mounted) {
      state = state.copyWith(
        personalTasbihCount: savedTasbih ?? state.personalTasbihCount,
        salawatMonthlyTarget: savedTarget ?? state.salawatMonthlyTarget,
        salawatDurationDays: savedDuration ?? state.salawatDurationDays,
        salawatCustomTitle: savedTitle ?? state.salawatCustomTitle,
        salawatMonthlyCount: savedSalawatMonth ?? state.salawatMonthlyCount,
        salawatTodayCount: savedToday,
        salawatLastDayIso: todayIso,
        salawatCycleStartIso: savedCycleStart ?? state.salawatCycleStartIso,
        dailyTasbihReminderEnabled:
            savedDailyRem ?? state.dailyTasbihReminderEnabled,
        openTasbihOnLaunch: savedOpenOnLaunch ?? state.openTasbihOnLaunch,
      );
    }
  }

  static List<VocabularyWordModel> _mergeVocabularyBank(
    List<VocabularyWordModel> loaded,
    List<VocabularyWordModel> defaults,
  ) {
    final existingIds = loaded.map((v) => v.id).toSet();
    final extra = defaults.where((v) => !existingIds.contains(v.id)).toList();
    if (extra.isEmpty) return loaded;
    return [...loaded, ...extra];
  }

  static List<ReflectionPost> _mergeHistoricalArchives(
    List<ReflectionPost> loaded,
    List<ReflectionPost> defaults, {
    Set<String> deletedIds = const {},
  }) {
    final existingIds = loaded.map((r) => r.id).toSet();
    final missingArchives = defaults
        .where((r) =>
            r.isHistoricalArchive &&
            !existingIds.contains(r.id) &&
            !deletedIds.contains(r.id))
        .toList();
    if (missingArchives.isEmpty) return loaded;
    return [...loaded, ...missingArchives];
  }

  // --- Reflections & Library ---
  void addReflection({
    required String authorId,
    required String authorName,
    required String title,
    required String body,
    required String category,
    String? attachmentName,
    String? introduction,
    String? contextText,
    String? motivatingFacts,
    String? problematics,
    List<String> mainQuestions = const [],
    List<String> secondaryQuestions = const [],
    List<String> reflectionAxes = const [],
    List<String> documentarySources = const [],
    String validationStatus = 'approved',
  }) {
    final post = ReflectionPost(
      id: _uuid.v4(),
      authorId: authorId,
      authorName: authorName,
      title: title,
      body: body,
      category: category,
      tags: [category, 'communauté'],
      attachmentName: attachmentName,
      introduction: introduction,
      contextText: contextText,
      motivatingFacts: motivatingFacts,
      problematics: problematics,
      mainQuestions: mainQuestions,
      secondaryQuestions: secondaryQuestions,
      reflectionAxes: reflectionAxes,
      documentarySources: documentarySources,
      validationStatus: validationStatus,
      createdAt: DateTime.now(),
    );
    final updated = [post, ...state.reflections];
    state = state.copyWith(
      reflections: updated,
      auditLogs: ['Publication ajoutée par $authorName : $title', ...state.auditLogs],
    );
    BackendRepository.instance.cacheReflections(updated);
    _persistSnapshot();
  }

  void approveReflectionProposal(String postId, String status) {
    final updated = state.reflections
        .map((p) => p.id == postId ? p.copyWith(validationStatus: status) : p)
        .toList();
    state = state.copyWith(
      reflections: updated,
      auditLogs: ['Validation éditoriale ($status) pour $postId', ...state.auditLogs],
    );
    BackendRepository.instance.cacheReflections(updated);
    _persistSnapshot();
  }

  void toggleReaction(String postId) {
    final updated = state.reflections
        .map((p) => p.id == postId
            ? p.copyWith(reactionsCount: p.reactionsCount + 1)
            : p)
        .toList();
    state = state.copyWith(reflections: updated);
    BackendRepository.instance.cacheReflections(updated);
    _persistSnapshot();
  }

  void toggleSaveReflection(String postId) {
    final updated = state.reflections
        .map((p) => p.id == postId ? p.copyWith(isSaved: !p.isSaved) : p)
        .toList();
    state = state.copyWith(reflections: updated);
    BackendRepository.instance.cacheReflections(updated);
    _persistSnapshot();
  }

  void featureInLibrary(String postId) {
    final updated = state.reflections
        .map((p) => p.id == postId
            ? p.copyWith(isFeaturedInLibrary: !p.isFeaturedInLibrary)
            : p)
        .toList();
    state = state.copyWith(
      reflections: updated,
      auditLogs: ['Bibliothèque mise à jour pour $postId', ...state.auditLogs],
    );
    BackendRepository.instance.cacheReflections(updated);
    _persistSnapshot();
  }

  void deleteReflection(String postId) {
    final updated = state.reflections.where((p) => p.id != postId).toList();
    final deletedIds = {...state.deletedReflectionIds, postId}.toList();
    state = state.copyWith(
      reflections: updated,
      deletedReflectionIds: deletedIds,
      auditLogs: ['Sujet / publication supprimé : $postId', ...state.auditLogs],
    );
    BackendRepository.instance.cacheReflections(updated);
    _persistSnapshot();
  }

  void toggleArchiveReflection(String postId) {
    final updated = state.reflections
        .map((p) => p.id == postId ? p.copyWith(isArchived: !p.isArchived) : p)
        .toList();
    state = state.copyWith(reflections: updated);
    BackendRepository.instance.cacheReflections(updated);
    _persistSnapshot();
  }

  void addComment(String postId, String authorName, String body) {
    final comment = ReflectionComment(
      id: _uuid.v4(),
      authorName: authorName,
      body: body,
      createdAt: DateTime.now(),
    );
    final updated = state.reflections
        .map((p) => p.id == postId
            ? p.copyWith(comments: [...p.comments, comment])
            : p)
        .toList();
    state = state.copyWith(reflections: updated);
    BackendRepository.instance.cacheReflections(updated);
    _persistSnapshot();
  }

  void addTopicContribution(String text) {
    final t = state.weeklyTopic;
    state = state.copyWith(
      weeklyTopic: WeeklyTopicModel(
        id: t.id,
        weekNumber: t.weekNumber,
        year: t.year,
        title: t.title,
        introduction: t.introduction,
        guidingQuestions: t.guidingQuestions,
        contributions: [...t.contributions, text],
        summary: t.summary,
      ),
    );
    _persistSnapshot();
  }

  Future<void> generateAiSummaryDraft() async {
    final t = state.weeklyTopic;
    final sourceItems = t.contributions.isNotEmpty
        ? t.contributions
        : state.reflections
            .where((r) => !r.isArchived)
            .take(4)
            .map((r) => '${r.title} : ${r.body}')
            .toList();
    final joinedContributions = sourceItems.join('\n');
    final aiText = await BackendRepository.instance.callAiAgent(
      agentName: 'YITTE_SUMMARIZER',
      prompt: 'Sujet : ${t.title}\nContributions :\n$joinedContributions',
    );
    final extractedTakeaways = sourceItems
        .take(4)
        .map((c) => c.trim())
        .where((c) => c.isNotEmpty)
        .toList();
    state = state.copyWith(
      weeklyTopic: WeeklyTopicModel(
        id: t.id,
        weekNumber: t.weekNumber,
        year: t.year,
        title: t.title,
        introduction: t.introduction,
        guidingQuestions: t.guidingQuestions,
        contributions: t.contributions,
        summary: TopicSummaryItem(
          id: _uuid.v4(),
          title: 'Synthèse Hebdomadaire — Semaine ${t.weekNumber}',
          summaryMarkdown:
              '$aiText\n\nTotal analysé : ${t.contributions.length} contribution(s) communautaire(s).',
          takeaways: extractedTakeaways.isNotEmpty
              ? extractedTakeaways
              : const ['En attente de contributions complémentaires.'],
          verifiedReferences: const [
            'Synthèse générée à partir des contributions réelles, soumise à validation éditeur',
          ],
          status: 'pending_review',
        ),
      ),
    );
    _persistSnapshot();
  }

  void approveAndPublishSummary(String editorName) {
    final s = state.weeklyTopic.summary;
    if (s == null) return;
    final t = state.weeklyTopic;
    state = state.copyWith(
      weeklyTopic: WeeklyTopicModel(
        id: t.id,
        weekNumber: t.weekNumber,
        year: t.year,
        title: t.title,
        introduction: t.introduction,
        guidingQuestions: t.guidingQuestions,
        contributions: t.contributions,
        summary: s.copyWith(status: 'published', reviewedByName: editorName),
      ),
      auditLogs: ['Résumé ${s.id} validé et publié par $editorName', ...state.auditLogs],
    );
    _persistSnapshot();
  }

  // --- Challenges ---
  void submitChallengeResponse(
    String challengeId,
    String responseText, {
    String? audioUrl,
  }) {
    final updated = state.challenges.map((c) {
      if (c.id != challengeId) return c;
      double score;
      if (c.correctAnswer != null) {
        score = responseText.trim().toLowerCase() ==
                c.correctAnswer!.trim().toLowerCase()
            ? 100
            : 45;
      } else {
        final eval = BackendRepository.analyzeDebateLocally(
          transcriptText: responseText,
          topicQuestion: c.title,
          isIslamicSubject: c.category == 'islamic_thought',
        );
        score = eval.totalScore.roundToDouble();
      }
      return c.copyWith(
        userSubmission: responseText,
        userAudioUrl: audioUrl,
        userScore: score,
      );
    }).toList();
    state = state.copyWith(challenges: updated);
    _persistSnapshot();
  }

  void createChallenge(ChallengeItem item) {
    state = state.copyWith(
      challenges: [item, ...state.challenges],
      auditLogs: ['Défi créé : ${item.title}', ...state.auditLogs],
    );
    _persistSnapshot();
  }

  // --- Debates (Face-à-Face) ---
  void createDebateMatch({
    required String topicTitle,
    required String topicQuestion,
    required String category,
    required bool isIslamicSubject,
    required String matchType,
    required String opponentName,
    required String userPosition,
    String? creatorName,
  }) {
    final match = DebateMatchModel(
      id: _uuid.v4(),
      topicTitle: topicTitle,
      topicQuestion: topicQuestion,
      category: category,
      isIslamicSubject: isIslamicSubject,
      matchType: matchType,
      status: 'open',
      creatorName: creatorName,
      opponentName: opponentName,
      userPosition: userPosition,
      opponentPosition: userPosition == 'for' ? 'against' : 'for',
    );
    state = state.copyWith(debates: [match, ...state.debates]);
    _persistSnapshot();
  }

  Future<void> submitDebateSpeech({
    required String matchId,
    required String transcriptText,
    String? audioPath,
    required bool consentGranted,
    required String retentionPolicy,
    bool asOpponent = false,
    String? speakerName,
  }) async {
    final match = state.debates.firstWhere((m) => m.id == matchId);
    final eval = await BackendRepository.instance.evaluateDebateSpeech(
      match: match,
      transcriptText: transcriptText,
      audioFilePath: audioPath,
      consentGranted: consentGranted,
      retentionPolicy: retentionPolicy,
    );

    final updated = state.debates.map((m) {
      if (m.id != matchId) return m;
      if (!asOpponent) {
        final otherEval = m.opponentEvaluation;
        final winner = otherEval != null
            ? (eval.totalScore >= otherEval.totalScore
                ? '${speakerName ?? m.creatorName ?? "Proposant"} (${eval.totalScore.toStringAsFixed(1)} vs ${otherEval.totalScore.toStringAsFixed(1)})'
                : '${m.opponentName} (${otherEval.totalScore.toStringAsFixed(1)} vs ${eval.totalScore.toStringAsFixed(1)})')
            : 'Plaidoyer évalué (${eval.totalScore.toStringAsFixed(1)} / 100) — en attente d’un second membre';
        return m.copyWith(
          status: otherEval != null ? 'completed' : 'awaiting_opponent',
          creatorName: speakerName ?? m.creatorName,
          userTranscript: transcriptText,
          userAudioPath: consentGranted ? audioPath : null,
          userEvaluation: eval,
          winnerLabel: winner,
        );
      } else {
        final firstEval = m.userEvaluation;
        final realOppName = speakerName ?? m.opponentName;
        final winner = firstEval != null
            ? (eval.totalScore > firstEval.totalScore
                ? '$realOppName (${eval.totalScore.toStringAsFixed(1)} vs ${firstEval.totalScore.toStringAsFixed(1)})'
                : '${m.creatorName ?? "Proposant"} (${firstEval.totalScore.toStringAsFixed(1)} vs ${eval.totalScore.toStringAsFixed(1)})')
            : '$realOppName a plaidé (${eval.totalScore.toStringAsFixed(1)} / 100)';
        return m.copyWith(
          status: firstEval != null ? 'completed' : 'awaiting_creator',
          opponentName: realOppName,
          opponentTranscript: transcriptText,
          opponentEvaluation: eval,
          winnerLabel: winner,
        );
      }
    }).toList();

    state = state.copyWith(debates: updated);
    _persistSnapshot();
  }

  void requestHumanDebateReview(String matchId, String reason) {
    final updated = state.debates
        .map((m) => m.id == matchId
            ? m.copyWith(status: 'under_review', humanReviewRequested: true)
            : m)
        .toList();
    state = state.copyWith(
      debates: updated,
      reports: [
        ModerationReportModel(
          id: _uuid.v4(),
          targetType: 'debate_match',
          reason: 'Demande de révision humaine : $reason',
          status: 'open',
          createdAt: DateTime.now(),
        ),
        ...state.reports,
      ],
    );
    _persistSnapshot();
  }

  // --- Quiz Arena ---
  void recordQuizPoints(
    int pointsEarned, {
    String? playerId,
    String? playerName,
  }) {
    final nextTotal = state.quizScoreTotal + pointsEarned;
    final nextMatches = state.quizMatchesPlayed + 1;
    final updatedBoard = [...state.quizLeaderboard];
    if (playerName != null && playerName.trim().isNotEmpty) {
      final pid = playerId ?? playerName.toLowerCase();
      final idx = updatedBoard.indexWhere((e) => e.memberId == pid);
      if (idx >= 0) {
        final cur = updatedBoard[idx];
        updatedBoard[idx] = LeaderboardEntryModel(
          memberId: pid,
          memberName: playerName.trim(),
          totalPoints: cur.totalPoints + pointsEarned,
          matchesPlayed: cur.matchesPlayed + 1,
        );
      } else {
        updatedBoard.add(
          LeaderboardEntryModel(
            memberId: pid,
            memberName: playerName.trim(),
            totalPoints: pointsEarned,
            matchesPlayed: 1,
          ),
        );
      }
      updatedBoard.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
    }
    state = state.copyWith(
      quizScoreTotal: nextTotal,
      quizMatchesPlayed: nextMatches,
      quizLeaderboard: updatedBoard,
    );
    _persistSnapshot();
  }

  // --- Zikr (NO competition or piety ranking) ---
  Future<void> incrementTasbih() async {
    final next = state.personalTasbihCount + 1;
    state = state.copyWith(personalTasbihCount: next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('yitte_tasbih_count', next);
  }

  Future<void> resetTasbihAndLogSession() async {
    state = state.copyWith(
      personalTasbihCount: 0,
      personalZikrSessionsCount: state.personalZikrSessionsCount + 1,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('yitte_tasbih_count', 0);
  }

  Future<void> incrementSalawat({int step = 1}) async {
    final todayIso = _todayIso();
    final currentToday =
        state.salawatLastDayIso == todayIso ? state.salawatTodayCount : 0;
    final nextMonthly = state.salawatMonthlyCount + step;
    final nextToday = currentToday + step;

    state = state.copyWith(
      salawatMonthlyCount: nextMonthly,
      salawatTodayCount: nextToday,
      salawatLastDayIso: todayIso,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('yitte_salawat_monthly', nextMonthly);
    await prefs.setInt('yitte_salawat_today', nextToday);
    await prefs.setString('yitte_salawat_day', todayIso);
    if (prefs.getString('yitte_salawat_cycle_start') == null) {
      await prefs.setString('yitte_salawat_cycle_start', state.salawatCycleStartIso);
    }
  }

  Future<void> updateSalawatGoal({
    required int target,
    required int durationDays,
    String? title,
    bool resetProgress = false,
  }) async {
    final safeTarget = target.clamp(1, 10000000);
    final safeDays = durationDays.clamp(1, 3650);
    final safeTitle = (title == null || title.trim().isEmpty)
        ? state.salawatCustomTitle
        : title.trim();
    final todayIso = _todayIso();

    state = state.copyWith(
      salawatMonthlyTarget: safeTarget,
      salawatDurationDays: safeDays,
      salawatCustomTitle: safeTitle,
      salawatMonthlyCount: resetProgress ? 0 : state.salawatMonthlyCount,
      salawatTodayCount: resetProgress ? 0 : state.salawatTodayCount,
      salawatCycleStartIso:
          resetProgress ? todayIso : state.salawatCycleStartIso,
      salawatLastDayIso: todayIso,
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('yitte_salawat_target', safeTarget);
    await prefs.setInt('yitte_salawat_duration_days', safeDays);
    await prefs.setString('yitte_salawat_title', safeTitle);
    if (resetProgress) {
      await prefs.setInt('yitte_salawat_monthly', 0);
      await prefs.setInt('yitte_salawat_today', 0);
      await prefs.setString('yitte_salawat_day', todayIso);
      await prefs.setString('yitte_salawat_cycle_start', todayIso);
    }
    if (state.dailyTasbihReminderEnabled) {
      await NotificationService.instance.scheduleDailyTasbihReminder(
        targetCount: safeTarget,
        durationDays: safeDays,
        titleLabel: safeTitle,
      );
    }
  }

  Future<void> resetSalawatCycle() async {
    final todayIso = _todayIso();
    state = state.copyWith(
      salawatMonthlyCount: 0,
      salawatTodayCount: 0,
      salawatLastDayIso: todayIso,
      salawatCycleStartIso: todayIso,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('yitte_salawat_monthly', 0);
    await prefs.setInt('yitte_salawat_today', 0);
    await prefs.setString('yitte_salawat_day', todayIso);
    await prefs.setString('yitte_salawat_cycle_start', todayIso);
  }

  Future<void> toggleDailyTasbihReminder(bool enabled) async {
    state = state.copyWith(dailyTasbihReminderEnabled: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('yitte_daily_tasbih_reminder', enabled);
    if (enabled) {
      await NotificationService.instance.scheduleDailyTasbihReminder(
        targetCount: state.salawatMonthlyTarget,
        durationDays: state.salawatDurationDays,
        titleLabel: state.salawatCustomTitle,
      );
    } else {
      await NotificationService.instance.cancelDailyTasbihReminder();
    }
  }

  Future<void> toggleOpenTasbihOnLaunch(bool enabled) async {
    state = state.copyWith(openTasbihOnLaunch: enabled);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('yitte_open_tasbih_launch', enabled);
  }

  Future<void> toggleZikrReminder(bool enabled) async {
    state = state.copyWith(zikrReminderEnabled: enabled);
    if (enabled) {
      await NotificationService.instance.scheduleSaturdayZikrReminder();
    }
  }

  // --- English Club ---
  void toggleVocabMastered(String wordId) {
    final updated = state.dailyVocab
        .map((w) => w.id == wordId ? w.copyWith(mastered: !w.mastered) : w)
        .toList();
    state = state.copyWith(dailyVocab: updated);
    _persistSnapshot();
  }

  Future<void> evaluateEnglishSpeech({
    required String prompt,
    required String transcript,
    required String variant,
    required String cefrLevel,
  }) async {
    final eval = await BackendRepository.instance.evaluateEnglishSpeaking(
      promptText: prompt,
      transcriptText: transcript,
      variant: variant,
      cefrLevel: cefrLevel,
    );
    state = state.copyWith(lastEnglishEval: eval);
  }

  // --- Professional ---
  void updateCareerDocs({required String cv, required String coverLetter}) {
    state = state.copyWith(cvDraft: cv, coverLetterDraft: coverLetter);
    _persistSnapshot();
  }

  void addPortfolioProject(String title) {
    state = state.copyWith(
      portfolioProjects: [title, ...state.portfolioProjects],
    );
    _persistSnapshot();
  }

  void deletePortfolioProject(int index) {
    if (index < 0 || index >= state.portfolioProjects.length) return;
    final list = [...state.portfolioProjects]..removeAt(index);
    state = state.copyWith(portfolioProjects: list);
    _persistSnapshot();
  }

  // --- Personal Growth (Strictly Private) ---
  void addPersonalGoal(String title, String horizon) {
    state = state.copyWith(
      personalGoals: [
        PersonalGoalModel(
          id: _uuid.v4(),
          title: title,
          horizon: horizon,
          progressPercent: 10,
        ),
        ...state.personalGoals,
      ],
    );
    _persistSnapshot();
  }

  void bumpGoalProgress(String goalId) {
    state = state.copyWith(
      personalGoals: state.personalGoals
          .map((g) => g.id == goalId
              ? g.copyWith(
                  progressPercent: (g.progressPercent + 15).clamp(0, 100),
                )
              : g)
          .toList(),
    );
    _persistSnapshot();
  }

  void addHabit(String name) {
    state = state.copyWith(
      habits: [
        HabitModel(id: _uuid.v4(), name: name, streakDays: 0),
        ...state.habits,
      ],
    );
    _persistSnapshot();
  }

  void toggleHabitToday(String habitId) {
    state = state.copyWith(
      habits: state.habits.map((h) {
        if (h.id != habitId) return h;
        final done = !h.completedToday;
        return h.copyWith(
          completedToday: done,
          streakDays: done ? h.streakDays + 1 : (h.streakDays - 1).clamp(0, 999),
        );
      }).toList(),
    );
    _persistSnapshot();
  }

  void addPrivateNote(String type, String title, String content) {
    state = state.copyWith(
      privateNotes: [
        PrivateNoteModel(
          id: _uuid.v4(),
          noteType: type,
          title: title,
          content: content,
          createdAt: DateTime.now(),
        ),
        ...state.privateNotes,
      ],
    );
    _persistSnapshot();
  }

  void addBook(String title, String author, int pages) {
    state = state.copyWith(
      books: [
        ReadingBookModel(
          id: _uuid.v4(),
          title: title,
          author: author,
          currentPage: 0,
          totalPages: pages.clamp(1, 5000),
        ),
        ...state.books,
      ],
    );
    _persistSnapshot();
  }

  void updateBookProgress(String bookId, int deltaPages) {
    state = state.copyWith(
      books: state.books
          .map((b) => b.id == bookId
              ? b.copyWith(
                  currentPage: (b.currentPage + deltaPages).clamp(0, b.totalPages),
                )
              : b)
          .toList(),
    );
    _persistSnapshot();
  }

  // --- Community, Messages, Moderation, Admin ---
  void sendMessage(
    String channel,
    String senderName,
    String body, {
    String? audioUrl,
    int? audioDurationSeconds,
  }) {
    state = state.copyWith(
      messages: [
        ...state.messages,
        ChatMessageModel(
          id: _uuid.v4(),
          channelName: channel,
          senderName: senderName,
          body: body,
          sentAt: DateTime.now(),
          audioUrl: audioUrl,
          audioDurationSeconds: audioDurationSeconds,
        ),
      ],
    );
    _persistSnapshot();
  }

  void createVoiceRoom(String title, String type, String hostName, {String? cefr}) {
    state = state.copyWith(
      voiceRooms: [
        VoiceRoomModel(
          id: _uuid.v4(),
          title: title,
          roomType: type,
          hostName: hostName,
          livekitRoomName: 'yitte-${DateTime.now().millisecondsSinceEpoch}',
          cefrFilter: cefr,
        ),
        ...state.voiceRooms,
      ],
    );
    _persistSnapshot();
  }

  void submitReport(String targetType, String reason) {
    state = state.copyWith(
      reports: [
        ModerationReportModel(
          id: _uuid.v4(),
          targetType: targetType,
          reason: reason,
          status: 'open',
          createdAt: DateTime.now(),
        ),
        ...state.reports,
      ],
    );
    _persistSnapshot();
  }

  void resolveReport(String reportId) {
    state = state.copyWith(
      reports: state.reports
          .map((r) => r.id == reportId
              ? ModerationReportModel(
                  id: r.id,
                  targetType: r.targetType,
                  reason: r.reason,
                  status: 'resolved',
                  createdAt: r.createdAt,
                )
              : r)
          .toList(),
      auditLogs: ['Signalement $reportId résolu par modérateur', ...state.auditLogs],
    );
    _persistSnapshot();
  }

  void blockUser(String username) {
    state = state.copyWith(
      blockedUsers: {...state.blockedUsers, username},
    );
    _persistSnapshot();
  }

  void generateInviteCode(String roleCode) {
    final code =
        'YITTE-${roleCode.substring(0, 3).toUpperCase()}-${DateTime.now().millisecond.toString().padLeft(3, '0')}';
    state = state.copyWith(
      generatedInvites: [code, ...state.generatedInvites],
      auditLogs: ['Invitation générée ($roleCode) : $code', ...state.auditLogs],
    );
    _persistSnapshot();
  }

  void registerOrTouchMember(UserProfile profile) {
    final exists = state.members.any((m) => m.id == profile.id);
    final updated = exists
        ? state.members
            .map((m) => m.id == profile.id
                ? MemberDirectoryItem(
                    id: profile.id,
                    fullName: profile.fullName,
                    username: profile.username,
                    roleCode: profile.role.code,
                    joinedAt: m.joinedAt,
                  )
                : m)
            .toList()
        : [
            MemberDirectoryItem(
              id: profile.id,
              fullName: profile.fullName,
              username: profile.username,
              roleCode: profile.role.code,
              joinedAt: DateTime.now(),
            ),
            ...state.members,
          ];
    state = state.copyWith(members: updated);
    _persistSnapshot();
  }

  Future<void> broadcastAnnouncement(
    String title,
    String body,
    String authorName,
  ) async {
    final item = AnnouncementModel(
      id: _uuid.v4(),
      title: title,
      body: body,
      authorName: authorName,
      createdAt: DateTime.now(),
    );
    final notif = AppNotificationItem(
      id: _uuid.v4(),
      title: title,
      body: body.isNotEmpty ? body : 'Nouvelle annonce publiée par $authorName.',
      category: 'announcement',
      deepLink: '/',
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      announcements: [item, ...state.announcements],
      notifications: [notif, ...state.notifications],
      auditLogs: ['Annonce diffusée : $title', ...state.auditLogs],
    );
    _persistSnapshot();
    await SpeechBridge.showWebNotification(title, body);
    await NotificationService.instance.showLocalNotification(
      title: title,
      body: body,
    );
  }

  // --- Documentary Knowledge Library (Partie II) ---
  void addLibraryDocument(LibraryDocumentModel doc) {
    state = state.copyWith(
      libraryDocuments: [doc, ...state.libraryDocuments],
      auditLogs: [
        'Document enregistré (${doc.domain} / ${doc.subcategory}) : ${doc.title}',
        ...state.auditLogs,
      ],
    );
    _persistSnapshot();
  }

  void recordDocumentConsultation(String docId) {
    state = state.copyWith(
      libraryDocuments: state.libraryDocuments
          .map((d) => d.id == docId
              ? d.copyWith(
                  viewCount: d.viewCount + 1,
                  lastViewedAt: DateTime.now(),
                )
              : d)
          .toList(),
    );
    _persistSnapshot();
  }

  Future<void> generateDocumentSummary(String docId) async {
    final doc = state.libraryDocuments.firstWhere((d) => d.id == docId);
    final summary = await BackendRepository.instance.summarizeDocumentSource(
      document: doc,
    );
    state = state.copyWith(
      libraryDocuments: state.libraryDocuments
          .map((d) => d.id == docId ? d.copyWith(summary: summary) : d)
          .toList(),
      auditLogs: [
        'Résumé documentaire généré (source réelle) : ${doc.title}',
        ...state.auditLogs,
      ],
    );
    _persistSnapshot();
  }

  void validateDocumentSummary(
    String docId,
    String reviewerName, {
    String? editedGeneralSummary,
  }) {
    state = state.copyWith(
      libraryDocuments: state.libraryDocuments.map((d) {
        if (d.id != docId || d.summary == null) return d;
        return d.copyWith(
          validationStatus: 'validated',
          summary: d.summary!.copyWith(
            generalSummary: editedGeneralSummary ?? d.summary!.generalSummary,
            status: 'validated',
            validatedBy: reviewerName,
          ),
        );
      }).toList(),
      auditLogs: [
        'Résumé documentaire validé par $reviewerName : $docId',
        ...state.auditLogs,
      ],
    );
    _persistSnapshot();
  }

  void updateDocumentMetadata(
    String docId, {
    String? title,
    String? description,
    String? domain,
    String? subcategory,
    String? validationStatus,
    bool? isPrivate,
  }) {
    state = state.copyWith(
      libraryDocuments: state.libraryDocuments
          .map((d) => d.id == docId
              ? d.copyWith(
                  title: title,
                  description: description,
                  domain: domain,
                  subcategory: subcategory,
                  validationStatus: validationStatus,
                  isPrivate: isPrivate,
                )
              : d)
          .toList(),
      auditLogs: ['Métadonnées documentaires mises à jour : $docId', ...state.auditLogs],
    );
    _persistSnapshot();
  }

  void deleteLibraryDocument(String docId) {
    final match = state.libraryDocuments.where((d) => d.id == docId).toList();
    for (final doc in match) {
      BackendRepository.instance.deleteUploadedFile(doc.storageUrl);
    }
    state = state.copyWith(
      libraryDocuments:
          state.libraryDocuments.where((d) => d.id != docId).toList(),
      auditLogs: ['Document et fichier supprimés : $docId', ...state.auditLogs],
    );
    _persistSnapshot();
  }

  void deleteChallenge(String challengeId) {
    state = state.copyWith(
      challenges: state.challenges.where((c) => c.id != challengeId).toList(),
      auditLogs: ['Défi supprimé : $challengeId', ...state.auditLogs],
    );
    _persistSnapshot();
  }

  void deleteExtraGroupeMeeting(String meetingId) {
    state = state.copyWith(
      extraGroupeMeetings:
          state.extraGroupeMeetings.where((m) => m.id != meetingId).toList(),
      auditLogs: ['Rencontre Extra Groupe supprimée : $meetingId', ...state.auditLogs],
    );
    _persistSnapshot();
  }

  void addAuthorizedGroupMember(String rawName) {
    final clean = rawName.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (clean.length < 2) return;
    final norm = GroupMembershipCatalog.normalizeName(clean);
    if (state.authorizedGroupMembers
        .any((n) => GroupMembershipCatalog.normalizeName(n) == norm)) {
      return;
    }
    state = state.copyWith(
      authorizedGroupMembers: [...state.authorizedGroupMembers, clean],
      auditLogs: ['Membre du groupe autorisé ajouté : $clean', ...state.auditLogs],
    );
    _persistSnapshot();
  }

  void removeAuthorizedGroupMember(String name) {
    final target = GroupMembershipCatalog.normalizeName(name);
    state = state.copyWith(
      authorizedGroupMembers: state.authorizedGroupMembers
          .where((n) => GroupMembershipCatalog.normalizeName(n) != target)
          .toList(),
      auditLogs: ['Membre retiré de la liste du groupe : $name', ...state.auditLogs],
    );
    _persistSnapshot();
  }

  void toggleRestrictAppToGroupOnly(bool restrictOnly) {
    state = state.copyWith(
      restrictAppToGroupOnly: restrictOnly,
      auditLogs: [
        restrictOnly
            ? 'Accès strictement restreint aux membres du groupe'
            : 'Ouverture générale aux comptes standard activée',
        ...state.auditLogs,
      ],
    );
    _persistSnapshot();
  }

  // --- Extra Groupe (Partie V) ---
  void createExtraGroupeMeeting(ExtraGroupeMeetingModel meeting) {
    final notif = AppNotificationItem(
      id: _uuid.v4(),
      title: 'Nouvelle rencontre Extra Groupe : ${meeting.guest.fullName}',
      body: meeting.theme,
      category: 'extra_groupe',
      deepLink: '/extra-groupe',
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      extraGroupeMeetings: [meeting, ...state.extraGroupeMeetings],
      notifications: [notif, ...state.notifications],
      auditLogs: [
        'Rencontre Extra Groupe programmée : ${meeting.guest.fullName}',
        ...state.auditLogs,
      ],
    );
    _persistSnapshot();
  }

  void addExtraGroupeQuestion(
    String meetingId,
    String authorName,
    String questionText, {
    bool isPrepared = false,
  }) {
    final q = ExtraGroupeQuestionModel(
      id: _uuid.v4(),
      authorName: authorName,
      questionText: questionText,
      isPrepared: isPrepared,
      createdAt: DateTime.now(),
    );
    state = state.copyWith(
      extraGroupeMeetings: state.extraGroupeMeetings
          .map((m) => m.id == meetingId
              ? m.copyWith(questions: [...m.questions, q])
              : m)
          .toList(),
    );
    _persistSnapshot();
  }

  void answerExtraGroupeQuestion(
    String meetingId,
    String questionId,
    String answerText,
  ) {
    state = state.copyWith(
      extraGroupeMeetings: state.extraGroupeMeetings.map((m) {
        if (m.id != meetingId) return m;
        return m.copyWith(
          questions: m.questions
              .map((q) =>
                  q.id == questionId ? q.copyWith(answerText: answerText) : q)
              .toList(),
        );
      }).toList(),
    );
    _persistSnapshot();
  }

  void updateExtraGroupeMeetingReport(
    String meetingId,
    String report, {
    bool archive = false,
  }) {
    state = state.copyWith(
      extraGroupeMeetings: state.extraGroupeMeetings
          .map((m) => m.id == meetingId
              ? m.copyWith(
                  meetingReport: report,
                  status: archive ? 'archived' : m.status,
                )
              : m)
          .toList(),
      auditLogs: [
        'Compte rendu Extra Groupe mis à jour ($meetingId)',
        ...state.auditLogs,
      ],
    );
    _persistSnapshot();
  }

  void toggleExtraGroupeRecordingConsent(String meetingId, bool authorized) {
    state = state.copyWith(
      extraGroupeMeetings: state.extraGroupeMeetings
          .map((m) => m.id == meetingId
              ? m.copyWith(recordingAuthorized: authorized)
              : m)
          .toList(),
    );
    _persistSnapshot();
  }

  void toggleExtraGroupeRosterVisibility(String meetingId, bool publicToCircle) {
    state = state.copyWith(
      extraGroupeMeetings: state.extraGroupeMeetings
          .map((m) => m.id == meetingId
              ? m.copyWith(rosterPublicToCircle: publicToCircle)
              : m)
          .toList(),
    );
    _persistSnapshot();
  }

  void toggleExtraGroupeParticipant(String meetingId, String memberName) {
    state = state.copyWith(
      extraGroupeMeetings: state.extraGroupeMeetings.map((m) {
        if (m.id != meetingId) return m;
        final list = [...m.registeredParticipants];
        if (list.contains(memberName)) {
          list.remove(memberName);
        } else {
          list.add(memberName);
        }
        return m.copyWith(registeredParticipants: list);
      }).toList(),
    );
    _persistSnapshot();
  }

  void publishValidatedDailyThought(String? text) {
    final clean = text?.trim() ?? '';
    state = state.copyWith(
      validatedDailyThought: clean.isEmpty ? null : clean,
      clearDailyThought: clean.isEmpty,
      auditLogs: [
        clean.isEmpty
            ? 'Pensée du jour retirée'
            : 'Pensée du jour validée par responsable',
        ...state.auditLogs,
      ],
    );
    _persistSnapshot();
  }

  void updateWhatsAppConfig({
    required String groupName,
    required String inviteUrl,
    String? webhookUrl,
  }) {
    final cleanGroup = groupName.trim().isEmpty
        ? 'BOROOM YITTÉ YU KAWÉ YI — Groupe WhatsApp'
        : groupName.trim();
    final rawInvite = inviteUrl.trim();
    final normalizedInvite = rawInvite.isEmpty
        ? null
        : WhatsAppBridgeService.normalizeInviteUrl(rawInvite);
    if (rawInvite.isNotEmpty && normalizedInvite == null) {
      throw ArgumentError(
        'Lien WhatsApp invalide : utilisez un lien officiel https://chat.whatsapp.com/... ou https://wa.me/...',
      );
    }
    final cleanWebhook = webhookUrl?.trim() ?? '';
    state = state.copyWith(
      whatsappGroupName: cleanGroup,
      whatsappInviteUrl: normalizedInvite,
      clearWhatsappInviteUrl: normalizedInvite == null,
      whatsappWebhookUrl: cleanWebhook.isEmpty ? null : cleanWebhook,
      clearWhatsappWebhookUrl: cleanWebhook.isEmpty,
      auditLogs: [
        normalizedInvite == null
            ? 'Lien du groupe WhatsApp réinitialisé'
            : 'Groupe WhatsApp lié : $cleanGroup',
        ...state.auditLogs,
      ],
    );
    _persistSnapshot();
  }

  int importWhatsAppChatExport({
    required String rawText,
    String channelName = 'Groupe WhatsApp',
  }) {
    final parsed = WhatsAppBridgeService.parseWhatsAppChatExport(rawText);
    if (parsed.isEmpty) return 0;

    final existingSignatures = state.messages
        .where((m) => m.channelName == channelName)
        .map((m) => '${m.senderName}::${m.body}')
        .toSet();

    final newMessages = <ChatMessageModel>[];
    for (final entry in parsed) {
      final sig = '${entry.sender}::${entry.body}';
      if (existingSignatures.contains(sig)) continue;
      existingSignatures.add(sig);
      newMessages.add(
        ChatMessageModel(
          id: _uuid.v4(),
          channelName: channelName,
          senderName: entry.sender,
          body: entry.body,
          sentAt: DateTime.now(),
        ),
      );
    }
    if (newMessages.isEmpty) return 0;

    state = state.copyWith(
      messages: [...state.messages, ...newMessages],
      auditLogs: [
        'Import réel WhatsApp (.txt) : ${newMessages.length} message(s) dans $channelName',
        ...state.auditLogs,
      ],
    );
    _persistSnapshot();
    return newMessages.length;
  }

  void markNotificationRead(String notifId) {
    state = state.copyWith(
      notifications: state.notifications
          .map((n) => n.id == notifId ? n.copyWith(isRead: true) : n)
          .toList(),
    );
    _persistSnapshot();
  }

  void markAllNotificationsRead() {
    state = state.copyWith(
      notifications:
          state.notifications.map((n) => n.copyWith(isRead: true)).toList(),
    );
    _persistSnapshot();
  }

  void joinVoiceRoom(String roomId) {
    state = state.copyWith(
      voiceRooms: state.voiceRooms
          .map((r) => r.id == roomId
              ? VoiceRoomModel(
                  id: r.id,
                  title: r.title,
                  roomType: r.roomType,
                  hostName: r.hostName,
                  livekitRoomName: r.livekitRoomName,
                  cefrFilter: r.cefrFilter,
                  participantsCount: r.participantsCount + 1,
                  isLocked: r.isLocked,
                )
              : r)
          .toList(),
    );
    _persistSnapshot();
  }

  void leaveVoiceRoom(String roomId) {
    state = state.copyWith(
      voiceRooms: state.voiceRooms
          .map((r) => r.id == roomId
              ? VoiceRoomModel(
                  id: r.id,
                  title: r.title,
                  roomType: r.roomType,
                  hostName: r.hostName,
                  livekitRoomName: r.livekitRoomName,
                  cefrFilter: r.cefrFilter,
                  participantsCount: (r.participantsCount - 1).clamp(0, 999),
                  isLocked: r.isLocked,
                )
              : r)
          .toList(),
    );
    _persistSnapshot();
  }
}

final ecosystemProvider =
    StateNotifierProvider<EcosystemNotifier, EcosystemState>((ref) {
  return EcosystemNotifier();
});

EcosystemState _buildInitialState() {
  final nextSaturday = _nextSaturday2000Utc();
  return EcosystemState(
    reflections: [
      ReflectionPost(
        id: 'ref-1',
        authorId: 'editorial-board',
        authorName: 'Comité Éditorial • Boroom Yitté',
        title: "Charte du discernement : vérifier avant de transmettre",
        body:
            "Dans cet espace, chaque membre publie ses idées, expériences et références vérifiables. Prendre le temps de vérifier une source avant de la partager élève la qualité collective des échanges.",
        category: 'islamic_thought',
        tags: const ['éthique', 'discernement', 'savoir'],
        reactionsCount: 0,
        isFeaturedInLibrary: true,
        comments: const [],
        createdAt: DateTime.now(),
      ),
      ReflectionPost(
        id: 'hist-1',
        authorId: 'archive-sokhna-diarra',
        authorName: 'Sokhna Diarra',
        title: "Une majorité en nombre, mais qu'en est-il des valeurs ?",
        body:
            "Au Sénégal, le poids démographique semble largement pencher en faveur de la communauté musulmane, qui constitue la majorité de la population. Pourtant, la minorité chrétienne semble, dans certaines sphères, occuper une place qui interroge dans le fonctionnement et les orientations de notre société.\n"
            "Mais au-delà de cette question de représentativité, une autre interrogation, bien plus dérangeante, mérite d'être posée.\n"
            "Dès qu'il est question de banditisme, de trafic de drogue, d'immigration clandestine ou encore de prostitution, on semble trop souvent associer ces fléaux à des individus issus de la communauté musulmane. À force d'entendre ces associations, une question finit par s'imposer : comment une communauté qui se réclame de valeurs religieuses aussi exigeantes peut-elle parfois donner à voir des comportements aussi éloignés des principes qu'elle prétend défendre ?\n"
            "Je ne prétends nullement que tous les chrétiens soient irréprochables, car la perfection n'est le propre d'aucun être humain. Mais n'est-il pas temps de cesser de suivre aveuglément le rythme du monde, de sortir de cette complaisance collective et de regarder lucidement ce qui se passe autour de nous ? N'est-il pas temps de nous interroger sur la direction que nous prenons et, surtout, sur les valeurs que nous sommes en train de perdre ?\n"
            "Comment ceux dont on attendrait naturellement une certaine exemplarité en viennent-ils à devenir, parfois, les acteurs de comportements aussi perturbateurs ? Qu'est-ce qui a bien pu conduire à un tel renversement entre les valeurs professées et les actes posés ?\n"
            "Dès lors, une question fondamentale se pose : sommes-nous face à une défaillance de l'éducation, à un manque de communication, à une crise des valeurs ou simplement aux conséquences d'une société qui ne sait plus transmettre ses repères ?\n"
            "Nos parents ont-ils failli dans la transmission des bonnes manières et des principes fondamentaux à leurs enfants ? Avons-nous collectivement échoué à faire de l'éducation morale et du sens des responsabilités des priorités ?\n"
            "Bon réflexion, on se retrouve au mois de décembre s'il plaît à Dieu.",
        category: 'society',
        tags: const ['archive', 'valeurs', 'éducation', 'responsabilité'],
        isFeaturedInLibrary: true,
        isHistoricalArchive: true,
        discussionDateLabel: 'Archive communautaire',
        moderationNote:
            'Cadre éditorial : examiner les représentations sociales, la responsabilité individuelle et collective et l’éducation, sans stigmatiser aucune communauté religieuse ni présenter des perceptions comme des statistiques.',
        mainQuestions: const [
          'Sommes-nous face à une défaillance de l’éducation, à un manque de communication, à une crise des valeurs ou aux conséquences d’une société qui ne sait plus transmettre ses repères ?',
          'Avons-nous collectivement échoué à faire de l’éducation morale et du sens des responsabilités des priorités ?',
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
      ),
      ReflectionPost(
        id: 'hist-2',
        authorId: 'archive-aida-thiam',
        authorName: 'Aida Thiam',
        title: "Le pardon existe-t-il réellement ?",
        body:
            "Le pardon existe-t-il réellement ?\n"
            "Si c'est le cas, doit-on oublier la cause ? Si oui, pourquoi ? Et sinon, pourquoi ?\n"
            "La question du pardon concerne aussi bien sa propre personne que les autres.",
        category: 'ethics',
        tags: const ['archive', 'pardon', 'éthique', 'introspection'],
        isFeaturedInLibrary: true,
        isHistoricalArchive: true,
        discussionDateLabel: 'Archive communautaire',
        reflectionAxes: const [
          'Que signifie réellement pardonner ?',
          'Peut-on pardonner sans oublier ?',
          'Le pardon implique-t-il nécessairement une réconciliation ?',
          'Peut-on se pardonner à soi-même ?',
          'Quelle place donner au temps dans le processus du pardon ?',
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 45)),
      ),
      ReflectionPost(
        id: 'hist-3',
        authorId: 'archive-khady-sylla',
        authorName: 'Khady Sylla',
        title: "Le viol, le consentement et la justice",
        body:
            "Voici le sujet :\n"
            "Le viol, le consentement et la justice.\n\n"
            "1. Le consentement\n"
            "• Qu'est-ce que le consentement ?\n"
            "• Est-ce que le silence signifie oui ?\n\n"
            "2. La société et la culpabilisation\n"
            "• Pourquoi demande-t-on souvent à la victime « Tu étais habillé comment ? » au lieu de demander à l'agresseur « Pourquoi as-tu fait ça ? »\n"
            "• La façon de s'habiller excuse-t-elle ou explique-t-elle un viol ?\n"
            "• Pourquoi beaucoup de victimes n'osent-elles pas parler ?\n\n"
            "3. La justice et la prévention\n"
            "• Comment mieux protéger les filles et les garçons ?\n"
            "• Que doit-on apprendre aux enfants dès le jeune âge pour prévenir ce type de violence ?",
        category: 'society',
        tags: const ['archive', 'justice', 'consentement', 'prévention'],
        isFeaturedInLibrary: true,
        isHistoricalArchive: true,
        discussionDateLabel: 'Archive communautaire',
        moderationNote:
            'Sujet sensible — modération renforcée : ne jamais culpabiliser les victimes ; ne pas présenter des opinions comme des vérités juridiques ou médicales ; garantir un cadre respectueux.',
        mainQuestions: const [
          'Qu’est-ce que le consentement et est-ce que le silence signifie oui ?',
          'Comment mieux protéger les filles et les garçons et que transmettre dès le jeune âge ?',
        ],
        createdAt: DateTime.now().subtract(const Duration(days: 60)),
      ),
    ],
    weeklyTopic: const WeeklyTopicModel(
      id: 'wt-46',
      weekNumber: 46,
      year: 2026,
      title:
          'Comment concilier ambition professionnelle, excellence scientifique et vie spirituelle équilibrée ?',
      introduction:
          "Sujet hebdomadaire ouvert à vos contributions écrites et argumentées.",
      guidingQuestions: [
        'Quelles habitudes protègent la concentration profonde au quotidien ?',
        'Comment transformer une compétence technique en utilité sociale ?',
        'Quel rôle joue l’entraide communautaire dans la persévérance ?',
      ],
      contributions: [],
    ),
    challenges: [
      ChallengeItem(
        id: 'ch-1',
        title:
            "L'automatisation par l'IA renforce-t-elle l'esprit critique humain ?",
        description:
            "Analyse nuancée de l'impact des assistants IA sur l'autonomie intellectuelle des jeunes chercheurs.",
        category: 'technology',
        format: 'yes_no_depends',
        difficulty: 'intermediate',
        timeLimitSeconds: 300,
        instructions:
            'Choisissez Oui, Non ou Cela dépend, puis exposez au moins deux conditions déterminantes.',
        evaluationCriteria: const [
          'Clarté de la thèse',
          'Identification des conditions',
          'Exemples concrets',
        ],
        options: const ['Oui', 'Non', 'Cela dépend'],
        correctAnswer: 'Cela dépend',
        explanation:
            "Utilisée comme tuteur socratique avec vérification active, l'IA aide ; utilisée comme substitut d'effort intellectuel, elle affaiblit l'esprit critique.",
        scheduledPublishAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
      ChallengeItem(
        id: 'ch-2',
        title: 'Distinguer corrélation statistique et lien de causalité',
        description:
            'Exercice de raisonnement scientifique chronométré sur les biais analytiques.',
        category: 'science',
        format: 'mcq',
        difficulty: 'intermediate',
        timeLimitSeconds: 180,
        instructions: 'Sélectionnez la réponse la plus rigoureuse.',
        evaluationCriteria: const ['Précision logique', 'Absence de confusion causale'],
        options: const [
          'Toute corrélation forte implique une causalité directe',
          'Une variable confondante ou une causalité inverse peut expliquer la corrélation',
          'La causalité ne peut jamais être étudiée scientifiquement',
        ],
        correctAnswer:
            'Une variable confondante ou une causalité inverse peut expliquer la corrélation',
        explanation:
            'L’existence d’une troisième variable confondante ou d’une inversion temporelle empêche de conclure à la causalité sans protocole expérimental ou contrefactuel.',
        scheduledPublishAt: DateTime.now(),
      ),
      ChallengeItem(
        id: 'ch-3',
        title: 'Plaidoyer vocal : Discipline individuelle et bien commun',
        description:
            'Exercice d’expression orale (max 3 min) reliant constance personnelle et service collectif.',
        category: 'ethics',
        format: 'audio_response',
        difficulty: 'advanced',
        timeLimitSeconds: 180,
        instructions:
            'Enregistrez votre réponse vocale structurée en introduction, 2 arguments et nuance.',
        evaluationCriteria: const ['Pertinence', 'Logique', 'Exemples', 'Clarté'],
        explanation:
            'Les meilleures réponses articulent responsabilité morale individuelle, exemples vérifiables et humilité intellectuelle.',
        scheduledPublishAt: DateTime.now(),
      ),
      ChallengeItem(
        id: 'ch-4',
        title: 'Agronomie & Eau : Irrigation raisonnée au Sahel',
        description:
            'Concevez un protocole pratique réduisant l’évaporation des cultures maraîchères sans perte de rendement.',
        category: 'science',
        format: 'open_ended',
        difficulty: 'intermediate',
        timeLimitSeconds: 300,
        instructions:
            'Proposez 3 leviers complémentaires (goutte-à-goutte, paillage, capteurs/horaires) et anticipez leurs limites.',
        evaluationCriteria: const ['Faisabilité terrain', 'Sobriété hydrique', 'Analyse coût-impact'],
        explanation:
            'La combinaison du paillage organique, du goutte-à-goutte basse pression et d’un arrosage crépusculaire réduit sensiblement les pertes hydriques.',
        scheduledPublishAt: DateTime.now().add(const Duration(days: 1)),
      ),
      ChallengeItem(
        id: 'ch-5',
        title: 'Oral Spirituel (Audio) : Adab du désaccord fraternel',
        description:
            'Prenez la parole (max 2 min) sur la manière de corriger une erreur sans briser la fraternité ni taire la vérité.',
        category: 'islamic_thought',
        format: 'audio_response',
        difficulty: 'intermediate',
        timeLimitSeconds: 120,
        instructions:
            'Enregistrez un message vocal posé distinguant conseil discret (nasīha), preuve vérifiée et humilité.',
        evaluationCriteria: const ['Douceur de forme', 'Rigueur des principes', 'Clarté orale'],
        explanation:
            'Le conseil sincère s’exprime en privé, avec respect de l’intention d’autrui et fidélité aux sources établies.',
        scheduledPublishAt: DateTime.now().add(const Duration(days: 2)),
      ),
      ChallengeItem(
        id: 'ch-6',
        title: 'Défi Technique : Résilience d’une alimentation solaire + batterie',
        description:
            'Calculez les marges de sécurité pour maintenir un poste médical rural ou laboratoire connecté 24h/24.',
        category: 'technology',
        format: 'argumentation',
        difficulty: 'advanced',
        timeLimitSeconds: 360,
        instructions:
            'Détaillez le bilan de puissance, l’autonomie minimale de 48h, la protection MPPT et le plan de maintenance.',
        evaluationCriteria: const ['Calcul cohérent', 'Marges de sécurité', 'Plan de maintenance'],
        explanation:
            'Un dimensionnement sain intègre le pic de démarrage, la profondeur de décharge (DoD), les pertes onduleur et la maintenance préventive.',
        scheduledPublishAt: DateTime.now().add(const Duration(days: 3)),
      ),
      ChallengeItem(
        id: 'ch-7',
        title: 'Atelier d’équipe interdisciplinaire : Eau, Santé & Logiciel',
        description:
            'Défi collectif réunissant agronome, médecin, ingénieur et développeur autour d’un cas réel au Sénégal.',
        category: 'society',
        format: 'team_challenge',
        difficulty: 'advanced',
        timeLimitSeconds: 420,
        instructions:
            'Attribuez un livrable concret à chaque spécialité et identifiez l’indicateur commun de réussite.',
        evaluationCriteria: const ['Complémentarité des métiers', 'Indicateur mesurable', 'Calendrier réaliste'],
        explanation:
            'L’interdisciplinarité réelle transforme chaque compétence en maillon vérifiable d’un projet commun durable.',
        scheduledPublishAt: DateTime.now().add(const Duration(days: 4)),
      ),
      ChallengeItem(
        id: 'ch-8',
        title: 'Logique Express (90s) : Identifier un sophisme d’appel à l’ignorance',
        description:
            'Repérez l’erreur de raisonnement dans un débat public contemporain.',
        category: 'logic',
        format: 'mcq',
        difficulty: 'beginner',
        timeLimitSeconds: 90,
        instructions: 'Choisissez l’analyse logique exacte.',
        evaluationCriteria: const ['Rigueur logique', 'Rapidité'],
        options: const [
          'L’absence actuelle de preuve d’une chose prouve automatiquement son impossibilité',
          'Une affirmation exige des preuves proportionnées à sa portée plutôt que d’exploiter l’absence de réfutation',
          'Tout argument ancien est nécessairement valide aujourd’hui',
        ],
        correctAnswer:
            'Une affirmation exige des preuves proportionnées à sa portée plutôt que d’exploiter l’absence de réfutation',
        explanation:
            'L’appel à l’ignorance (ad ignorantiam) confond l’absence de preuve avec la preuve de l’absence ou de la vérité.',
        scheduledPublishAt: DateTime.now().add(const Duration(days: 5)),
      ),
    ],
    debates: [
      const DebateMatchModel(
        id: 'deb-1',
        topicTitle: 'Éducation numérique et maîtrise de l’attention',
        topicQuestion:
            'Faut-il privilégier l’apprentissage sur papier pour la réflexion profonde malgré la richesse des outils numériques ?',
        category: 'society',
        isIslamicSubject: false,
        matchType: 'public',
        status: 'open',
        opponentName: 'Ouvert à un membre',
        userPosition: 'nuanced',
        opponentPosition: 'against',
      ),
      const DebateMatchModel(
        id: 'deb-2',
        topicTitle: 'Méthodologie et dialogue interdisciplinaire',
        topicQuestion:
            'Comment articuler fidélité aux fondements scripturaires vérifiés et renouvellement des sciences humaines contemporaines ?',
        category: 'islamic_thought',
        isIslamicSubject: true,
        matchType: 'public',
        status: 'open',
        opponentName: 'Ouvert à un membre',
        userPosition: 'for',
        opponentPosition: 'nuanced',
      ),
    ],
    quizQuestions: const [
      QuizQuestionModel(
        id: 'q-1',
        category: 'logic',
        questionType: 'logic_puzzle',
        difficulty: 'intermediate',
        questionText:
            'Si tous les chercheurs rigoureux vérifient leurs sources, et que certains étudiants sont des chercheurs rigoureux, quelle conclusion est certaine ?',
        options: [
          'Tous les étudiants vérifient leurs sources',
          'Certains étudiants vérifient leurs sources',
          'Aucun étudiant ne se trompe',
          'Tous ceux qui vérifient leurs sources sont étudiants',
        ],
        correctOptionIndex: 1,
        explanation:
            'Syllogisme valide (Darii) : l’intersection non vide garantit que certains étudiants appartiennent à la classe des personnes qui vérifient leurs sources.',
        verifiedReferences: ['Logique formelle classique'],
      ),
      QuizQuestionModel(
        id: 'q-2',
        category: 'islamic_thought',
        questionType: 'islamic_knowledge',
        difficulty: 'beginner',
        questionText:
            'Dans la méthodologie scientifique du Hadith, quel terme désigne la chaîne des transmetteurs ?',
        options: ['Al-Isnad', 'Al-Qiyas', 'Al-Ijma', 'Al-Istihsan'],
        correctOptionIndex: 0,
        explanation:
            "Al-Isnad permet d'examiner la continuité et l'intégrité historique de chaque maillon de transmission.",
        verifiedReferences: ['Ulum al-Hadith — Ibn al-Salah'],
      ),
      QuizQuestionModel(
        id: 'q-3',
        category: 'history',
        questionType: 'history',
        difficulty: 'intermediate',
        questionText:
            'Quelle institution fondée à Bagdad au IXe siècle a favorisé la traduction et la recherche pluridisciplinaire ?',
        options: [
          'Bayt al-Hikma (La Maison de la Sagesse)',
          'La Royal Society',
          'L’Université de Bologne',
          'L’Académie de Florence',
        ],
        correctOptionIndex: 0,
        explanation:
            'Bayt al-Hikma a réuni traducteurs et savants de diverses cultures pour faire progresser mathématiques, astronomie, médecine et philosophie.',
        verifiedReferences: ['Histoire des sciences arabes — Roshdi Rashed'],
      ),
      QuizQuestionModel(
        id: 'q-4',
        category: 'science',
        questionType: 'true_false',
        difficulty: 'beginner',
        questionText:
            'Vrai ou Faux : Une corrélation statistique élevée entre deux phénomènes prouve automatiquement qu’un phénomène cause l’autre.',
        options: ['Vrai', 'Faux'],
        correctOptionIndex: 1,
        explanation:
            'Faux : une variable confondante ou une causalité inverse peut créer une corrélation sans causalité directe.',
        verifiedReferences: ['Méthodologie statistique'],
      ),
      QuizQuestionModel(
        id: 'q-5',
        category: 'philosophy',
        questionType: 'mcq',
        difficulty: 'intermediate',
        questionText:
            'En philosophie et logique argumentative, en quoi consiste le « principe de charité interprétative » ?',
        options: [
          'Reconstruire la thèse de l’interlocuteur dans sa forme la plus forte avant de la discuter',
          'Éviter toute critique pour préserver le consensus apparent',
          'Citer un auteur sans vérifier le contexte de sa phrase',
          'Réduire un argument complexe à une caricature facile à réfuter',
        ],
        correctOptionIndex: 0,
        explanation:
            'Contrairement à l’homme de paille (strawman), le principe de charité interprète un propos sous son meilleur jour rationnel avant de l’évaluer.',
        verifiedReferences: ['Rhétorique & Philosophie analytique'],
      ),
      QuizQuestionModel(
        id: 'q-6',
        category: 'ethics',
        questionType: 'mcq',
        difficulty: 'intermediate',
        questionText:
            'Quelle disposition coranique (Sourate Al-Hujurat, 49:6) fonde l’éthique de vérification des informations (« at-tabayyun ») ?',
        options: [
          'Vérifier la véracité d’une nouvelle transmise avant d’agir ou de juger des personnes',
          'Diffuser toute rumeur dès qu’elle circule rapidement',
          'Ignorer les témoignages concordants',
          'Déléguer tout jugement moral à des rumeurs anonymes',
        ],
        correctOptionIndex: 0,
        explanation:
            'Le verset recommande expressément d’examiner et vérifier les faits (« fatabayyanū ») afin de ne léser personne par ignorance.',
        verifiedReferences: ['Coran, Sourate Al-Hujurat (49:6)'],
      ),
    ],
    quizScoreTotal: 0,
    quizMatchesPlayed: 0,
    zikrSessions: [
      ZikrSessionModel(
        id: 'zikr-sat-2000',
        title: 'Rassemblement Hebdomadaire — Samedi 20h00 GMT',
        description:
            'Cercle fraternel hebdomadaire de dhikr, gratitude et invocation sereine, sans classement ni compétition.',
        programDetails:
            '20h00 GMT Ouverture • 20h05 Tasbih & Tahmid • 20h25 Invocations authentiques • 20h40 Clôture fraternelle',
        scheduledAt: nextSaturday,
        isRecurring: true,
        recurrenceLabel: 'Chaque samedi à 20h00 GMT',
        arabicText: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، سُبْحَانَ اللَّهِ الْعَظِيمِ',
        transliteration: 'SubḥānAllāhi wa bi-ḥamdih, SubḥānAllāhi l-ʿAẓīm',
        frenchTranslation: 'Gloire et louange à Allah, Gloire à Allah l’Immense.',
        verifiedReferences: const [
          'Sahih al-Bukhari n° 6406 & 7563',
          'Sahih Muslim n° 2694',
        ],
        recommendedRepetitions: 33,
        livekitRoomName: 'yitte-zikr-saturday-2000-gmt',
      ),
      ZikrSessionModel(
        id: 'zikr-tahlil',
        title: 'Cercle de Méditation : Tahlīl & Constance',
        description:
            'Session calme dédiée à la présence du cœur et au sens profond des invocations.',
        programDetails: 'Lecture posée, traduction commentée et rappel vérifié.',
        scheduledAt: nextSaturday.subtract(const Duration(days: 3)),
        isRecurring: true,
        recurrenceLabel: 'Chaque mercredi à 19h00 GMT',
        arabicText:
            'لَا إِلَهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ، لَهُ الْمُلْكُ وَلَهُ الْحَمْدُ وَهُوَ عَلَى كُلِّ شَيْءٍ قَدِيرٌ',
        transliteration:
            'Lā ilāha illAllāhu waḥdahu lā sharīka lah, lahu l-mulku wa lahu l-ḥamdu wa huwa ʿalā kulli shayʾin qadīr',
        frenchTranslation:
            'Il n’y a de divinité digne d’adoration qu’Allah, Seul sans associé ; à Lui la royauté, à Lui la louange et Il est Omnipotent.',
        verifiedReferences: const [
          'Sahih al-Bukhari n° 3293',
          'Sahih Muslim n° 2691',
        ],
        recommendedRepetitions: 33,
        livekitRoomName: 'yitte-zikr-wednesday-1900-gmt',
      ),
    ],
    personalTasbihCount: 0,
    personalZikrSessionsCount: 0,
    zikrReminderEnabled: true,
    salawatMonthlyTarget: 10000,
    salawatDurationDays: 30,
    salawatCustomTitle: 'Ṣalātu ʿalā an-Nabī',
    salawatMonthlyCount: 0,
    salawatTodayCount: 0,
    salawatLastDayIso: EcosystemNotifier._todayIso(),
    salawatCycleStartIso: EcosystemNotifier._todayIso(),
    dailyTasbihReminderEnabled: true,
    openTasbihOnLaunch: false,
    dailyVocab: const [
      VocabularyWordModel(
        id: 'v-1',
        word: 'Discernment',
        phoneticUk: '/dɪˈsɜːn.mənt/',
        phoneticUs: '/dɪˈsɝːn.mənt/',
        partOfSpeech: 'noun',
        cefrLevel: 'C1',
        definitionEn: 'The ability to judge well with clarity and nuance.',
        definitionFr: 'Capacité de juger avec justesse et nuance.',
        exampleEn:
            'Intellectual discernment protects us from hasty conclusions.',
        exampleFr:
            'Le discernement intellectuel nous protège des conclusions hâtives.',
      ),
      VocabularyWordModel(
        id: 'v-2',
        word: 'Steadfast',
        phoneticUk: '/ˈsted.fɑːst/',
        phoneticUs: '/ˈsted.fæst/',
        partOfSpeech: 'adjective',
        cefrLevel: 'B2',
        definitionEn: 'Resolutely firm and consistent in purpose.',
        definitionFr: 'Constant et résolu dans ses engagements.',
        exampleEn: 'She remained steadfast in her daily reading habit.',
        exampleFr: 'Elle est restée constante dans sa lecture quotidienne.',
      ),
      VocabularyWordModel(
        id: 'v-3',
        word: 'Coherence',
        phoneticUk: '/kəʊˈhɪə.rəns/',
        phoneticUs: '/koʊˈhɪr.əns/',
        partOfSpeech: 'noun',
        cefrLevel: 'B2',
        definitionEn: 'Logical and consistent connection across ideas.',
        definitionFr: 'Enchaînement logique et cohérent des idées.',
        exampleEn: 'Clear coherence strengthened your opening statement.',
        exampleFr: 'Une claire cohérence a renforcé votre introduction.',
      ),
      VocabularyWordModel(
        id: 'v-4',
        word: 'Articulate',
        phoneticUk: '/ɑːˈtɪk.jə.lət/',
        phoneticUs: '/ɑːrˈtɪk.jə.lət/',
        partOfSpeech: 'adjective',
        cefrLevel: 'B1',
        definitionEn: 'Able to express ideas clearly in speech or writing.',
        definitionFr: 'Capable d’exprimer sa pensée avec clarté.',
        exampleEn: 'Daily speaking practice makes learners more articulate.',
        exampleFr: 'La pratique orale rend les apprenants plus clairs.',
      ),
      VocabularyWordModel(
        id: 'v-5',
        word: 'Stewardship',
        phoneticUk: '/ˈstjuː.əd.ʃɪp/',
        phoneticUs: '/ˈstuː.ɚd.ʃɪp/',
        partOfSpeech: 'noun',
        cefrLevel: 'C1',
        definitionEn: 'Ethical, responsible care of shared trust and knowledge.',
        definitionFr: 'Gestion responsable et éthique d’un bien confié.',
        exampleEn: 'Community stewardship preserves knowledge for everyone.',
        exampleFr: 'La responsabilité partagée préserve le savoir pour tous.',
      ),
      VocabularyWordModel(
        id: 'v-6',
        word: 'Diligence',
        phoneticUk: '/ˈdɪl.ɪ.dʒəns/',
        phoneticUs: '/ˈdɪl.ə.dʒəns/',
        partOfSpeech: 'noun',
        cefrLevel: 'B2',
        definitionEn: 'Careful, persistent and conscientious effort.',
        definitionFr: 'Assiduité, soin constant et application rigoureuse.',
        exampleEn: 'Academic excellence requires daily diligence.',
        exampleFr: 'L’excellence académique exige une assiduité quotidienne.',
      ),
      VocabularyWordModel(
        id: 'v-7',
        word: 'Humility',
        phoneticUk: '/hjuːˈmɪl.ə.ti/',
        phoneticUs: '/hjuːˈmɪl.ə.t̬i/',
        partOfSpeech: 'noun',
        cefrLevel: 'B2',
        definitionEn: 'Modest view of oneself coupled with openness to learn.',
        definitionFr: 'Humilité intellectuelle et modestie devant le savoir.',
        exampleEn: 'True scholars combine vast knowledge with deep humility.',
        exampleFr: 'Les vrais savants allient vaste savoir et profonde humilité.',
      ),
      VocabularyWordModel(
        id: 'v-8',
        word: 'Integrity',
        phoneticUk: '/ɪnˈteɡ.rə.ti/',
        phoneticUs: '/ɪnˈteɡ.rə.t̬i/',
        partOfSpeech: 'noun',
        cefrLevel: 'B2',
        definitionEn: 'Honesty and consistent adherence to moral principles.',
        definitionFr: 'Intégrité morale et droiture sans compromission.',
        exampleEn: 'Professional integrity builds lasting community trust.',
        exampleFr: 'L’intégrité professionnelle bâtit une confiance durable.',
      ),
      VocabularyWordModel(
        id: 'v-9',
        word: 'Clarity',
        phoneticUk: '/ˈklær.ə.ti/',
        phoneticUs: '/ˈkler.ə.t̬i/',
        partOfSpeech: 'noun',
        cefrLevel: 'B1',
        definitionEn: 'The quality of being coherent, transparent and easy to grasp.',
        definitionFr: 'Clarté d’expression et limpidité du raisonnement.',
        exampleEn: 'Explain complex medical concepts with clarity.',
        exampleFr: 'Expliquez les notions médicales complexes avec clarté.',
      ),
      VocabularyWordModel(
        id: 'v-10',
        word: 'Purpose',
        phoneticUk: '/ˈpɜː.pəs/',
        phoneticUs: '/ˈpɝː.pəs/',
        partOfSpeech: 'noun',
        cefrLevel: 'A2',
        definitionEn: 'The reason for which something is done or created.',
        definitionFr: 'But réfléchi, intention et sens profond d’une action.',
        exampleEn: 'Work with clear purpose rather than distraction.',
        exampleFr: 'Travaillez avec un objectif clair plutôt qu’avec dispersion.',
      ),
      VocabularyWordModel(
        id: 'v-11',
        word: 'Gratitude',
        phoneticUk: '/ˈɡræt.ɪ.tʃuːd/',
        phoneticUs: '/ˈɡræt̬.ə.tuːd/',
        partOfSpeech: 'noun',
        cefrLevel: 'B1',
        definitionEn: 'Warm appreciation and thankfulness for blessings.',
        definitionFr: 'Reconnaissance sincère envers Dieu et autrui.',
        exampleEn: 'Gratitude keeps the heart serene in every season.',
        exampleFr: 'La gratitude garde le cœur apaisé en toute saison.',
      ),
      VocabularyWordModel(
        id: 'v-12',
        word: 'Evidence',
        phoneticUk: '/ˈev.ɪ.dəns/',
        phoneticUs: '/ˈev.ə.dəns/',
        partOfSpeech: 'noun',
        cefrLevel: 'B1',
        definitionEn: 'Verifiable facts supporting a claim or hypothesis.',
        definitionFr: 'Preuve vérifiable appuyant une affirmation.',
        exampleEn: 'Always check primary evidence before sharing news.',
        exampleFr: 'Vérifiez toujours les preuves avant de relayer une information.',
      ),
      VocabularyWordModel(
        id: 'v-13',
        word: 'Nuance',
        phoneticUk: '/ˈnjuː.ɑːns/',
        phoneticUs: '/ˈnuː.ɑːns/',
        partOfSpeech: 'noun',
        cefrLevel: 'C1',
        definitionEn: 'Subtle distinction in meaning, tone or reasoning.',
        definitionFr: 'Distinction fine permettant d’éviter la caricature.',
        exampleEn: 'Balanced debates thrive on careful nuance.',
        exampleFr: 'Les débats équilibrés s’élèvent par la nuance rigoureuse.',
      ),
      VocabularyWordModel(
        id: 'v-14',
        word: 'Hypothesis',
        phoneticUk: '/haɪˈpɒθ.ə.sɪs/',
        phoneticUs: '/haɪˈpɑː.θə.sɪs/',
        partOfSpeech: 'noun',
        cefrLevel: 'B2',
        definitionEn: 'A proposed explanation tested through scientific method.',
        definitionFr: 'Hypothèse formulée en vue d’une vérification expérimentale.',
        exampleEn: 'Our physics team tested the hypothesis in the lab.',
        exampleFr: 'Notre équipe de physique a testé l’hypothèse en laboratoire.',
      ),
      VocabularyWordModel(
        id: 'v-15',
        word: 'Sustainability',
        phoneticUk: '/səˌsteɪ.nəˈbɪl.ə.ti/',
        phoneticUs: '/səˌsteɪ.nəˈbɪl.ə.t̬i/',
        partOfSpeech: 'noun',
        cefrLevel: 'B2',
        definitionEn: 'Meeting present needs responsibly without harming the future.',
        definitionFr: 'Durabilité écologique, agricole et économique.',
        exampleEn: 'Modern agronomy prioritizes soil sustainability.',
        exampleFr: 'L’agronomie moderne donne la priorité à la durabilité des sols.',
      ),
      VocabularyWordModel(
        id: 'v-16',
        word: 'Irrigation',
        phoneticUk: '/ˌɪr.ɪˈɡeɪ.ʃən/',
        phoneticUs: '/ˌɪr.əˈɡeɪ.ʃən/',
        partOfSpeech: 'noun',
        cefrLevel: 'B2',
        definitionEn: 'Controlled water supply to cultivate healthy crops.',
        definitionFr: 'Système d’irrigation maîtrisée des cultures agricoles.',
        exampleEn: 'Smart drip irrigation saves water during dry months.',
        exampleFr: 'L’irrigation goutte-à-goutte économise l’eau en saison sèche.',
      ),
      VocabularyWordModel(
        id: 'v-17',
        word: 'Diagnosis',
        phoneticUk: '/ˌdaɪ.əɡˈnəʊ.sɪs/',
        phoneticUs: '/ˌdaɪ.əɡˈnoʊ.sɪs/',
        partOfSpeech: 'noun',
        cefrLevel: 'B2',
        definitionEn: 'Accurate identification of an illness or system issue.',
        definitionFr: 'Diagnostic médical ou analytique fondé sur l’observation.',
        exampleEn: 'Early diagnosis significantly improves patient recovery.',
        exampleFr: 'Un diagnostic précoce améliore fortement la guérison.',
      ),
      VocabularyWordModel(
        id: 'v-18',
        word: 'Circuitry',
        phoneticUk: '/ˈsɜː.kɪt.ri/',
        phoneticUs: '/ˈsɝː.kɪt.ri/',
        partOfSpeech: 'noun',
        cefrLevel: 'C1',
        definitionEn: 'Interconnected electronic components routing signals or power.',
        definitionFr: 'Ensemble de circuits et composants électroniques.',
        exampleEn: 'She designed low-power circuitry for solar sensors.',
        exampleFr: 'Elle a conçu des circuits basse consommation pour capteurs solaires.',
      ),
      VocabularyWordModel(
        id: 'v-19',
        word: 'Algorithm',
        phoneticUk: '/ˈæl.ɡə.rɪ.ðəm/',
        phoneticUs: '/ˈæl.ɡə.rɪ.ðəm/',
        partOfSpeech: 'noun',
        cefrLevel: 'B2',
        definitionEn: 'A precise sequence of steps solving a computational task.',
        definitionFr: 'Suite ordonnée d’instructions logiques en informatique.',
        exampleEn: 'An efficient algorithm reduces server energy use.',
        exampleFr: 'Un algorithme efficace réduit la consommation énergétique.',
      ),
      VocabularyWordModel(
        id: 'v-20',
        word: 'Theorem',
        phoneticUk: '/ˈθɪə.rəm/',
        phoneticUs: '/ˈθiː.ə.rəm/',
        partOfSpeech: 'noun',
        cefrLevel: 'C1',
        definitionEn: 'A mathematical truth rigorously proven from axioms.',
        definitionFr: 'Proposition mathématique démontrée de manière rigoureuse.',
        exampleEn: 'Every step of the proof supported the final theorem.',
        exampleFr: 'Chaque étape de la démonstration appuyait le théorème final.',
      ),
      VocabularyWordModel(
        id: 'v-21',
        word: 'Prototype',
        phoneticUk: '/ˈprəʊ.tə.taɪp/',
        phoneticUs: '/ˈproʊ.t̬ə.taɪp/',
        partOfSpeech: 'noun',
        cefrLevel: 'B2',
        definitionEn: 'First working model used to validate an engineering design.',
        definitionFr: 'Premier modèle fonctionnel d’un projet technique.',
        exampleEn: 'Our students built an agricultural sensor prototype.',
        exampleFr: 'Nos membres ont conçu un prototype de capteur agricole.',
      ),
      VocabularyWordModel(
        id: 'v-22',
        word: 'Reliability',
        phoneticUk: '/rɪˌlaɪ.əˈbɪl.ə.ti/',
        phoneticUs: '/rɪˌlaɪ.əˈbɪl.ə.t̬i/',
        partOfSpeech: 'noun',
        cefrLevel: 'B2',
        definitionEn: 'Consistent, trustworthy performance under real conditions.',
        definitionFr: 'Fiabilité technique et constance d’exécution.',
        exampleEn: 'Reliability matters more than flashy features.',
        exampleFr: 'La fiabilité compte plus que les artifices visuels.',
      ),
      VocabularyWordModel(
        id: 'v-23',
        word: 'Collaboration',
        phoneticUk: '/kəˌlæb.əˈreɪ.ʃən/',
        phoneticUs: '/kəˌlæb.əˈreɪ.ʃən/',
        partOfSpeech: 'noun',
        cefrLevel: 'B1',
        definitionEn: 'Working together across specialties toward a shared goal.',
        definitionFr: 'Complémentarité active et travail collectif.',
        exampleEn: 'Agronomists and engineers achieved great results through collaboration.',
        exampleFr: 'Agronomes et ingénieurs ont réussi grâce à la collaboration.',
      ),
      VocabularyWordModel(
        id: 'v-24',
        word: 'Synthesize',
        phoneticUk: '/ˈsɪn.θə.saɪz/',
        phoneticUs: '/ˈsɪn.θə.saɪz/',
        partOfSpeech: 'verb',
        cefrLevel: 'C1',
        definitionEn: 'Combine distinct verified sources into a unified insight.',
        definitionFr: 'Synthétiser plusieurs idées sourcées en un ensemble clair.',
        exampleEn: 'Let us synthesize the group notes into a study guide.',
        exampleFr: 'Synthétisons les notes du groupe en un guide d’étude.',
      ),
      VocabularyWordModel(
        id: 'v-25',
        word: 'Conscientious',
        phoneticUk: '/ˌkɒn.ʃiˈen.ʃəs/',
        phoneticUs: '/ˌkɑːn.ʃiˈen.ʃəs/',
        partOfSpeech: 'adjective',
        cefrLevel: 'C1',
        definitionEn: 'Thorough, principled and deeply attentive to duty.',
        definitionFr: 'Consciencieux, appliqué et guidé par l’éthique.',
        exampleEn: 'Conscientious work honours both the team and oneself.',
        exampleFr: 'Un travail consciencieux honore l’équipe autant que soi-même.',
      ),
      VocabularyWordModel(
        id: 'v-26',
        word: 'Comprehend',
        phoneticUk: '/ˌkɒm.prɪˈhend/',
        phoneticUs: '/ˌkɑːm.prəˈhend/',
        partOfSpeech: 'verb',
        cefrLevel: 'B2',
        definitionEn: 'Understand something deeply rather than superficially.',
        definitionFr: 'Comprendre en profondeur un principe ou un texte.',
        exampleEn: 'Read slowly to comprehend the author’s core argument.',
        exampleFr: 'Lisez posément pour comprendre la thèse centrale de l’auteur.',
      ),
      VocabularyWordModel(
        id: 'v-27',
        word: 'Methodology',
        phoneticUk: '/ˌmeθ.əˈdɒl.ə.dʒi/',
        phoneticUs: '/ˌmeθ.əˈdɑː.lə.dʒi/',
        partOfSpeech: 'noun',
        cefrLevel: 'C1',
        definitionEn: 'Structured system of principles guiding research or work.',
        definitionFr: 'Méthodologie structurée guidant une démarche rigoureuse.',
        exampleEn: 'Clear methodology distinguishes science from guesswork.',
        exampleFr: 'Une méthode claire distingue la science de l’approximation.',
      ),
      VocabularyWordModel(
        id: 'v-28',
        word: 'Resilience',
        phoneticUk: '/rɪˈzɪl.i.əns/',
        phoneticUs: '/rɪˈzɪl.jəns/',
        partOfSpeech: 'noun',
        cefrLevel: 'B2',
        definitionEn: 'Strength to recover and grow steadfastly after adversity.',
        definitionFr: 'Résilience et fermeté face aux épreuves.',
        exampleEn: 'Faith and brotherhood foster remarkable resilience.',
        exampleFr: 'La foi et la fraternité nourrissent une résilience remarquable.',
      ),
      VocabularyWordModel(
        id: 'v-29',
        word: 'Knowledge',
        phoneticUk: '/ˈnɒl.ɪdʒ/',
        phoneticUs: '/ˈnɑː.lɪdʒ/',
        partOfSpeech: 'noun',
        cefrLevel: 'A1',
        definitionEn: 'Facts, understanding and wisdom gained through study.',
        definitionFr: 'Connaissance acquise par l’étude et l’expérience.',
        exampleEn: 'Seek beneficial knowledge every single day.',
        exampleFr: 'Recherchez chaque jour le savoir bénéfique.',
      ),
      VocabularyWordModel(
        id: 'v-30',
        word: 'Improve',
        phoneticUk: '/ɪmˈpruːv/',
        phoneticUs: '/ɪmˈpruːv/',
        partOfSpeech: 'verb',
        cefrLevel: 'A1',
        definitionEn: 'To make or become better in skill, clarity or character.',
        definitionFr: 'Améliorer, progresser pas à pas.',
        exampleEn: 'Five minutes of speaking daily will improve your fluency.',
        exampleFr: 'Cinq minutes d’oral par jour amélioreront votre fluidité.',
      ),
      VocabularyWordModel(
        id: 'v-31',
        word: 'Listen',
        phoneticUk: '/ˈlɪs.ən/',
        phoneticUs: '/ˈlɪs.ən/',
        partOfSpeech: 'verb',
        cefrLevel: 'A1',
        definitionEn: 'Give attentive respect to what someone is saying.',
        definitionFr: 'Écouter attentivement avec respect.',
        exampleEn: 'Listen carefully before formulating your rebuttal.',
        exampleFr: 'Écoutez attentivement avant de formuler votre réponse.',
      ),
      VocabularyWordModel(
        id: 'v-32',
        word: 'Respect',
        phoneticUk: '/rɪˈspekt/',
        phoneticUs: '/rɪˈspekt/',
        partOfSpeech: 'noun',
        cefrLevel: 'A2',
        definitionEn: 'Due regard for the dignity, intellect and feelings of others.',
        definitionFr: 'Respect sincère de la dignité d’autrui.',
        exampleEn: 'Disagree with ideas while maintaining full respect.',
        exampleFr: 'Discutez des idées tout en gardant un respect total.',
      ),
      VocabularyWordModel(
        id: 'v-33',
        word: 'Verify',
        phoneticUk: '/ˈver.ɪ.faɪ/',
        phoneticUs: '/ˈver.ə.faɪ/',
        partOfSpeech: 'verb',
        cefrLevel: 'B1',
        definitionEn: 'Confirm that a quote, number or source is accurate.',
        definitionFr: 'Vérifier l’exactitude d’une source avant diffusion.',
        exampleEn: 'Always verify citations before presenting them publicly.',
        exampleFr: 'Vérifiez toujours les citations avant de les présenter.',
      ),
      VocabularyWordModel(
        id: 'v-34',
        word: 'Calibration',
        phoneticUk: '/ˌkæl.ɪˈbreɪ.ʃən/',
        phoneticUs: '/ˌkæl.əˈbreɪ.ʃən/',
        partOfSpeech: 'noun',
        cefrLevel: 'C2',
        definitionEn: 'Fine adjustment of instruments or judgment to match reality.',
        definitionFr: 'Étalonnage de précision en physique et métrologie.',
        exampleEn: 'Sensor calibration ensures reliable physics measurements.',
        exampleFr: 'L’étalonnage des capteurs assure des mesures physiques fiables.',
      ),
      VocabularyWordModel(
        id: 'v-35',
        word: 'Equanimity',
        phoneticUk: '/ˌek.wəˈnɪm.ə.ti/',
        phoneticUs: '/ˌiː.kwəˈnɪm.ə.t̬i/',
        partOfSpeech: 'noun',
        cefrLevel: 'C2',
        definitionEn: 'Calmness and composure especially under difficult pressure.',
        definitionFr: 'Sérénité d’esprit et sang-froid dans l’épreuve.',
        exampleEn: 'She answered tough debate questions with equanimity.',
        exampleFr: 'Elle a répondu aux objections difficiles avec sérénité.',
      ),
    ],
    englishLessons: const [
      EnglishLessonModel(
        id: 'el-1',
        moduleType: 'grammar',
        title: 'Concession & Nuance: Although vs Despite',
        description: 'Build balanced arguments cleanly in British & American English.',
        cefrLevel: 'B2',
        variant: 'en-GB',
        contentMarkdown:
            'Use "Although + clause" and "Despite + noun/-ing" to acknowledge counter-perspectives without weakening your thesis.',
      ),
      EnglishLessonModel(
        id: 'el-2',
        moduleType: 'pronunciation_lab',
        title: 'Intelligibility First: Word Stress & Pausing',
        description:
            'Train clear stress patterns without erasing your authentic accent.',
        cefrLevel: 'B1',
        variant: 'en-US',
        contentMarkdown:
            'Clear rhythm and primary stress (de-VE-lop-ment, e-VA-lu-ate) maximize understanding across global teams.',
      ),
      EnglishLessonModel(
        id: 'el-3',
        moduleType: 'weekly_speaking_challenge',
        title: 'Weekly Speaking Challenge: AI & Genuine Learning',
        description: 'Record a 90-second structured reflection.',
        cefrLevel: 'B2',
        variant: 'en-GB',
        contentMarkdown:
            'How can young scholars use technology without sacrificing deep concentration and intellectual honesty?',
        isWeeklyChallenge: true,
      ),
    ],
    careerOpportunities: const [
      CareerOpportunityModel(
        id: 'op-1',
        title: 'Mentorat Ingénierie IA & Architecture Logicielle',
        organization: 'Collectif Boroom Yitté Tech',
        type: 'mentorship',
        domain: 'Intelligence Artificielle',
        location: 'En ligne',
        description:
            '8 semaines d’accompagnement : architecture, revue de code, simulations d’entretien et projet concret.',
      ),
      CareerOpportunityModel(
        id: 'op-2',
        title: 'Parcours Cybersécurité & Gestion de Projet Agile',
        organization: 'Académie Yitté Pro',
        type: 'certification',
        domain: 'Cybersécurité',
        location: 'En ligne (FR/EN)',
        description:
            'Préparation structurée aux bonnes pratiques OWASP, sécurité cloud et pilotage produit.',
      ),
    ],
    portfolioProjects: const [],
    cvDraft: '',
    coverLetterDraft: '',
    personalGoals: const [
      PersonalGoalModel(
        id: 'pg-1',
        title: 'Lire 20 pages par jour d’un ouvrage de fond',
        horizon: 'weekly',
        progressPercent: 0,
      ),
    ],
    habits: const [
      HabitModel(id: 'hb-1', name: 'Lecture quotidienne (20 min)', streakDays: 0),
      HabitModel(id: 'hb-2', name: 'Pratique orale en anglais', streakDays: 0),
    ],
    books: const [
      ReadingBookModel(
        id: 'bk-1',
        title: 'Iḥyāʾ ʿUlūm ad-Dīn (Sélection éthique du savoir)',
        author: 'Al-Ghazālī',
        currentPage: 0,
        totalPages: 220,
      ),
    ],
    privateNotes: const [],
    voiceRooms: const [
      VoiceRoomModel(
        id: 'vr-1',
        title: 'Cercle Anglais B1/B2 — Practical Leadership',
        roomType: 'english_conversation',
        hostName: 'Cercle Boroom Yitté',
        livekitRoomName: 'yitte-english-b1-b2',
        cefrFilter: 'B1/B2',
        participantsCount: 0,
      ),
      VoiceRoomModel(
        id: 'vr-2',
        title: 'Atelier Philosophie & Logique Appliquée',
        roomType: 'workshop',
        hostName: 'Cercle Boroom Yitté',
        livekitRoomName: 'yitte-workshop-logic',
        participantsCount: 0,
      ),
    ],
    messages: const [],
    blockedUsers: const {},
    reports: const [],
    generatedInvites: const [],
    auditLogs: const [
      'Initialisation de la plateforme Boroom Yitté Yu Kawé Yi',
    ],
    announcements: const [],
    members: const [],
    quizLeaderboard: const [],
    libraryDocuments: const [],
    extraGroupeMeetings: [
      ExtraGroupeMeetingModel(
        id: 'eg-1',
        guest: const ExtraGroupeGuestModel(
          id: 'guest-serigne-makhtar-thiam',
          fullName: 'Serigne Makhtar Thiam',
          titleOrRole: 'Invité d’honneur — Première rencontre Extra Groupe',
          biography:
              'Personnalité invitée pour éclairer les jeunes de la communauté sur les défis contemporains à la lumière des enseignements des Gaayu Bakh Yi.',
          expertiseDomains: [
            'Éducation spirituelle & valeurs',
            'Responsabilité de la jeunesse',
            'Enseignements de Cheikhoul Khadim',
          ],
        ),
        theme:
            '« La jeunesse face aux défis de son époque : s’élever ensemble à la lumière des enseignements de nos Gaayu Bakh Yi à l’image de Cheikhoul Khadim. »',
        presentationText:
            'Nous souhaiterions vous proposer comme thème de notre rencontre : « La jeunesse face aux défis de son époque : s’élever ensemble à la lumière des enseignements de nos Gaayu Bakh Yi à l’image de Cheikhoul Khadim. »\n'
            'Il s’agira de réfléchir à la place et à la responsabilité du jeune dans un monde où les repères semblent de plus en plus fragilisés, aux valeurs qu’il doit cultiver, aux principes auxquels il doit s’attacher et aux comportements dont il doit s’éloigner pour construire un avenir meilleur.\n'
            'Nous aimerions également que cette réflexion tienne compte des réalités et des défis auxquels notre génération est confrontée aujourd’hui, particulièrement dans notre chère patrie.\n'
            'À la suite de votre intervention, un temps d’échange sera consacré aux questions et aux réflexions des participants afin d’approfondir davantage les différents points abordés.\n'
            'Nous serions honorés de bénéficier de vos éclairages et de vos précieux conseils sur cette thématique.\n'
            'Qu’Allah vous récompense pour votre disponibilité et vous accorde une abondante baraka.',
        contextNotes:
            'Première rencontre mensuelle Extra Groupe distincte des discussions hebdomadaires ordinaires.',
        objectives: const [
          'Identifier les repères moraux et spirituels face aux défis contemporains',
          'Renforcer la responsabilité et l’engagement utile des jeunes dans la société',
          'Favoriser un temps approfondi de questions-réponses avec l’invité',
        ],
        programItems: const [
          'Accueil et présentation du thème',
          'Présentation du parcours de Serigne Makhtar Thiam',
          'Intervention principale sur les enseignements des Gaayu Bakh Yi',
          'Échanges, questions des participants et synthèse',
        ],
        scheduledAt: nextSaturday.add(const Duration(days: 7)),
        practicalInfo:
            'Enregistrement audio/vidéo soumis strictement à autorisation préalable de l’invité et des participants.',
        status: 'upcoming',
        recordingAuthorized: false,
        registeredParticipants: const [
          'Cheikh Mouhamadou Moustapha Lo',
          'Sokhna Diarra Lo',
          'Sokhna Amy Mountakha Thiam',
          'Serigne Khadim Seye',
          'Ahmadou Bamba Deme',
          'Sokhna Bintou Beye',
          'Sokhna Khady Sylla',
          'Sokhna Aida Thiam',
          'Sokhna Oumy Lo',
        ],
        rosterPublicToCircle: false,
      ),
    ],
    notifications: const [],
    validatedDailyThought: null,
  );
}

DateTime _nextSaturday2000Utc() {
  final now = DateTime.now().toUtc();
  var candidate = DateTime.utc(now.year, now.month, now.day, 20, 0);
  while (candidate.weekday != DateTime.saturday || !candidate.isAfter(now)) {
    candidate = candidate.add(const Duration(days: 1));
  }
  return candidate;
}
