// Core immutable domain models matching the 39+ PostgreSQL tables

enum AppRole {
  superAdmin('super_admin', 'Super Administrateur'),
  admin('admin', 'Administrateur'),
  moderator('moderator', 'Modérateur'),
  contentEditor('content_editor', 'Éditeur de Contenu'),
  member('member', 'Membre');

  const AppRole(this.code, this.labelFr);
  final String code;
  final String labelFr;

  bool get isAdminOrAbove => this == superAdmin || this == admin;
  bool get isModeratorOrAbove => isAdminOrAbove || this == moderator;
  bool get isEditorOrAbove => isAdminOrAbove || this == contentEditor;

  static AppRole fromCode(String? code) => AppRole.values.firstWhere(
        (r) => r.code == code,
        orElse: () => AppRole.member,
      );
}

class UserProfile {
  final String id;
  final String username;
  final String fullName;
  final String email;
  final String bio;
  final String city;
  final String country;
  final String preferredLanguage;
  final String cefrLevel;
  final String englishVariant;
  final AppRole role;
  final List<String> interests;
  final bool onboardingCompleted;
  final bool voiceRecordingConsent;
  final String voiceRetentionPolicy;
  final bool showOnEducationalLeaderboard;
  final bool isGroupMember;

  const UserProfile({
    required this.id,
    required this.username,
    required this.fullName,
    required this.email,
    this.bio = '',
    this.city = 'Dakar',
    this.country = 'Sénégal',
    this.preferredLanguage = 'fr',
    this.cefrLevel = 'B1',
    this.englishVariant = 'en-GB',
    this.role = AppRole.member,
    this.interests = const ['Pensée islamique', 'Philosophie', 'IA & Tech'],
    this.onboardingCompleted = false,
    this.voiceRecordingConsent = false,
    this.voiceRetentionPolicy = 'thirty_days',
    this.showOnEducationalLeaderboard = true,
    this.isGroupMember = true,
  });

