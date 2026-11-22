import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/services/english_learna_curriculum.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/editorial_widgets.dart';

enum _ExerciseKind {
  conceptCard,
  trapChoice,
  wordBank,
  listeningMatch,
  quizChoice,
}

class _DuolingoExercise {
  final _ExerciseKind kind;
  final String badge;
  final String prompt;
  final String? audioText;
  final List<String> bullets;
  final List<String> options;
  final List<String> correctWords;
  final List<String> shuffledWords;
  final String correctAnswer;
  final String explanation;

  const _DuolingoExercise({
    required this.kind,
    required this.badge,
    required this.prompt,
    this.audioText,
    this.bullets = const [],
    this.options = const [],
    this.correctWords = const [],
    this.shuffledWords = const [],
    this.correctAnswer = '',
    this.explanation = '',
  });
}

class DuolingoLessonPlayer extends StatefulWidget {
  final LearnaLesson lesson;
  final void Function(String text, {double? rate}) onSpeak;
  final VoidCallback onClose;
  final VoidCallback onCompleteAndNext;
  final VoidCallback onPracticeWithAmy;

  const DuolingoLessonPlayer({
    super.key,
    required this.lesson,
    required this.onSpeak,
    required this.onClose,
    required this.onCompleteAndNext,
    required this.onPracticeWithAmy,
  });

  @override
  State<DuolingoLessonPlayer> createState() => _DuolingoLessonPlayerState();
}

class _DuolingoLessonPlayerState extends State<DuolingoLessonPlayer> {
  late final List<_DuolingoExercise> _deck;
  int _idx = 0;
  bool _finished = false;
  int _correctCount = 0;
  int _gradedTotal = 0;

  // Current exercise selection state
  String? _selectedOption;
  final List<int> _selectedWordIndices = [];
  bool _checked = false;
  bool _lastWasCorrect = false;

  @override
  void initState() {
    super.initState();
    _deck = _buildDeck(widget.lesson);
  }

