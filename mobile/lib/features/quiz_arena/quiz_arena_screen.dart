import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/state/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/editorial_widgets.dart';

class QuizArenaScreen extends ConsumerStatefulWidget {
  const QuizArenaScreen({super.key});

  @override
  ConsumerState<QuizArenaScreen> createState() => _QuizArenaScreenState();
}

class _QuizArenaScreenState extends ConsumerState<QuizArenaScreen>
    with WidgetsBindingObserver {
  String _selectedMode = 'one_vs_one';
  int _bracketSize = 8;
  bool _matchActive = false;
  int _qIndex = 0;
  int _secondsLeft = 25;
  int _matchScore = 0;
  int _correctCount = 0;
  String? _lastMatchSummary;
  int _focusLostCount = 0;
  int? _selectedOption;
  bool _answered = false;
  Timer? _timer;

  static const _modes = {
    'one_vs_one': '1 vs 1',
    'team_vs_team': 'Équipe vs Équipe',
    'tournament_8': 'Tournoi 8 joueurs',
    'tournament_16': 'Tournoi 16 joueurs',
    'tournament_32': 'Tournoi 32 joueurs',
    'community_tournament': 'Tournoi Communautaire',
    'weekly_championship': 'Championnat Hebdomadaire',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Anti-cheating protection: track backgrounding / tab switch during live question
    if (_matchActive &&
        !_answered &&
        (state == AppLifecycleState.paused || state == AppLifecycleState.inactive)) {
      _focusLostCount++;
    }
  }

  void _startMatch() {
    setState(() {
      _matchActive = true;
      _qIndex = 0;
      _matchScore = 0;
      _correctCount = 0;
      _focusLostCount = 0;
      _selectedOption = null;
      _answered = false;
    });
    _startQuestionTimer();
  }

  void _startQuestionTimer() {
    _timer?.cancel();
    final questions = ref.read(ecosystemProvider).quizQuestions;
    setState(() => _secondsLeft = questions[_qIndex].timeLimitSeconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _answered) {
        t.cancel();
        return;
      }
      if (_secondsLeft <= 1) {
        t.cancel();
        _submitAnswer(-1);
      } else {
        setState(() => _secondsLeft--);
      }
    });
  }

  void _submitAnswer(int optionIdx) {
    if (_answered) return;
    _timer?.cancel();
    final q = ref.read(ecosystemProvider).quizQuestions[_qIndex];
    final suspicious = _focusLostCount > 2;
    final correct = optionIdx == q.correctOptionIndex;
    final earned = (!suspicious && correct)
        ? q.points + (_secondsLeft * 2)
        : 0;

    setState(() {
      _selectedOption = optionIdx;
      _answered = true;
      if (correct) _correctCount++;
      _matchScore += earned;
    });
  }

  void _nextQuestion() {
    final questions = ref.read(ecosystemProvider).quizQuestions;
    if (_qIndex + 1 < questions.length) {
      setState(() {
        _qIndex++;
        _selectedOption = null;
        _answered = false;
      });
      _startQuestionTimer();
    } else {
      final profile = ref.read(authProvider);
      ref.read(ecosystemProvider.notifier).recordQuizPoints(
            _matchScore,
            playerId: profile?.id,
            playerName: profile?.fullName ?? 'Participant',
          );
      setState(() {
        _matchActive = false;
        _lastMatchSummary =
            'Session (${_modes[_selectedMode]}) : $_matchScore pts '
            '• $_correctCount/${questions.length} bonnes réponses';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final eco = ref.watch(ecosystemProvider);
    final q = eco.quizQuestions[_qIndex];

    return Scaffold(
      appBar: AppBar(title: const Text('YITTÉ QUIZ ARENA')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          YitteReveal(
            order: 0,
            child: EditorialHeroBanner(
              eyebrow: 'TOURNOIS & COMPÉTITIONS ÉDUCATIVES VOLONTAIRES',
              title: 'Quiz Arena en Temps Réel',
              subtitle:
                  'Logique, histoire, pensée islamique, philosophie et sciences — avec compte à rebours, explications et protection anti-triche.',
              trailing: Chip(
                label: Text('${eco.quizScoreTotal} pts'),
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (!_matchActive) ...[
            if (_lastMatchSummary != null) ...[
              Card(
                color: YitteColors.emeraldSoft,
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.emoji_events_rounded,
                      color: YitteColors.emerald),
                  title: const Text(
                    'Résultat du dernier match',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(_lastMatchSummary!),
                ),
              ),
            ],
            DropdownButtonFormField<String>(
              initialValue: _selectedMode,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Mode de jeu'),
              items: _modes.entries
                  .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) {
                setState(() {
                  _selectedMode = v ?? 'one_vs_one';
                  if (_selectedMode == 'tournament_16') _bracketSize = 16;
                  if (_selectedMode == 'tournament_32') _bracketSize = 32;
                  if (_selectedMode == 'tournament_8') _bracketSize = 8;
                });
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text('Démarrer : ${_modes[_selectedMode]}'),
                onPressed: _startMatch,
              ),
            ),
            const SizedBox(height: 18),
            SectionHeader(title: 'Format de Tournoi ($_bracketSize places)'),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Format élimination directe à ${(_bracketSize == 8 ? 3 : _bracketSize == 16 ? 4 : 5)} tours — '
                      'Score calculé sur la précision et le temps de réponse réel.',
                    ),
                    const SizedBox(height: 10),
                    Text(
                      eco.members.isEmpty
                          ? 'Inscriptions ouvertes : invitez des membres ou lancez un match chronométré ci-dessus.'
                          : 'Participants inscrits disponibles : ${eco.members.take(6).map((m) => m.fullName).join(", ")}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const SectionHeader(title: 'Classement Réel des Participants'),
            const SizedBox(height: 8),
            eco.quizLeaderboard.isEmpty
                ? const YitteEmptyState(
                    icon: Icons.leaderboard_outlined,
                    title: 'Aucun score enregistré pour l’instant',
                    description:
                        'Terminez un match pour inaugurer le classement réel des participants.',
                  )
                : YitteSurfaceCard(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: [
                        for (int idx = 0; idx < eco.quizLeaderboard.length; idx++)
                          ListTile(
                            leading: CircleAvatar(child: Text('${idx + 1}')),
                            title: Text(eco.quizLeaderboard[idx].memberName),
                            subtitle: Text(
                              '${eco.quizLeaderboard[idx].matchesPlayed} match(s) joué(s)',
                            ),
                            trailing: Text(
                              '${eco.quizLeaderboard[idx].totalPoints} pts',
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                      ],
                    ),
                  ),
          ] else ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text('Question ${_qIndex + 1}/${eco.quizQuestions.length}',
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        const Spacer(),
                        Chip(
                          backgroundColor: _secondsLeft <= 5
                              ? YitteColors.danger.withValues(alpha: 0.15)
                              : null,
                          label: Text('${_secondsLeft}s'),
                        ),
                        const SizedBox(width: 6),
                        Chip(label: Text('Score : $_matchScore')),
                        const SizedBox(width: 6),
                        Chip(label: Text('Réussite : $_correctCount/${_qIndex + (_answered ? 1 : 0)}')),
                      ],
                    ),
                    if (_focusLostCount > 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Alerte anti-triche : $_focusLostCount changement(s) de fenêtre détecté(s).',
                          style: const TextStyle(fontSize: 11.5, color: YitteColors.warning),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Text(q.questionText,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    ...List.generate(q.options.length, (i) {
                      final isCorrect = i == q.correctOptionIndex;
                      Color? tileColor;
                      if (_answered) {
                        if (isCorrect) {
                          tileColor = YitteColors.success.withValues(alpha: 0.14);
                        } else if (_selectedOption == i) {
                          tileColor = YitteColors.danger.withValues(alpha: 0.14);
                        }
                      }
                      return Card(
                        color: tileColor,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          title: Text(q.options[i]),
                          onTap: _answered ? null : () => _submitAnswer(i),
                        ),
                      );
                    }),
                    if (_answered) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: YitteColors.emeraldSoft,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Explication : ${q.explanation}\nRéférence : ${q.verifiedReferences.join(", ")}',
                          style: const TextStyle(
                              fontSize: 12.5, color: YitteColors.inkDark),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _nextQuestion,
                          child: Text(_qIndex + 1 < eco.quizQuestions.length
                              ? 'Question suivante'
                              : 'Terminer le match'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
