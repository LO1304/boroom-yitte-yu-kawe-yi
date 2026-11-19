import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:boroom_yitte/app/app.dart';
import 'package:boroom_yitte/app/state/app_providers.dart';
import 'package:boroom_yitte/core/l10n/app_localizations.dart';
import 'package:boroom_yitte/core/models/domain_models.dart';
import 'package:boroom_yitte/core/services/backend_repository.dart';
import 'package:boroom_yitte/core/services/calendar_export_service.dart';
import 'package:boroom_yitte/core/services/daily_quotes_catalog.dart';
import 'package:boroom_yitte/core/services/deep_link_service.dart';
import 'package:boroom_yitte/core/services/english_open_source_service.dart';
import 'package:boroom_yitte/core/services/pdf_export_service.dart';
import 'package:boroom_yitte/core/services/whatsapp_bridge_service.dart';
import 'package:boroom_yitte/core/theme/app_theme.dart';
import 'package:boroom_yitte/features/admin/admin_dashboard_screen.dart';
import 'package:boroom_yitte/features/auth/auth_screen.dart';
import 'package:boroom_yitte/features/auth/splash_screen.dart';
import 'package:boroom_yitte/features/challenges/challenges_screen.dart';
import 'package:boroom_yitte/features/community/community_screen.dart';
import 'package:boroom_yitte/features/debates/debates_screen.dart';
import 'package:boroom_yitte/features/documents/documents_library_screen.dart';
import 'package:boroom_yitte/features/english_club/english_club_screen.dart';
import 'package:boroom_yitte/features/extra_groupe/extra_groupe_screen.dart';
import 'package:boroom_yitte/features/notifications/notifications_screen.dart';
import 'package:boroom_yitte/features/personal_growth/personal_growth_screen.dart';
import 'package:boroom_yitte/features/quiz_arena/quiz_arena_screen.dart';
import 'package:boroom_yitte/features/reflections/reflections_screen.dart';
import 'package:boroom_yitte/features/zikr/zikr_screen.dart';

Widget _wrapScreen(Widget screen) {
  return ProviderScope(
    child: MaterialApp(
      theme: AppTheme.light(),
      home: screen,
    ),
  );
}

