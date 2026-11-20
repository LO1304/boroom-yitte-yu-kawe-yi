import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/state/app_providers.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/english_open_source_service.dart';
import '../../core/services/external_link_bridge.dart';
import '../../core/services/speech_bridge.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/editorial_widgets.dart';

class EnglishClubScreen extends ConsumerStatefulWidget {
  const EnglishClubScreen({super.key});

  @override
  ConsumerState<EnglishClubScreen> createState() => _EnglishClubScreenState();
}

class _EnglishClubScreenState extends ConsumerState<EnglishClubScreen> {
  static const _stepsPrefKey = 'yitte_english_completed_steps_v1';

  int _activeTab = 0; // 0 = Parcours & Oral, 1 = Amy (Oral IA), 2 = Dictionnaire, 3 = Programme A1-C2
  String _variant = 'en-GB';
  String _cefr = 'B1';
  bool _consent = false;
  final _speechCtrl = TextEditingController();
  final _coachCtrl = TextEditingController();
  final _amyInputCtrl = TextEditingController();
  int _amyScenarioIdx = 0;
  bool _amyAutoSpeak = true;
  String _amyVoiceProfile = 'amy-fluent-us'; // amy-fluent-us (Ava), amy-soft-uk (Libby), amy-clear-uk (Sonia)
  double _amyRate = 0.96; // 0.78 (Lent), 0.96 (Fluide), 1.14 (Natif)
  bool _amyBusy = false;
  bool _amyListening = false;
  bool _amySpeaking = false;
  int? _speakingMessageIdx;
  int _speakingWordIdx = -1;
  String _amyVoiceEngineLabel = 'Voix Neurale Studio';
  final Set<int> _revealedTranslations = {0};
  bool _showAmyHints = true;
  List<String> _amyHints = const [];
  String? _tappedWord;
  String? _tappedWordInfo;
  bool _tappedWordLoading = false;
  String? _shadowingTarget;
  ShadowingEvaluation? _shadowingEval;
  final List<_AmyChatMessage> _amyMessages = [];
  final _dictLookupCtrl = TextEditingController(text: 'resilience');
  final _ltCheckCtrl = TextEditingController(
    text: 'Despite of the rain, I have saw him yesterday and we discussed about informations.',
  );
  final _vocabSearchCtrl = TextEditingController();
  String _vocabQuery = '';
  String _vocabCefrFilter = 'Tous';
  String? _coachReply;
  bool _coachLoading = false;
  String _grammarFeedback = '';
  int _grammarIdx = 0;
  String _vocabFeedback = '';
  int _vocabIdx = 0;
  int _vocabXp = 0;
  bool _busy = false;

  final _openDictService = EnglishOpenSourceService();
  bool _lookingUpDict = false;
  OpenDictionaryEntry? _dictEntry;
  String? _dictError;
  bool _checkingLt = false;
  LanguageToolCheckResult? _ltResult;
  Set<String> _completedStepIds = {};
  final Map<String, String> _courseQuizFeedback = {};

  static const _coachQuickTopics = [
    'For vs Since',
    'Present Perfect',
    'Make vs Do',
    'Faux amis FR→EN',
    'In / On / At',
    'Conditionnels',
    'Entretien STAR',
    'Phrasal Verbs',
    'Prononciation',
  ];

  static const _grammarDrills = [
    (
      question: '"_____ the difficulty, she spoke clearly."',
      options: ['Although', 'Despite', 'Whereas'],
      answer: 'Despite',
      explain: '"Despite" is followed by a noun phrase ("the difficulty"); "Although/Whereas" require a clause.',
    ),
    (
      question: '"The team discussed _____ the new architecture this morning."',
      options: ['about', '(no preposition)', 'around'],
      answer: '(no preposition)',
      explain: '"Discuss" is transitive in English ("discuss the architecture", never "discuss about").',
    ),
    (
      question: '"Could you give me _____ practical advice before the debate?"',
      options: ['some', 'an', 'many'],
      answer: 'some',
      explain: '"Advice" is uncountable in English — use "some advice" or "a piece of advice".',
    ),
    (
      question: '"Had we verified the source earlier, we _____ avoided that error."',
      options: ['would have', 'will have', 'would'],
      answer: 'would have',
      explain: 'Third conditional ("Had + subject + past participle") pairs with "would have + past participle".',
    ),
    (
      question: '"Neither the agronomist nor the engineers _____ ready to compromise on quality."',
      options: ['were', 'was', 'is'],
      answer: 'were',
      explain: 'With "neither... nor...", the verb agrees with the nearest plural subject ("engineers").',
    ),
  ];

