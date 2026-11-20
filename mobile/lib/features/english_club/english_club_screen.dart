import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app/state/app_providers.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/english_learna_curriculum.dart';
import '../../core/services/english_open_source_service.dart';
import '../../core/services/speech_bridge.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/editorial_widgets.dart';

class EnglishClubScreen extends ConsumerStatefulWidget {
  const EnglishClubScreen({super.key});

  @override
  ConsumerState<EnglishClubScreen> createState() => _EnglishClubScreenState();
}

class _EnglishClubScreenState extends ConsumerState<EnglishClubScreen> {
  static const _completedLessonsPrefKey = 'yitte_learna_completed_lessons_v2';
  static const _cefrPrefKey = 'yitte_learna_cefr_v2';

  // 0 = Discuter (Amy), 1 = Cours (A1–C2), 2 = Vocabulaire
  int _activeTab = 0;
  String _cefr = 'B1';
  String _voiceProfile = 'amy-soft-uk'; // amy-soft-uk (UK) | amy-fluent-us (US)
  double _speechRate = 0.96; // 0.96 (Fluide) | 0.78 (Lent)

  // Conversation naturelle avec Amy (façon Learna AI)
  int _topicIdx = 0;
  LearnaTopic? _customLessonTopic;
  final _chatInputCtrl = TextEditingController();
  final _chatScrollCtrl = ScrollController();
  bool _amyBusy = false;
  bool _listening = false;
  bool _amySpeaking = false;
  int? _speakingMsgIdx;
  int _speakingWordIdx = -1;
  bool _showHelpDrawer = false;
  List<String> _currentHints = const [];
  final Set<int> _revealedTranslations = {};
  final List<_ChatBubble> _messages = [];
  final List<int> _turnScores = [];
  int _solidTurnsAtLevel = 0;

  // Mini-dictionnaire au clic sur un mot d'Amy
  String? _tappedWord;
  String? _tappedWordDef;
  bool _tappedWordLoading = false;

  // Cours interactifs (18 leçons A1 → C2)
  LearnaLesson? _openLesson;
  Set<String> _completedLessonIds = {};
  final Map<String, String> _lessonQuizFeedback = {};

  // Vocabulaire & recherche de mots
  final _dictCtrl = TextEditingController();
  final _service = EnglishOpenSourceService();
  bool _searchingWord = false;
  OpenDictionaryEntry? _dictEntry;
  String? _dictError;

  LearnaTopic get _activeTopic =>
      _customLessonTopic ??
      EnglishLearnaCurriculum.naturalTopics[
          _topicIdx.clamp(0, EnglishLearnaCurriculum.naturalTopics.length - 1)];