Future<void> _scrollTo(WidgetTester tester, Finder target) async {
  await tester.scrollUntilVisible(
    target,
    240,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('100-point debate rubric analyzer calculates bounded component sums', () {
    final rubric = BackendRepository.analyzeDebateLocally(
      transcriptText:
          'Premièrement, par exemple dans l’histoire des sciences, la méthode critique demeure centrale. '
          'Cependant, il faut distinguer les faits établis des hypothèses interprétatives, car la nuance renforce le dialogue.',
      topicQuestion: 'La rigueur critique élève-t-elle le débat ?',
      isIslamicSubject: true,
    );

    expect(rubric.relevance, inInclusiveRange(0, 20));
    expect(rubric.logicalReasoning, inInclusiveRange(0, 25));
    expect(rubric.depthOfAnalysis, inInclusiveRange(0, 20));
    expect(rubric.argumentsAndExamples, inInclusiveRange(0, 15));
    expect(rubric.criticalNuance, inInclusiveRange(0, 10));
    expect(rubric.clarity, inInclusiveRange(0, 10));
    expect(rubric.totalScore, inInclusiveRange(0, 100));
    expect(rubric.verifiedReferences, isNotEmpty);
  });

  test('Deep link mapper resolves ecosystem routes accurately', () {
    expect(DeepLinkService.mapUriToRoute(Uri.parse('boroomyitte://zikr')), '/zikr');
    expect(DeepLinkService.mapUriToRoute(Uri.parse('boroomyitte://debates')), '/debates');
    expect(DeepLinkService.mapUriToRoute(Uri.parse('boroomyitte://quiz')), '/quiz-arena');
    expect(DeepLinkService.mapUriToRoute(Uri.parse('boroomyitte://english')), '/english-club');
  });

  test('Localization supports FR, EN, AR (RTL) and Wolof', () {
    expect(AppLanguage.ar.direction, TextDirection.rtl);
    expect(AppLanguage.fr.direction, TextDirection.ltr);
    expect(const AppStrings(AppLanguage.wo).t('nav_home'), 'KËR GI');
    expect(const AppStrings(AppLanguage.fr).t('nav_challenges'), 'Défis');
  });

  test('PDF export service generates valid PDF bytes for summaries & debates', () async {
    final pdfBytes = await PdfExportService.buildSummaryPdf(
      title: 'Synthèse Communautaire',
      subtitle: 'Semaine 46 — Lecture & Nuance',
      bodyMarkdown: 'Contenu validé par un éditeur autorisé : « l’éthique d’abord ».',
      bulletPoints: const ['Point 1 • Raisonnement', 'Point 2 — Discipline'],
      references: const ['Sourate Al-Hujurat (49:6) • Vérification de l’information'],
    );
    expect(pdfBytes.length, greaterThan(500));
    expect(String.fromCharCodes(pdfBytes.take(4)), '%PDF');

    const match = DebateMatchModel(
      id: 'm1',
      topicTitle: 'Éthique et Savoir',
      topicQuestion: 'Comment concilier vitesse et discernement ?',
      category: 'ethics',
      matchType: 'public',
      status: 'completed',
      opponentName: 'Moussa',
    );
    final rubric = BackendRepository.analyzeDebateLocally(
      transcriptText: 'Par exemple, la vérification des sources est essentielle.',
      topicQuestion: match.topicQuestion,
      isIslamicSubject: false,
    );
    final debatePdf = await PdfExportService.buildDebateEvaluationPdf(
      match: match,
      rubric: rubric,
    );
    expect(String.fromCharCodes(debatePdf.take(4)), '%PDF');
  });

  testWidgets('App renders main 5-tab navigation and navigates across modules',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: BoroomYitteApp(enablePlatformHooks: false),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('BOROOM YITTÉ'), findsOneWidget);
    expect(find.text('À LA UNE — DÉBAT DE LA SEMAINE'), findsOneWidget);
    expect(find.text('Rejoindre le débat →'), findsOneWidget);
    expect(find.text('PROCHAIN RENDEZ-VOUS'), findsOneWidget);
    await _scrollTo(tester, find.text('DERNIÈRES CONTRIBUTIONS'));
    expect(find.text('DERNIÈRES CONTRIBUTIONS'), findsOneWidget);
    expect(find.text('Accueil'), findsOneWidget);
    expect(find.text('Réflexions'), findsOneWidget);
    expect(find.text('Défis'), findsOneWidget);
    expect(find.text('Apprendre'), findsOneWidget);
    expect(find.text('Communauté'), findsOneWidget);

    await tester.tap(find.text('Réflexions'));
    await tester.pumpAndSettle();
    expect(find.text('Réflexions & Savoir'), findsOneWidget);

    await tester.tap(find.text('Défis'));
    await tester.pumpAndSettle();
    expect(find.text('Défis & Arènes'), findsOneWidget);

    await tester.tap(find.text('Apprendre'));
    await tester.pumpAndSettle();
    expect(find.text('Apprentissage & Évolution'), findsOneWidget);
  });

  testWidgets('DebatesScreen evaluates reasoned transcript on 100-point rubric',
      (tester) async {
    await tester.pumpWidget(_wrapScreen(const DebatesScreen()));
    await tester.pumpAndSettle();

    expect(find.text('YITTÉ FACE-À-FACE'), findsOneWidget);

    final fieldFinder = find.byType(TextField);
    await _scrollTo(tester, fieldFinder);
    await tester.enterText(
      fieldFinder.first,
      'Premièrement, par exemple dans l’éducation civique, l’esprit critique repose sur des faits vérifiables. '
      'Cependant, il faut distinguer l’opinion personnelle du savoir établi.',
    );

    final evalButton = find.text('Évaluer mon discours (Grille 100 pts)');
    await _scrollTo(tester, evalButton);
    await tester.tap(evalButton);
    await tester.pumpAndSettle();

    await _scrollTo(tester, find.text('Raisonnement logique'));
    expect(find.textContaining('/ 100'), findsWidgets);
  });

  testWidgets('QuizArenaScreen runs live question and reveals explanation',
      (tester) async {
    await tester.pumpWidget(_wrapScreen(const QuizArenaScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Démarrer : 1 vs 1'));
    await tester.pump();

    expect(find.textContaining('Question 1/'), findsOneWidget);

    await tester.tap(find.byType(ListTile).first);
    await tester.pumpAndSettle();

    expect(find.textContaining('Explication :'), findsOneWidget);
  });

  testWidgets('ZikrScreen keeps spiritual practice non-competitive and tracks Tasbih',
      (tester) async {
    await tester.pumpWidget(_wrapScreen(const ZikrScreen()));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Aucune compétition, aucun classement ni badge de piété'),
      findsOneWidget,
    );

    final salawatPlus33 = find.text('+33');
    await _scrollTo(tester, salawatPlus33);
    await tester.tap(salawatPlus33);
    await tester.pumpAndSettle();
    expect(find.text('Progression du cycle (privée) : 33 / 10000'), findsOneWidget);

    final targetFinder = find.text('/ 33');
    await _scrollTo(tester, targetFinder);
    await tester.tap(targetFinder);
    await tester.pumpAndSettle();
    expect(find.text('1'), findsOneWidget);
    expect(find.text('Progression du cycle (privée) : 34 / 10000'), findsOneWidget);

    final configBtn = find.text('Configurer objectif & durée');
    await _scrollTo(tester, configBtn);
    await tester.tap(configBtn);
    await tester.pumpAndSettle();

    final targetField = find.widgetWithText(TextField, 'Objectif total (répétitions)');
    await tester.ensureVisible(targetField);
    await tester.enterText(targetField, '33000');

    final daysField = find.widgetWithText(TextField, 'Durée souhaitée (en jours)');
    await tester.ensureVisible(daysField);
    await tester.enterText(daysField, '10');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Appliquer'));
    await tester.pumpAndSettle();
    expect(find.text('Progression du cycle (privée) : 34 / 33000'), findsOneWidget);
    expect(find.text('Ṣalātu ʿalā an-Nabī — 33000 sur 10 jour(s)'), findsOneWidget);
    expect(find.text('Nouveau cycle (10j)'), findsOneWidget);

    final closeFinder = find.text('Clôturer & réinitialiser');
    await _scrollTo(tester, closeFinder);
    await tester.tap(closeFinder);
    await tester.pumpAndSettle();

    expect(find.text('Sessions personnelles : 1'), findsOneWidget);
  });

  testWidgets('EnglishClubScreen supports CEFR grammar & accent-fair evaluation',
      (tester) async {
    await tester.pumpWidget(_wrapScreen(const EnglishClubScreen()));
    await tester.pumpAndSettle();

    expect(find.text('A. 5 Mots Quotidiens'), findsOneWidget);

    final speechFinder = find.byType(TextField);
    await _scrollTo(tester, speechFinder);
    await tester.enterText(
      speechFinder.first,
      'Although communication requires consistent practice, clear structure helps learners express nuanced ideas.',
    );

    final analyzeBtn = find.text('Analyser avec YITTE_ENGLISH_COACH');
    await _scrollTo(tester, analyzeBtn);
    await tester.tap(analyzeBtn);
    await tester.pumpAndSettle();

    await _scrollTo(tester, find.textContaining('Score Global :'));
    expect(find.textContaining('Score Global :'), findsOneWidget);

    final optFinder = find.text('Despite');
    await _scrollTo(tester, optFinder);
    await tester.tap(optFinder);
    await tester.pumpAndSettle();
  });

  testWidgets('PersonalGrowthScreen toggles habits and saves private journal note',
      (tester) async {
    await tester.pumpWidget(_wrapScreen(const PersonalGrowthScreen()));
    await tester.pumpAndSettle();

    final habitTile = find.byType(CheckboxListTile).first;
    await _scrollTo(tester, habitTile);
    await tester.tap(habitTile);
    await tester.pumpAndSettle();

    final titleField = find.widgetWithText(TextField, 'Titre de la note privée');
    final bodyField = find.widgetWithText(TextField, 'Contenu confidentiel');
    await _scrollTo(tester, titleField);
    await tester.enterText(titleField, 'Bilan Hebdomadaire Privé');
    await tester.enterText(bodyField, 'Discipline matinale respectée sans distraction.');

    final saveBtn = find.text('Enregistrer en privé');
    await _scrollTo(tester, saveBtn);
    await tester.tap(saveBtn);
    await tester.pumpAndSettle();

    await _scrollTo(tester, find.text('Bilan Hebdomadaire Privé'));
    expect(find.text('Bilan Hebdomadaire Privé'), findsOneWidget);
  });

  testWidgets('AdminDashboardScreen generates RBAC invitation codes',
      (tester) async {
    await tester.pumpWidget(_wrapScreen(const AdminDashboardScreen()));
    await tester.pumpAndSettle();

    final beforeChips = tester.widgetList(find.byType(Chip)).length;
    await tester.tap(find.text('Générer'));
    await tester.pumpAndSettle();
    final afterChips = tester.widgetList(find.byType(Chip)).length;

    expect(afterChips, greaterThan(beforeChips));
  });

  test('BackendRepository AI agents and snapshot persistence operate concretely',
      () async {
    final starReply = await BackendRepository.instance.callAiAgent(
      agentName: 'YITTE_CAREER_COACH',
      prompt:
          'Dans le contexte de notre projet équipe, j’ai développé une API qui a réduit la latence de 40 pour cent.',
    );
    expect(starReply, contains('Score structurel STAR : 100 / 100'));

    final weakReply = await BackendRepository.instance.callAiAgent(
      agentName: 'YITTE_CAREER_COACH',
      prompt: 'Bonjour test rapide.',
    );
    expect(weakReply, contains('Score structurel STAR : 42 / 100'));

    final englishReply = await BackendRepository.instance.callAiAgent(
      agentName: 'YITTE_ENGLISH_COACH',
      prompt: 'Despite of the informations, i read a important book and discuss about it.',
    );
    expect(englishReply, contains('Diagnostic linguistique'));
    expect(
      englishReply,
      contains('despite the information, I read an important book and discuss it.'),
    );

    await BackendRepository.instance.saveEcosystemSnapshot({
      'quizScoreTotal': 420,
      'books': const [
        {
          'id': 'b-test',
          'title': 'Éthique à Nicomaque',
          'author': 'Aristote',
          'currentPage': 45,
          'totalPages': 300,
        },
      ],
    });
    final restored = await BackendRepository.instance.loadEcosystemSnapshot();
    expect(restored, isNotNull);
    expect(restored!['quizScoreTotal'], 420);
    expect((restored['books'] as List).first['title'], 'Éthique à Nicomaque');
  });

  testWidgets('PersonalGrowthScreen tracks reading pages and adds new book',
      (tester) async {
    await tester.pumpWidget(_wrapScreen(const PersonalGrowthScreen()));
    await tester.pumpAndSettle();

    final addBookBtn = find.text('+ Livre');
    await _scrollTo(tester, addBookBtn);
    await tester.tap(addBookBtn);
    await tester.pumpAndSettle();

    expect(find.text('Ajouter un livre à suivre'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextField, 'Titre du livre'),
      'Al-Muqaddima',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Auteur'),
      'Ibn Khaldūn',
    );
    await tester.tap(find.text('Ajouter'));
    await tester.pumpAndSettle();

    await _scrollTo(tester, find.text('Al-Muqaddima'));
    expect(find.text('Al-Muqaddima'), findsOneWidget);

    final plusTen = find.byTooltip('+10 pages').first;
    await tester.ensureVisible(plusTen);
    await tester.tap(plusTen);
    await tester.pumpAndSettle();
    expect(find.textContaining('Page 10/240'), findsOneWidget);
  });

  testWidgets('Zero fabricated persona names or fake points appear in default UI',
      (tester) async {
    await tester.pumpWidget(_wrapScreen(const QuizArenaScreen()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Aïssatou Diallo'), findsNothing);
    expect(find.textContaining('Membre 1 vs 2'), findsNothing);
    expect(find.text('0 pts'), findsOneWidget);
  });

  testWidgets('ReflectionsScreen supports live search, category filter, and archiving',
      (tester) async {
    await tester.pumpWidget(_wrapScreen(const ReflectionsScreen()));
    await tester.pumpAndSettle();

    expect(find.textContaining('Charte du discernement'), findsOneWidget);

    await tester.enterText(
      find.byType(TextField).first,
      'inexistant_mot_cle',
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Charte du discernement'), findsNothing);

    await tester.tap(find.byIcon(Icons.clear_rounded));
    await tester.pumpAndSettle();
    expect(find.textContaining('Charte du discernement'), findsOneWidget);

    await tester.tap(find.byTooltip('Archiver').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Charte du discernement'), findsNothing);

    await tester.tap(find.text('Archivées'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Charte du discernement'), findsOneWidget);
  });

  testWidgets('PersonalGrowthScreen runs Deep Work chrono and adds custom habit',
      (tester) async {
    await tester.pumpWidget(_wrapScreen(const PersonalGrowthScreen()));
    await tester.pumpAndSettle();

    final addHabitBtn = find.text('+ Habitude');
    await _scrollTo(tester, addHabitBtn);
    await tester.tap(addHabitBtn);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).last, 'Révision logique 15 min');
    await tester.tap(find.text('Ajouter'));
    await tester.pumpAndSettle();
    expect(find.text('Révision logique 15 min'), findsOneWidget);

    final startChrono = find.text('Démarrer le chrono');
    await _scrollTo(tester, startChrono);
    await tester.tap(startChrono);
    await tester.pump(const Duration(seconds: 2));
    expect(find.text('Pause'), findsOneWidget);
    await tester.tap(find.text('Réinitialiser'));
    await tester.pumpAndSettle();
    expect(find.text('45:00'), findsOneWidget);
  });

  test('Document catalog defines 5 domains and blocks summary hallucination', () {
    expect(DocumentCategoryCatalog.domains.length, 5);
    final totalSubcats = DocumentCategoryCatalog.domains.values
        .fold<int>(0, (acc, list) => acc + list.length);
    expect(totalSubcats, 40);

    expect(
      () => BackendRepository.summarizeSourceTextLocally(
        documentId: 'doc-empty',
        title: 'Document Vide',
        sourceText: 'trop court',
      ),
      throwsStateError,
    );

    final summary = BackendRepository.summarizeSourceTextLocally(
      documentId: 'doc-1',
      title: 'Épistémologie et Discernement',
      sourceText:
          'La méthode critique désigne l’examen rigoureux des sources avant toute conclusion. '
          'Car sans vérification des faits, l’opinion remplace la connaissance établie. '
          'Selon le chapitre 2, la cohérence logique guide la recherche scientifique.',
    );
    expect(summary.isAiAssisted, true);
    expect(summary.status, 'draft');
    expect(summary.mainIdeas, isNotEmpty);
    expect(summary.definitions, isNotEmpty);
    expect(summary.comprehensionQuestions, isNotEmpty);
  });

  testWidgets('DocumentsLibraryScreen saves real source doc and summarizes faithfully',
      (tester) async {
    await tester.pumpWidget(_wrapScreen(const DocumentsLibraryScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Aucun document enregistré dans cette vue'), findsOneWidget);

    await _scrollTo(tester, find.text('Ajouter un vrai document'));
    await tester.tap(find.text('Ajouter un vrai document'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextField, 'Titre du document *'),
      'Notes de Logique Formelle',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Source / référence bibliographique *'),
      'Cours d’introduction logique',
    );
    await tester.enterText(
      find.widgetWithText(TextField, 'Texte extrait ou contenu textuel source'),
      'La logique formelle étudie la validité des raisonnements indépendamment du contenu émotionnel. '
      'Car une déduction valide garantit la vérité de la conclusion lorsque les prémisses sont établies.',
    );
    await tester.tap(find.text('Enregistrer'));
    await tester.pumpAndSettle();

    expect(find.text('Notes de Logique Formelle'), findsOneWidget);
    await tester.tap(find.text('Notes de Logique Formelle'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Résumer depuis le document'));
    await tester.pumpAndSettle();
    expect(find.textContaining('1. Résumé général'), findsOneWidget);
  });

  testWidgets('ReflectionsScreen integrates historical community topics verbatim',
      (tester) async {
    await tester.pumpWidget(_wrapScreen(const ReflectionsScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Sokhna Diarra'), findsOneWidget);
    await _scrollTo(tester, find.text('Aida Thiam'));
    expect(find.text('Aida Thiam'), findsOneWidget);
    await _scrollTo(tester, find.text('Khady Sylla'));
    expect(find.text('Khady Sylla'), findsOneWidget);
  });

  testWidgets('ExtraGroupeScreen displays Serigne Makhtar Thiam and protects roster privacy',
      (tester) async {
    await tester.pumpWidget(_wrapScreen(const ExtraGroupeScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Serigne Makhtar Thiam'), findsOneWidget);
    expect(find.textContaining('Gaayu Bakh Yi'), findsWidgets);

    final qField = find.widgetWithText(
      TextField,
      'Poser une question réfléchie pour l’invité...',
    );
    await _scrollTo(tester, qField);
    await tester.enterText(
      qField,
      'Quelles priorités pratiques conseillez-vous aux jeunes étudiants ?',
    );
    await tester.tap(find.text('Envoyer'));
    await tester.pumpAndSettle();

    await _scrollTo(tester, find.textContaining('Quelles priorités pratiques'));
    expect(find.textContaining('Quelles priorités pratiques'), findsOneWidget);

    await _scrollTo(tester, find.textContaining('Participants (9)'));
    expect(
      find.textContaining('protégée par les paramètres de confidentialité'),
      findsOneWidget,
    );
  });

  testWidgets('Splash, Auth recovery tabs, and Notifications render cleanly',
      (tester) async {
    await tester.pumpWidget(_wrapScreen(const SplashScreen()));
    await tester.pumpAndSettle();
    expect(find.text('BOROOM YITTÉ YU KAWÉ YI'), findsOneWidget);

    await tester.pumpWidget(_wrapScreen(const AuthScreen()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Récupération'));
    await tester.pumpAndSettle();
    expect(find.text('Récupération de Mot de Passe'), findsOneWidget);

    await tester.pumpWidget(_wrapScreen(const NotificationsScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Aucune notification pour le moment'), findsOneWidget);
  });

  testWidgets('Full-name-only login creates member profile and continues into structure',
      (tester) async {
    await tester.pumpWidget(_wrapScreen(const AuthScreen()));
    await tester.pumpAndSettle();

    expect(find.text('Accès par Nom Complet'), findsOneWidget);
    final nameField = find.widgetWithText(
      TextFormField,
      'Votre nom complet (Prénom & Nom) *',
    );
    await tester.enterText(nameField, 'Sokhna Amy Mountakha Thiam');
    await tester.tap(find.text('Continuer vers la structure'));
    await tester.pumpAndSettle();

    final restored = await BackendRepository.instance.restoreSessionProfile();
    expect(restored, isNotNull);
    expect(restored!.fullName, 'Sokhna Amy Mountakha Thiam');
  });

  testWidgets('WhatsApp bridge validates official links and parses real .txt exports',
      (tester) async {
    expect(
      WhatsAppBridgeService.normalizeInviteUrl(
          'https://chat.whatsapp.com/Ioa04LfRCvvFdTtCE6Hj7V?s=cl&p=a&iam=2'),
      'https://chat.whatsapp.com/Ioa04LfRCvvFdTtCE6Hj7V?s=cl&p=a&iam=2',
    );
    expect(
      WhatsAppBridgeService.normalizeInviteUrl('http://insecure.example.com/chat'),
      isNull,
    );

    final shareUrl = WhatsAppBridgeService.buildShareUrl(
      'Rencontre Extra Groupe',
      groupInviteUrl:
          'https://chat.whatsapp.com/Ioa04LfRCvvFdTtCE6Hj7V?s=cl&p=a&iam=2',
    );
    expect(shareUrl, startsWith('https://wa.me/?text='));

    final parsed = WhatsAppBridgeService.parseWhatsAppChatExport(
      '18/11/2026, 19:50 - Les messages et les appels sont chiffrés de bout en bout.\n'
      '18/11/2026, 20:05 - Cheikh Moustapha Lo: Assalamu alaykum la famille.\n'
      '[18/11/2026, 20:07] Sokhna Diarra Lo: Wa alaykum salam, bienvenue !',
    );
    expect(parsed.length, 2);
    expect(parsed.first.sender, 'Cheikh Moustapha Lo');
    expect(parsed.last.sender, 'Sokhna Diarra Lo');

    await tester.pumpWidget(_wrapScreen(const CommunityScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Liaison Groupe WhatsApp'), findsOneWidget);
    expect(find.text('Lien officiel actif'), findsOneWidget);
    expect(find.text('Ouvrir le groupe WhatsApp'), findsOneWidget);
    expect(find.text('Importer & Archiver (.txt)'), findsOneWidget);
    expect(find.text('Exporter Digest PDF'), findsOneWidget);
  });

  testWidgets(
      'Group-only full-name auth rejects non-members, and test content can be deleted',
      (tester) async {
    expect(
      () => BackendRepository.instance.signInByFullName(
        fullName: 'Personne Exterieure Non Autorisee',
      ),
      throwsStateError,
    );

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(ecosystemProvider.notifier);

    notifier.addReflection(
      authorId: 'test-id',
      authorName: 'Sokhna Diarra Lo',
      title: 'Sujet Test Supprimable',
      body: 'Contenu temporaire de test pour vérification.',
      category: 'philosophy',
    );
    final addedId = container
        .read(ecosystemProvider)
        .reflections
        .firstWhere((r) => r.title == 'Sujet Test Supprimable')
        .id;
    notifier.deleteReflection(addedId);
    expect(
      container
          .read(ecosystemProvider)
          .reflections
          .any((r) => r.id == addedId),
      isFalse,
    );
  });

  testWidgets(
      'Sanctuary palettes, 35-word English bank, and free projects operate properly',
      (tester) async {
    expect(SanctuaryPalette.values.length, 8);
    expect(UiVisualModel.values.length, 4);
    for (final p in SanctuaryPalette.values) {
      for (final m in UiVisualModel.values) {
        expect(AppTheme.light(p, m).colorScheme.primary, p.primary);
        expect(AppTheme.dark(p, m).colorScheme.primary, p.primaryLight);
      }
    }

    final container = ProviderContainer();
    addTearDown(container.dispose);
    final eco = container.read(ecosystemProvider);
    expect(eco.dailyVocab.length, 35);

    final notifier = container.read(ecosystemProvider.notifier);
    notifier.addPortfolioProject('Capteur solaire agricole [Agronomie]');
    expect(
      container
          .read(ecosystemProvider)
          .portfolioProjects
          .first,
      contains('Capteur solaire agricole'),
    );
    notifier.deletePortfolioProject(0);
    expect(container.read(ecosystemProvider).portfolioProjects, isEmpty);
  });

  testWidgets(
      'Open-source English program parses dictionary API entries and navigates tabs',
      (tester) async {
    const sampleJson = '''
    [
      {
        "word": "resilience",
        "phonetic": "/ɹɪˈzɪl.i.əns/",
        "phonetics": [
          {"text": "/ɹɪˈzɪl.i.əns/", "audio": "//ssl.gstatic.com/dictionary/static/sounds/20200429/resilience--_gb_1.mp3"},
          {"text": "/ɹɪˈzɪliəns/", "audio": "https://api.dictionaryapi.dev/media/pronunciations/en/resilience-us.mp3"}
        ],
        "meanings": [
          {
            "partOfSpeech": "noun",
            "synonyms": ["toughness", "adaptability"],
            "definitions": [
              {
                "definition": "The mental ability to recover quickly from adversity.",
                "example": "Community resilience grows with shared knowledge."
              }
            ]
          }
        ]
      }
    ]
    ''';
    final parsed = EnglishOpenSourceService.parseDictionaryResponse(sampleJson);
    expect(parsed, isNotNull);
    expect(parsed!.word, 'resilience');
    expect(
      parsed.preferredAudioFor('en-US'),
      'https://api.dictionaryapi.dev/media/pronunciations/en/resilience-us.mp3',
    );
    expect(parsed.meanings.first.partOfSpeech, 'noun');
    expect(EnglishOpenSourceService.curriculum.length, 6);
    expect(EnglishOpenSourceService.irregularVerbs.length, greaterThanOrEqualTo(10));
    expect(EnglishOpenSourceService.openPortals.length, greaterThanOrEqualTo(3));

    await tester.pumpWidget(_wrapScreen(const EnglishClubScreen()));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Programme A1–C2'));
    await tester.pumpAndSettle();
    expect(find.text('Procédure Complète A1 → C2'), findsOneWidget);
    final portalFinder = find.textContaining('British Council LearnEnglish');
    await _scrollTo(tester, portalFinder);
    expect(portalFinder, findsOneWidget);
  });

  testWidgets(
      'Organized Challenges & voice note models persist audio URLs properly',
      (tester) async {
    final voiceMsg = ChatMessageModel(
      id: 'm-voice-1',
      channelName: 'Groupe WhatsApp',
      senderName: 'Cheikh Mouhamadou Moustapha Lo',
      body: 'Note vocale (8s)',
      sentAt: DateTime(2026, 11, 18),
      audioUrl: '/api/files/voice_test.webm',
      audioDurationSeconds: 8,
    );
    final decodedMsg = ChatMessageModel.fromJson(voiceMsg.toJson());
    expect(decodedMsg.audioUrl, '/api/files/voice_test.webm');
    expect(decodedMsg.audioDurationSeconds, 8);

    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.read(ecosystemProvider.notifier).submitChallengeResponse(
          'ch-3',
          'Réponse vocale enregistrée',
          audioUrl: '/api/files/ch3_test.webm',
        );
    final updatedCh3 = container
        .read(ecosystemProvider)
        .challenges
        .firstWhere((c) => c.id == 'ch-3');
    expect(updatedCh3.userAudioUrl, '/api/files/ch3_test.webm');

    await tester.pumpWidget(_wrapScreen(const ChallengesScreen()));
    await tester.pumpAndSettle();
    expect(find.text('Programme Organisé des Défis'), findsOneWidget);
    await tester.tap(find.text('Vocaux'));
    await tester.pumpAndSettle();
    expect(
      find.text('Plaidoyer vocal : Discipline individuelle et bien commun'),
      findsOneWidget,
    );
  });

  testWidgets(
      'Calendar export, Masalik/Philosopher daily quotes, LanguageTool Coach, and pure free Zikr work cleanly',
      (tester) async {
    final ics = CalendarExportService.buildIcsContent(
      title: 'Réunion Mensuelle',
      description: 'Ordre du jour communautaire',
      start: DateTime.utc(2026, 12, 1, 20, 0),
      location: 'En ligne',
    );
    expect(ics, contains('BEGIN:VCALENDAR'));
    expect(ics, contains('SUMMARY:Réunion Mensuelle'));
    expect(ics, contains('LOCATION:En ligne'));
    final gcal = CalendarExportService.buildGoogleCalendarUrl(
      title: 'Réunion Mensuelle',
      description: 'Ordre du jour',
      start: DateTime.utc(2026, 12, 1, 20, 0),
    );
    expect(gcal, startsWith('https://calendar.google.com/calendar/render'));

    expect(
      DailyQuotesCatalog.quotes
          .any((q) => q.author == 'Cheikh Ahmadou Bamba' && q.sourceWork.contains('Masālik al-Jinān')),
      isTrue,
    );
    expect(
      DailyQuotesCatalog.quotes.any((q) => q.author.contains('al-Ghazālī')),
      isTrue,
    );
    expect(
      DailyQuotesCatalog.quotes.any((q) => q.author == 'Épictète'),
      isTrue,
    );
    expect(
      DailyQuotesCatalog.quotes.any((q) => q.author == 'Sénèque'),
      isTrue,
    );
    expect(
      DailyQuotesCatalog.quotes.any((q) => q.author == 'Épicure'),
      isTrue,
    );

    const ltJson = '''
    {
      "matches": [
        {
          "message": "Use 'have' instead of 'has'.",
          "offset": 2,
          "length": 3,
          "replacements": [{"value": "have"}],
          "rule": {"category": {"name": "Grammar"}}
        }
      ]
    }
    ''';
    final ltParsed = EnglishOpenSourceService.parseLanguageToolResponse(
      'I has finished.',
      ltJson,
    );
    expect(ltParsed.correctedText, 'I have finished.');
    expect(ltParsed.issues.length, 1);

    final coach = EnglishOpenSourceService();
    final forSinceReply = await coach.askEnglishCoachLive(
      input: 'Différence entre for et since ?',
      variant: 'en-GB',
      cefrLevel: 'B1',
    );
    expect(forSinceReply, contains('FOR vs SINCE'));
    expect(EnglishOpenSourceService.concreteCourses.length, 6);

    await tester.pumpWidget(_wrapScreen(const ZikrScreen()));
    await tester.pumpAndSettle();
    expect(find.text('صَلَّى اللهُ عَلَى مُحَمَّدٍ'), findsWidgets);
    expect(find.textContaining('Samedi 20h00'), findsNothing);
    expect(find.textContaining('Rejoindre le salon audio'), findsNothing);
  });
}