  static const _vocabDrills = [
    (
      prompt: 'Quel synonyme exprime le mieux « steady persistence » ?',
      options: ['Steadfastness', 'Hesitation', 'Fragmentation'],
      answer: 'Steadfastness',
      note: 'Steadfastness = ferme constance.',
    ),
    (
      prompt: 'Quel terme signifie « careful moral or intellectual judgment » ?',
      options: ['Discernment', 'Complacency', 'Ambiguity'],
      answer: 'Discernment',
      note: 'Discernment = discernement rigoureux.',
    ),
    (
      prompt: 'Quel adjectif décrit un propos « clearly structured & easy to follow » ?',
      options: ['Coherent', 'Arbitrary', 'Obscure'],
      answer: 'Coherent',
      note: 'Coherent = cohérent et structuré.',
    ),
    (
      prompt: 'Quel mot désigne « composure under difficult pressure » ?',
      options: ['Equanimity', 'Impulsiveness', 'Confusion'],
      answer: 'Equanimity',
      note: 'Equanimity = sérénité et maîtrise de soi.',
    ),
    (
      prompt: 'Quel verbe signifie « combine multiple sources into one clear summary » ?',
      options: ['Synthesize', 'Scatter', 'Omit'],
      answer: 'Synthesize',
      note: 'Synthesize = synthétiser des sources vérifiées.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadCompletedSteps();
    _resetAmyScenario(0, speakNow: false);
  }

  void _speakAsAmy(
    String text, {
    int? messageIdx,
    double? overrideRate,
    String? bundledAssetPath,
  }) {
    final effectiveLocale =
        _amyVoiceProfile.endsWith('-uk') ? 'en-GB' : 'en-US';
    SpeechBridge.speak(
      text,
      locale: effectiveLocale,
      rate: overrideRate ?? _amyRate,
      preferFemale: true,
      voiceProfile: _amyVoiceProfile,
      bundledAssetPath: bundledAssetPath,
      onSpeakingChanged: (speaking) {
        if (!mounted) return;
        setState(() {
          _amySpeaking = speaking;
          if (!speaking) {
            _speakingMessageIdx = null;
            _speakingWordIdx = -1;
          } else {
            _speakingMessageIdx = messageIdx;
          }
        });
      },
      onWordIndex: (wordIdx) {
        if (!mounted) return;
        setState(() {
          _speakingMessageIdx = messageIdx;
          _speakingWordIdx = wordIdx;
        });
      },
      onEngineUsed: (engine) {
        if (!mounted) return;
        setState(() => _amyVoiceEngineLabel = engine);
      },
    );
  }

  Future<void> _tapWordInAmyMessage(String rawWord) async {
    final clean = rawWord.replaceAll(RegExp(r"[^a-zA-Z'-]"), '').trim();
    if (clean.isEmpty) return;
    _speakAsAmy(clean, overrideRate: 0.88);
    setState(() {
      _tappedWord = clean;
      _tappedWordInfo = null;
      _tappedWordLoading = true;
    });
    try {
      final entry = await _openDictService.lookupWord(clean.toLowerCase());
      if (!mounted || _tappedWord != clean) return;
      if (entry != null && entry.meanings.isNotEmpty) {
        final def = entry.meanings.first.definitions.isNotEmpty
            ? entry.meanings.first.definitions.first
            : '';
        final phon = entry.phonetic.isNotEmpty ? '${entry.phonetic} • ' : '';
        setState(() {
          _tappedWordLoading = false;
          _tappedWordInfo = '$phon${entry.meanings.first.partOfSpeech} : $def';
        });
      } else {
        setState(() {
          _tappedWordLoading = false;
          _tappedWordInfo = 'Mot prononcé par Amy. Cherchez-le dans l’onglet Dictionnaire pour plus d’exemples.';
        });
      }
    } catch (_) {
      if (!mounted || _tappedWord != clean) return;
      setState(() {
        _tappedWordLoading = false;
        _tappedWordInfo = 'Mot prononcé par Amy.';
      });
    }
  }

  void _resetAmyScenario(int index, {bool speakNow = true}) {
    final sc = EnglishOpenSourceService.amyScenarios[
        index.clamp(0, EnglishOpenSourceService.amyScenarios.length - 1)];
    SpeechBridge.stopSpeaking();
    setState(() {
      _amyScenarioIdx = index;
      _amyHints = sc.suggestedRepliesEn;
      _shadowingTarget = null;
      _shadowingEval = null;
      _tappedWord = null;
      _tappedWordInfo = null;
      _revealedTranslations
        ..clear()
        ..add(0);
      _amyMessages
        ..clear()
        ..add(
          _AmyChatMessage(
            fromAmy: true,
            englishText: sc.openingEn,
            frenchNote: sc.openingFr,
            bundledAssetPath: sc.openingAssetPath,
          ),
        );
    });
    if (speakNow && _amyAutoSpeak) {
      _speakAsAmy(
        sc.openingEn,
        messageIdx: 0,
        bundledAssetPath: sc.openingAssetPath,
      );
    }
  }

  Future<void> _sendToAmy(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty || _amyBusy) return;
    if (_amyListening) {
      SpeechBridge.stopDictation();
      _amyListening = false;
    }

    // Si l'utilisateur est en mode Répéter (Shadowing), évalue d'abord sa prononciation mot par mot !
    if (_shadowingTarget != null) {
      final eval = EnglishOpenSourceService.evaluateShadowing(
        targetSentence: _shadowingTarget!,
        spokenText: text,
      );
      setState(() {
        _shadowingEval = eval;
        _amyInputCtrl.clear();
      });
      return;
    }

    final sc = EnglishOpenSourceService.amyScenarios[_amyScenarioIdx];
    final userTurns = _amyMessages.where((m) => !m.fromAmy).length;
    setState(() {
      _amyMessages.add(_AmyChatMessage(fromAmy: false, englishText: text));
      _amyInputCtrl.clear();
      _amyBusy = true;
    });
    final reply = await _openDictService.converseWithAmy(
      userInput: text,
      scenario: sc,
      turnIndex: userTurns,
      variant: _amyVoiceProfile.endsWith('-uk') ? 'en-GB' : 'en-US',
      cefrLevel: _cefr,
    );
    if (!mounted) return;
    final newMsgIndex = _amyMessages.length;
    setState(() {
      _amyBusy = false;
      if (reply.suggestedRepliesEn.isNotEmpty) {
        _amyHints = reply.suggestedRepliesEn;
      }
      _amyMessages.add(
        _AmyChatMessage(
          fromAmy: true,
          englishText: reply.amySpeechEn,
          frenchNote: reply.amyTranslationFr,
          correctionNote: reply.correctionNote,
          correctedText: reply.correctedText,
          nativeUpgrade: reply.nativeUpgrade,
          fluencyScore: reply.fluencyScore,
        ),
      );
    });
    if (_amyAutoSpeak) {
      _speakAsAmy(reply.amySpeechEn, messageIdx: newMsgIndex);
    }
  }

