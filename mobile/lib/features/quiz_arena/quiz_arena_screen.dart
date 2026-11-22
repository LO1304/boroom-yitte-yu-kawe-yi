import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/state/app_providers.dart';
import '../../core/models/domain_models.dart';
import '../../core/services/external_link_bridge.dart';
import '../../core/services/whatsapp_bridge_service.dart';
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
  String _selectedCategory = 'all';
  bool _matchActive = false;
  bool _matchFinished = false;
  int _qIndex = 0;
  int _secondsLeft = 25;
  int _maxSeconds = 25;
  int _matchScore = 0;
  int _correctCount = 0;
  int _currentCombo = 0;
  int _bestCombo = 0;
  int _focusLostCount = 0;
  int? _selectedOption;
  bool _answered = false;
  Timer? _timer;
  List<QuizQuestionModel> _activePool = const [];
  final List<({QuizQuestionModel question, int chosenIdx})> _missedQuestions =
      [];

  static const _modes = {
    'one_vs_one': '1 vs 1',
    'solo_chrono': 'Solo Chrono',
    'team_vs_team': 'Équipe vs Équipe',
    'community_tournament': 'Tournoi Communautaire',
    'weekly_championship': 'Championnat Hebdo',
  };

  static const _categories = {
    'all': 'Tous thèmes',
    'islamic_thought': 'Pensée islamique',
    'ethics': 'Éthique & Philo',
    'science': 'Sciences & Tech',
    'history': 'Histoire & Société',
    'english': 'Anglais',
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
    if (_matchActive &&
        !_answered &&
        (state == AppLifecycleState.paused ||
            state == AppLifecycleState.inactive)) {
      _focusLostCount++;
    }
  }

  List<QuizQuestionModel> _filteredQuestions(List<QuizQuestionModel> all) {
    if (_selectedCategory == 'all') return all;
    final matched = all.where((q) {
      final cat = q.category.toLowerCase();
      return switch (_selectedCategory) {
        'ethics' => cat == 'ethics' || cat == 'philosophy' || cat == 'logic',
        'science' => cat == 'science' || cat == 'technology',
        'history' => cat == 'history' || cat == 'society' || cat == 'general_knowledge',
        _ => cat == _selectedCategory,
      };
    }).toList();
    return matched.isNotEmpty ? matched : all;
  }

  void _startMatch() {
    final all = ref.read(ecosystemProvider).quizQuestions;
    final pool = _filteredQuestions(all);
    if (pool.isEmpty) return;

    setState(() {
      _activePool = pool;
      _matchActive = true;
      _matchFinished = false;
      _qIndex = 0;
      _matchScore = 0;
      _correctCount = 0;
      _currentCombo = 0;
      _bestCombo = 0;
      _focusLostCount = 0;
      _selectedOption = null;
      _answered = false;
      _missedQuestions.clear();
    });
    _startQuestionTimer();
  }

  void _startQuestionTimer() {
    _timer?.cancel();
    final limit = _activePool[_qIndex].timeLimitSeconds.clamp(10, 60);
    setState(() {
      _maxSeconds = limit;
      _secondsLeft = limit;
    });
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
    final q = _activePool[_qIndex];
    final suspicious = _focusLostCount > 2;
    final correct = optionIdx == q.correctOptionIndex;

    HapticFeedback.lightImpact();

    setState(() {
      _selectedOption = optionIdx;
      _answered = true;
      if (correct && !suspicious) {
        _correctCount++;
        _currentCombo++;
        if (_currentCombo > _bestCombo) _bestCombo = _currentCombo;
        final multiplier = _currentCombo >= 4
            ? 3
            : (_currentCombo >= 2 ? 2 : 1);
        _matchScore += (q.points * multiplier) + (_secondsLeft * 2);
      } else {
        _currentCombo = 0;
        _missedQuestions.add((question: q, chosenIdx: optionIdx));
      }
    });
  }

  void _nextQuestion() {
    if (_qIndex + 1 < _activePool.length) {
      setState(() {
        _qIndex++;
        _selectedOption = null;
        _answered = false;
      });
      _startQuestionTimer();
    } else {
      _timer?.cancel();
      final profile = ref.read(authProvider);
      ref.read(ecosystemProvider.notifier).recordQuizPoints(
            _matchScore,
            playerId: profile?.id,
            playerName: profile?.fullName ?? 'Membre du cercle',
          );
      setState(() {
        _matchActive = false;
        _matchFinished = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final eco = ref.watch(ecosystemProvider);
    final tokens = AppTheme.tokensOf(context);
    final modeLabel = _modes[_selectedMode] ?? '1 vs 1';

    return Scaffold(
      backgroundColor: tokens.canvas,
      appBar: AppBar(title: const Text('YITTÉ QUIZ ARENA')),
      body: _matchActive
          ? _buildLiveMatch(context, tokens)
          : (_matchFinished
              ? _buildPodiumSummary(context, eco, tokens, modeLabel)
              : _buildLobby(context, eco, tokens, modeLabel)),
    );
  }

  Widget _buildLobby(
    BuildContext context,
    EcosystemState eco,
    YitteSurfaceTokens tokens,
    String modeLabel,
  ) {
    final availableCount = _filteredQuestions(eco.quizQuestions).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
      children: [
        // Carte Score & Statut Arène (Émeraude & Or 1px)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: YitteColors.emerald,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: YitteColors.gold, width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ARÈNE DU SAVOIR • CHRONO & COMBO',
                style: TextStyle(
                  color: YitteColors.gold,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${eco.quizScoreTotal} pts',
                          style: const TextStyle(
                            fontFamily: YitteFonts.display,
                            color: YitteColors.ivory,
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${eco.quizMatchesPlayed} partie(s) jouée(s) • $availableCount question(s) prêtes',
                          style: TextStyle(
                            color: YitteColors.ivory.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: YitteColors.gold,
                      border: Border.all(color: YitteColors.ivory, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.emoji_events_rounded,
                      size: 28,
                      color: YitteColors.inkDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: YitteColors.gold,
                    foregroundColor: YitteColors.inkDark,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: eco.quizQuestions.isEmpty ? null : _startMatch,
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: Text('Démarrer : $modeLabel'),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Sélecteur de Thème d'Arène
        Text(
          'CHOISIR UNE ARÈNE THÉMATIQUE',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _categories.entries.map((e) {
            final sel = _selectedCategory == e.key;
            return ChoiceChip(
              selected: sel,
              showCheckmark: false,
              selectedColor: YitteColors.emerald,
              label: Text(e.value),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: sel
                    ? YitteColors.ivory
                    : Theme.of(context).colorScheme.onSurface,
              ),
              onSelected: (_) => setState(() => _selectedCategory = e.key),
            );
          }).toList(),
        ),
        const SizedBox(height: 16),

        // Sélecteur de Mode de Jeu
        Text(
          'MODE DE COMPÉTITION',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _modes.entries.map((e) {
            final sel = _selectedMode == e.key;
            return ChoiceChip(
              selected: sel,
              showCheckmark: false,
              selectedColor: YitteColors.emerald,
              label: Text(e.value),
              labelStyle: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: sel
                    ? YitteColors.ivory
                    : Theme.of(context).colorScheme.onSurface,
              ),
              onSelected: (_) => setState(() => _selectedMode = e.key),
            );
          }).toList(),
        ),
        const SizedBox(height: 18),

        // Classement réel des membres
        const SectionHeader(title: 'Classement du Cercle'),
        const SizedBox(height: 8),
        if (eco.quizLeaderboard.isEmpty)
          YitteSurfaceCard(
            padding: const EdgeInsets.all(14),
            child: Text(
              'Aucun score enregistré pour le moment. Lancez la première partie pour apparaître en tête du classement !',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          )
        else
          YitteSurfaceCard(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Column(
              children: eco.quizLeaderboard.asMap().entries.map((entry) {
                final rank = entry.key + 1;
                final item = entry.value;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: rank == 1
                                ? YitteColors.gold
                                : tokens.subtleFill,
                            child: Text(
                              '$rank',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: rank == 1
                                    ? YitteColors.inkDark
                                    : YitteColors.emerald,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              item.memberName,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          Text(
                            '${item.totalPoints} pts',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: tokens.goldAccent,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (entry.key < eco.quizLeaderboard.length - 1)
                      Divider(height: 1, color: tokens.borderSubtle),
                  ],
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildLiveMatch(BuildContext context, YitteSurfaceTokens tokens) {
    final q = _activePool[_qIndex];
    final timeRatio =
        _maxSeconds > 0 ? (_secondsLeft / _maxSeconds).clamp(0.0, 1.0) : 0.0;
    final timerColor = _secondsLeft <= 6
        ? YitteColors.danger
        : (_secondsLeft <= 12 ? YitteColors.gold : YitteColors.emerald);
    final multiplier =
        _currentCombo >= 4 ? 3 : (_currentCombo >= 2 ? 2 : 1);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 36),
      children: [
        // En-tête de manche + Chrono + Combo
        Row(
          children: [
            YitteStatusPill(
              label: 'Question ${_qIndex + 1}/${_activePool.length}',
            ),
            const SizedBox(width: 8),
            if (multiplier > 1)
              YitteStatusPill(
                label: 'COMBO ×$multiplier',
                backgroundColor: YitteColors.gold,
                foregroundColor: YitteColors.inkDark,
              ),
            const Spacer(),
            Text(
              '$_matchScore pts',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: tokens.goldAccent,
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(width: 10),
            YitteStatusPill(
              icon: Icons.timer_outlined,
              label: '${_secondsLeft}s',
              foregroundColor: timerColor,
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: timeRatio,
            minHeight: 7,
            backgroundColor: tokens.borderSubtle,
            valueColor: AlwaysStoppedAnimation<Color>(timerColor),
          ),
        ),
        const SizedBox(height: 16),

        // Carte Question
        YitteSurfaceCard(
          borderColor: tokens.borderAccent,
          padding: const EdgeInsets.all(16),
          child: Text(
            q.questionText,
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 14),

        // Options tactiles nettes (ListTile préservé pour compatibilité & accessibilité)
        ...q.options.asMap().entries.map((entry) {
          final idx = entry.key;
          final text = entry.value;
          final isCorrect = idx == q.correctOptionIndex;
          final isPicked = _selectedOption == idx;

          Color bg = tokens.elevated;
          Color border = tokens.borderSubtle;
          if (_answered) {
            if (isCorrect) {
              bg = YitteColors.emeraldSoft;
              border = YitteColors.emerald;
            } else if (isPicked) {
              bg = YitteColors.danger.withValues(alpha: 0.08);
              border = YitteColors.danger;
            }
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: border,
                width: (_answered && (isCorrect || isPicked)) ? 1.8 : 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                leading: CircleAvatar(
                  radius: 14,
                  backgroundColor: _answered && isCorrect
                      ? YitteColors.emerald
                      : (_answered && isPicked
                          ? YitteColors.danger
                          : tokens.subtleFill),
                  child: Text(
                    String.fromCharCode(65 + idx),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: (_answered && (isCorrect || isPicked))
                          ? Colors.white
                          : YitteColors.emerald,
                    ),
                  ),
                ),
                title: Text(
                  text,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: (_answered && isCorrect)
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                ),
                onTap: _answered ? null : () => _submitAnswer(idx),
              ),
            ),
          );
        }),

        if (_answered) ...[
          const SizedBox(height: 6),
          YitteSurfaceCard(
            color: tokens.goldSurface,
            borderColor: tokens.borderAccent,
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _selectedOption == q.correctOptionIndex
                      ? '✓ Bonne réponse !'
                      : (_selectedOption == -1
                          ? 'Temps écoulé !'
                          : 'Pas tout à fait !'),
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: _selectedOption == q.correctOptionIndex
                        ? YitteColors.emerald
                        : YitteColors.danger,
                  ),
                ),
                const SizedBox(height: 4),
                Text('Explication : ${q.explanation}'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _nextQuestion,
              icon: const Icon(Icons.arrow_forward_rounded, size: 18),
              label: Text(
                _qIndex + 1 < _activePool.length
                    ? 'Question suivante'
                    : 'Voir le podium & bilan',
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPodiumSummary(
    BuildContext context,
    EcosystemState eco,
    YitteSurfaceTokens tokens,
    String modeLabel,
  ) {
    final total = _activePool.isEmpty ? 1 : _activePool.length;
    final accuracy = ((_correctCount / total) * 100).round();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: YitteColors.emerald,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: YitteColors.gold, width: 1.5),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.emoji_events_rounded,
                size: 46,
                color: YitteColors.gold,
              ),
              const SizedBox(height: 8),
              Text(
                'MANCHE TERMINÉE • $modeLabel',
                style: const TextStyle(
                  color: YitteColors.gold,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$_matchScore pts',
                style: const TextStyle(
                  fontFamily: YitteFonts.display,
                  color: YitteColors.ivory,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$_correctCount / $total exactes ($accuracy%) • Meilleur combo : ×${_bestCombo < 2 ? 1 : (_bestCombo >= 4 ? 3 : 2)}',
                style: TextStyle(
                  color: YitteColors.ivory.withValues(alpha: 0.85),
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: YitteColors.gold,
              foregroundColor: YitteColors.inkDark,
            ),
            onPressed: () {
              final msg =
                  '*BOROOM YITTÉ YU KAWÉ YI — Quiz Arena*\n'
                  '━━━━━━━━━━━━━━\n'
                  'Score réalisé : *$_matchScore pts* ($accuracy% de précision)\n'
                  'Mode : _${modeLabel}_\n'
                  '━━━━━━━━━━━━━━\n'
                  '_Qui relève le défi dans le groupe ?_';
              final url = WhatsAppBridgeService.buildShareUrl(
                msg,
                groupInviteUrl: eco.whatsappInviteUrl,
              );
              ExternalLinkBridge.openUrl(url);
            },
            icon: const Icon(Icons.share_outlined, size: 18),
            label: const Text('Défier le groupe sur WhatsApp'),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _startMatch,
                icon: const Icon(Icons.replay_rounded, size: 18),
                label: const Text('Rejouer'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                onPressed: () => setState(() => _matchFinished = false),
                child: const Text('Retour à l’Arène'),
              ),
            ),
          ],
        ),

        if (_missedQuestions.isNotEmpty) ...[
          const SizedBox(height: 18),
          SectionHeader(
            title: 'Questions à réviser (${_missedQuestions.length})',
          ),
          const SizedBox(height: 8),
          ..._missedQuestions.map(
            (m) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: YitteSurfaceCard(
                padding: const EdgeInsets.all(13),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.question.questionText,
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bonne réponse : ${m.question.options[m.question.correctOptionIndex]}',
                      style: const TextStyle(
                        color: YitteColors.emerald,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      m.question.explanation,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