  List<_DuolingoExercise> _buildDeck(LearnaLesson lesson) {
    final items = <_DuolingoExercise>[];

    // 1. Concept flashcard (L'essentiel en 3 points)
    items.add(
      _DuolingoExercise(
        kind: _ExerciseKind.conceptCard,
        badge: 'L’ESSENTIEL • ${lesson.level}',
        prompt: lesson.titleFr,
        bullets: lesson.coreRules,
        audioText: lesson.dialogue.isNotEmpty ? lesson.dialogue.first.english : null,
      ),
    );

    // 2. Trap comparison card (À éviter vs Naturel)
    if (lesson.traps.isNotEmpty) {
      final t = lesson.traps.first;
      final cleanNatural = t.natural.replaceAll('✅', '').trim();
      final cleanAvoid = t.avoid.replaceAll('❌', '').trim();
      final opts = [cleanNatural, cleanAvoid];
      if (lesson.unitNumber.isOdd) {
        opts.reversed;
      }
      items.add(
        _DuolingoExercise(
          kind: _ExerciseKind.trapChoice,
          badge: 'PIÈGE FR → EN',
          prompt: 'Choisissez la formulation anglaise naturelle :',
          audioText: cleanNatural,
          options: lesson.unitNumber.isEven ? [cleanAvoid, cleanNatural] : opts,
          correctAnswer: cleanNatural,
          explanation: t.explanationFr,
        ),
      );
    }

    // 3. Word Bank sentence builder (signature Duolingo!)
    final targetLine = lesson.dialogue.length > 1
        ? lesson.dialogue[1]
        : (lesson.dialogue.isNotEmpty ? lesson.dialogue.first : null);
    if (targetLine != null) {
      final rawWords = targetLine.english
          .replaceAll(RegExp(r'[.,!?]'), '')
          .trim()
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .take(9)
          .toList();
      if (rawWords.length >= 4) {
        final shuffled = List<String>.from(rawWords);
        // Deterministic readable shuffle
        for (int i = 0; i < shuffled.length - 1; i += 2) {
          final tmp = shuffled[i];
          shuffled[i] = shuffled[shuffled.length - 1 - i];
          shuffled[shuffled.length - 1 - i] = tmp;
        }
        if (shuffled.join(' ') == rawWords.join(' ') && shuffled.length >= 2) {
          final tmp = shuffled[0];
          shuffled[0] = shuffled[1];
          shuffled[1] = tmp;
        }
        items.add(
          _DuolingoExercise(
            kind: _ExerciseKind.wordBank,
            badge: 'ASSEMBLER LA PHRASE',
            prompt: targetLine.french,
            audioText: rawWords.join(' '),
            correctWords: rawWords,
            shuffledWords: shuffled,
            correctAnswer: rawWords.join(' '),
            explanation: 'Phrase exacte : « ${rawWords.join(' ')} ».',
          ),
        );
      }
    }

    // 4. Listening comprehension from dialogue
    if (lesson.dialogue.isNotEmpty) {
      final line = lesson.dialogue.first;
      final distractors = <String>[
        'Demander l’heure d’un rendez-vous demain matin.',
        'Expliquer qu’on annule une réunion professionnelle.',
      ];
      final opts = [line.french, ...distractors];
      if (lesson.unitNumber % 3 == 0) {
        opts.insert(0, opts.removeLast());
      }
      items.add(
        _DuolingoExercise(
          kind: _ExerciseKind.listeningMatch,
          badge: 'ÉCOUTER & COMPRENDRE',
          prompt: 'Écoutez Amy et choisissez le sens exact :',
          audioText: line.english,
          options: opts,
          correctAnswer: line.french,
          explanation: 'Amy a dit : « ${line.english} ».',
        ),
      );
    }

    // 5. Quiz items
    for (final q in lesson.quiz) {
      items.add(
        _DuolingoExercise(
          kind: _ExerciseKind.quizChoice,
          badge: 'MISE EN PRATIQUE',
          prompt: q.question,
          options: q.options,
          correctAnswer: q.answer,
          explanation: q.explanation,
        ),
      );
    }

    return items;
  }

  bool get _canCheck {
    final ex = _deck[_idx];
    return switch (ex.kind) {
      _ExerciseKind.conceptCard => true,
      _ExerciseKind.wordBank => _selectedWordIndices.isNotEmpty,
      _ => _selectedOption != null,
    };
  }

  void _checkAnswer() {
    final ex = _deck[_idx];
    if (ex.kind == _ExerciseKind.conceptCard) {
      _advance();
      return;
    }
    bool ok;
    if (ex.kind == _ExerciseKind.wordBank) {
      final assembled = _selectedWordIndices
          .map((i) => ex.shuffledWords[i])
          .join(' ')
          .trim()
          .toLowerCase();
      ok = assembled == ex.correctAnswer.trim().toLowerCase();
    } else {
      ok = _selectedOption == ex.correctAnswer;
    }
    HapticFeedback.lightImpact();
    setState(() {
      _checked = true;
      _lastWasCorrect = ok;
      _gradedTotal++;
      if (ok) _correctCount++;
    });
  }