  UserProfile copyWith({
    String? username,
    String? fullName,
    String? bio,
    String? city,
    String? country,
    String? preferredLanguage,
    String? cefrLevel,
    String? englishVariant,
    AppRole? role,
    List<String>? interests,
    bool? onboardingCompleted,
    bool? voiceRecordingConsent,
    String? voiceRetentionPolicy,
    bool? showOnEducationalLeaderboard,
    bool? isGroupMember,
  }) {
    return UserProfile(
      id: id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      email: email,
      bio: bio ?? this.bio,
      city: city ?? this.city,
      country: country ?? this.country,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      cefrLevel: cefrLevel ?? this.cefrLevel,
      englishVariant: englishVariant ?? this.englishVariant,
      role: role ?? this.role,
      interests: interests ?? this.interests,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      voiceRecordingConsent:
          voiceRecordingConsent ?? this.voiceRecordingConsent,
      voiceRetentionPolicy: voiceRetentionPolicy ?? this.voiceRetentionPolicy,
      showOnEducationalLeaderboard:
          showOnEducationalLeaderboard ?? this.showOnEducationalLeaderboard,
      isGroupMember: isGroupMember ?? this.isGroupMember,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'full_name': fullName,
        'email': email,
        'bio': bio,
        'city': city,
        'country': country,
        'preferred_language': preferredLanguage,
        'cefr_level': cefrLevel,
        'preferred_english_variant': englishVariant,
        'primary_role': role.code,
        'interests': interests,
        'onboarding_completed': onboardingCompleted,
        'voice_recording_consent': voiceRecordingConsent,
        'voice_retention_preference': voiceRetentionPolicy,
        'show_on_educational_leaderboard': showOnEducationalLeaderboard,
        'is_group_member': isGroupMember,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json, {String email = ''}) =>
      UserProfile(
        id: json['id']?.toString() ?? 'local-user',
        username: json['username']?.toString() ?? 'membre_yitte',
        fullName: json['full_name']?.toString() ?? 'Membre Boroom Yitté',
        email: email.isNotEmpty ? email : (json['email']?.toString() ?? ''),
        bio: json['bio']?.toString() ?? '',
        city: json['city']?.toString() ?? '',
        country: json['country']?.toString() ?? '',
        preferredLanguage: json['preferred_language']?.toString() ?? 'fr',
        cefrLevel: json['cefr_level']?.toString() ?? 'B1',
        englishVariant:
            json['preferred_english_variant']?.toString() ?? 'en-GB',
        role: AppRole.fromCode(json['primary_role']?.toString()),
        interests: (json['interests'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        onboardingCompleted: json['onboarding_completed'] == true,
        voiceRecordingConsent: json['voice_recording_consent'] == true,
        voiceRetentionPolicy:
            json['voice_retention_preference']?.toString() ?? 'thirty_days',
        showOnEducationalLeaderboard:
            json['show_on_educational_leaderboard'] != false,
        isGroupMember: json['is_group_member'] != false,
      );
}

class GroupMembershipCatalog {
  const GroupMembershipCatalog._();

  static const List<String> officialMembers = [
    'Cheikh Mouhamadou Moustapha Lo',
    'Sokhna Diarra Lo',
    'Sokhna Amy Mountakha Thiam',
    'Serigne Khadim Seye',
    'Ahmadou Bamba Deme',
    'Sokhna Bintou Beye',
    'Sokhna Khady Sylla',
    'Sokhna Aida Thiam',
    'Sokhna Oumy Lo',
  ];

  static String normalizeName(String raw) {
    return raw
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[àáâãä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[îïìí]'), 'i')
        .replaceAll(RegExp(r'[ôöòó]'), 'o')
        .replaceAll(RegExp(r'[ûüùú]'), 'u')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  static String? matchCanonicalName(
    String input, [
    List<String> extraAuthorizedNames = const [],
  ]) {
    final target = normalizeName(input);
    if (target.isEmpty) return null;
    final pool = [...officialMembers, ...extraAuthorizedNames];
    for (final candidate in pool) {
      if (normalizeName(candidate) == target) return candidate;
    }
    return null;
  }

  static bool isRecognizedName(
    String input, [
    List<String> extraAuthorizedNames = const [],
  ]) =>
      matchCanonicalName(input, extraAuthorizedNames) != null;
}

class ReflectionComment {
  final String id;
  final String authorName;
  final String body;
  final DateTime createdAt;
  final List<ReflectionComment> replies;

  const ReflectionComment({
    required this.id,
    required this.authorName,
    required this.body,
    required this.createdAt,
    this.replies = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'author_name': authorName,
        'body': body,
        'created_at': createdAt.toIso8601String(),
        'replies': replies.map((r) => r.toJson()).toList(),
      };

  factory ReflectionComment.fromJson(Map<String, dynamic> j) =>
      ReflectionComment(
        id: j['id'].toString(),
        authorName: j['author_name']?.toString() ?? 'Membre',
        body: j['body']?.toString() ?? '',
        createdAt:
            DateTime.tryParse(j['created_at']?.toString() ?? '') ?? DateTime.now(),
        replies: (j['replies'] as List?)
                ?.map((e) => ReflectionComment.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            const [],
      );
}

class ReflectionPost {
  final String id;
  final String authorId;
  final String authorName;
  final String title;
  final String body;
  final String category;
  final List<String> tags;
  final String? attachmentName;
  final int reactionsCount;
  final bool isSaved;
  final bool isFeaturedInLibrary;
  final bool isArchived;
  final String? introduction;
  final String? contextText;
  final String? motivatingFacts;
  final String? problematics;
  final List<String> mainQuestions;
  final List<String> secondaryQuestions;
  final List<String> reflectionAxes;
  final List<String> documentarySources;
  final String? moderationNote;
  final String validationStatus; // pending | approved | rejected
  final String? discussionDateLabel;
  final bool isHistoricalArchive;
  final List<ReflectionComment> comments;
  final DateTime createdAt;

  const ReflectionPost({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.title,
    required this.body,
    required this.category,
    this.tags = const [],
    this.attachmentName,
    this.reactionsCount = 0,
    this.isSaved = false,
    this.isFeaturedInLibrary = false,
    this.isArchived = false,
    this.introduction,
    this.contextText,
    this.motivatingFacts,
    this.problematics,
    this.mainQuestions = const [],
    this.secondaryQuestions = const [],
    this.reflectionAxes = const [],
    this.documentarySources = const [],
    this.moderationNote,
    this.validationStatus = 'approved',
    this.discussionDateLabel,
    this.isHistoricalArchive = false,
    this.comments = const [],
    required this.createdAt,
  });

  ReflectionPost copyWith({
    int? reactionsCount,
    bool? isSaved,
    bool? isFeaturedInLibrary,
    bool? isArchived,
    String? validationStatus,
    List<ReflectionComment>? comments,
  }) {
    return ReflectionPost(
      id: id,
      authorId: authorId,
      authorName: authorName,
      title: title,
      body: body,
      category: category,
      tags: tags,
      attachmentName: attachmentName,
      reactionsCount: reactionsCount ?? this.reactionsCount,
      isSaved: isSaved ?? this.isSaved,
      isFeaturedInLibrary: isFeaturedInLibrary ?? this.isFeaturedInLibrary,
      isArchived: isArchived ?? this.isArchived,
      introduction: introduction,
      contextText: contextText,
      motivatingFacts: motivatingFacts,
      problematics: problematics,
      mainQuestions: mainQuestions,
      secondaryQuestions: secondaryQuestions,
      reflectionAxes: reflectionAxes,
      documentarySources: documentarySources,
      moderationNote: moderationNote,
      validationStatus: validationStatus ?? this.validationStatus,
      discussionDateLabel: discussionDateLabel,
      isHistoricalArchive: isHistoricalArchive,
      comments: comments ?? this.comments,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'author_id': authorId,
        'author_name': authorName,
        'title': title,
        'body': body,
        'category': category,
        'tags': tags,
        'attachment_name': attachmentName,
        'reactions_count': reactionsCount,
        'is_saved': isSaved,
        'is_featured_in_library': isFeaturedInLibrary,
        'is_archived': isArchived,
        'introduction': introduction,
        'context_text': contextText,
        'motivating_facts': motivatingFacts,
        'problematics': problematics,
        'main_questions': mainQuestions,
        'secondary_questions': secondaryQuestions,
        'reflection_axes': reflectionAxes,
        'documentary_sources': documentarySources,
        'moderation_note': moderationNote,
        'validation_status': validationStatus,
        'discussion_date_label': discussionDateLabel,
        'is_historical_archive': isHistoricalArchive,
        'comments': comments.map((c) => c.toJson()).toList(),
        'created_at': createdAt.toIso8601String(),
      };

  factory ReflectionPost.fromJson(Map<String, dynamic> j) => ReflectionPost(
        id: j['id'].toString(),
        authorId: j['author_id']?.toString() ?? '',
        authorName: j['author_name']?.toString() ?? 'Membre Yitté',
        title: j['title']?.toString() ?? '',
        body: j['body']?.toString() ?? '',
        category: j['category']?.toString() ?? 'philosophy',
        tags: (j['tags'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        attachmentName: j['attachment_name']?.toString(),
        reactionsCount: (j['reactions_count'] as num?)?.toInt() ?? 0,
        isSaved: j['is_saved'] == true,
        isFeaturedInLibrary: j['is_featured_in_library'] == true,
        isArchived: j['is_archived'] == true,
        introduction: j['introduction']?.toString(),
        contextText: j['context_text']?.toString(),
        motivatingFacts: j['motivating_facts']?.toString(),
        problematics: j['problematics']?.toString(),
        mainQuestions: (j['main_questions'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        secondaryQuestions:
            (j['secondary_questions'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        reflectionAxes:
            (j['reflection_axes'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        documentarySources:
            (j['documentary_sources'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        moderationNote: j['moderation_note']?.toString(),
        validationStatus: j['validation_status']?.toString() ?? 'approved',
        discussionDateLabel: j['discussion_date_label']?.toString(),
        isHistoricalArchive: j['is_historical_archive'] == true,
        comments: (j['comments'] as List?)
                ?.map((e) => ReflectionComment.fromJson(Map<String, dynamic>.from(e)))
                .toList() ??
            const [],
        createdAt:
            DateTime.tryParse(j['created_at']?.toString() ?? '') ?? DateTime.now(),
      );
}

class TopicSummaryItem {
  final String id;
  final String title;
  final String summaryMarkdown;
  final List<String> takeaways;
  final List<String> verifiedReferences;
  final String status; // draft | pending_review | approved | rejected | published
  final String? reviewedByName;

  const TopicSummaryItem({
    required this.id,
    required this.title,
    required this.summaryMarkdown,
    this.takeaways = const [],
    this.verifiedReferences = const [],
    this.status = 'pending_review',
    this.reviewedByName,
  });

  TopicSummaryItem copyWith({String? status, String? reviewedByName}) =>
      TopicSummaryItem(
        id: id,
        title: title,
        summaryMarkdown: summaryMarkdown,
        takeaways: takeaways,
        verifiedReferences: verifiedReferences,
        status: status ?? this.status,
        reviewedByName: reviewedByName ?? this.reviewedByName,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'summary_markdown': summaryMarkdown,
        'takeaways': takeaways,
        'verified_references': verifiedReferences,
        'status': status,
        'reviewed_by_name': reviewedByName,
      };

  factory TopicSummaryItem.fromJson(Map<String, dynamic> j) => TopicSummaryItem(
        id: j['id']?.toString() ?? '',
        title: j['title']?.toString() ?? '',
        summaryMarkdown: j['summary_markdown']?.toString() ?? '',
        takeaways: (j['takeaways'] as List?)?.map((e) => e.toString()).toList() ?? const [],
        verifiedReferences:
            (j['verified_references'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        status: j['status']?.toString() ?? 'pending_review',
        reviewedByName: j['reviewed_by_name']?.toString(),
      );
}

class WeeklyTopicModel {
  final String id;
  final int weekNumber;
  final int year;
  final String title;
  final String introduction;
  final List<String> guidingQuestions;
  final List<String> contributions;
  final TopicSummaryItem? summary;

  const WeeklyTopicModel({
    required this.id,
    required this.weekNumber,
    required this.year,
    required this.title,
    required this.introduction,
    required this.guidingQuestions,
    this.contributions = const [],
    this.summary,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'week_number': weekNumber,
        'year': year,
        'title': title,
        'introduction': introduction,
        'guiding_questions': guidingQuestions,
        'contributions': contributions,
        'summary': summary?.toJson(),
      };

  factory WeeklyTopicModel.fromJson(Map<String, dynamic> j) => WeeklyTopicModel(
        id: j['id']?.toString() ?? 'wt-1',
        weekNumber: (j['week_number'] as num?)?.toInt() ?? 46,
        year: (j['year'] as num?)?.toInt() ?? 2026,
        title: j['title']?.toString() ?? '',
        introduction: j['introduction']?.toString() ?? '',
        guidingQuestions:
            (j['guiding_questions'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        contributions:
            (j['contributions'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        summary: j['summary'] is Map
            ? TopicSummaryItem.fromJson(Map<String, dynamic>.from(j['summary']))
            : null,
      );
}

class ChallengeItem {
  final String id;
  final String title;
  final String description;
  final String category; // 10 categories
  final String format; // 7 formats
  final String difficulty;
  final int timeLimitSeconds;
  final String instructions;
  final List<String> evaluationCriteria;
  final List<String>? options;
  final String? correctAnswer;
  final String explanation;
  final DateTime scheduledPublishAt;
  final bool isOfficial;
  final String? authorId;
  final String? authorName;
  final String? userSubmission;
  final String? userAudioUrl;
  final double? userScore;
  final Map<String, int> userRubricBreakdown;
  final String? userFeedbackNote;

  const ChallengeItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.format,
    required this.difficulty,
    required this.timeLimitSeconds,
    required this.instructions,
    required this.evaluationCriteria,
    this.options,
    this.correctAnswer,
    required this.explanation,
    required this.scheduledPublishAt,
    this.isOfficial = false,
    this.authorId,
    this.authorName,
    this.userSubmission,
    this.userAudioUrl,
    this.userScore,
    this.userRubricBreakdown = const {},
    this.userFeedbackNote,
  });

  ChallengeItem copyWith({
    String? userSubmission,
    String? userAudioUrl,
    double? userScore,
    Map<String, int>? userRubricBreakdown,
    String? userFeedbackNote,
  }) =>
      ChallengeItem(
        id: id,
        title: title,
        description: description,
        category: category,
        format: format,
        difficulty: difficulty,
        timeLimitSeconds: timeLimitSeconds,
        instructions: instructions,
        evaluationCriteria: evaluationCriteria,
        options: options,
        correctAnswer: correctAnswer,
        explanation: explanation,
        scheduledPublishAt: scheduledPublishAt,
        isOfficial: isOfficial,
        authorId: authorId,
        authorName: authorName,
        userSubmission: userSubmission ?? this.userSubmission,
        userAudioUrl: userAudioUrl ?? this.userAudioUrl,
        userScore: userScore ?? this.userScore,
        userRubricBreakdown: userRubricBreakdown ?? this.userRubricBreakdown,
        userFeedbackNote: userFeedbackNote ?? this.userFeedbackNote,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'category': category,
        'format': format,
        'difficulty': difficulty,
        'time_limit_seconds': timeLimitSeconds,
        'instructions': instructions,
        'evaluation_criteria': evaluationCriteria,
        'options': options,
        'correct_answer': correctAnswer,
        'explanation': explanation,
        'scheduled_publish_at': scheduledPublishAt.toIso8601String(),
        'is_official': isOfficial,
        if (authorId != null) 'author_id': authorId,
        if (authorName != null) 'author_name': authorName,
        'user_submission': userSubmission,
        'user_audio_url': userAudioUrl,
        'user_score': userScore,
        if (userRubricBreakdown.isNotEmpty)
          'user_rubric_breakdown': userRubricBreakdown,
        if (userFeedbackNote != null) 'user_feedback_note': userFeedbackNote,
      };

  factory ChallengeItem.fromJson(Map<String, dynamic> j) => ChallengeItem(
        id: j['id'].toString(),
        title: j['title']?.toString() ?? '',
        description: j['description']?.toString() ?? '',
        category: j['category']?.toString() ?? 'logic',
        format: j['format']?.toString() ?? 'open_ended',
        difficulty: j['difficulty']?.toString() ?? 'intermediate',
        timeLimitSeconds: (j['time_limit_seconds'] as num?)?.toInt() ?? 180,
        instructions: j['instructions']?.toString() ?? '',
        evaluationCriteria:
            (j['evaluation_criteria'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        options: (j['options'] as List?)?.map((e) => e.toString()).toList(),
        correctAnswer: j['correct_answer']?.toString(),
        explanation: j['explanation']?.toString() ?? '',
        scheduledPublishAt:
            DateTime.tryParse(j['scheduled_publish_at']?.toString() ?? '') ??
                DateTime.now(),
        isOfficial: j['is_official'] == true ||
            j['id'].toString().startsWith('ch-'),
        authorId: j['author_id']?.toString(),
        authorName: j['author_name']?.toString(),
        userSubmission: j['user_submission']?.toString(),
        userAudioUrl: j['user_audio_url']?.toString(),
        userScore: (j['user_score'] as num?)?.toDouble(),
        userRubricBreakdown: (j['user_rubric_breakdown'] is Map)
            ? (j['user_rubric_breakdown'] as Map).map(
                (k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0),
              )
            : const {},
        userFeedbackNote: j['user_feedback_note']?.toString(),
      );
}

class DebateRubricBreakdown {
  final double relevance; // /20
  final double logicalReasoning; // /25
  final double depthOfAnalysis; // /20
  final double argumentsAndExamples; // /15
  final double criticalNuance; // /10
  final double clarity; // /10
  final List<String> contradictions;
  final List<String> unsupportedClaims;
  final List<String> fallacies;
  final List<String> nuances;
  final List<String> examples;
  final String explanation;
  final List<String> recommendations;
  final List<String> verifiedReferences;
  final bool isLocalPreview;

  const DebateRubricBreakdown({
    required this.relevance,
    required this.logicalReasoning,
    required this.depthOfAnalysis,
    required this.argumentsAndExamples,
    required this.criticalNuance,
    required this.clarity,
    this.contradictions = const [],
    this.unsupportedClaims = const [],
    this.fallacies = const [],
    this.nuances = const [],
    this.examples = const [],
    required this.explanation,
    this.recommendations = const [],
    this.verifiedReferences = const [],
    this.isLocalPreview = false,
  });

  double get totalScore =>
      relevance +
      logicalReasoning +
      depthOfAnalysis +
      argumentsAndExamples +
      criticalNuance +
      clarity;

  Map<String, dynamic> toJson() => {
        'relevance': relevance,
        'logical_reasoning': logicalReasoning,
        'depth_of_analysis': depthOfAnalysis,
        'arguments_and_examples': argumentsAndExamples,
        'critical_nuance': criticalNuance,
        'clarity': clarity,
        'contradictions': contradictions,
        'unsupported_claims': unsupportedClaims,
        'fallacies': fallacies,
        'nuances': nuances,
        'examples': examples,
        'explanation': explanation,
        'recommendations': recommendations,
        'verified_references': verifiedReferences,
        'is_local_preview': isLocalPreview,
      };

  factory DebateRubricBreakdown.fromJson(Map<String, dynamic> j) =>
      DebateRubricBreakdown(
        relevance: (j['relevance'] as num?)?.toDouble() ?? 0,
        logicalReasoning: (j['logical_reasoning'] as num?)?.toDouble() ?? 0,
        depthOfAnalysis: (j['depth_of_analysis'] as num?)?.toDouble() ?? 0,
        argumentsAndExamples:
            (j['arguments_and_examples'] as num?)?.toDouble() ?? 0,
        criticalNuance: (j['critical_nuance'] as num?)?.toDouble() ?? 0,
        clarity: (j['clarity'] as num?)?.toDouble() ?? 0,
        contradictions:
            (j['contradictions'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        unsupportedClaims: (j['unsupported_claims'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        fallacies:
            (j['fallacies'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        nuances:
            (j['nuances'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        examples:
            (j['examples'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        explanation: j['explanation']?.toString() ?? '',
        recommendations: (j['recommendations'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        verifiedReferences: (j['verified_references'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        isLocalPreview: j['is_local_preview'] == true,
      );
}

class DebateMatchModel {
  final String id;
  final String topicTitle;
  final String topicQuestion;
  final String category;
  final bool isIslamicSubject;
  final String matchType; // friend_challenge | matchmaking | tournament | public
  final String status; // preparing | recording | completed | under_review
  final String? creatorName;
  final String opponentName;
  final String userPosition; // for | against | nuanced
  final String opponentPosition;
  final String? userTranscript;
  final String? opponentTranscript;
  final String? userAudioPath;
  final DebateRubricBreakdown? userEvaluation;
  final DebateRubricBreakdown? opponentEvaluation;
  final String? winnerLabel;
  final bool humanReviewRequested;

  const DebateMatchModel({
    required this.id,
    required this.topicTitle,
    required this.topicQuestion,
    required this.category,
    this.isIslamicSubject = false,
    required this.matchType,
    required this.status,
    this.creatorName,
    required this.opponentName,
    this.userPosition = 'for',
    this.opponentPosition = 'against',
    this.userTranscript,
    this.opponentTranscript,
    this.userAudioPath,
    this.userEvaluation,
    this.opponentEvaluation,
    this.winnerLabel,
    this.humanReviewRequested = false,
  });

  DebateMatchModel copyWith({
    String? status,
    String? creatorName,
    String? opponentName,
    String? userPosition,
    String? opponentPosition,
    String? userTranscript,
    String? opponentTranscript,
    String? userAudioPath,
    DebateRubricBreakdown? userEvaluation,
    DebateRubricBreakdown? opponentEvaluation,
    String? winnerLabel,
    bool? humanReviewRequested,
  }) =>
      DebateMatchModel(
        id: id,
        topicTitle: topicTitle,
        topicQuestion: topicQuestion,
        category: category,
        isIslamicSubject: isIslamicSubject,
        matchType: matchType,
        status: status ?? this.status,
        creatorName: creatorName ?? this.creatorName,
        opponentName: opponentName ?? this.opponentName,
        userPosition: userPosition ?? this.userPosition,
        opponentPosition: opponentPosition ?? this.opponentPosition,
        userTranscript: userTranscript ?? this.userTranscript,
        opponentTranscript: opponentTranscript ?? this.opponentTranscript,
        userAudioPath: userAudioPath ?? this.userAudioPath,
        userEvaluation: userEvaluation ?? this.userEvaluation,
        opponentEvaluation: opponentEvaluation ?? this.opponentEvaluation,
        winnerLabel: winnerLabel ?? this.winnerLabel,
        humanReviewRequested: humanReviewRequested ?? this.humanReviewRequested,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'topic_title': topicTitle,
        'topic_question': topicQuestion,
        'category': category,
        'is_islamic_subject': isIslamicSubject,
        'match_type': matchType,
        'status': status,
        'creator_name': creatorName,
        'opponent_name': opponentName,
        'user_position': userPosition,
        'opponent_position': opponentPosition,
        'user_transcript': userTranscript,
        'opponent_transcript': opponentTranscript,
        'user_audio_path': userAudioPath,
        'user_evaluation': userEvaluation?.toJson(),
        'opponent_evaluation': opponentEvaluation?.toJson(),
        'winner_label': winnerLabel,
        'human_review_requested': humanReviewRequested,
      };

  factory DebateMatchModel.fromJson(Map<String, dynamic> j) => DebateMatchModel(
        id: j['id'].toString(),
        topicTitle: j['topic_title']?.toString() ?? '',
        topicQuestion: j['topic_question']?.toString() ?? '',
        category: j['category']?.toString() ?? 'society',
        isIslamicSubject: j['is_islamic_subject'] == true,
        matchType: j['match_type']?.toString() ?? 'public',
        status: j['status']?.toString() ?? 'preparing',
        creatorName: j['creator_name']?.toString(),
        opponentName: j['opponent_name']?.toString() ?? 'Ouvert à un membre',
        userPosition: j['user_position']?.toString() ?? 'for',
        opponentPosition: j['opponent_position']?.toString() ?? 'against',
        userTranscript: j['user_transcript']?.toString(),
        opponentTranscript: j['opponent_transcript']?.toString(),
        userAudioPath: j['user_audio_path']?.toString(),
        userEvaluation: j['user_evaluation'] is Map
            ? DebateRubricBreakdown.fromJson(
                Map<String, dynamic>.from(j['user_evaluation']))
            : null,
        opponentEvaluation: j['opponent_evaluation'] is Map
            ? DebateRubricBreakdown.fromJson(
                Map<String, dynamic>.from(j['opponent_evaluation']))
            : null,
        winnerLabel: j['winner_label']?.toString(),
        humanReviewRequested: j['human_review_requested'] == true,
      );
}

class QuizQuestionModel {
  final String id;
  final String category;
  final String questionType;
  final String difficulty;
  final String questionText;
  final List<String> options;
  final int correctOptionIndex;
  final String explanation;
  final List<String> verifiedReferences;
  final int timeLimitSeconds;
  final int points;

  const QuizQuestionModel({
    required this.id,
    required this.category,
    required this.questionType,
    required this.difficulty,
    required this.questionText,
    required this.options,
    required this.correctOptionIndex,
    required this.explanation,
    this.verifiedReferences = const [],
    this.timeLimitSeconds = 25,
    this.points = 100,
  });
}

class ZikrSessionModel {
  final String id;
  final String title;
  final String description;
  final String programDetails;
  final DateTime scheduledAt;
  final bool isRecurring;
  final String recurrenceLabel;
  final String arabicText;
  final String transliteration;
  final String frenchTranslation;
  final List<String> verifiedReferences;
  final int recommendedRepetitions;
  final String livekitRoomName;

  const ZikrSessionModel({
    required this.id,
    required this.title,
    required this.description,
    required this.programDetails,
    required this.scheduledAt,
    required this.isRecurring,
    required this.recurrenceLabel,
    required this.arabicText,
    required this.transliteration,
    required this.frenchTranslation,
    required this.verifiedReferences,
    required this.recommendedRepetitions,
    required this.livekitRoomName,
  });
}

/// Session collective de Zikr inspirée de SDM Communauté :
/// formule au choix ou libre, objectif global, contributions cumulées et partage.
class CommunityZikrSessionModel {
  final String id;
  final String title;
  final String formulaArabic;
  final String formulaLabel;
  final String transliteration;
  final int targetCount;
  final int currentCount;
  final String creatorName;
  final bool isPrivate;
  final String shareCode;
  final DateTime createdAt;
  final Map<String, int> contributions;

  const CommunityZikrSessionModel({
    required this.id,
    required this.title,
    required this.formulaArabic,
    required this.formulaLabel,
    this.transliteration = '',
    required this.targetCount,
    this.currentCount = 0,
    required this.creatorName,
    this.isPrivate = false,
    required this.shareCode,
    required this.createdAt,
    this.contributions = const {},
  });

  bool get isCompleted => targetCount > 0 && currentCount >= targetCount;

  double get progressRatio =>
      targetCount <= 0 ? 0.0 : (currentCount / targetCount).clamp(0.0, 1.0);

  CommunityZikrSessionModel copyWith({
    int? currentCount,
    Map<String, int>? contributions,
  }) {
    return CommunityZikrSessionModel(
      id: id,
      title: title,
      formulaArabic: formulaArabic,
      formulaLabel: formulaLabel,
      transliteration: transliteration,
      targetCount: targetCount,
      currentCount: currentCount ?? this.currentCount,
      creatorName: creatorName,
      isPrivate: isPrivate,
      shareCode: shareCode,
      createdAt: createdAt,
      contributions: contributions ?? this.contributions,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'formula_arabic': formulaArabic,
        'formula_label': formulaLabel,
        'transliteration': transliteration,
        'target_count': targetCount,
        'current_count': currentCount,
        'creator_name': creatorName,
        'is_private': isPrivate,
        'share_code': shareCode,
        'created_at': createdAt.toIso8601String(),
        'contributions': contributions,
      };

  factory CommunityZikrSessionModel.fromJson(Map<String, dynamic> j) {
    final rawMap = j['contributions'];
    final parsedContrib = <String, int>{};
    if (rawMap is Map) {
      rawMap.forEach((k, v) {
        parsedContrib[k.toString()] = (v as num?)?.toInt() ?? 0;
      });
    }
    return CommunityZikrSessionModel(
      id: j['id']?.toString() ?? '',
      title: j['title']?.toString() ?? '',
      formulaArabic: j['formula_arabic']?.toString() ?? '',
      formulaLabel: j['formula_label']?.toString() ?? '',
      transliteration: j['transliteration']?.toString() ?? '',
      targetCount: (j['target_count'] as num?)?.toInt() ?? 1000,
      currentCount: (j['current_count'] as num?)?.toInt() ?? 0,
      creatorName: j['creator_name']?.toString() ?? 'Membre',
      isPrivate: j['is_private'] == true,
      shareCode: j['share_code']?.toString() ?? 'YITTE',
      createdAt:
          DateTime.tryParse(j['created_at']?.toString() ?? '') ?? DateTime.now(),
      contributions: parsedContrib,
    );
  }
}

class VocabularyWordModel {
  final String id;
  final String word;
  final String phoneticUk;
  final String phoneticUs;
  final String partOfSpeech;
  final String cefrLevel;
  final String definitionEn;
  final String definitionFr;
  final String exampleEn;
  final String exampleFr;
  final bool mastered;

  const VocabularyWordModel({
    required this.id,
    required this.word,
    required this.phoneticUk,
    required this.phoneticUs,
    required this.partOfSpeech,
    required this.cefrLevel,
    required this.definitionEn,
    required this.definitionFr,
    required this.exampleEn,
    required this.exampleFr,
    this.mastered = false,
  });

  VocabularyWordModel copyWith({bool? mastered}) => VocabularyWordModel(
        id: id,
        word: word,
        phoneticUk: phoneticUk,
        phoneticUs: phoneticUs,
        partOfSpeech: partOfSpeech,
        cefrLevel: cefrLevel,
        definitionEn: definitionEn,
        definitionFr: definitionFr,
        exampleEn: exampleEn,
        exampleFr: exampleFr,
        mastered: mastered ?? this.mastered,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'word': word,
        'phonetic_uk': phoneticUk,
        'phonetic_us': phoneticUs,
        'part_of_speech': partOfSpeech,
        'cefr_level': cefrLevel,
        'definition_en': definitionEn,
        'definition_fr': definitionFr,
        'example_en': exampleEn,
        'example_fr': exampleFr,
        'mastered': mastered,
      };

  factory VocabularyWordModel.fromJson(Map<String, dynamic> j) =>
      VocabularyWordModel(
        id: j['id'].toString(),
        word: j['word']?.toString() ?? '',
        phoneticUk: j['phonetic_uk']?.toString() ?? '',
        phoneticUs: j['phonetic_us']?.toString() ?? '',
        partOfSpeech: j['part_of_speech']?.toString() ?? 'noun',
        cefrLevel: j['cefr_level']?.toString() ?? 'B1',
        definitionEn: j['definition_en']?.toString() ?? '',
        definitionFr: j['definition_fr']?.toString() ?? '',
        exampleEn: j['example_en']?.toString() ?? '',
        exampleFr: j['example_fr']?.toString() ?? '',
        mastered: j['mastered'] == true,
      );
}

class EnglishLessonModel {
  final String id;
  final String moduleType;
  final String title;
  final String description;
  final String cefrLevel;
  final String variant;
  final String contentMarkdown;
  final bool isWeeklyChallenge;

  const EnglishLessonModel({
    required this.id,
    required this.moduleType,
    required this.title,
    required this.description,
    required this.cefrLevel,
    required this.variant,
    required this.contentMarkdown,
    this.isWeeklyChallenge = false,
  });
}

class EnglishSpeakingEval {
  final double grammar;
  final double vocabulary;
  final double fluency;
  final double intelligibility;
  final double coherence;
  final String transcript;
  final List<String> correctedSentences;
  final List<String> naturalExpressions;
  final List<String> suggestedVocabulary;
  final List<String> exercises;
  final bool isLocalPreview;

  const EnglishSpeakingEval({
    required this.grammar,
    required this.vocabulary,
    required this.fluency,
    required this.intelligibility,
    required this.coherence,
    required this.transcript,
    this.correctedSentences = const [],
    this.naturalExpressions = const [],
    this.suggestedVocabulary = const [],
    this.exercises = const [],
    this.isLocalPreview = false,
  });

  double get totalScore =>
      grammar + vocabulary + fluency + intelligibility + coherence;
}

class CareerOpportunityModel {
  final String id;
  final String title;
  final String organization;
  final String type;
  final String domain;
  final String location;
  final String description;

  const CareerOpportunityModel({
    required this.id,
    required this.title,
    required this.organization,
    required this.type,
    required this.domain,
    required this.location,
    required this.description,
  });
}

class PersonalGoalModel {
  final String id;
  final String title;
  final String horizon;
  final int progressPercent;

  const PersonalGoalModel({
    required this.id,
    required this.title,
    required this.horizon,
    required this.progressPercent,
  });

  PersonalGoalModel copyWith({int? progressPercent}) => PersonalGoalModel(
        id: id,
        title: title,
        horizon: horizon,
        progressPercent: progressPercent ?? this.progressPercent,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'horizon': horizon,
        'progress_percent': progressPercent,
      };

  factory PersonalGoalModel.fromJson(Map<String, dynamic> j) => PersonalGoalModel(
        id: j['id'].toString(),
        title: j['title']?.toString() ?? '',
        horizon: j['horizon']?.toString() ?? 'weekly',
        progressPercent: (j['progress_percent'] as num?)?.toInt() ?? 0,
      );
}

class HabitModel {
  final String id;
  final String name;
  final int streakDays;
  final bool completedToday;

  const HabitModel({
    required this.id,
    required this.name,
    required this.streakDays,
    this.completedToday = false,
  });

  HabitModel copyWith({int? streakDays, bool? completedToday}) => HabitModel(
        id: id,
        name: name,
        streakDays: streakDays ?? this.streakDays,
        completedToday: completedToday ?? this.completedToday,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'streak_days': streakDays,
        'completed_today': completedToday,
      };

  factory HabitModel.fromJson(Map<String, dynamic> j) => HabitModel(
        id: j['id'].toString(),
        name: j['name']?.toString() ?? '',
        streakDays: (j['streak_days'] as num?)?.toInt() ?? 0,
        completedToday: j['completed_today'] == true,
      );
}

class ReadingBookModel {
  final String id;
  final String title;
  final String author;
  final int currentPage;
  final int totalPages;

  const ReadingBookModel({
    required this.id,
    required this.title,
    required this.author,
    required this.currentPage,
    required this.totalPages,
  });

  ReadingBookModel copyWith({int? currentPage}) => ReadingBookModel(
        id: id,
        title: title,
        author: author,
        currentPage: currentPage ?? this.currentPage,
        totalPages: totalPages,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'author': author,
        'current_page': currentPage,
        'total_pages': totalPages,
      };

  factory ReadingBookModel.fromJson(Map<String, dynamic> j) => ReadingBookModel(
        id: j['id'].toString(),
        title: j['title']?.toString() ?? '',
        author: j['author']?.toString() ?? '',
        currentPage: (j['current_page'] as num?)?.toInt() ?? 0,
        totalPages: (j['total_pages'] as num?)?.toInt() ?? 100,
      );
}

class PrivateNoteModel {
  final String id;
  final String noteType;
  final String title;
  final String content;
  final DateTime createdAt;

  const PrivateNoteModel({
    required this.id,
    required this.noteType,
    required this.title,
    required this.content,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'note_type': noteType,
        'title': title,
        'content': content,
        'created_at': createdAt.toIso8601String(),
      };

  factory PrivateNoteModel.fromJson(Map<String, dynamic> j) => PrivateNoteModel(
        id: j['id'].toString(),
        noteType: j['note_type']?.toString() ?? 'journal',
        title: j['title']?.toString() ?? '',
        content: j['content']?.toString() ?? '',
        createdAt:
            DateTime.tryParse(j['created_at']?.toString() ?? '') ?? DateTime.now(),
      );
}

class VoiceRoomModel {
  final String id;
  final String title;
  final String roomType;
  final String hostName;
  final String livekitRoomName;
  final String? cefrFilter;
  final int participantsCount;
  final bool isLocked;

  const VoiceRoomModel({
    required this.id,
    required this.title,
    required this.roomType,
    required this.hostName,
    required this.livekitRoomName,
    this.cefrFilter,
    this.participantsCount = 1,
    this.isLocked = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'room_type': roomType,
        'host_name': hostName,
        'livekit_room_name': livekitRoomName,
        'cefr_filter': cefrFilter,
        'participants_count': participantsCount,
        'is_locked': isLocked,
      };

  factory VoiceRoomModel.fromJson(Map<String, dynamic> j) => VoiceRoomModel(
        id: j['id'].toString(),
        title: j['title']?.toString() ?? '',
        roomType: j['room_type']?.toString() ?? 'community',
        hostName: j['host_name']?.toString() ?? 'Hôte',
        livekitRoomName: j['livekit_room_name']?.toString() ?? 'yitte-room',
        cefrFilter: j['cefr_filter']?.toString(),
        participantsCount: (j['participants_count'] as num?)?.toInt() ?? 1,
        isLocked: j['is_locked'] == true,
      );
}

class ChatMessageModel {
  final String id;
  final String channelName;
  final String senderName;
  final String body;
  final DateTime sentAt;
  final String? audioUrl;
  final int? audioDurationSeconds;

  const ChatMessageModel({
    required this.id,
    required this.channelName,
    required this.senderName,
    required this.body,
    required this.sentAt,
    this.audioUrl,
    this.audioDurationSeconds,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'channel_name': channelName,
        'sender_name': senderName,
        'body': body,
        'sent_at': sentAt.toIso8601String(),
        if (audioUrl != null) 'audio_url': audioUrl,
        if (audioDurationSeconds != null)
          'audio_duration_seconds': audioDurationSeconds,
      };

  factory ChatMessageModel.fromJson(Map<String, dynamic> j) => ChatMessageModel(
        id: j['id'].toString(),
        channelName: j['channel_name']?.toString() ?? 'Cercle Général',
        senderName: j['sender_name']?.toString() ?? 'Membre',
        body: j['body']?.toString() ?? '',
        sentAt:
            DateTime.tryParse(j['sent_at']?.toString() ?? '') ?? DateTime.now(),
        audioUrl: j['audio_url']?.toString(),
        audioDurationSeconds: (j['audio_duration_seconds'] as num?)?.toInt(),
      );
}

class ModerationReportModel {
  final String id;
  final String targetType;
  final String reason;
  final String status;
  final DateTime createdAt;

  const ModerationReportModel({
    required this.id,
    required this.targetType,
    required this.reason,
    required this.status,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'target_type': targetType,
        'reason': reason,
        'status': status,
        'created_at': createdAt.toIso8601String(),
      };

  factory ModerationReportModel.fromJson(Map<String, dynamic> j) =>
      ModerationReportModel(
        id: j['id'].toString(),
        targetType: j['target_type']?.toString() ?? 'message',
        reason: j['reason']?.toString() ?? '',
        status: j['status']?.toString() ?? 'open',
        createdAt:
            DateTime.tryParse(j['created_at']?.toString() ?? '') ?? DateTime.now(),
      );
}

class AnnouncementModel {
  final String id;
  final String title;
  final String body;
  final String authorName;
  final DateTime createdAt;
  final DateTime? eventDate;
  final String? location;

  const AnnouncementModel({
    required this.id,
    required this.title,
    required this.body,
    required this.authorName,
    required this.createdAt,
    this.eventDate,
    this.location,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'author_name': authorName,
        'created_at': createdAt.toIso8601String(),
        if (eventDate != null) 'event_date': eventDate!.toIso8601String(),
        if (location != null && location!.isNotEmpty) 'location': location,
      };

  factory AnnouncementModel.fromJson(Map<String, dynamic> j) => AnnouncementModel(
        id: j['id'].toString(),
        title: j['title']?.toString() ?? '',
        body: j['body']?.toString() ?? '',
        authorName: j['author_name']?.toString() ?? 'Administration',
        createdAt:
            DateTime.tryParse(j['created_at']?.toString() ?? '') ?? DateTime.now(),
        eventDate: j['event_date'] != null
            ? DateTime.tryParse(j['event_date'].toString())
            : null,
        location: j['location']?.toString(),
      );
}

class MemberDirectoryItem {
  final String id;
  final String fullName;
  final String username;
  final String roleCode;
  final bool isGroupMember;
  final DateTime joinedAt;

  const MemberDirectoryItem({
    required this.id,
    required this.fullName,
    required this.username,
    required this.roleCode,
    this.isGroupMember = true,
    required this.joinedAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'username': username,
        'role_code': roleCode,
        'is_group_member': isGroupMember,
        'joined_at': joinedAt.toIso8601String(),
      };

  factory MemberDirectoryItem.fromJson(Map<String, dynamic> j) =>
      MemberDirectoryItem(
        id: j['id'].toString(),
        fullName: j['full_name']?.toString() ?? '',
        username: j['username']?.toString() ?? '',
        roleCode: j['role_code']?.toString() ?? 'member',
        isGroupMember: j['is_group_member'] != false,
        joinedAt:
            DateTime.tryParse(j['joined_at']?.toString() ?? '') ?? DateTime.now(),
      );
}

class LeaderboardEntryModel {
  final String memberId;
  final String memberName;
  final int totalPoints;
  final int matchesPlayed;

  const LeaderboardEntryModel({
    required this.memberId,
    required this.memberName,
    required this.totalPoints,
    required this.matchesPlayed,
  });

  Map<String, dynamic> toJson() => {
        'member_id': memberId,
        'member_name': memberName,
        'total_points': totalPoints,
        'matches_played': matchesPlayed,
      };

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> j) =>
      LeaderboardEntryModel(
        memberId: j['member_id']?.toString() ?? '',
        memberName: j['member_name']?.toString() ?? '',
        totalPoints: (j['total_points'] as num?)?.toInt() ?? 0,
        matchesPlayed: (j['matches_played'] as num?)?.toInt() ?? 0,
      );
}

/// Official Document Library domains & subcategories (Partie II Section 4).
class DocumentCategoryCatalog {
  const DocumentCategoryCatalog._();

  static const Map<String, List<String>> domains = {
    'Spiritualité et religion': [
      'Coran',
      'Sciences religieuses',
      'Éthique islamique',
      'Spiritualité',
      'Enseignements de Cheikh Ahmadou Bamba',
      'Histoire des figures religieuses',
      'Textes et références',
    ],
    'Philosophie et pensée': [
      'Philosophie',
      'Logique',
      'Épistémologie',
      'Éthique',
      'Métaphysique',
      'Pensée critique',
      'Grands courants philosophiques',
    ],
    'Société et civilisation': [
      'Société sénégalaise',
      'Société africaine',
      'Éducation',
      'Famille',
      'Jeunesse',
      'Culture',
      'Histoire',
      'Citoyenneté',
      'Économie',
      'Géopolitique',
      'Enjeux contemporains',
    ],
    'Sciences et technologies': [
      'Mathématiques',
      'Physique',
      'Informatique',
      'Intelligence artificielle',
      'Cybersécurité',
      'Télécommunications',
      'Innovation scientifique',
    ],
    'Développement personnel et professionnel': [
      'Leadership',
      'Communication',
      'Organisation',
      'Entrepreneuriat',
      'Carrière',
      'Gestion de projets',
      'Apprentissage',
      'Formation',
    ],
  };
}

class DocumentSummaryModel {
  final String sourceDocumentId;
  final String generalSummary;
  final List<String> mainIdeas;
  final List<String> importantConcepts;
  final List<String> definitions;
  final List<String> developedArguments;
  final List<String> authorConclusions;
  final List<String> citedReferences;
  final List<String> comprehensionQuestions;
  final List<String> unreadableNotices;
  final bool isAiAssisted;
  final String status; // draft | validated
  final String? validatedBy;
  final DateTime generatedAt;

  const DocumentSummaryModel({
    required this.sourceDocumentId,
    required this.generalSummary,
    this.mainIdeas = const [],
    this.importantConcepts = const [],
    this.definitions = const [],
    this.developedArguments = const [],
    this.authorConclusions = const [],
    this.citedReferences = const [],
    this.comprehensionQuestions = const [],
    this.unreadableNotices = const [],
    this.isAiAssisted = true,
    this.status = 'draft',
    this.validatedBy,
    required this.generatedAt,
  });

  DocumentSummaryModel copyWith({
    String? generalSummary,
    List<String>? mainIdeas,
    String? status,
    String? validatedBy,
  }) =>
      DocumentSummaryModel(
        sourceDocumentId: sourceDocumentId,
        generalSummary: generalSummary ?? this.generalSummary,
        mainIdeas: mainIdeas ?? this.mainIdeas,
        importantConcepts: importantConcepts,
        definitions: definitions,
        developedArguments: developedArguments,
        authorConclusions: authorConclusions,
        citedReferences: citedReferences,
        comprehensionQuestions: comprehensionQuestions,
        unreadableNotices: unreadableNotices,
        isAiAssisted: isAiAssisted,
        status: status ?? this.status,
        validatedBy: validatedBy ?? this.validatedBy,
        generatedAt: generatedAt,
      );

  Map<String, dynamic> toJson() => {
        'source_document_id': sourceDocumentId,
        'general_summary': generalSummary,
        'main_ideas': mainIdeas,
        'important_concepts': importantConcepts,
        'definitions': definitions,
        'developed_arguments': developedArguments,
        'author_conclusions': authorConclusions,
        'cited_references': citedReferences,
        'comprehension_questions': comprehensionQuestions,
        'unreadable_notices': unreadableNotices,
        'is_ai_assisted': isAiAssisted,
        'status': status,
        'validated_by': validatedBy,
        'generated_at': generatedAt.toIso8601String(),
      };

  factory DocumentSummaryModel.fromJson(Map<String, dynamic> j) =>
      DocumentSummaryModel(
        sourceDocumentId: j['source_document_id']?.toString() ?? '',
        generalSummary: j['general_summary']?.toString() ?? '',
        mainIdeas:
            (j['main_ideas'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        importantConcepts: (j['important_concepts'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        definitions:
            (j['definitions'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        developedArguments: (j['developed_arguments'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        authorConclusions: (j['author_conclusions'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        citedReferences: (j['cited_references'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        comprehensionQuestions: (j['comprehension_questions'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        unreadableNotices: (j['unreadable_notices'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        isAiAssisted: j['is_ai_assisted'] != false,
        status: j['status']?.toString() ?? 'draft',
        validatedBy: j['validated_by']?.toString(),
        generatedAt: DateTime.tryParse(j['generated_at']?.toString() ?? '') ??
            DateTime.now(),
      );
}

class LibraryDocumentModel {
  final String id;
  final String title;
  final String description;
  final String domain;
  final String subcategory;
  final String authorOrContributor;
  final String sourceReference;
  final DateTime addedAt;
  final String? publishedDateLabel;
  final List<String> keywords;
  final String language;
  final String fileName;
  final String format; // pdf | doc | docx | ppt | pptx | txt | image | text
  final int fileSizeBytes;
  final String? storageUrl;
  final String? extractedText;
  final String? unreadableWarning;
  final bool isPrivate;
  final String validationStatus; // pending | validated | rejected
  final int viewCount;
  final DateTime? lastViewedAt;
  final DocumentSummaryModel? summary;

  const LibraryDocumentModel({
    required this.id,
    required this.title,
    required this.description,
    required this.domain,
    required this.subcategory,
    required this.authorOrContributor,
    required this.sourceReference,
    required this.addedAt,
    this.publishedDateLabel,
    this.keywords = const [],
    this.language = 'fr',
    required this.fileName,
    required this.format,
    this.fileSizeBytes = 0,
    this.storageUrl,
    this.extractedText,
    this.unreadableWarning,
    this.isPrivate = false,
    this.validationStatus = 'pending',
    this.viewCount = 0,
    this.lastViewedAt,
    this.summary,
  });

  LibraryDocumentModel copyWith({
    String? title,
    String? description,
    String? domain,
    String? subcategory,
    bool? isPrivate,
    String? validationStatus,
    int? viewCount,
    DateTime? lastViewedAt,
    DocumentSummaryModel? summary,
  }) =>
      LibraryDocumentModel(
        id: id,
        title: title ?? this.title,
        description: description ?? this.description,
        domain: domain ?? this.domain,
        subcategory: subcategory ?? this.subcategory,
        authorOrContributor: authorOrContributor,
        sourceReference: sourceReference,
        addedAt: addedAt,
        publishedDateLabel: publishedDateLabel,
        keywords: keywords,
        language: language,
        fileName: fileName,
        format: format,
        fileSizeBytes: fileSizeBytes,
        storageUrl: storageUrl,
        extractedText: extractedText,
        unreadableWarning: unreadableWarning,
        isPrivate: isPrivate ?? this.isPrivate,
        validationStatus: validationStatus ?? this.validationStatus,
        viewCount: viewCount ?? this.viewCount,
        lastViewedAt: lastViewedAt ?? this.lastViewedAt,
        summary: summary ?? this.summary,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'domain': domain,
        'subcategory': subcategory,
        'author_or_contributor': authorOrContributor,
        'source_reference': sourceReference,
        'added_at': addedAt.toIso8601String(),
        'published_date_label': publishedDateLabel,
        'keywords': keywords,
        'language': language,
        'file_name': fileName,
        'format': format,
        'file_size_bytes': fileSizeBytes,
        'storage_url': storageUrl,
        'extracted_text': extractedText,
        'unreadable_warning': unreadableWarning,
        'is_private': isPrivate,
        'validation_status': validationStatus,
        'view_count': viewCount,
        'last_viewed_at': lastViewedAt?.toIso8601String(),
        'summary': summary?.toJson(),
      };

  factory LibraryDocumentModel.fromJson(Map<String, dynamic> j) =>
      LibraryDocumentModel(
        id: j['id'].toString(),
        title: j['title']?.toString() ?? '',
        description: j['description']?.toString() ?? '',
        domain: j['domain']?.toString() ?? 'Philosophie et pensée',
        subcategory: j['subcategory']?.toString() ?? 'Philosophie',
        authorOrContributor: j['author_or_contributor']?.toString() ?? '',
        sourceReference: j['source_reference']?.toString() ?? '',
        addedAt:
            DateTime.tryParse(j['added_at']?.toString() ?? '') ?? DateTime.now(),
        publishedDateLabel: j['published_date_label']?.toString(),
        keywords:
            (j['keywords'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        language: j['language']?.toString() ?? 'fr',
        fileName: j['file_name']?.toString() ?? '',
        format: j['format']?.toString() ?? 'txt',
        fileSizeBytes: (j['file_size_bytes'] as num?)?.toInt() ?? 0,
        storageUrl: j['storage_url']?.toString(),
        extractedText: j['extracted_text']?.toString(),
        unreadableWarning: j['unreadable_warning']?.toString(),
        isPrivate: j['is_private'] == true,
        validationStatus: j['validation_status']?.toString() ?? 'pending',
        viewCount: (j['view_count'] as num?)?.toInt() ?? 0,
        lastViewedAt: DateTime.tryParse(j['last_viewed_at']?.toString() ?? ''),
        summary: j['summary'] is Map
            ? DocumentSummaryModel.fromJson(
                Map<String, dynamic>.from(j['summary']))
            : null,
      );
}

class ExtraGroupeGuestModel {
  final String id;
  final String fullName;
  final String titleOrRole;
  final String biography;
  final List<String> expertiseDomains;

  const ExtraGroupeGuestModel({
    required this.id,
    required this.fullName,
    required this.titleOrRole,
    required this.biography,
    this.expertiseDomains = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'title_or_role': titleOrRole,
        'biography': biography,
        'expertise_domains': expertiseDomains,
      };

  factory ExtraGroupeGuestModel.fromJson(Map<String, dynamic> j) =>
      ExtraGroupeGuestModel(
        id: j['id'].toString(),
        fullName: j['full_name']?.toString() ?? '',
        titleOrRole: j['title_or_role']?.toString() ?? '',
        biography: j['biography']?.toString() ?? '',
        expertiseDomains: (j['expertise_domains'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
      );
}

class ExtraGroupeQuestionModel {
  final String id;
  final String authorName;
  final String questionText;
  final String? answerText;
  final bool isPrepared;
  final DateTime createdAt;

  const ExtraGroupeQuestionModel({
    required this.id,
    required this.authorName,
    required this.questionText,
    this.answerText,
    this.isPrepared = false,
    required this.createdAt,
  });

  ExtraGroupeQuestionModel copyWith({String? answerText}) =>
      ExtraGroupeQuestionModel(
        id: id,
        authorName: authorName,
        questionText: questionText,
        answerText: answerText ?? this.answerText,
        isPrepared: isPrepared,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'author_name': authorName,
        'question_text': questionText,
        'answer_text': answerText,
        'is_prepared': isPrepared,
        'created_at': createdAt.toIso8601String(),
      };

  factory ExtraGroupeQuestionModel.fromJson(Map<String, dynamic> j) =>
      ExtraGroupeQuestionModel(
        id: j['id'].toString(),
        authorName: j['author_name']?.toString() ?? '',
        questionText: j['question_text']?.toString() ?? '',
        answerText: j['answer_text']?.toString(),
        isPrepared: j['is_prepared'] == true,
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );
}

class ExtraGroupeMeetingModel {
  final String id;
  final ExtraGroupeGuestModel guest;
  final String theme;
  final String presentationText;
  final String contextNotes;
  final List<String> objectives;
  final List<String> programItems;
  final DateTime scheduledAt;
  final String practicalInfo;
  final String status; // upcoming | live | archived
  final bool recordingAuthorized;
  final String? meetingReport;
  final List<String> linkedDocumentIds;
  final List<ExtraGroupeQuestionModel> questions;
  final List<String> registeredParticipants;
  final bool rosterPublicToCircle;

  const ExtraGroupeMeetingModel({
    required this.id,
    required this.guest,
    required this.theme,
    required this.presentationText,
    this.contextNotes = '',
    this.objectives = const [],
    this.programItems = const [],
    required this.scheduledAt,
    this.practicalInfo = '',
    this.status = 'upcoming',
    this.recordingAuthorized = false,
    this.meetingReport,
    this.linkedDocumentIds = const [],
    this.questions = const [],
    this.registeredParticipants = const [],
    this.rosterPublicToCircle = false,
  });

  ExtraGroupeMeetingModel copyWith({
    String? status,
    bool? recordingAuthorized,
    String? meetingReport,
    List<String>? linkedDocumentIds,
    List<ExtraGroupeQuestionModel>? questions,
    List<String>? registeredParticipants,
    bool? rosterPublicToCircle,
  }) =>
      ExtraGroupeMeetingModel(
        id: id,
        guest: guest,
        theme: theme,
        presentationText: presentationText,
        contextNotes: contextNotes,
        objectives: objectives,
        programItems: programItems,
        scheduledAt: scheduledAt,
        practicalInfo: practicalInfo,
        status: status ?? this.status,
        recordingAuthorized: recordingAuthorized ?? this.recordingAuthorized,
        meetingReport: meetingReport ?? this.meetingReport,
        linkedDocumentIds: linkedDocumentIds ?? this.linkedDocumentIds,
        questions: questions ?? this.questions,
        registeredParticipants:
            registeredParticipants ?? this.registeredParticipants,
        rosterPublicToCircle:
            rosterPublicToCircle ?? this.rosterPublicToCircle,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'guest': guest.toJson(),
        'theme': theme,
        'presentation_text': presentationText,
        'context_notes': contextNotes,
        'objectives': objectives,
        'program_items': programItems,
        'scheduled_at': scheduledAt.toIso8601String(),
        'practical_info': practicalInfo,
        'status': status,
        'recording_authorized': recordingAuthorized,
        'meeting_report': meetingReport,
        'linked_document_ids': linkedDocumentIds,
        'questions': questions.map((q) => q.toJson()).toList(),
        'registered_participants': registeredParticipants,
        'roster_public_to_circle': rosterPublicToCircle,
      };

  factory ExtraGroupeMeetingModel.fromJson(Map<String, dynamic> j) =>
      ExtraGroupeMeetingModel(
        id: j['id'].toString(),
        guest: j['guest'] is Map
            ? ExtraGroupeGuestModel.fromJson(
                Map<String, dynamic>.from(j['guest']))
            : const ExtraGroupeGuestModel(
                id: 'g-0',
                fullName: '',
                titleOrRole: '',
                biography: '',
              ),
        theme: j['theme']?.toString() ?? '',
        presentationText: j['presentation_text']?.toString() ?? '',
        contextNotes: j['context_notes']?.toString() ?? '',
        objectives:
            (j['objectives'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        programItems:
            (j['program_items'] as List?)?.map((e) => e.toString()).toList() ??
                const [],
        scheduledAt: DateTime.tryParse(j['scheduled_at']?.toString() ?? '') ??
            DateTime.now(),
        practicalInfo: j['practical_info']?.toString() ?? '',
        status: j['status']?.toString() ?? 'upcoming',
        recordingAuthorized: j['recording_authorized'] == true,
        meetingReport: j['meeting_report']?.toString(),
        linkedDocumentIds: (j['linked_document_ids'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        questions: (j['questions'] as List?)
                ?.map((e) => ExtraGroupeQuestionModel.fromJson(
                    Map<String, dynamic>.from(e)))
                .toList() ??
            const [],
        registeredParticipants: (j['registered_participants'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        rosterPublicToCircle: j['roster_public_to_circle'] == true,
      );
}

class AppNotificationItem {
  final String id;
  final String title;
  final String body;
  final String category; // announcement | extra_groupe | challenge | moderation | zikr
  final String? deepLink;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? eventDate;
  final String? location;

  const AppNotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.category,
    this.deepLink,
    this.isRead = false,
    required this.createdAt,
    this.eventDate,
    this.location,
  });

  AppNotificationItem copyWith({bool? isRead}) => AppNotificationItem(
        id: id,
        title: title,
        body: body,
        category: category,
        deepLink: deepLink,
        isRead: isRead ?? this.isRead,
        createdAt: createdAt,
        eventDate: eventDate,
        location: location,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'category': category,
        'deep_link': deepLink,
        'is_read': isRead,
        'created_at': createdAt.toIso8601String(),
        if (eventDate != null) 'event_date': eventDate!.toIso8601String(),
        if (location != null && location!.isNotEmpty) 'location': location,
      };

  factory AppNotificationItem.fromJson(Map<String, dynamic> j) =>
      AppNotificationItem(
        id: j['id'].toString(),
        title: j['title']?.toString() ?? '',
        body: j['body']?.toString() ?? '',
        category: j['category']?.toString() ?? 'announcement',
        deepLink: j['deep_link']?.toString(),
        isRead: j['is_read'] == true,
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? '') ??
            DateTime.now(),
        eventDate: j['event_date'] != null
            ? DateTime.tryParse(j['event_date'].toString())
            : null,
        location: j['location']?.toString(),
      );
}

class EnglishCircleFeedbackModel {
  final String id;
  final String authorName;
  final String note;
  final String? suggestedCorrection;
  final DateTime createdAt;

  const EnglishCircleFeedbackModel({
    required this.id,
    required this.authorName,
    required this.note,
    this.suggestedCorrection,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'author_name': authorName,
        'note': note,
        if (suggestedCorrection != null && suggestedCorrection!.isNotEmpty)
          'suggested_correction': suggestedCorrection,
        'created_at': createdAt.toIso8601String(),
      };

  factory EnglishCircleFeedbackModel.fromJson(Map<String, dynamic> j) =>
      EnglishCircleFeedbackModel(
        id: j['id'].toString(),
        authorName: j['author_name']?.toString() ?? 'Membre',
        note: j['note']?.toString() ?? '',
        suggestedCorrection: j['suggested_correction']?.toString(),
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );
}

class EnglishCirclePostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String cefrLevel;
  final String promptTitle;
  final String englishText;
  final String? audioUrl;
  final int audioDurationSeconds;
  final int encouragements;
  final List<EnglishCircleFeedbackModel> feedbacks;
  final DateTime createdAt;

  const EnglishCirclePostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.cefrLevel,
    required this.promptTitle,
    required this.englishText,
    this.audioUrl,
    this.audioDurationSeconds = 0,
    this.encouragements = 0,
    this.feedbacks = const [],
    required this.createdAt,
  });

  EnglishCirclePostModel copyWith({
    int? encouragements,
    List<EnglishCircleFeedbackModel>? feedbacks,
  }) =>
      EnglishCirclePostModel(
        id: id,
        authorId: authorId,
        authorName: authorName,
        cefrLevel: cefrLevel,
        promptTitle: promptTitle,
        englishText: englishText,
        audioUrl: audioUrl,
        audioDurationSeconds: audioDurationSeconds,
        encouragements: encouragements ?? this.encouragements,
        feedbacks: feedbacks ?? this.feedbacks,
        createdAt: createdAt,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'author_id': authorId,
        'author_name': authorName,
        'cefr_level': cefrLevel,
        'prompt_title': promptTitle,
        'english_text': englishText,
        if (audioUrl != null) 'audio_url': audioUrl,
        'audio_duration_seconds': audioDurationSeconds,
        'encouragements': encouragements,
        'feedbacks': feedbacks.map((f) => f.toJson()).toList(),
        'created_at': createdAt.toIso8601String(),
      };

  factory EnglishCirclePostModel.fromJson(Map<String, dynamic> j) =>
      EnglishCirclePostModel(
        id: j['id'].toString(),
        authorId: j['author_id']?.toString() ?? '',
        authorName: j['author_name']?.toString() ?? 'Membre',
        cefrLevel: j['cefr_level']?.toString() ?? 'B1',
        promptTitle: j['prompt_title']?.toString() ?? '',
        englishText: j['english_text']?.toString() ?? '',
        audioUrl: j['audio_url']?.toString(),
        audioDurationSeconds:
            (j['audio_duration_seconds'] as num?)?.toInt() ?? 0,
        encouragements: (j['encouragements'] as num?)?.toInt() ?? 0,
        feedbacks: (j['feedbacks'] as List?)
                ?.whereType<Map>()
                .map((e) => EnglishCircleFeedbackModel.fromJson(
                    Map<String, dynamic>.from(e)))
                .toList() ??
            const [],
        createdAt: DateTime.tryParse(j['created_at']?.toString() ?? '') ??
            DateTime.now(),
      );
}