  Future<void> _loadCompletedSteps() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_stepsPrefKey);
    if (saved != null && mounted) {
      setState(() => _completedStepIds = saved.toSet());
    }
  }

  Future<void> _toggleStepCompleted(String stepId) async {
    final next = Set<String>.from(_completedStepIds);
    if (next.contains(stepId)) {
      next.remove(stepId);
    } else {
      next.add(stepId);
    }
    setState(() => _completedStepIds = next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_stepsPrefKey, next.toList());
  }

  Future<void> _performDictionaryLookup(String queryWord) async {
    final clean = queryWord.trim();
    if (clean.isEmpty) return;
    setState(() {
      _lookingUpDict = true;
      _dictError = null;
    });
    try {
      final entry = await _openDictService.lookupWord(clean);
      if (!mounted) return;
      if (entry == null) {
        setState(() {
          _lookingUpDict = false;
          _dictEntry = null;
          _dictError =
              'Mot « $clean » introuvable dans Free Dictionary API ou connexion hors ligne.';
        });
      } else {
        setState(() {
          _lookingUpDict = false;
          _dictEntry = entry;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _lookingUpDict = false;
        _dictError =
            'API dictionnaire open-source momentanément inaccessible ($e). Consultez la banque hors ligne ci-dessous.';
      });
    }
  }

  Future<void> _runLanguageToolCheck() async {
    final text = _ltCheckCtrl.text.trim();
    if (text.isEmpty) return;
    setState(() => _checkingLt = true);
    final res = await _openDictService.checkGrammarLive(text, language: _variant);
    if (mounted) {
      setState(() {
        _checkingLt = false;
        _ltResult = res;
      });
    }
  }

  Future<void> _askCoach(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return;
    setState(() => _coachLoading = true);
    final reply = await _openDictService.askEnglishCoachLive(
      input: clean,
      variant: _variant,
      cefrLevel: _cefr,
    );
    if (mounted) {
      setState(() {
        _coachLoading = false;
        _coachReply = reply;
      });
    }
  }

  Future<void> _playOpenDictPronunciation(
    AudioService audio,
    OpenDictionaryEntry entry,
  ) async {
    final audioUrl = entry.preferredAudioFor(_variant);
    if (audioUrl != null && audioUrl.isNotEmpty) {
      await audio.playFile(
        audioUrl,
        onError: (_) => _speakAsAmy(entry.word),
      );
      return;
    }
    _speakAsAmy(entry.word);
  }

  @override
  void dispose() {
    _speechCtrl.dispose();
    _coachCtrl.dispose();
    _amyInputCtrl.dispose();
    _dictLookupCtrl.dispose();
    _ltCheckCtrl.dispose();
    _vocabSearchCtrl.dispose();
    if (_amyListening) SpeechBridge.stopDictation();
    SpeechBridge.stopSpeaking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eco = ref.watch(ecosystemProvider);
    final audio = ref.watch(audioServiceProvider);
    final activeStage = EnglishOpenSourceService.curriculum.firstWhere(
      (m) => m.level == _cefr,
      orElse: () => EnglishOpenSourceService.curriculum[2],
    );
    final activeCourse = EnglishOpenSourceService.courseForLevel(_cefr);

    final dailyPool = eco.dailyVocab.where((w) => w.cefrLevel == _cefr).toList();
    final featuredDaily5 =
        (dailyPool.length >= 5 ? dailyPool : eco.dailyVocab).take(5).toList();
    final masteredCount = eco.dailyVocab.where((w) => w.mastered).length;

    return Scaffold(
      appBar: AppBar(title: const Text('YITTÉ ENGLISH CLUB')),
      body: YitteAuroraBackdrop(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const YitteReveal(
              order: 0,
              child: EditorialHeroBanner(
                eyebrow: 'PROGRAMME RIGOUREUX A1–C2 • PRATIQUE ORALE AVEC AMY',
                accentColor: YitteDomainAccents.english,
                title: 'Maîtrise de l’Anglais — 12 Semaines',
                subtitle:
                    'Parlez en direct avec Amy (voix féminine UK/US), suivez le plan d’étude 4 compétences (Listening · Speaking · Reading · Writing), le correcteur LanguageTool et le dictionnaire complet MIT.',
              ),
            ),
            const SizedBox(height: 12),
            SegmentedButton<int>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                textStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
              ),
              segments: const [
                ButtonSegment(value: 0, label: Text('Pratique')),
                ButtonSegment(value: 1, label: Text('Amy (Oral)')),
                ButtonSegment(value: 2, label: Text('Dictionnaire')),
                ButtonSegment(value: 3, label: Text('Programme A1–C2')),
              ],
              selected: {_activeTab},
              onSelectionChanged: (s) {
                setState(() => _activeTab = s.first);
                if (s.first == 2 && _dictEntry == null && !_lookingUpDict) {
                  _performDictionaryLookup(_dictLookupCtrl.text);
                }
              },
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _variant,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Variante'),
                    items: const [
                      DropdownMenuItem(value: 'en-GB', child: Text('British (en-GB)')),
                      DropdownMenuItem(value: 'en-US', child: Text('American (en-US)')),
                    ],
                    onChanged: (v) => setState(() {
                      _variant = v ?? 'en-GB';
                      _amyVoiceProfile =
                          _variant == 'en-GB' ? 'amy-soft-uk' : 'amy-fluent-us';
                    }),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _cefr,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Niveau CEFR'),
                    items: const ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']
                        .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                        .toList(),
                    onChanged: (v) => setState(() => _cefr = v ?? 'B1'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (_activeTab == 0)
              ..._buildPracticeAndDailyTab(
                context,
                eco,
                audio,
                activeStage,
                activeCourse,
                featuredDaily5,
                masteredCount,
              )
            else if (_activeTab == 1)
              ..._buildAmyConversationTab(context)
            else if (_activeTab == 2)
              ..._buildOpenDictionaryTab(context, eco, audio, masteredCount)
            else
              ..._buildStructuredCurriculumTab(context, activeCourse),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildPracticeAndDailyTab(
    BuildContext context,
    EcosystemState eco,
    AudioService audio,
    CefrStageModule activeStage,
    ConcreteEnglishCourse activeCourse,
    List<dynamic> featuredDaily5,
    int masteredCount,
  ) {
    final stageDone = activeStage.orderedSteps
        .asMap()
        .keys
        .where((i) => _completedStepIds.contains('${activeStage.level}_$i'))
        .length;

    return [
      // Accès direct à Amy (Professeure IA féminine vocale)
      Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: YitteColors.emerald,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: YitteColors.gold, width: 1),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: YitteColors.gold,
                border: Border.all(color: YitteColors.ivory, width: 1),
              ),
              child: const Center(
                child: Text(
                  'A',
                  style: TextStyle(
                    fontFamily: YitteFonts.display,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: YitteColors.inkDark,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Parler en direct avec Amy (IA)',
                    style: TextStyle(
                      color: YitteColors.ivory,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'Voix féminine UK/US • 6 scénarios • Correction en direct',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: YitteColors.ivory.withValues(alpha: 0.8),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: YitteColors.gold,
                foregroundColor: YitteColors.inkDark,
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              onPressed: () {
                setState(() => _activeTab = 1);
                if (_amyAutoSpeak && _amyMessages.isNotEmpty) {
                  final lastIdx = _amyMessages.lastIndexWhere((m) => m.fromAmy);
                  if (lastIdx >= 0) {
                    final m = _amyMessages[lastIdx];
                    _speakAsAmy(
                      m.englishText,
                      messageIdx: lastIdx,
                      bundledAssetPath: m.bundledAssetPath,
                    );
                  }
                }
              },
              child: const Text('Parler →'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 10),
      YitteSurfaceCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        onTap: () => setState(() => _activeTab = 3),
        child: Row(
          children: [
            const YitteIconBadge(
              icon: Icons.menu_book_outlined,
              color: YitteDomainAccents.english,
              size: 38,
              iconSize: 19,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    activeCourse.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                  ),
                  Text(
                    '$stageDone/${activeStage.orderedSteps.length} étapes • Programme 12 semaines A1→C2',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11.5),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
      const SizedBox(height: 12),
      SectionHeader(
        title: 'A. 5 Mots Quotidiens',
        actionLabel: 'Dictionnaire Complet',
        onAction: () {
          setState(() => _activeTab = 2);
          if (_dictEntry == null && !_lookingUpDict) {
            _performDictionaryLookup(_dictLookupCtrl.text);
          }
        },
      ),
      const SizedBox(height: 8),
      ...featuredDaily5.map(
        (w) => YitteSurfaceCard(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    '${w.word} (${w.partOfSpeech})',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 6),
                YitteStatusPill(label: w.cefrLevel),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 2, bottom: 4),
                  child: Text(
                    _variant == 'en-GB' ? w.phoneticUk : w.phoneticUs,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
                Text(
                  '${w.definitionEn}\nFR : ${w.definitionFr}\nEx : "${w.exampleEn}"',
                ),
              ],
            ),
            isThreeLine: false,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Écouter la prononciation ($_variant)',
                  icon: const Icon(Icons.volume_up_rounded),
                  onPressed: () => _speakAsAmy('${w.word}. ${w.exampleEn}'),
                ),
                IconButton(
                  tooltip: w.mastered
                      ? 'Maîtrisé ($masteredCount/${eco.dailyVocab.length})'
                      : 'Marquer comme acquis',
                  icon: Icon(
                    w.mastered
                        ? Icons.check_circle_rounded
                        : Icons.check_circle_outline_rounded,
                    color: w.mastered ? YitteColors.success : null,
                  ),
                  onPressed: () => ref
                      .read(ecosystemProvider.notifier)
                      .toggleVocabMastered(w.id),
                ),
              ],
            ),
          ),
        ),
      ),
      const SizedBox(height: 18),
      const SectionHeader(title: 'B, D, J. Pratique Orale & Évaluation IA (100 pts)'),
      const SizedBox(height: 8),
      ConsentVoiceRecorderCard(
        audioService: audio,
        prefix: 'english_club',
        consentGranted: _consent,
        speechLocale: _variant,
        onConsentChanged: (v) => setState(() => _consent = v),
        onLiveTranscript: (t) => setState(() => _speechCtrl.text = t),
        onRecorded: (path, sec) {
          if (path != null && _speechCtrl.text.trim().isEmpty && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Audio enregistré (${sec}s). Réécoutez ou saisissez/dictez le texte à évaluer.',
                ),
              ),
            );
          }
        },
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _speechCtrl,
        maxLines: 3,
        decoration: const InputDecoration(
          labelText: 'Votre prise de parole en anglais (transcript / exercice)',
          hintText: 'Speak or enter your English response...',
        ),
      ),
      const SizedBox(height: 10),
      ElevatedButton.icon(
        onPressed: _busy
            ? null
            : () async {
                if (_speechCtrl.text.trim().isEmpty) return;
                setState(() => _busy = true);
                await ref.read(ecosystemProvider.notifier).evaluateEnglishSpeech(
                      prompt: activeStage.oralTask,
                      transcript: _speechCtrl.text.trim(),
                      variant: _variant,
                      cefrLevel: _cefr,
                    );
                if (mounted) setState(() => _busy = false);
              },
        icon: const Icon(Icons.auto_fix_high_rounded),
        label: const Text('Analyser avec YITTE_ENGLISH_COACH'),
      ),
      if (eco.lastEnglishEval != null) ...[
        const SizedBox(height: 12),
        YitteSurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Score Global : ${eco.lastEnglishEval!.totalScore.toStringAsFixed(0)} / 100',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 10),
              RubricBar(label: 'Grammar', score: eco.lastEnglishEval!.grammar, maxScore: 20),
              RubricBar(label: 'Vocabulary', score: eco.lastEnglishEval!.vocabulary, maxScore: 20),
              RubricBar(label: 'Fluency', score: eco.lastEnglishEval!.fluency, maxScore: 20),
              RubricBar(
                label: 'Intelligibility (Accent-Fair)',
                score: eco.lastEnglishEval!.intelligibility,
                maxScore: 20,
              ),
              RubricBar(label: 'Coherence', score: eco.lastEnglishEval!.coherence, maxScore: 20),
              ...eco.lastEnglishEval!.correctedSentences.map(
                (s) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    children: [
                      Expanded(child: Text('✓ $s')),
                      IconButton(
                        tooltip: 'Écouter la phrase corrigée',
                        visualDensity: VisualDensity.compact,
                        icon: const Icon(Icons.volume_up_rounded, size: 18),
                        onPressed: () => _speakAsAmy(s),
                      ),
                    ],
                  ),
                ),
              ),
              ...eco.lastEnglishEval!.naturalExpressions
                  .map((e) => Text('• Natural expression: $e')),
              if (eco.lastEnglishEval!.suggestedVocabulary.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: eco.lastEnglishEval!.suggestedVocabulary
                      .map((w) => Chip(label: Text(w)))
                      .toList(),
                ),
              ],
              if (eco.lastEnglishEval!.exercises.isNotEmpty) ...[
                const SizedBox(height: 10),
                const Text(
                  'Exercices personnalisés :',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                ...eco.lastEnglishEval!.exercises.map(
                  (ex) => Padding(
                    padding: const EdgeInsets.only(bottom: 3),
                    child: Text('→ $ex', style: const TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
      const SizedBox(height: 18),
      const SectionHeader(title: 'C. AI English Coach & F. Grammaire'),
      const SizedBox(height: 8),
      YitteSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Quiz Rapide (${_grammarIdx + 1}/${_grammarDrills.length}) : ${_grammarDrills[_grammarIdx].question}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _grammarIdx = (_grammarIdx + 1) % _grammarDrills.length;
                    _grammarFeedback = '';
                  }),
                  child: const Text('Suivant'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _grammarDrills[_grammarIdx].options.map((opt) {
                return ActionChip(
                  label: Text(opt),
                  onPressed: () {
                    final d = _grammarDrills[_grammarIdx];
                    setState(() {
                      _grammarFeedback = opt == d.answer
                          ? 'Correct ! ${d.explain}'
                          : 'Pas tout à fait. ${d.explain}';
                    });
                  },
                );
              }).toList(),
            ),
            if (_grammarFeedback.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(_grammarFeedback,
                  style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ],
        ),
      ),
      const SizedBox(height: 12),
      YitteSurfaceCard(
        borderColor: YitteDomainAccents.english.withValues(alpha: 0.3),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const YitteIconBadge(
                  icon: Icons.school_rounded,
                  color: YitteDomainAccents.english,
                  size: 38,
                  iconSize: 19,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Coach Anglais Interactif (LanguageTool Open-Source)',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      Text(
                        'Collez une phrase anglaise à corriger en direct OU cliquez sur une leçon rapide :',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _coachQuickTopics
                  .map(
                    (topic) => ActionChip(
                      label: Text(topic, style: const TextStyle(fontSize: 12)),
                      onPressed: () {
                        _coachCtrl.text = topic;
                        _askCoach(topic);
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _coachCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Poser une question à YITTE_ENGLISH_COACH ou coller un texte EN à corriger',
                hintText: 'Ex. "For vs Since" ou "Yesterday I have went to the meeting and discuss about..."',
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _coachLoading ? null : () => _askCoach(_coachCtrl.text),
              icon: const Icon(Icons.auto_awesome_rounded, size: 18),
              label: Text(_coachLoading ? 'Analyse en cours...' : 'Demander au Coach'),
            ),
            if (_coachReply != null) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: YitteDomainAccents.english.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: YitteDomainAccents.english.withValues(alpha: 0.25),
                  ),
                ),
                child: Text(_coachReply!, style: const TextStyle(height: 1.48)),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 18),
      const SectionHeader(title: 'G, H, I. Débats Anglais, Salles CEFR & Vocab Battle'),
      const SizedBox(height: 8),
      YitteSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Vocabulary Battle ($_cefr • $_vocabXp XP) : ${_vocabDrills[_vocabIdx].prompt}',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton(
                  onPressed: () => setState(() {
                    _vocabIdx = (_vocabIdx + 1) % _vocabDrills.length;
                    _vocabFeedback = '';
                  }),
                  child: const Text('Mot suivant'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _vocabDrills[_vocabIdx]
                  .options
                  .map(
                    (word) => ActionChip(
                      label: Text(word),
                      onPressed: () {
                        final v = _vocabDrills[_vocabIdx];
                        _speakAsAmy(word);
                        setState(() {
                          if (word == v.answer) {
                            _vocabXp += 25;
                            _vocabFeedback = '+25 XP ! ${v.note}';
                          } else {
                            _vocabFeedback = 'Indications : ${v.note}';
                          }
                        });
                      },
                    ),
                  )
                  .toList(),
            ),
            if (_vocabFeedback.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                _vocabFeedback,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 10),
      const SectionHeader(title: 'E, J. Leçons & Défi Oral de la Semaine'),
      const SizedBox(height: 8),
      ...eco.englishLessons.map(
        (l) => YitteSurfaceCard(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l.title, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('${l.cefrLevel} • ${l.variant}\n${l.contentMarkdown}'),
            isThreeLine: true,
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildOpenDictionaryTab(
    BuildContext context,
    EcosystemState eco,
    AudioService audio,
    int masteredCount,
  ) {
    final q = _vocabQuery.trim().toLowerCase();
    final filteredVocab = eco.dailyVocab.where((w) {
      final levelOk = _vocabCefrFilter == 'Tous' || w.cefrLevel == _vocabCefrFilter;
      if (!levelOk) return false;
      if (q.isEmpty) return true;
      return w.word.toLowerCase().contains(q) ||
          w.definitionFr.toLowerCase().contains(q) ||
          w.definitionEn.toLowerCase().contains(q);
    }).toList();

    return [
      const SectionHeader(title: 'Dictionnaire Open-Source en direct (Free Dictionary API / Wiktionary)'),
      const SizedBox(height: 8),
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _dictLookupCtrl,
              onSubmitted: _performDictionaryLookup,
              decoration: const InputDecoration(
                labelText: 'Rechercher n’importe quel mot anglais',
                hintText: 'ex. agronomy, resilience, algorithm, methodology...',
                prefixIcon: Icon(Icons.menu_book_rounded),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _lookingUpDict
                ? null
                : () => _performDictionaryLookup(_dictLookupCtrl.text),
            icon: const Icon(Icons.search_rounded),
            label: const Text('Chercher'),
          ),
        ],
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 6,
        runSpacing: 6,
        children: ['resilience', 'agronomy', 'integrity', 'hypothesis', 'catalyst']
            .map(
              (sample) => ActionChip(
                label: Text(sample),
                onPressed: () {
                  _dictLookupCtrl.text = sample;
                  _performDictionaryLookup(sample);
                },
              ),
            )
            .toList(),
      ),
      if (_lookingUpDict)
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Center(child: CircularProgressIndicator()),
        ),
      if (_dictError != null)
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Text(_dictError!, style: const TextStyle(color: YitteColors.danger)),
        ),
      if (_dictEntry != null)
        YitteSurfaceCard(
          margin: const EdgeInsets.only(top: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_dictEntry!.word}  ${_dictEntry!.phonetic}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () =>
                        _playOpenDictPronunciation(audio, _dictEntry!),
                    icon: const Icon(Icons.volume_up_rounded),
                    label: Text(
                      _dictEntry!.preferredAudioFor(_variant) != null
                          ? 'Audio natif ($_variant)'
                          : 'Synthèse vocale',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ..._dictEntry!.meanings.map(
                (m) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      YitteStatusPill(label: m.partOfSpeech),
                      const SizedBox(height: 4),
                      ...m.definitions.map(
                        (def) => Padding(
                          padding: const EdgeInsets.only(bottom: 3),
                          child: Text('• $def', style: const TextStyle(fontSize: 13.5)),
                        ),
                      ),
                      if (m.examples.isNotEmpty)
                        Text(
                          'Ex : "${m.examples.first}"',
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                            fontSize: 12.5,
                          ),
                        ),
                      if (m.synonyms.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            'Synonymes : ${m.synonyms.join(", ")}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      const SizedBox(height: 18),
      const SectionHeader(title: 'Correcteur Grammatical Open-Source (LanguageTool LGPL en direct)'),
      const SizedBox(height: 8),
      YitteSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _ltCheckCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Écrivez ou collez un paragraphe anglais à vérifier',
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _checkingLt ? null : _runLanguageToolCheck,
              icon: const Icon(Icons.spellcheck_rounded),
              label: Text(
                _checkingLt ? 'Vérification LanguageTool...' : 'Corriger avec LanguageTool Open-Source',
              ),
            ),
            if (_ltResult != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  YitteStatusPill(
                    label: _ltResult!.usedOnlineApi
                        ? 'LanguageTool en direct'
                        : 'Moteur hors-ligne FR→EN',
                  ),
                  const SizedBox(width: 8),
                  YitteStatusPill(
                    label: '${_ltResult!.issues.length} remarque(s)',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '✅ ${_ltResult!.correctedText}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Écouter la version corrigée',
                    icon: const Icon(Icons.volume_up_rounded),
                    onPressed: () => _speakAsAmy(_ltResult!.correctedText),
                  ),
                ],
              ),
              ..._ltResult!.issues.map(
                (i) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '• [${i.category}] "${i.badText}" → ${i.replacements.isNotEmpty ? i.replacements.join(" / ") : "(à revoir)"} : ${i.message}',
                    style: const TextStyle(fontSize: 12.5),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
      const SizedBox(height: 18),
      SectionHeader(
        title: 'Lexique CEFR Essentiel ($masteredCount maîtrisé(s))',
      ),
      const SizedBox(height: 8),
      TextField(
        controller: _vocabSearchCtrl,
        onChanged: (v) => setState(() => _vocabQuery = v),
        decoration: InputDecoration(
          hintText: 'Filtrer la banque locale (mot EN ou traduction FR)...',
          prefixIcon: const Icon(Icons.filter_list_rounded),
          suffixIcon: _vocabQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  onPressed: () {
                    _vocabSearchCtrl.clear();
                    setState(() => _vocabQuery = '');
                  },
                )
              : null,
        ),
      ),
      const SizedBox(height: 8),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: ['Tous', 'A1', 'A2', 'B1', 'B2', 'C1', 'C2']
              .map(
                (lvl) => Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                    label: Text(lvl),
                    selected: _vocabCefrFilter == lvl,
                    onSelected: (_) => setState(() => _vocabCefrFilter = lvl),
                  ),
                ),
              )
              .toList(),
        ),
      ),
      const SizedBox(height: 10),
      ...filteredVocab.map(
        (w) => YitteSurfaceCard(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    '${w.word} (${w.partOfSpeech})',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                YitteStatusPill(label: w.cefrLevel),
              ],
            ),
            subtitle: Text(
              '${_variant == "en-GB" ? w.phoneticUk : w.phoneticUs}\n${w.definitionEn}\nFR : ${w.definitionFr}',
            ),
            isThreeLine: true,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.travel_explore_rounded),
                  tooltip: 'Chercher sur Free Dictionary API',
                  onPressed: () {
                    _dictLookupCtrl.text = w.word;
                    _performDictionaryLookup(w.word);
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.volume_up_rounded),
                  onPressed: () => _speakAsAmy('${w.word}. ${w.exampleEn}'),
                ),
                IconButton(
                  icon: Icon(
                    w.mastered
                        ? Icons.check_circle_rounded
                        : Icons.check_circle_outline_rounded,
                    color: w.mastered ? YitteColors.success : null,
                  ),
                  onPressed: () =>
                      ref.read(ecosystemProvider.notifier).toggleVocabMastered(w.id),
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildStructuredCurriculumTab(
    BuildContext context,
    ConcreteEnglishCourse activeCourse,
  ) {
    final totalSteps = EnglishOpenSourceService.curriculum
        .fold<int>(0, (sum, m) => sum + m.orderedSteps.length);
    return [
      YitteSurfaceCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Procédure Complète A1 → C2',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(
              '${_completedStepIds.length} / $totalSteps étapes validées • Sélectionnez un niveau pour ouvrir le cours concret complet (règles, pièges FR→EN, dialogue audio et exercices).',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']
                    .map(
                      (lvl) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: ChoiceChip(
                          label: Text('Cours $lvl'),
                          selected: _cefr == lvl,
                          onSelected: (_) => setState(() => _cefr = lvl),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      // CONCRETE INTERACTIVE COURSE FOR SELECTED LEVEL
      YitteSurfaceCard(
        borderColor: YitteDomainAccents.english.withValues(alpha: 0.4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                YitteStatusPill(label: 'COURS ${activeCourse.level}'),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    activeCourse.title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(activeCourse.summaryFr, style: Theme.of(context).textTheme.bodyMedium),
            const Divider(height: 20),
            const Text('1. Règles essentielles', style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            ...activeCourse.coreRules.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Text('• $r', style: const TextStyle(fontSize: 13.5, height: 1.4)),
              ),
            ),
            const Divider(height: 20),
            const Text('2. Pièges francophones : À éviter vs Naturel',
                style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            ...activeCourse.comparisons.map(
              (row) => Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(row.avoid,
                        style: const TextStyle(
                            color: YitteColors.danger, fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(row.natural,
                        style: const TextStyle(
                            color: YitteColors.success, fontWeight: FontWeight.w700, fontSize: 13.5)),
                    const SizedBox(height: 2),
                    Text(row.explanationFr, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ),
            const Divider(height: 20),
            Row(
              children: [
                const Expanded(
                  child: Text('3. Dialogue concret (Audio)',
                      style: TextStyle(fontWeight: FontWeight.w800)),
                ),
                FilledButton.tonalIcon(
                  onPressed: () {
                    final fullScript =
                        activeCourse.dialogue.map((l) => l.english).join(' ');
                    _speakAsAmy(fullScript);
                  },
                  icon: const Icon(Icons.volume_up_rounded, size: 18),
                  label: const Text('Tout écouter'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...activeCourse.dialogue.map(
              (line) => ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  '${line.speaker} : "${line.english}"',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
                subtitle: Text(line.french, style: const TextStyle(fontSize: 12)),
                trailing: IconButton(
                  tooltip: 'Écouter cette réplique',
                  icon: const Icon(Icons.play_circle_outline_rounded),
                  onPressed: () => _speakAsAmy(line.english),
                ),
              ),
            ),
            const Divider(height: 20),
            const Text('4. Exercices immédiats corrigés',
                style: TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            ...activeCourse.exercises.asMap().entries.map((entry) {
              final key = '${activeCourse.level}_${entry.key}';
              final ex = entry.value;
              final fb = _courseQuizFeedback[key];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ex.question, style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: ex.options
                          .map(
                            (opt) => ActionChip(
                              label: Text(opt),
                              onPressed: () {
                                setState(() {
                                  _courseQuizFeedback[key] = opt == ex.answer
                                      ? '✅ Bravo ! ${ex.explanation}'
                                      : '❌ Réponse attendue : "${ex.answer}". ${ex.explanation}';
                                });
                              },
                            ),
                          )
                          .toList(),
                    ),
                    if (fb != null) ...[
                      const SizedBox(height: 4),
                      Text(fb, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                    ],
                  ],
                ),
              );
            }),
          ],
        ),
      ),
      const SizedBox(height: 14),
      const SectionHeader(title: 'Programme Rigoureux — 12 Semaines (4 Compétences)'),
      const SizedBox(height: 8),
      ...EnglishOpenSourceService.twelveWeekMasteryPlan.map(
        (phase) => YitteSurfaceCard(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  YitteStatusPill(label: phase.phaseCode),
                  const SizedBox(width: 6),
                  YitteStatusPill(label: phase.cefr),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      phase.title,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                phase.dailyRoutineFr,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
              ),
              const SizedBox(height: 8),
              Text('• Listening : ${phase.listeningGoal}',
                  style: Theme.of(context).textTheme.bodySmall),
              Text('• Speaking : ${phase.speakingGoal}',
                  style: Theme.of(context).textTheme.bodySmall),
              Text('• Reading : ${phase.readingGoal}',
                  style: Theme.of(context).textTheme.bodySmall),
              Text('• Writing : ${phase.writingGoal}',
                  style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
      const SizedBox(height: 14),
      const SectionHeader(title: 'Feuille de route & Suivi par Palier (A1 → C2)'),
      const SizedBox(height: 8),
      ...EnglishOpenSourceService.curriculum.map(
        (stage) => YitteSurfaceCard(
          margin: const EdgeInsets.only(bottom: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  YitteStatusPill(label: stage.level),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      stage.title,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(stage.objective, style: Theme.of(context).textTheme.bodyMedium),
              const SizedBox(height: 6),
              ...stage.orderedSteps.asMap().entries.map((entry) {
                final stepId = '${stage.level}_${entry.key}';
                return CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  value: _completedStepIds.contains(stepId),
                  onChanged: (_) => _toggleStepCompleted(stepId),
                  title: Text(entry.value, style: const TextStyle(fontSize: 13)),
                );
              }),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonalIcon(
                  onPressed: () {
                    setState(() {
                      _cefr = stage.level;
                      _activeTab = 0;
                    });
                  },
                  icon: const Icon(Icons.mic_rounded, size: 18),
                  label: Text('Pratiquer l’oral ${stage.level}'),
                ),
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 14),
      const SectionHeader(title: 'Verbes Irréguliers Clés (Base • Prétérit • Participe)'),
      const SizedBox(height: 8),
      YitteSurfaceCard(
        child: Column(
          children: EnglishOpenSourceService.irregularVerbs
              .map(
                (v) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${v.base}  →  ${v.past}  →  ${v.participle}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                  ),
                  subtitle: Text(v.french),
                  trailing: IconButton(
                    icon: const Icon(Icons.volume_up_rounded),
                    onPressed: () =>
                        _speakAsAmy('${v.base}, ${v.past}, ${v.participle}'),
                  ),
                ),
              )
              .toList(),
        ),
      ),
      const SizedBox(height: 14),
      const SectionHeader(title: 'Cours Complets Open-Source & Plateformes Exploitées'),
      const SizedBox(height: 8),
      ...EnglishOpenSourceService.openPortals.map(
        (p) => YitteSurfaceCard(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.w700)),
            subtitle: Text('${p.licenseOrAccess}\n${p.summary}'),
            isThreeLine: true,
            trailing: IconButton(
              tooltip: 'Ouvrir le cours externe',
              icon: const Icon(Icons.open_in_new_rounded),
              onPressed: () => ExternalLinkBridge.openUrl(p.url),
            ),
          ),
        ),
      ),
    ];
  }

  /// Onglet 1 : Conversation Orale & Lecture Fluide avec Amy (inspiré d'English AI).
  List<Widget> _buildAmyConversationTab(BuildContext context) {
    final tokens = AppTheme.tokensOf(context);
    final scenarios = EnglishOpenSourceService.amyScenarios;
    final active = scenarios[_amyScenarioIdx.clamp(0, scenarios.length - 1)];

    const voiceProfiles = [
      (id: 'amy-fluent-us', label: 'Amy Fluide (Ava · US)'),
      (id: 'amy-soft-uk', label: 'Amy Douce (Libby · UK)'),
      (id: 'amy-clear-uk', label: 'Amy Claire (Sonia · UK)'),
    ];
    const speeds = [
      (rate: 0.78, label: '0.8× Lent'),
      (rate: 0.96, label: '1.0× Fluide'),
      (rate: 1.14, label: '1.15× Natif'),
    ];

    return [
      // Carte Studio Vocale Amy (Émeraude & Or 1px — façon English AI)
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: YitteColors.emerald,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: YitteColors.gold, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: YitteColors.gold,
                    border: Border.all(
                      color: _amySpeaking ? YitteColors.ivory : YitteColors.gold,
                      width: _amySpeaking ? 2.2 : 1.2,
                    ),
                  ),
                  child: Center(
                    child: _amySpeaking
                        ? const Icon(
                            Icons.graphic_eq_rounded,
                            size: 22,
                            color: YitteColors.inkDark,
                          )
                        : const Text(
                            'A',
                            style: TextStyle(
                              fontFamily: YitteFonts.display,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: YitteColors.inkDark,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Amy — Coach IA Vocale',
                        style: TextStyle(
                          fontFamily: YitteFonts.display,
                          color: YitteColors.ivory,
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        _amySpeaking
                            ? 'Amy parle • $_amyVoiceEngineLabel'
                            : '$_amyVoiceEngineLabel • Touchez un mot pour l’écouter',
                        style: TextStyle(
                          color: YitteColors.ivory.withValues(alpha: 0.84),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: _amySpeaking ? 'Arrêter la lecture' : 'Écouter Amy',
                  onPressed: () {
                    if (_amySpeaking) {
                      SpeechBridge.stopSpeaking();
                      return;
                    }
                    final lastIdx = _amyMessages.lastIndexWhere((m) => m.fromAmy);
                    if (lastIdx >= 0) {
                      final m = _amyMessages[lastIdx];
                      _speakAsAmy(
                        m.englishText,
                        messageIdx: lastIdx,
                        bundledAssetPath: m.bundledAssetPath,
                      );
                    } else {
                      _speakAsAmy(
                        active.openingEn,
                        bundledAssetPath: active.openingAssetPath,
                      );
                    }
                  },
                  icon: Icon(
                    _amySpeaking
                        ? Icons.stop_circle_outlined
                        : Icons.volume_up_rounded,
                    color: YitteColors.gold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            // Sélecteur de Voix Féminine Neurale
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: voiceProfiles.map((vp) {
                  final selected = _amyVoiceProfile == vp.id;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      selected: selected,
                      showCheckmark: false,
                      visualDensity: VisualDensity.compact,
                      selectedColor: YitteColors.gold,
                      backgroundColor: Colors.white.withValues(alpha: 0.08),
                      side: BorderSide(
                        color: selected
                            ? YitteColors.gold
                            : YitteColors.ivory.withValues(alpha: 0.28),
                      ),
                      label: Text(
                        vp.label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? YitteColors.inkDark
                              : YitteColors.ivory,
                        ),
                      ),
                      onSelected: (_) {
                        setState(() {
                          _amyVoiceProfile = vp.id;
                          _variant = vp.id.endsWith('-uk') ? 'en-GB' : 'en-US';
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            // Vitesse fluide (0.8× / 1.0× / 1.15×) + Voix auto
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                ...speeds.map((sp) {
                  final sel = (_amyRate - sp.rate).abs() < 0.05;
                  return ChoiceChip(
                    selected: sel,
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    selectedColor: YitteColors.ivory,
                    backgroundColor: Colors.white.withValues(alpha: 0.08),
                    side: BorderSide(
                      color: YitteColors.ivory.withValues(alpha: 0.25),
                    ),
                    label: Text(
                      sp.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: sel ? YitteColors.emerald : YitteColors.ivory,
                      ),
                    ),
                    onSelected: (_) => setState(() => _amyRate = sp.rate),
                  );
                }),
                FilterChip(
                  selected: _amyAutoSpeak,
                  showCheckmark: false,
                  visualDensity: VisualDensity.compact,
                  selectedColor: YitteColors.gold,
                  backgroundColor: Colors.white.withValues(alpha: 0.08),
                  side: BorderSide(
                    color: YitteColors.ivory.withValues(alpha: 0.25),
                  ),
                  label: Text(
                    _amyAutoSpeak ? 'Auto : ON' : 'Auto : OFF',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _amyAutoSpeak
                          ? YitteColors.inkDark
                          : YitteColors.ivory,
                    ),
                  ),
                  onSelected: (v) => setState(() => _amyAutoSpeak = v),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),

      // Sélecteur des 6 Scénarios de pratique orale
      Text(
        'SCÉNARIO DE PRATIQUE AVEC AMY',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
      ),
      const SizedBox(height: 6),
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: scenarios.asMap().entries.map((entry) {
            final idx = entry.key;
            final sc = entry.value;
            final selected = idx == _amyScenarioIdx;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                selected: selected,
                showCheckmark: false,
                selectedColor: YitteColors.emerald,
                visualDensity: VisualDensity.compact,
                label: Text('${sc.titleFr} (${sc.levelRange})'),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? YitteColors.ivory
                      : Theme.of(context).colorScheme.onSurface,
                ),
                onSelected: (_) => _resetAmyScenario(idx),
              ),
            );
          }).toList(),
        ),
      ),
      const SizedBox(height: 10),

      // Mini-dictionnaire instantané lorsqu'un mot est touché dans le texte d'Amy (façon English AI)
      if (_tappedWord != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: YitteSurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            color: tokens.goldSurface,
            borderColor: tokens.borderAccent,
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Réécouter le mot',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _speakAsAmy(_tappedWord!, overrideRate: 0.86),
                  icon: const Icon(
                    Icons.volume_up_rounded,
                    size: 18,
                    color: YitteColors.emerald,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _tappedWord!,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      Text(
                        _tappedWordLoading
                            ? 'Chargement de la phonétique & définition...'
                            : (_tappedWordInfo ?? ''),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Fermer',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => setState(() => _tappedWord = null),
                  icon: const Icon(Icons.close_rounded, size: 17),
                ),
              ],
            ),
          ),
        ),

      // Fil de dialogue interactif façon English AI (lecture synchronisée mot-à-mot + traduction + répétition)
      ..._amyMessages.asMap().entries.map((entry) {
        final msgIdx = entry.key;
        final m = entry.value;
        final isThisSpeaking = _amySpeaking && _speakingMessageIdx == msgIdx;
        final showFr = _revealedTranslations.contains(msgIdx);
        final words = m.englishText
            .trim()
            .split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty)
            .toList();

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: YitteSurfaceCard(
            padding: const EdgeInsets.all(13),
            color: m.fromAmy ? tokens.elevated : tokens.subtleFill,
            borderColor: isThisSpeaking
                ? YitteColors.emerald
                : (m.fromAmy ? tokens.borderAccent : tokens.borderSubtle),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      m.fromAmy ? 'AMY (COACH IA)' : 'VOUS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.1,
                        color: m.fromAmy
                            ? tokens.goldAccent
                            : Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    if (m.fluencyScore != null && m.fluencyScore! > 0) ...[
                      const SizedBox(width: 8),
                      YitteStatusPill(label: 'Fluidité ${m.fluencyScore}/100'),
                    ],
                    const Spacer(),
                    if (isThisSpeaking)
                      const YitteStatusPill(
                        icon: Icons.graphic_eq_rounded,
                        label: 'Lecture en cours',
                      ),
                  ],
                ),
                const SizedBox(height: 8),

                // Lecture synchronisée mot-à-mot (chaque mot cliquable pour écoute & définition)
                if (m.fromAmy)
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: words.asMap().entries.map((wEntry) {
                      final wIdx = wEntry.key;
                      final wText = wEntry.value;
                      final highlighted =
                          isThisSpeaking && _speakingWordIdx == wIdx;
                      return GestureDetector(
                        onTap: () => _tapWordInAmyMessage(wText),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 3,
                            vertical: 1,
                          ),
                          decoration: highlighted
                              ? BoxDecoration(
                                  color: YitteColors.emerald,
                                  borderRadius: BorderRadius.circular(4),
                                )
                              : null,
                          child: Text(
                            wText,
                            style: Theme.of(context)
                                .textTheme
                                .bodyLarge
                                ?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                  color: highlighted
                                      ? YitteColors.ivory
                                      : Theme.of(context).colorScheme.onSurface,
                                ),
                          ),
                        ),
                      );
                    }).toList(),
                  )
                else
                  Text(
                    m.englishText,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),

                // Barre d'actions English AI sous chaque bulle d'Amy : Écouter • Lent • Traduire • Répéter
                if (m.fromAmy) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          textStyle: const TextStyle(fontSize: 11.5),
                        ),
                        onPressed: () => _speakAsAmy(
                          m.englishText,
                          messageIdx: msgIdx,
                          bundledAssetPath: m.bundledAssetPath,
                        ),
                        icon: const Icon(Icons.volume_up_outlined, size: 15),
                        label: const Text('Écouter'),
                      ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          textStyle: const TextStyle(fontSize: 11.5),
                        ),
                        onPressed: () => _speakAsAmy(
                          m.englishText,
                          messageIdx: msgIdx,
                          overrideRate: 0.78,
                          bundledAssetPath: m.bundledAssetPath,
                        ),
                        icon: const Icon(Icons.slow_motion_video_rounded, size: 15),
                        label: const Text('Lent'),
                      ),
                      if (m.frenchNote != null && m.frenchNote!.isNotEmpty)
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 9,
                              vertical: 4,
                            ),
                            textStyle: const TextStyle(fontSize: 11.5),
                          ),
                          onPressed: () => setState(() {
                            if (showFr) {
                              _revealedTranslations.remove(msgIdx);
                            } else {
                              _revealedTranslations.add(msgIdx);
                            }
                          }),
                          icon: const Icon(Icons.translate_rounded, size: 15),
                          label: Text(showFr ? 'Masquer FR' : 'Traduire'),
                        ),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          textStyle: const TextStyle(fontSize: 11.5),
                        ),
                        onPressed: () {
                          setState(() {
                            _shadowingTarget = m.englishText;
                            _shadowingEval = null;
                          });
                          _speakAsAmy(
                            m.englishText,
                            messageIdx: msgIdx,
                            overrideRate: 0.85,
                            bundledAssetPath: m.bundledAssetPath,
                          );
                        },
                        icon: const Icon(Icons.record_voice_over_outlined, size: 15),
                        label: const Text('Répéter'),
                      ),
                    ],
                  ),
                ],

                if (showFr && m.frenchNote != null && m.frenchNote!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    m.frenchNote!,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],

                if (m.correctionNote != null && m.correctionNote!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: tokens.goldSurface,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: tokens.borderAccent),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          m.correctionNote!,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                        if (m.correctedText != null &&
                            m.correctedText!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: TextButton.icon(
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                padding: EdgeInsets.zero,
                              ),
                              onPressed: () => _speakAsAmy(m.correctedText!),
                              icon: const Icon(Icons.volume_up_outlined, size: 16),
                              label: const Text('Écouter la version corrigée'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                if (m.nativeUpgrade != null && m.nativeUpgrade!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Version native : "${m.nativeUpgrade!}"',
                          style: TextStyle(
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Écouter la version native',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _speakAsAmy(m.nativeUpgrade!),
                        icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        );
      }),

      if (_amyBusy)
        const Padding(
          padding: EdgeInsets.only(bottom: 10),
          child: YitteLoadingBanner(
            message: 'Amy analyse votre phrase et prépare sa réponse...',
          ),
        ),

      // Mode Shadowing / Répétition guidée mot-à-mot (façon English AI)
      if (_shadowingTarget != null)
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: YitteSurfaceCard(
            borderColor: YitteColors.emerald,
            padding: const EdgeInsets.all(13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.record_voice_over_rounded,
                      size: 18,
                      color: YitteColors.emerald,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'MODE RÉPÉTITION (SHADOWING)',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              letterSpacing: 1.1,
                              fontWeight: FontWeight.w700,
                              color: YitteColors.emerald,
                            ),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      onPressed: () => setState(() {
                        _shadowingTarget = null;
                        _shadowingEval = null;
                      }),
                      child: const Text('Quitter'),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Répétez à voix haute au micro :',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  '« $_shadowingTarget »',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                if (_shadowingEval != null) ...[
                  const SizedBox(height: 10),
                  YitteStatusPill(
                    label: 'Prononciation : ${_shadowingEval!.scorePercent}%',
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: _shadowingEval!.wordResults.map((wr) {
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: wr.matched
                              ? YitteColors.emeraldSoft
                              : tokens.goldSurface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: wr.matched
                                ? YitteColors.emerald
                                : tokens.goldAccent,
                          ),
                        ),
                        child: Text(
                          wr.word,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: wr.matched
                                ? YitteColors.emerald
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _shadowingEval!.feedbackFr,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),

      // Idées de réponse guidées (façon English AI : "Aide-moi à répondre")
      if (_amyHints.isNotEmpty && _shadowingTarget == null) ...[
        Row(
          children: [
            Expanded(
              child: Text(
                'IDÉES DE RÉPONSE (AIDE ORALE)',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            TextButton(
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              onPressed: () => setState(() => _showAmyHints = !_showAmyHints),
              child: Text(_showAmyHints ? 'Masquer' : 'Afficher'),
            ),
          ],
        ),
        if (_showAmyHints) ...[
          const SizedBox(height: 4),
          ..._amyHints.map(
            (hint) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: tokens.elevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: tokens.borderSubtle),
                ),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Écouter cette suggestion',
                      visualDensity: VisualDensity.compact,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => _speakAsAmy(hint),
                      icon: const Icon(
                        Icons.volume_up_outlined,
                        size: 17,
                        color: YitteColors.emerald,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _amyInputCtrl.text = hint;
                          setState(() {});
                        },
                        child: Text(
                          hint,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.onSurface,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                      ),
                      onPressed: () => _sendToAmy(hint),
                      child: const Text('Utiliser'),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
        ],
      ],

      // Zone Micro & Saisie orientée voix (façon English AI)
      YitteSurfaceCard(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _amyInputCtrl,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: _shadowingTarget != null
                    ? 'Parlez au micro pour évaluer votre répétition'
                    : 'Parlez au micro ou répondez à Amy en anglais',
                hintText:
                    'Ex : Hello Amy, I joined BOROOM YITTÉ in 2026 to master English.',
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _amyListening
                        ? YitteColors.danger
                        : YitteColors.gold,
                    foregroundColor: _amyListening
                        ? Colors.white
                        : YitteColors.inkDark,
                  ),
                  onPressed: () {
                    if (_amyListening) {
                      SpeechBridge.stopDictation();
                      setState(() => _amyListening = false);
                      return;
                    }
                    SpeechBridge.stopSpeaking();
                    final started = SpeechBridge.startDictation(
                      locale: _amyVoiceProfile.endsWith('-uk')
                          ? 'en-GB'
                          : 'en-US',
                      onTranscript: (t) {
                        if (!mounted) return;
                        setState(() => _amyInputCtrl.text = t);
                      },
                      onError: (err) {
                        if (!mounted) return;
                        setState(() => _amyListening = false);
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(err)));
                      },
                    );
                    if (started) {
                      setState(() => _amyListening = true);
                    }
                  },
                  icon: Icon(
                    _amyListening
                        ? Icons.stop_circle_outlined
                        : Icons.mic_rounded,
                    size: 18,
                  ),
                  label: Text(_amyListening ? 'Arrêter' : 'Parler'),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _amyBusy
                        ? null
                        : () => _sendToAmy(_amyInputCtrl.text),
                    icon: Icon(
                      _shadowingTarget != null
                          ? Icons.check_circle_outline_rounded
                          : Icons.send_rounded,
                      size: 17,
                    ),
                    label: Text(
                      _shadowingTarget != null
                          ? 'Vérifier prononciation'
                          : 'Répondre à Amy',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ];
  }
}

class _AmyChatMessage {
  final bool fromAmy;
  final String englishText;
  final String? frenchNote;
  final String? correctionNote;
  final String? correctedText;
  final String? nativeUpgrade;
  final int? fluencyScore;
  final String? bundledAssetPath;

  const _AmyChatMessage({
    required this.fromAmy,
    required this.englishText,
    this.frenchNote,
    this.correctionNote,
    this.correctedText,
    this.nativeUpgrade,
    this.fluencyScore,
    this.bundledAssetPath,
  });
}