  String get _activeLocale =>
      _voiceProfile.endsWith('-uk') ? 'en-GB' : 'en-US';

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _startTopic(0, speakNow: false);
  }

  @override
  void dispose() {
    _chatInputCtrl.dispose();
    _chatScrollCtrl.dispose();
    _dictCtrl.dispose();
    if (_listening) SpeechBridge.stopDictation();
    SpeechBridge.stopSpeaking();
    super.dispose();
  }

  Future<void> _loadProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLessons = prefs.getStringList(_completedLessonsPrefKey);
    final savedCefr = prefs.getString(_cefrPrefKey);
    if (!mounted) return;
    setState(() {
      if (savedLessons != null) _completedLessonIds = savedLessons.toSet();
      if (savedCefr != null &&
          EnglishOpenSourceService.cefrLevelsOrdered.contains(savedCefr)) {
        _cefr = savedCefr;
      }
    });
  }

  Future<void> _saveCefr(String level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cefrPrefKey, level);
  }

  Future<void> _toggleLessonCompleted(String lessonId) async {
    final next = Set<String>.from(_completedLessonIds);
    if (next.contains(lessonId)) {
      next.remove(lessonId);
    } else {
      next.add(lessonId);
    }
    setState(() => _completedLessonIds = next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_completedLessonsPrefKey, next.toList());
  }

  void _speakFluid(
    String text, {
    int? msgIdx,
    double? overrideRate,
  }) {
    SpeechBridge.speak(
      text,
      locale: _activeLocale,
      rate: overrideRate ?? _speechRate,
      preferFemale: true,
      voiceProfile: _voiceProfile,
      onSpeakingChanged: (speaking) {
        if (!mounted) return;
        setState(() {
          _amySpeaking = speaking;
          if (!speaking) {
            _speakingMsgIdx = null;
            _speakingWordIdx = -1;
          } else {
            _speakingMsgIdx = msgIdx;
          }
        });
      },
      onWordIndex: (wordIdx) {
        if (!mounted) return;
        setState(() {
          _speakingMsgIdx = msgIdx;
          _speakingWordIdx = wordIdx;
        });
      },
    );
  }

  void _startTopic(int index, {bool speakNow = true}) {
    final topics = EnglishLearnaCurriculum.naturalTopics;
    final topic = topics[index.clamp(0, topics.length - 1)];
    SpeechBridge.stopSpeaking();
    setState(() {
      _topicIdx = index.clamp(0, topics.length - 1);
      _customLessonTopic = null;
      _showHelpDrawer = false;
      _tappedWord = null;
      _tappedWordDef = null;
      _currentHints = topic.starterHintsEn;
      _revealedTranslations.clear();
      _messages
        ..clear()
        ..add(
          _ChatBubble(
            fromAmy: true,
            englishText: topic.openingEn,
            frenchTranslation: topic.openingFr,
          ),
        );
    });
    if (speakNow) {
      _speakFluid(topic.openingEn, msgIdx: 0);
    }
  }

  void _practiceLessonWithAmy(LearnaLesson lesson) {
    final custom = LearnaTopic(
      id: 'lesson_${lesson.id}',
      titleFr: lesson.titleFr,
      subtitleFr: 'Mise en pratique ${lesson.level}',
      levelRange: lesson.level,
      openingEn: lesson.amyPracticeOpeningEn,
      openingFr: lesson.amyPracticeIntroFr,
      followUpsEn: [
        "That's a great example! Could you add one more detail using the same structure?",
        "You're getting much more natural with this! How would you use that in your own daily life?",
      ],
      starterHintsEn: lesson.dialogue
          .where((d) => d.speaker == 'You')
          .map((d) => d.english)
          .take(3)
          .toList(),
    );
    SpeechBridge.stopSpeaking();
    setState(() {
      _cefr = lesson.level;
      _customLessonTopic = custom;
      _openLesson = null;
      _activeTab = 0;
      _showHelpDrawer = false;
      _tappedWord = null;
      _currentHints = custom.starterHintsEn;
      _revealedTranslations.clear();
      _messages
        ..clear()
        ..add(
          _ChatBubble(
            fromAmy: true,
            englishText: custom.openingEn,
            frenchTranslation: custom.openingFr,
          ),
        );
    });
    _saveCefr(lesson.level);
    _speakFluid(custom.openingEn, msgIdx: 0);
  }

  Future<void> _tapWord(String rawWord) async {
    final clean = rawWord.replaceAll(RegExp(r"[^a-zA-Z'-]"), '').trim();
    if (clean.isEmpty) return;
    _speakFluid(clean, overrideRate: 0.86);
    setState(() {
      _tappedWord = clean;
      _tappedWordDef = null;
      _tappedWordLoading = true;
    });
    try {
      final entry = await _service.lookupWord(clean.toLowerCase());
      if (!mounted || _tappedWord != clean) return;
      if (entry != null && entry.meanings.isNotEmpty) {
        final def = entry.meanings.first.definitions.isNotEmpty
            ? entry.meanings.first.definitions.first
            : '';
        final phon = entry.phonetic.isNotEmpty ? '${entry.phonetic} • ' : '';
        setState(() {
          _tappedWordLoading = false;
          _tappedWordDef = '$phon$def';
        });
      } else {
        setState(() {
          _tappedWordLoading = false;
          _tappedWordDef = 'Mot prononcé par Amy.';
        });
      }
    } catch (_) {
      if (!mounted || _tappedWord != clean) return;
      setState(() {
        _tappedWordLoading = false;
        _tappedWordDef = 'Mot prononcé par Amy.';
      });
    }
  }

  Future<void> _sendMessage(String raw) async {
    final text = raw.trim();
    if (text.isEmpty || _amyBusy) return;
    if (_listening) {
      SpeechBridge.stopDictation();
      _listening = false;
    }

    final topic = _activeTopic;
    final history = _messages
        .map((m) => (fromAmy: m.fromAmy, text: m.englishText))
        .toList();
    final userTurns = _messages.where((m) => !m.fromAmy).length;
    final userBubbleIdx = _messages.length;

    setState(() {
      _messages.add(_ChatBubble(fromAmy: false, englishText: text));
      _chatInputCtrl.clear();
      _showHelpDrawer = false;
      _amyBusy = true;
    });
    _scrollChatToBottom();

    final reply = await _service.converseWithAmy(
      userInput: text,
      scenario: topic.toAmyScenario(),
      turnIndex: userTurns,
      variant: _activeLocale,
      cefrLevel: _cefr,
      history: history,
    );
    if (!mounted) return;

    final amyMsgIdx = _messages.length;
    setState(() {
      _amyBusy = false;
      // Attache le feedback Learna AI proprement sous la bulle de l'utilisateur
      _messages[userBubbleIdx] = _messages[userBubbleIdx].copyWith(
        correctedText: reply.correctedText,
        coachingTipFr: reply.correctionNote,
        nativeUpgrade: reply.nativeUpgrade,
        fluencyScore: reply.fluencyScore,
      );
      if (reply.fluencyScore > 0) {
        _turnScores.add(reply.fluencyScore);
        if (reply.fluencyScore >= 80) _solidTurnsAtLevel++;
      }
      if (reply.suggestedRepliesEn.isNotEmpty) {
        _currentHints = reply.suggestedRepliesEn;
      }
      _messages.add(
        _ChatBubble(
          fromAmy: true,
          englishText: reply.amySpeechEn,
          frenchTranslation: reply.amyTranslationFr,
        ),
      );
    });
    _scrollChatToBottom();
    _speakFluid(reply.amySpeechEn, msgIdx: amyMsgIdx);
  }

  void _scrollChatToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScrollCtrl.hasClients) {
        _chatScrollCtrl.animateTo(
          _chatScrollCtrl.position.maxScrollExtent + 140,
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _levelUpCefr() {
    final next = EnglishOpenSourceService.nextCefrLevel(_cefr);
    if (next == null) return;
    setState(() {
      _cefr = next;
      _solidTurnsAtLevel = 0;
    });
    _saveCefr(next);
    const msgFr =
        'Bravo ! Amy adapte maintenant ses questions et expressions à votre nouveau niveau.';
    final msgEn =
        "Awesome job — you've just moved up to level $next! I'll naturally step up our conversation from here. What would you like to talk about next?";
    final idx = _messages.length;
    setState(() {
      _messages.add(
        _ChatBubble(
          fromAmy: true,
          englishText: msgEn,
          frenchTranslation: msgFr,
        ),
      );
    });
    _scrollChatToBottom();
    _speakFluid(msgEn, msgIdx: idx);
  }

  Future<void> _lookupDictionary(String query) async {
    final clean = query.trim();
    if (clean.isEmpty) return;
    setState(() {
      _searchingWord = true;
      _dictError = null;
    });
    try {
      final entry = await _service.lookupWord(clean);
      if (!mounted) return;
      setState(() {
        _searchingWord = false;
        _dictEntry = entry;
        _dictError = entry == null ? 'Mot « $clean » introuvable.' : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _searchingWord = false;
        _dictError = 'Recherche indisponible hors ligne.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.tokensOf(context);
    final eco = ref.watch(ecosystemProvider);
    final audio = ref.watch(audioServiceProvider);

    return Scaffold(
      backgroundColor: tokens.canvas,
      appBar: AppBar(
        title: const Text('ENGLISH STUDIO'),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Changer votre niveau d’anglais',
            onSelected: (lvl) {
              setState(() {
                _cefr = lvl;
                _solidTurnsAtLevel = 0;
              });
              _saveCefr(lvl);
            },
            itemBuilder: (context) => EnglishOpenSourceService.cefrLevelsOrdered
                .map(
                  (lvl) => PopupMenuItem<String>(
                    value: lvl,
                    child: Text(
                      'Niveau $lvl${lvl == _cefr ? " ✓" : ""}',
                      style: TextStyle(
                        fontWeight:
                            lvl == _cefr ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                  ),
                )
                .toList(),
            child: Container(
              margin: const EdgeInsets.only(right: 14),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: YitteColors.emerald,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: YitteColors.gold, width: 1),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Niveau $_cefr',
                    style: const TextStyle(
                      color: YitteColors.ivory,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: YitteColors.gold,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Barre 3 onglets épurée (façon Learna AI : Discuter • Cours • Vocabulaire)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: tokens.elevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: tokens.borderSubtle),
              ),
              child: Row(
                children: [
                  _StudioTabButton(
                    icon: Icons.forum_outlined,
                    label: 'Discuter',
                    active: _activeTab == 0,
                    onTap: () => setState(() => _activeTab = 0),
                  ),
                  _StudioTabButton(
                    icon: Icons.school_outlined,
                    label: 'Cours',
                    active: _activeTab == 1,
                    onTap: () => setState(() => _activeTab = 1),
                  ),
                  _StudioTabButton(
                    icon: Icons.menu_book_outlined,
                    label: 'Vocabulaire',
                    active: _activeTab == 2,
                    onTap: () => setState(() => _activeTab = 2),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: switch (_activeTab) {
              0 => _buildLearnaChatTab(context),
              1 => _buildCoursesTab(context),
              _ => _buildVocabularyTab(context, eco, audio),
            },
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ONGLET 0 : DISCUTER EN DIRECT AVEC AMY (INSPIRÉ DE LEARNA AI)
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildLearnaChatTab(BuildContext context) {
    final tokens = AppTheme.tokensOf(context);
    final topics = EnglishLearnaCurriculum.naturalTopics;
    final nextLevel = EnglishOpenSourceService.nextCefrLevel(_cefr);
    final isUk = _voiceProfile.endsWith('-uk');
    final isSlow = _speechRate < 0.85;

    return Column(
      children: [
        // 1. Barre compacte Amy (1 seule ligne propre : Avatar + Sujet + Accent UK/US + Vitesse + Audio)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: YitteColors.emerald,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: YitteColors.gold, width: 1),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: YitteColors.gold,
                    border: Border.all(
                      color: _amySpeaking ? YitteColors.ivory : YitteColors.gold,
                      width: _amySpeaking ? 2 : 1,
                    ),
                  ),
                  child: Center(
                    child: _amySpeaking
                        ? const Icon(
                            Icons.graphic_eq_rounded,
                            size: 18,
                            color: YitteColors.inkDark,
                          )
                        : const Text(
                            'A',
                            style: TextStyle(
                              fontFamily: YitteFonts.display,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                              color: YitteColors.inkDark,
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amy • ${_activeTopic.titleFr}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: YitteColors.ivory,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.5,
                        ),
                      ),
                      Text(
                        _amySpeaking
                            ? 'Amy vous parle…'
                            : 'Touchez un mot pour l’écouter',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: YitteColors.ivory.withValues(alpha: 0.78),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                // Accent UK / US compact
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () => setState(() {
                    _voiceProfile = isUk ? 'amy-fluent-us' : 'amy-soft-uk';
                  }),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isUk ? 'UK' : 'US',
                      style: const TextStyle(
                        color: YitteColors.ivory,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                // Vitesse 1x / 0.8x compacte
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: () =>
                      setState(() => _speechRate = isSlow ? 0.96 : 0.78),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isSlow
                          ? YitteColors.gold
                          : Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isSlow ? '0.8×' : '1×',
                      style: TextStyle(
                        color:
                            isSlow ? YitteColors.inkDark : YitteColors.ivory,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                IconButton(
                  tooltip: _amySpeaking ? 'Arrêter' : 'Réécouter Amy',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  onPressed: () {
                    if (_amySpeaking) {
                      SpeechBridge.stopSpeaking();
                      return;
                    }
                    final lastAmy = _messages.lastIndexWhere((m) => m.fromAmy);
                    if (lastAmy >= 0) {
                      _speakFluid(
                        _messages[lastAmy].englishText,
                        msgIdx: lastAmy,
                      );
                    }
                  },
                  icon: Icon(
                    _amySpeaking
                        ? Icons.stop_circle_outlined
                        : Icons.volume_up_rounded,
                    color: YitteColors.gold,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),

        // 2. Sélecteur horizontal de sujets naturels (façon Learna AI)
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: topics.length,
            separatorBuilder: (_, _) => const SizedBox(width: 6),
            itemBuilder: (context, idx) {
              final t = topics[idx];
              final selected = _customLessonTopic == null && idx == _topicIdx;
              return ChoiceChip(
                selected: selected,
                showCheckmark: false,
                visualDensity: VisualDensity.compact,
                selectedColor: YitteColors.emerald,
                label: Text(t.titleFr),
                labelStyle: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? YitteColors.ivory
                      : Theme.of(context).colorScheme.onSurface,
                ),
                onSelected: (_) => _startTopic(idx),
              );
            },
          ),
        ),

        // 3. Barre discrète de progression CEFR (uniquement une fois la discussion lancée)
        if (_turnScores.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: tokens.elevated,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: tokens.borderSubtle),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      nextLevel != null
                          ? 'Progression $_cefr → $nextLevel : $_solidTurnsAtLevel/3 échanges fluides'
                          : 'Niveau $_cefr • Maîtrise confirmée',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  if (_solidTurnsAtLevel >= 3 && nextLevel != null)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: YitteColors.gold,
                        foregroundColor: YitteColors.inkDark,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                      ),
                      onPressed: _levelUpCefr,
                      child: Text('Passer en $nextLevel →'),
                    ),
                ],
              ),
            ),
          ),

        // 4. Mini-fiche mot cliqué
        if (_tappedWord != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: YitteSurfaceCard(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              color: tokens.goldSurface,
              borderColor: tokens.borderAccent,
              child: Row(
                children: [
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () =>
                        _speakFluid(_tappedWord!, overrideRate: 0.86),
                    icon: const Icon(
                      Icons.volume_up_rounded,
                      size: 18,
                      color: YitteColors.emerald,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _tappedWordLoading
                          ? '${_tappedWord!} …'
                          : '${_tappedWord!} — ${_tappedWordDef ?? ""}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                  IconButton(
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

        // 5. Fil de discussion naturel (façon Learna AI)
        Expanded(
          child: ListView.builder(
            controller: _chatScrollCtrl,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            itemCount: _messages.length + (_amyBusy ? 1 : 0),
            itemBuilder: (context, idx) {
              if (idx >= _messages.length) {
                return const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: YitteLoadingBanner(message: 'Amy prépare sa réponse…'),
                );
              }
              final m = _messages[idx];
              return m.fromAmy
                  ? _buildAmyBubble(context, m, idx, tokens)
                  : _buildUserBubble(context, m, tokens);
            },
          ),
        ),

        // 6. Tiroir d'aide optionnel (uniquement si l'utilisateur clique "Aide")
        if (_showHelpDrawer && _currentHints.isNotEmpty)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 6),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: tokens.elevated,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: tokens.borderAccent),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'IDÉES POUR RÉPONDRE',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w700,
                            color: tokens.goldAccent,
                          ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => setState(() => _showHelpDrawer = false),
                      child: const Icon(Icons.close_rounded, size: 16),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ..._currentHints.map(
                  (hint) => Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      children: [
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _speakFluid(hint),
                          icon: const Icon(
                            Icons.volume_up_outlined,
                            size: 16,
                            color: YitteColors.emerald,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () {
                              _chatInputCtrl.text = hint;
                              setState(() => _showHelpDrawer = false);
                            },
                            child: Text(
                              hint,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color:
                                        Theme.of(context).colorScheme.onSurface,
                                  ),
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

        // 7. Barre de saisie vocale & écrite (ancrée en bas, épurée)
        Container(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
          decoration: BoxDecoration(
            color: tokens.elevated,
            border: Border(top: BorderSide(color: tokens.borderSubtle)),
          ),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Idées de réponse',
                onPressed: () =>
                    setState(() => _showHelpDrawer = !_showHelpDrawer),
                icon: Icon(
                  Icons.lightbulb_outline_rounded,
                  color: _showHelpDrawer
                      ? tokens.goldAccent
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              Expanded(
                child: TextField(
                  controller: _chatInputCtrl,
                  minLines: 1,
                  maxLines: 3,
                  textInputAction: TextInputAction.send,
                  onSubmitted: _sendMessage,
                  decoration: const InputDecoration(
                    hintText: 'Répondez à Amy en anglais…',
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Bouton Micro direct
              Material(
                color: _listening ? YitteColors.danger : YitteColors.gold,
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: _listening ? 'Arrêter le micro' : 'Parler en anglais',
                  onPressed: () {
                    if (_listening) {
                      SpeechBridge.stopDictation();
                      setState(() => _listening = false);
                      return;
                    }
                    SpeechBridge.stopSpeaking();
                    final started = SpeechBridge.startDictation(
                      locale: _activeLocale,
                      onTranscript: (t) {
                        if (!mounted) return;
                        setState(() => _chatInputCtrl.text = t);
                      },
                      onError: (err) {
                        if (!mounted) return;
                        setState(() => _listening = false);
                        ScaffoldMessenger.of(context)
                            .showSnackBar(SnackBar(content: Text(err)));
                      },
                    );
                    if (started) setState(() => _listening = true);
                  },
                  icon: Icon(
                    _listening ? Icons.stop_rounded : Icons.mic_rounded,
                    size: 20,
                    color: _listening ? Colors.white : YitteColors.inkDark,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              // Bouton Envoyer
              Material(
                color: YitteColors.emerald,
                shape: const CircleBorder(),
                child: IconButton(
                  tooltip: 'Envoyer',
                  onPressed:
                      _amyBusy ? null : () => _sendMessage(_chatInputCtrl.text),
                  icon: const Icon(
                    Icons.arrow_upward_rounded,
                    size: 20,
                    color: YitteColors.ivory,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAmyBubble(
    BuildContext context,
    _ChatBubble m,
    int msgIdx,
    YitteSurfaceTokens tokens,
  ) {
    final isSpeakingThis = _amySpeaking && _speakingMsgIdx == msgIdx;
    final showFr = _revealedTranslations.contains(msgIdx);
    final words = m.englishText
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();

    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10, right: 24),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: tokens.elevated,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(14),
            bottomLeft: Radius.circular(14),
            bottomRight: Radius.circular(14),
          ),
          border: Border.all(
            color: isSpeakingThis ? YitteColors.emerald : tokens.borderSubtle,
            width: isSpeakingThis ? 1.4 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: words.asMap().entries.map((entry) {
                final wIdx = entry.key;
                final wText = entry.value;
                final active = isSpeakingThis && _speakingWordIdx == wIdx;
                return GestureDetector(
                  onTap: () => _tapWord(wText),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 2.5, vertical: 1),
                    decoration: active
                        ? BoxDecoration(
                            color: YitteColors.emerald,
                            borderRadius: BorderRadius.circular(4),
                          )
                        : null,
                    child: Text(
                      wText,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontSize: 15,
                            height: 1.38,
                            color: active
                                ? YitteColors.ivory
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                  ),
                );
              }).toList(),
            ),
            if (showFr &&
                m.frenchTranslation != null &&
                m.frenchTranslation!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Divider(height: 1, color: tokens.borderSubtle),
              const SizedBox(height: 6),
              Text(
                m.frenchTranslation!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                    ),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _MiniBubbleAction(
                  icon: Icons.volume_up_outlined,
                  label: 'Écouter',
                  onTap: () => _speakFluid(m.englishText, msgIdx: msgIdx),
                ),
                const SizedBox(width: 12),
                _MiniBubbleAction(
                  icon: Icons.slow_motion_video_rounded,
                  label: 'Lent',
                  onTap: () => _speakFluid(
                    m.englishText,
                    msgIdx: msgIdx,
                    overrideRate: 0.78,
                  ),
                ),
                if (m.frenchTranslation != null &&
                    m.frenchTranslation!.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  _MiniBubbleAction(
                    icon: Icons.translate_rounded,
                    label: showFr ? 'Masquer' : 'Traduire',
                    onTap: () => setState(() {
                      if (showFr) {
                        _revealedTranslations.remove(msgIdx);
                      } else {
                        _revealedTranslations.add(msgIdx);
                      }
                    }),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUserBubble(
    BuildContext context,
    _ChatBubble m,
    YitteSurfaceTokens tokens,
  ) {
    final hasFix = m.correctedText != null && m.correctedText!.isNotEmpty;
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10, left: 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
              decoration: BoxDecoration(
                color: YitteColors.emerald,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(4),
                  bottomLeft: Radius.circular(14),
                  bottomRight: Radius.circular(14),
                ),
              ),
              child: Text(
                m.englishText,
                style: const TextStyle(
                  color: YitteColors.ivory,
                  fontSize: 14.5,
                  height: 1.38,
                ),
              ),
            ),
            // Feedback Learna AI sobre juste sous la bulle de l'utilisateur
            if (hasFix || (m.nativeUpgrade != null && m.nativeUpgrade!.isNotEmpty))
              Container(
                margin: const EdgeInsets.only(top: 5),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: hasFix ? tokens.goldSurface : tokens.elevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: hasFix ? tokens.borderAccent : tokens.borderSubtle,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (hasFix) ...[
                      Row(
                        children: [
                          Text(
                            'MIEUX DIRE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                              color: tokens.goldAccent,
                            ),
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: () => _speakFluid(m.correctedText!),
                            child: const Icon(
                              Icons.volume_up_outlined,
                              size: 16,
                              color: YitteColors.emerald,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        m.correctedText!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: YitteColors.emerald,
                            ),
                      ),
                      if (m.coachingTipFr != null &&
                          m.coachingTipFr!.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text(
                          m.coachingTipFr!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ] else if (m.nativeUpgrade != null &&
                        m.nativeUpgrade!.isNotEmpty) ...[
                      Row(
                        children: [
                          const Text(
                            '✓ NATUREL • VERSION PLUS FLUIDE',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.9,
                              color: YitteColors.emerald,
                            ),
                          ),
                          const Spacer(),
                          InkWell(
                            onTap: () => _speakFluid(m.nativeUpgrade!),
                            child: const Icon(
                              Icons.volume_up_outlined,
                              size: 16,
                              color: YitteColors.emerald,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '"${m.nativeUpgrade!}"',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontStyle: FontStyle.italic,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                    ],
                  ],
                ),
              )
            else if (m.fluencyScore != null && m.fluencyScore! >= 80)
              Padding(
                padding: const EdgeInsets.only(top: 4, right: 4),
                child: Text(
                  '✓ Naturel',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: YitteColors.emerald,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ONGLET 1 : COURS STRUCTURÉS POUR SE PERFECTIONNER (18 LEÇONS A1 → C2)
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildCoursesTab(BuildContext context) {
    if (_openLesson != null) {
      return _buildLessonDetail(context, _openLesson!);
    }

    final tokens = AppTheme.tokensOf(context);
    final levelLessons = EnglishLearnaCurriculum.lessonsForLevel(_cefr);
    final totalDone = _completedLessonIds.length;
    final totalAll = EnglishLearnaCurriculum.lessons.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      children: [
        // Sélecteur de niveau CEFR (A1 → C2) + progression globale
        YitteSurfaceCard(
          padding: const EdgeInsets.all(14),
          borderColor: tokens.borderAccent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Parcours de perfectionnement',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  YitteStatusPill(label: '$totalDone / $totalAll'),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Choisissez votre niveau et suivez chaque leçon, puis pratiquez-la directement à l’oral avec Amy.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: EnglishOpenSourceService.cefrLevelsOrdered
                      .map((lvl) {
                    final sel = _cefr == lvl;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        selected: sel,
                        showCheckmark: false,
                        visualDensity: VisualDensity.compact,
                        selectedColor: YitteColors.emerald,
                        label: Text(lvl),
                        labelStyle: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: sel
                              ? YitteColors.ivory
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                        onSelected: (_) {
                          setState(() => _cefr = lvl);
                          _saveCefr(lvl);
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        Text(
          'LEÇONS NIVEAU $_cefr (${levelLessons.length} UNITÉS)',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),

        ...levelLessons.map((lesson) {
          final done = _completedLessonIds.contains(lesson.id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: YitteSurfaceCard(
              padding: const EdgeInsets.all(14),
              borderColor: done ? YitteColors.emerald : tokens.borderSubtle,
              onTap: () => setState(() => _openLesson = lesson),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: done ? YitteColors.emerald : tokens.subtleFill,
                      border: Border.all(
                        color: done ? YitteColors.gold : tokens.borderSubtle,
                      ),
                    ),
                    child: Center(
                      child: done
                          ? const Icon(
                              Icons.check_rounded,
                              size: 20,
                              color: YitteColors.ivory,
                            )
                          : Text(
                              '${lesson.unitNumber}',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: YitteColors.emerald,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          lesson.titleFr,
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${lesson.subtitleFr} • ${lesson.durationMin} min',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 20),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildLessonDetail(BuildContext context, LearnaLesson lesson) {
    final tokens = AppTheme.tokensOf(context);
    final done = _completedLessonIds.contains(lesson.id);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 36),
      children: [
        Row(
          children: [
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                visualDensity: VisualDensity.compact,
              ),
              onPressed: () => setState(() => _openLesson = null),
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text('Tous les cours'),
            ),
            const Spacer(),
            YitteStatusPill(label: '${lesson.level} • Unité ${lesson.unitNumber}'),
          ],
        ),
        const SizedBox(height: 10),

        YitteSurfaceCard(
          padding: const EdgeInsets.all(15),
          borderColor: tokens.borderAccent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                lesson.titleFr,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 4),
              Text(lesson.subtitleFr, style: Theme.of(context).textTheme.bodySmall),
              const Divider(height: 22),

              // 1. L'essentiel
              Text(
                '1. L’ESSENTIEL À MAÎTRISER',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w700,
                      color: tokens.goldAccent,
                    ),
              ),
              const SizedBox(height: 8),
              ...lesson.coreRules.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('• $r', style: const TextStyle(height: 1.42)),
                ),
              ),

              const Divider(height: 22),

              // 2. À éviter vs Naturel (avec écoute fluide)
              Text(
                '2. PIÈGES FRANCOPHONES : À ÉVITER VS NATUREL',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w700,
                      color: tokens.goldAccent,
                    ),
              ),
              const SizedBox(height: 8),
              ...lesson.traps.map(
                (row) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: tokens.subtleFill,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: tokens.borderSubtle),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              row.avoid,
                              style: const TextStyle(
                                color: YitteColors.danger,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              row.natural,
                              style: const TextStyle(
                                color: YitteColors.emerald,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              row.explanationFr,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Écouter la tournure naturelle',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _speakFluid(
                          row.natural.replaceAll('✅', '').trim(),
                        ),
                        icon: const Icon(
                          Icons.volume_up_outlined,
                          size: 19,
                          color: YitteColors.emerald,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 22),

              // 3. Dialogue audio naturel
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '3. DIALOGUE AUDIO',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            letterSpacing: 1.1,
                            fontWeight: FontWeight.w700,
                            color: tokens.goldAccent,
                          ),
                    ),
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => _speakFluid(
                      lesson.dialogue.map((d) => d.english).join(' '),
                    ),
                    icon: const Icon(Icons.volume_up_rounded, size: 16),
                    label: const Text('Tout écouter'),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ...lesson.dialogue.map(
                (line) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${line.speaker} : "${line.english}"',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                              ),
                            ),
                            Text(
                              line.french,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        onPressed: () => _speakFluid(line.english),
                        icon: const Icon(
                          Icons.play_circle_outline_rounded,
                          size: 19,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Divider(height: 22),

              // 4. Exercice immédiat corrigé
              Text(
                '4. VÉRIFICATION RAPIDE',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.1,
                      fontWeight: FontWeight.w700,
                      color: tokens.goldAccent,
                    ),
              ),
              const SizedBox(height: 8),
              ...lesson.quiz.asMap().entries.map((entry) {
                final qKey = '${lesson.id}_${entry.key}';
                final q = entry.value;
                final fb = _lessonQuizFeedback[qKey];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        q.question,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: q.options.map((opt) {
                          return ActionChip(
                            label: Text(opt),
                            onPressed: () {
                              setState(() {
                                _lessonQuizFeedback[qKey] = opt == q.answer
                                    ? '✓ Exact ! ${q.explanation}'
                                    : 'À revoir : la bonne réponse est « ${q.answer} ». ${q.explanation}';
                              });
                            },
                          );
                        }).toList(),
                      ),
                      if (fb != null) ...[
                        const SizedBox(height: 5),
                        Text(
                          fb,
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: fb.startsWith('✓')
                                ? YitteColors.emerald
                                : YitteColors.danger,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),

              const SizedBox(height: 6),
              // CTA signature Learna AI : appliquer la leçon en discutant en direct avec Amy !
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: YitteColors.gold,
                    foregroundColor: YitteColors.inkDark,
                  ),
                  onPressed: () => _practiceLessonWithAmy(lesson),
                  icon: const Icon(Icons.forum_outlined, size: 18),
                  label: const Text('Pratiquer cette leçon avec Amy →'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _toggleLessonCompleted(lesson.id),
                  icon: Icon(
                    done
                        ? Icons.check_circle_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 18,
                  ),
                  label: Text(
                    done ? 'Leçon validée ✓' : 'Marquer cette leçon comme terminée',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ONGLET 2 : VOCABULAIRE & DICTIONNAIRE RAPIDE (ÉPURÉ, ZÉRO JARGON)
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildVocabularyTab(
    BuildContext context,
    EcosystemState eco,
    AudioService audio,
  ) {
    final tokens = AppTheme.tokensOf(context);
    final levelPool = eco.dailyVocab.where((w) => w.cefrLevel == _cefr).toList();
    final displayedWords = levelPool.isNotEmpty ? levelPool : eco.dailyVocab;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 36),
      children: [
        // Recherche instantanée de n'importe quel mot anglais
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _dictCtrl,
                onSubmitted: _lookupDictionary,
                decoration: const InputDecoration(
                  hintText: 'Chercher un mot anglais (ex. fluent, achieve)…',
                  prefixIcon: Icon(Icons.search_rounded),
                  isDense: true,
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: _searchingWord
                  ? null
                  : () => _lookupDictionary(_dictCtrl.text),
              child: const Text('Chercher'),
            ),
          ],
        ),
        if (_searchingWord)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (_dictError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _dictError!,
              style: const TextStyle(color: YitteColors.danger),
            ),
          ),
        if (_dictEntry != null)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: YitteSurfaceCard(
              borderColor: tokens.borderAccent,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${_dictEntry!.word}  ${_dictEntry!.phonetic}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Écouter la prononciation',
                        onPressed: () {
                          final url = _dictEntry!.preferredAudioFor(_activeLocale);
                          if (url != null && url.isNotEmpty) {
                            audio.playFile(
                              url,
                              onError: (_) => _speakFluid(_dictEntry!.word),
                            );
                          } else {
                            _speakFluid(_dictEntry!.word);
                          }
                        },
                        icon: const Icon(
                          Icons.volume_up_rounded,
                          color: YitteColors.emerald,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ..._dictEntry!.meanings.take(2).map(
                        (m) => Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              YitteStatusPill(label: m.partOfSpeech),
                              const SizedBox(height: 4),
                              ...m.definitions.take(2).map(
                                    (d) => Text(
                                      '• $d',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                            ],
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 16),
        Text(
          'MOTS ESSENTIELS — NIVEAU $_cefr',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        ...displayedWords.map(
          (w) => YitteSurfaceCard(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            w.word,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14.5,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _activeLocale == 'en-GB'
                                ? w.phoneticUk
                                : w.phoneticUs,
                            style: TextStyle(
                              fontSize: 11.5,
                              color: tokens.goldAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${w.definitionFr} • "${w.exampleEn}"',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Écouter',
                  onPressed: () => _speakFluid('${w.word}. ${w.exampleEn}'),
                  icon: const Icon(
                    Icons.volume_up_outlined,
                    size: 19,
                    color: YitteColors.emerald,
                  ),
                ),
                IconButton(
                  tooltip: w.mastered ? 'Acquis' : 'Marquer acquis',
                  onPressed: () => ref
                      .read(ecosystemProvider.notifier)
                      .toggleVocabMastered(w.id),
                  icon: Icon(
                    w.mastered
                        ? Icons.check_circle_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 19,
                    color: w.mastered ? YitteColors.emerald : null,
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 14),
        Text(
          'VERBES IRRÉGULIERS CLÉS',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        YitteSurfaceCard(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Column(
            children: EnglishOpenSourceService.irregularVerbs
                .asMap()
                .entries
                .map((entry) {
              final v = entry.value;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${v.base}  →  ${v.past}  →  ${v.participle}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                ),
                              ),
                              Text(
                                v.french,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          visualDensity: VisualDensity.compact,
                          onPressed: () =>
                              _speakFluid('${v.base}, ${v.past}, ${v.participle}'),
                          icon: const Icon(
                            Icons.volume_up_outlined,
                            size: 18,
                            color: YitteColors.emerald,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (entry.key < EnglishOpenSourceService.irregularVerbs.length - 1)
                    Divider(height: 1, color: tokens.borderSubtle),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _StudioTabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _StudioTabButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.tokensOf(context);
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(9),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? YitteColors.emerald : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: active ? YitteColors.gold : tokens.goldAccent,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: active
                      ? YitteColors.ivory
                      : Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniBubbleAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _MiniBubbleAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: YitteColors.emerald),
            const SizedBox(width: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: YitteColors.emerald,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatBubble {
  final bool fromAmy;
  final String englishText;
  final String? frenchTranslation;
  final String? correctedText;
  final String? coachingTipFr;
  final String? nativeUpgrade;
  final int? fluencyScore;

  const _ChatBubble({
    required this.fromAmy,
    required this.englishText,
    this.frenchTranslation,
    this.correctedText,
    this.coachingTipFr,
    this.nativeUpgrade,
    this.fluencyScore,
  });

  _ChatBubble copyWith({
    String? correctedText,
    String? coachingTipFr,
    String? nativeUpgrade,
    int? fluencyScore,
  }) {
    return _ChatBubble(
      fromAmy: fromAmy,
      englishText: englishText,
      frenchTranslation: frenchTranslation,
      correctedText: correctedText ?? this.correctedText,
      coachingTipFr: coachingTipFr ?? this.coachingTipFr,
      nativeUpgrade: nativeUpgrade ?? this.nativeUpgrade,
      fluencyScore: fluencyScore ?? this.fluencyScore,
    );
  }
}