  void _advance() {
    if (_idx + 1 >= _deck.length) {
      setState(() => _finished = true);
      return;
    }
    setState(() {
      _idx++;
      _selectedOption = null;
      _selectedWordIndices.clear();
      _checked = false;
      _lastWasCorrect = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.tokensOf(context);
    if (_finished) {
      final accuracy = _gradedTotal == 0
          ? 100
          : ((_correctCount / _gradedTotal) * 100).round();
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 36),
        children: [
          Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: YitteColors.emerald,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: YitteColors.gold, width: 1.5),
            ),
            child: Column(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: YitteColors.gold,
                    border: Border.all(color: YitteColors.ivory, width: 2),
                  ),
                  child: const Icon(
                    Icons.emoji_events_rounded,
                    size: 36,
                    color: YitteColors.inkDark,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'ÉTAPE TERMINÉE !',
                  style: TextStyle(
                    color: YitteColors.gold,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.lesson.titleFr,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: YitteFonts.display,
                    color: YitteColors.ivory,
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _CelebrationStat(label: 'GAIN', value: '+50 XP'),
                    const SizedBox(width: 12),
                    _CelebrationStat(label: 'PRÉCISION', value: '$accuracy%'),
                    const SizedBox(width: 12),
                    _CelebrationStat(
                        label: 'NIVEAU', value: widget.lesson.level),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: YitteColors.gold,
                foregroundColor: YitteColors.inkDark,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: widget.onCompleteAndNext,
              icon: const Icon(Icons.arrow_forward_rounded, size: 20),
              label: const Text('Valider (+50 XP) & Étape suivante →'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              onPressed: widget.onPracticeWithAmy,
              icon: const Icon(Icons.forum_outlined, size: 19),
              label: const Text('Pratiquer cette leçon avec Amy →'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: widget.onClose,
            child: const Text('Retour au parcours'),
          ),
        ],
      );
    }

    final ex = _deck[_idx];
    final progress = (_idx + 1) / _deck.length;

    return Column(
      children: [
        // Top Duolingo-style progress bar
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 6, 16, 8),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Quitter la leçon',
                onPressed: widget.onClose,
                icon: const Icon(Icons.close_rounded),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 10,
                    backgroundColor: tokens.borderSubtle,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      YitteColors.emerald,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${_idx + 1}/${_deck.length}',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),

        // Main Exercise Body (1 clean step per screen)
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            children: [
              YitteStatusPill(label: ex.badge),
              const SizedBox(height: 10),
              Text(
                ex.prompt,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 14),

              if (ex.kind == _ExerciseKind.conceptCard) ...[
                YitteSurfaceCard(
                  borderColor: tokens.borderAccent,
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...ex.bullets.map(
                        (b) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.check_circle_outline_rounded,
                                size: 18,
                                color: YitteColors.emerald,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  b,
                                  style: const TextStyle(height: 1.45),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (ex.audioText != null) ...[
                        const Divider(height: 18),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () => widget.onSpeak(ex.audioText!),
                              icon: const Icon(Icons.volume_up_rounded, size: 17),
                              label: const Text('Écouter un exemple'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () =>
                                  widget.onSpeak(ex.audioText!, rate: 0.78),
                              child: const Text('Lent'),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ] else if (ex.kind == _ExerciseKind.wordBank) ...[
                if (ex.audioText != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Wrap(
                      spacing: 8,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => widget.onSpeak(ex.audioText!),
                          icon: const Icon(Icons.volume_up_outlined, size: 18),
                          label: const Text('Écouter la phrase'),
                        ),
                        OutlinedButton(
                          onPressed: () =>
                              widget.onSpeak(ex.audioText!, rate: 0.78),
                          child: const Text('Lent 0.8×'),
                        ),
                      ],
                    ),
                  ),
                // Assembled answer tray
                Container(
                  constraints: const BoxConstraints(minHeight: 74),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: tokens.elevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: tokens.borderAccent,
                      width: 1.2,
                    ),
                  ),
                  child: _selectedWordIndices.isEmpty
                      ? Center(
                          child: Text(
                            'Touchez les mots ci-dessous dans le bon ordre…',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        )
                      : Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: _selectedWordIndices.map((wordIdx) {
                            return ActionChip(
                              backgroundColor: YitteColors.emerald,
                              label: Text(
                                ex.shuffledWords[wordIdx],
                                style: const TextStyle(
                                  color: YitteColors.ivory,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              onPressed: _checked
                                  ? null
                                  : () => setState(
                                        () => _selectedWordIndices.remove(wordIdx),
                                      ),
                            );
                          }).toList(),
                        ),
                ),
                const SizedBox(height: 16),
                // Word bank chips
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ex.shuffledWords.asMap().entries.map((e) {
                    final used = _selectedWordIndices.contains(e.key);
                    return ChoiceChip(
                      selected: used,
                      showCheckmark: false,
                      label: Text(
                        e.value,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: used
                              ? Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.35)
                              : Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      onSelected: (_checked || used)
                          ? null
                          : (_) {
                              widget.onSpeak(e.value);
                              setState(() => _selectedWordIndices.add(e.key));
                            },
                    );
                  }).toList(),
                ),
              ] else ...[
                if (ex.audioText != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: YitteColors.emerald,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: YitteColors.gold),
                      ),
                      child: Row(
                        children: [
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: YitteColors.gold,
                              foregroundColor: YitteColors.inkDark,
                            ),
                            onPressed: () => widget.onSpeak(ex.audioText!),
                            icon: const Icon(Icons.volume_up_rounded, size: 20),
                            label: const Text('Écouter'),
                          ),
                          const SizedBox(width: 10),
                          OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: YitteColors.ivory,
                              side: BorderSide(
                                color: YitteColors.gold.withValues(alpha: 0.7),
                              ),
                            ),
                            onPressed: () =>
                                widget.onSpeak(ex.audioText!, rate: 0.78),
                            child: const Text('Lent'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ...ex.options.map((opt) {
                  final sel = _selectedOption == opt;
                  final isRight = _checked && opt == ex.correctAnswer;
                  final isWrongSel = _checked && sel && opt != ex.correctAnswer;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _checked
                          ? null
                          : () => setState(() => _selectedOption = opt),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: isRight
                              ? YitteColors.emeraldSoft
                              : (isWrongSel
                                  ? YitteColors.danger.withValues(alpha: 0.08)
                                  : (sel ? tokens.goldSurface : tokens.elevated)),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isRight
                                ? YitteColors.emerald
                                : (isWrongSel
                                    ? YitteColors.danger
                                    : (sel
                                        ? YitteColors.gold
                                        : tokens.borderSubtle)),
                            width: (sel || isRight || isWrongSel) ? 1.8 : 1,
                          ),
                        ),
                        child: Text(
                          opt,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontWeight: sel || isRight
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                              ),
                        ),
                      ),
                    ),
                  );
                }),
              ],
            ],
          ),
        ),

        // Bottom Duolingo-style Check / Instant Feedback Bar
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: _checked
                ? (_lastWasCorrect ? YitteColors.emeraldSoft : tokens.goldSurface)
                : tokens.elevated,
            border: Border(
              top: BorderSide(
                color: _checked
                    ? (_lastWasCorrect ? YitteColors.emerald : tokens.goldAccent)
                    : tokens.borderSubtle,
              ),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (_checked) ...[
                Text(
                  _lastWasCorrect
                      ? '✓ Excellent ! +10 XP'
                      : 'À retenir : ${ex.correctAnswer}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: _lastWasCorrect
                        ? YitteColors.emerald
                        : YitteColors.danger,
                  ),
                ),
                if (ex.explanation.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    ex.explanation,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                const SizedBox(height: 10),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _lastWasCorrect
                        ? YitteColors.emerald
                        : YitteColors.gold,
                    foregroundColor: _lastWasCorrect
                        ? YitteColors.ivory
                        : YitteColors.inkDark,
                  ),
                  onPressed: _advance,
                  child: const Text('CONTINUER'),
                ),
              ] else
                ElevatedButton(
                  onPressed: _canCheck ? _checkAnswer : null,
                  child: Text(
                    ex.kind == _ExerciseKind.conceptCard
                        ? 'COMMENCER LES EXERCICES →'
                        : 'VÉRIFIER',
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CelebrationStat extends StatelessWidget {
  final String label;
  final String value;

  const _CelebrationStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: YitteColors.gold.withValues(alpha: 0.45)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              color: YitteColors.ivory.withValues(alpha: 0.72),
              fontSize: 9.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: YitteColors.gold,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
