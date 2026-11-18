import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/state/app_providers.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/backend_repository.dart';
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

  int _activeTab = 0; // 0 = Parcours & Oral, 1 = Dico Open-Source, 2 = Programme A1-C2
  String _variant = 'en-GB';
  String _cefr = 'B1';
  bool _consent = false;
  final _speechCtrl = TextEditingController();
  final _coachCtrl = TextEditingController();
  final _dictLookupCtrl = TextEditingController(text: 'resilience');
  final _vocabSearchCtrl = TextEditingController();
  String _vocabQuery = '';
  String _vocabCefrFilter = 'Tous';
  String? _coachReply;
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
  Set<String> _completedStepIds = {};

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

  Future<void> _playOpenDictPronunciation(
    AudioService audio,
    OpenDictionaryEntry entry,
  ) async {
    final audioUrl = entry.preferredAudioFor(_variant);
    if (audioUrl != null && audioUrl.isNotEmpty) {
      await audio.playFile(
        audioUrl,
        onError: (_) => SpeechBridge.speak(entry.word, locale: _variant),
      );
      return;
    }
    SpeechBridge.speak(entry.word, locale: _variant);
  }

  @override
  void dispose() {
    _speechCtrl.dispose();
    _coachCtrl.dispose();
    _dictLookupCtrl.dispose();
    _vocabSearchCtrl.dispose();
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

    final dailyPool = eco.dailyVocab.where((w) => w.cefrLevel == _cefr).toList();
    final featuredDaily5 =
        (dailyPool.length >= 5 ? dailyPool : eco.dailyVocab).take(5).toList();
    final masteredCount = eco.dailyVocab.where((w) => w.mastered).length;

    return Scaffold(
      appBar: AppBar(title: const Text('YITTÉ ENGLISH CLUB')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const YitteReveal(
            order: 0,
            child: EditorialHeroBanner(
              eyebrow: 'PROGRAMME STRUCTURÉ A1–C2 • DICO OPEN-SOURCE MIT',
              accentColor: YitteDomainAccents.english,
              title: 'Speak Clearly, Think Globally',
              subtitle:
                  'Parcours progressif par paliers CEFR (A1 → C2), dictionnaire open-source Free Dictionary API (IPA + audio natif UK/US) et coach IA bienveillant sur 100 points.',
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 0, label: Text('Parcours & Oral')),
              ButtonSegment(value: 1, label: Text('Dico Open-Source')),
              ButtonSegment(value: 2, label: Text('Programme A1–C2')),
            ],
            selected: {_activeTab},
            onSelectionChanged: (s) {
              setState(() => _activeTab = s.first);
              if (s.first == 1 && _dictEntry == null && !_lookingUpDict) {
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
                  onChanged: (v) => setState(() => _variant = v ?? 'en-GB'),
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
          const SizedBox(height: 16),
          if (_activeTab == 0)
            ..._buildPracticeAndDailyTab(
              context,
              eco,
              audio,
              activeStage,
              featuredDaily5,
              masteredCount,
            )
          else if (_activeTab == 1)
            ..._buildOpenDictionaryTab(context, eco, audio, masteredCount)
          else
            ..._buildStructuredCurriculumTab(context),
        ],
      ),
    );
  }

  List<Widget> _buildPracticeAndDailyTab(
    BuildContext context,
    EcosystemState eco,
    AudioService audio,
    CefrStageModule activeStage,
    List<dynamic> featuredDaily5,
    int masteredCount,
  ) {
    final stageDone = activeStage.orderedSteps
        .asMap()
        .keys
        .where((i) => _completedStepIds.contains('${activeStage.level}_$i'))
        .length;

    return [
      YitteSurfaceCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                '${activeStage.level} ($stageDone/${activeStage.orderedSteps.length} étapes) • ${activeStage.focusGrammar}',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
            ),
            TextButton(
              onPressed: () => setState(() => _activeTab = 2),
              child: const Text('Programme →'),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      SectionHeader(
        title: 'A. 5 Mots Quotidiens',
        actionLabel: 'Dico Open-Source (${eco.dailyVocab.length})',
        onAction: () {
          setState(() => _activeTab = 1);
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
                  onPressed: () => SpeechBridge.speak(
                    '${w.word}. ${w.exampleEn}',
                    locale: _variant,
                  ),
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
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                          onPressed: () => SpeechBridge.speak(s, locale: _variant),
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
        ),
      ],
      const SizedBox(height: 18),
      const SectionHeader(title: 'C. AI English Coach & F. Grammaire'),
      const SizedBox(height: 8),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
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
      ),
      const SizedBox(height: 10),
      TextField(
        controller: _coachCtrl,
        decoration: const InputDecoration(
          labelText: 'Poser une question à YITTE_ENGLISH_COACH',
        ),
      ),
      const SizedBox(height: 8),
      OutlinedButton(
        onPressed: () async {
          if (_coachCtrl.text.trim().isEmpty) return;
          final reply = await BackendRepository.instance.callAiAgent(
            agentName: 'YITTE_ENGLISH_COACH',
            prompt: '($_variant, $_cefr) ${_coachCtrl.text.trim()}',
            language: 'en',
          );
          if (mounted) setState(() => _coachReply = reply);
        },
        child: const Text('Demander au Coach'),
      ),
      if (_coachReply != null)
        Card(
          margin: const EdgeInsets.only(top: 8),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Text(_coachReply!),
          ),
        ),
      const SizedBox(height: 18),
      const SectionHeader(title: 'G, H, I. Débats Anglais, Salles CEFR & Vocab Battle'),
      const SizedBox(height: 8),
      Card(
        child: Padding(
          padding: const EdgeInsets.all(14),
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
                          SpeechBridge.speak(word, locale: _variant);
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
      ),
      const SizedBox(height: 10),
      const SectionHeader(title: 'E, J. Leçons & Défi Oral de la Semaine'),
      const SizedBox(height: 8),
      ...eco.englishLessons.map(
        (l) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
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
      SectionHeader(
        title: 'Banque CEFR Hors-Ligne (${eco.dailyVocab.length} mots • $masteredCount maîtrisé(s))',
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
                    '${w.word} (${w.partOfSpeech}) • ${_variant == "en-GB" ? w.phoneticUk : w.phoneticUs}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                YitteStatusPill(label: w.cefrLevel),
              ],
            ),
            subtitle: Text('${w.definitionEn}\nFR : ${w.definitionFr}\nEx : "${w.exampleEn}"'),
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
                  onPressed: () =>
                      SpeechBridge.speak('${w.word}. ${w.exampleEn}', locale: _variant),
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

  List<Widget> _buildStructuredCurriculumTab(BuildContext context) {
    final totalSteps = EnglishOpenSourceService.curriculum
        .fold<int>(0, (sum, m) => sum + m.orderedSteps.length);
    return [
      YitteSurfaceCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Procédure Complète A1 → C2',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_completedStepIds.length} / $totalSteps étapes validées • Suivez chaque palier dans l’ordre : Phonétique → Grammaire → Lexique → Oral.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
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
              const SizedBox(height: 4),
              Text(
                'Grammaire : ${stage.focusGrammar}',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
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
              const SizedBox(height: 4),
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
                    onPressed: () => SpeechBridge.speak(
                      '${v.base}, ${v.past}, ${v.participle}',
                      locale: _variant,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      ),
      const SizedBox(height: 14),
      const SectionHeader(title: 'Plateformes Open-Source & Cours Gratuits Vérifiés'),
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
              tooltip: 'Ouvrir le site externe',
              icon: const Icon(Icons.open_in_new_rounded),
              onPressed: () => ExternalLinkBridge.openUrl(p.url),
            ),
          ),
        ),
      ),
    ];
  }
}
