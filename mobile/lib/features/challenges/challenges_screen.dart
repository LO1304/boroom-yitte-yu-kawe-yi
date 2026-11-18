import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';

import '../../app/state/app_providers.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/models/domain_models.dart';
import '../../core/services/audio_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/editorial_widgets.dart';

class ChallengesScreen extends ConsumerStatefulWidget {
  const ChallengesScreen({super.key});

  @override
  ConsumerState<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends ConsumerState<ChallengesScreen> {
  String _selectedCategory = 'all';
  String _selectedFormat = 'all';
  String _scheduleView = 'all';
  String? _playingChallengeId;

  static const _categories = {
    'all': 'Toutes',
    'islamic_thought': 'Pensée islamique',
    'philosophy': 'Philosophie',
    'spirituality': 'Spiritualité',
    'ethics': 'Éthique',
    'history': 'Histoire',
    'science': 'Sciences',
    'technology': 'Technologie',
    'logic': 'Logique',
    'society': 'Société',
    'general_knowledge': 'Culture générale',
  };

  static const _formats = {
    'all': 'Tous formats',
    'yes_no_depends': 'Oui / Non / Cela dépend',
    'mcq': 'QCM',
    'open_ended': 'Question ouverte',
    'argumentation': 'Argumentation',
    'audio_response': 'Réponse audio',
    'timed_reasoning': 'Raisonnement chronométré',
    'team_challenge': 'Défi d’équipe',
  };

  @override
  Widget build(BuildContext context) {
    final eco = ref.watch(ecosystemProvider);
    final profile = ref.watch(authProvider);
    final audioService = ref.watch(audioServiceProvider);

    final completedCount =
        eco.challenges.where((c) => c.userSubmission != null).length;
    final scoredItems =
        eco.challenges.where((c) => c.userScore != null).toList();
    final avgScore = scoredItems.isEmpty
        ? 0.0
        : scoredItems.map((c) => c.userScore!).reduce((a, b) => a + b) /
            scoredItems.length;

    final filtered = eco.challenges.where((c) {
      final catOk = _selectedCategory == 'all' || c.category == _selectedCategory;
      final fmtOk = _selectedFormat == 'all' || c.format == _selectedFormat;
      final viewOk = switch (_scheduleView) {
        'daily' => !c.scheduledPublishAt.isAfter(DateTime.now().add(const Duration(hours: 18))),
        'audio' => c.format == 'audio_response',
        'done' => c.userSubmission != null,
        _ => true,
      };
      return catOk && fmtOk && viewOk;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Défis & Arènes'),
        actions: [
          if (profile?.role.isAdminOrAbove ?? true)
            IconButton(
              tooltip: 'Créer / Planifier un défi',
              icon: const Icon(Icons.add_circle_outline_rounded),
              onPressed: () => _openCreateChallengeDialog(context),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _ArenaEntryCard(
                    icon: Icons.record_voice_over_rounded,
                    title: 'Face-à-Face',
                    subtitle: 'Débats vocaux & IA 100 pts',
                    color: YitteDomainAccents.debates,
                    onTap: () => context.push('/debates'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ArenaEntryCard(
                    icon: Icons.emoji_events_rounded,
                    title: 'Quiz Arena',
                    subtitle: '1v1 & Tournois 8/16/32',
                    color: YitteDomainAccents.challenges,
                    onTap: () => context.push('/quiz-arena'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          YitteSurfaceCard(
            child: Row(
              children: [
                YitteProgressRing(
                  progress: eco.challenges.isEmpty
                      ? 0
                      : completedCount / eco.challenges.length,
                  size: 58,
                  strokeWidth: 6.5,
                  color: YitteDomainAccents.challenges,
                  child: Text(
                    '$completedCount/${eco.challenges.length}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Programme Organisé des Défis',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$completedCount / ${eco.challenges.length} défis relevés • Moyenne : ${avgScore.toStringAsFixed(0)}/100',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                YitteStatusPill(
                  icon: Icons.mic_rounded,
                  label: '${eco.challenges.where((c) => c.format == 'audio_response').length} Vocaux',
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 'all', label: Text('Tous')),
              ButtonSegment(value: 'daily', label: Text('Du Jour')),
              ButtonSegment(value: 'audio', label: Text('Vocaux')),
              ButtonSegment(value: 'done', label: Text('Relevés')),
            ],
            selected: {_scheduleView},
            onSelectionChanged: (s) => setState(() => _scheduleView = s.first),
          ),
          const SizedBox(height: 16),
          const SectionHeader(title: 'Yitté Challenge — Catégories & Formats'),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.entries.map((e) {
                final selected = _selectedCategory == e.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    selected: selected,
                    label: Text(e.value),
                    onSelected: (_) => setState(() => _selectedCategory = e.key),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _selectedFormat,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Filtrer par format'),
            items: _formats.entries
                .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                .toList(),
            onChanged: (v) => setState(() => _selectedFormat = v ?? 'all'),
          ),
          const SizedBox(height: 14),
          if (filtered.isEmpty)
            const YitteEmptyState(
              icon: Icons.flag_outlined,
              title: 'Aucun défi dans cette vue',
              description:
                  'Changez le filtre de programme (Du Jour / Vocaux / Tous) ou créez un nouveau défi.',
            ),
          ...filtered.map(
            (c) => YitteSurfaceCard(
              margin: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      YitteStatusPill(
                        label: c.scheduledPublishAt.isAfter(
                                DateTime.now().add(const Duration(hours: 18)))
                            ? 'Semaine'
                            : 'Défi du Jour',
                      ),
                      YitteStatusPill(
                        label: _categories[c.category] ?? c.category,
                      ),
                      YitteStatusPill(
                        label: _formats[c.format] ?? c.format,
                      ),
                      YitteStatusPill(
                        icon: Icons.timer_outlined,
                        label:
                            '${c.timeLimitSeconds}s • ${AppStrings.difficultyLabel(c.difficulty)}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(c.title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 5),
                  Text(c.description,
                      style: Theme.of(context).textTheme.bodyMedium),
                  if (c.userSubmission != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: YitteColors.emeraldSoft,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Votre soumission : ${c.userSubmission}\n'
                            'Score : ${c.userScore?.toStringAsFixed(0) ?? "-"}/100\n'
                            'Explication : ${c.explanation}',
                            style: const TextStyle(
                                fontSize: 12.5, color: YitteColors.inkDark),
                          ),
                          if (c.userAudioUrl != null &&
                              c.userAudioUrl!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            YitteAudioPlayerTile(
                              playing: _playingChallengeId == c.id,
                              label: _playingChallengeId == c.id
                                  ? 'Arrêter la lecture'
                                  : 'Écouter votre réponse vocale',
                              accentColor: YitteDomainAccents.debates,
                              onToggle: () async {
                                if (_playingChallengeId == c.id) {
                                  await audioService.stopPlayback();
                                  if (mounted) {
                                    setState(() => _playingChallengeId = null);
                                  }
                                  return;
                                }
                                setState(() => _playingChallengeId = c.id);
                                await audioService.playFile(
                                  c.userAudioUrl!,
                                  onEnded: () {
                                    if (mounted) {
                                      setState(() => _playingChallengeId = null);
                                    }
                                  },
                                  onError: (err) {
                                    if (mounted) {
                                      setState(() => _playingChallengeId = null);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text(err)),
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () => _openSolveChallengeSheet(context, c),
                        child: Text(c.userSubmission == null
                            ? 'Relever ce défi'
                            : 'Revoir / Modifier'),
                      ),
                      if (profile == null || profile.role.isAdminOrAbove)
                        IconButton(
                          tooltip: 'Supprimer ce défi',
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            color: YitteColors.danger,
                          ),
                          onPressed: () => ref
                              .read(ecosystemProvider.notifier)
                              .deleteChallenge(c.id),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openSolveChallengeSheet(
      BuildContext context, ChallengeItem item) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _SolveChallengeSheet(
        item: item,
        audioService: ref.read(audioServiceProvider),
        onSubmitted: (answer, audioUrl) {
          ref
              .read(ecosystemProvider.notifier)
              .submitChallengeResponse(item.id, answer, audioUrl: audioUrl);
        },
      ),
    );
  }

  Future<void> _openCreateChallengeDialog(BuildContext context) async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final expCtrl = TextEditingController();
    String category = 'islamic_thought';
    String format = 'argumentation';

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: const Text('Créer & Planifier un Défi'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Titre du défi'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Catégorie'),
                  items: _categories.entries
                      .where((e) => e.key != 'all')
                      .map((e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (v) =>
                      setModalState(() => category = v ?? 'islamic_thought'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: format,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Format'),
                  items: _formats.entries
                      .where((e) => e.key != 'all')
                      .map((e) =>
                          DropdownMenuItem(value: e.key, child: Text(e.value)))
                      .toList(),
                  onChanged: (v) =>
                      setModalState(() => format = v ?? 'argumentation'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: expCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Explication pédagogique'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty) return;
                ref.read(ecosystemProvider.notifier).createChallenge(
                      ChallengeItem(
                        id: const Uuid().v4(),
                        title: titleCtrl.text.trim(),
                        description: descCtrl.text.trim(),
                        category: category,
                        format: format,
                        difficulty: 'intermediate',
                        timeLimitSeconds: 300,
                        instructions: 'Développez une réponse claire et argumentée.',
                        evaluationCriteria: const [
                          'Pertinence',
                          'Cohérence logique',
                          'Exemples',
                        ],
                        explanation: expCtrl.text.trim().isEmpty
                            ? 'Évaluation basée sur la qualité des arguments.'
                            : expCtrl.text.trim(),
                        scheduledPublishAt: DateTime.now(),
                      ),
                    );
                Navigator.pop(ctx);
              },
              child: const Text('Publier'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ArenaEntryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ArenaEntryCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = AppTheme.tokensOf(context).cardRadius;
    final darkShade = Color.lerp(color, Colors.black, 0.35) ?? color;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, darkShade],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.34),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(radius),
          onTap: onTap,
          child: Stack(
            children: [
              Positioned(
                right: -14,
                bottom: -14,
                child: Icon(
                  icon,
                  size: 74,
                  color: Colors.white.withValues(alpha: 0.12),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16.5,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SolveChallengeSheet extends ConsumerStatefulWidget {
  final ChallengeItem item;
  final AudioService audioService;
  final void Function(String answer, String? audioUrl) onSubmitted;

  const _SolveChallengeSheet({
    required this.item,
    required this.audioService,
    required this.onSubmitted,
  });

  @override
  ConsumerState<_SolveChallengeSheet> createState() =>
      _SolveChallengeSheetState();
}

class _SolveChallengeSheetState extends ConsumerState<_SolveChallengeSheet> {
  late final TextEditingController _answerCtrl;
  String? _selectedChoice;
  String? _recordedAudioPath;
  bool _audioConsent = false;
  late int _secondsLeft;
  Timer? _countdown;

  @override
  void initState() {
    super.initState();
    _answerCtrl = TextEditingController(text: widget.item.userSubmission ?? '');
    if (widget.item.format == 'yes_no_depends') {
      _selectedChoice = 'Cela dépend';
    } else if (widget.item.format == 'mcq' &&
        (widget.item.options?.isNotEmpty ?? false)) {
      _selectedChoice = widget.item.options!.first;
    }
    _secondsLeft = widget.item.timeLimitSeconds;
    _countdown = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _countdown?.cancel();
    _answerCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.item.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(width: 8),
                Chip(
                  avatar: const Icon(Icons.timer_outlined, size: 16),
                  backgroundColor: _secondsLeft <= 20
                      ? YitteColors.danger.withValues(alpha: 0.14)
                      : null,
                  label: Text('${_secondsLeft}s'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Consignes : ${widget.item.instructions}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 6),
            Text(
              'Critères : ${widget.item.evaluationCriteria.join(" • ")}',
              style: const TextStyle(
                fontSize: 12,
                color: YitteColors.gold,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            if (widget.item.format == 'yes_no_depends') ...[
              Wrap(
                spacing: 8,
                children: ['Oui', 'Non', 'Cela dépend']
                    .map(
                      (choice) => ChoiceChip(
                        label: Text(choice),
                        selected: _selectedChoice == choice,
                        onSelected: (_) => setState(() => _selectedChoice = choice),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 10),
            ],
            if (widget.item.format == 'mcq' &&
                widget.item.options != null) ...[
              ...widget.item.options!.map(
                (opt) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    _selectedChoice == opt
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: _selectedChoice == opt
                        ? YitteColors.emerald
                        : null,
                  ),
                  title: Text(opt),
                  onTap: () => setState(() => _selectedChoice = opt),
                ),
              ),
              const SizedBox(height: 8),
            ],
            if (widget.item.format == 'audio_response') ...[
              ConsentVoiceRecorderCard(
                audioService: widget.audioService,
                maxSeconds: widget.item.timeLimitSeconds.clamp(30, 180),
                prefix: 'challenge_${widget.item.id}',
                consentGranted: _audioConsent,
                onConsentChanged: (v) => setState(() => _audioConsent = v),
                speechLocale: 'fr-FR',
                onLiveTranscript: (text) {
                  setState(() {
                    _answerCtrl.text = text;
                  });
                },
                onRecorded: (path, duration) {
                  setState(() {
                    _recordedAudioPath = path;
                  });
                  if (_answerCtrl.text.trim().isEmpty) {
                    _answerCtrl.text =
                        'Plaidoyer vocal enregistré (${duration}s). Résumez vos points clés si la dictée STT n’était pas active.';
                  }
                },
              ),
              const SizedBox(height: 10),
            ],
            TextField(
              controller: _answerCtrl,
              maxLines: widget.item.format == 'mcq' ? 2 : 5,
              decoration: InputDecoration(
                labelText: widget.item.format == 'mcq'
                    ? 'Justification (optionnel pour QCM)'
                    : 'Votre argumentation / développement',
                hintText:
                    'Structurez votre raisonnement : thèse, arguments, nuance et exemples...',
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.check_circle_outline_rounded),
                label: const Text('Soumettre ma réponse'),
                onPressed: () {
                  final rawText = _answerCtrl.text.trim();
                  String finalSubmission;
                  if (widget.item.format == 'yes_no_depends') {
                    if (rawText.length < 10) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Ajoutez une justification écrite d’au moins 10 caractères.',
                          ),
                        ),
                      );
                      return;
                    }
                    finalSubmission = '[${_selectedChoice ?? "Nuancé"}] $rawText';
                  } else if (widget.item.format == 'mcq') {
                    final choice = _selectedChoice ?? '';
                    if (choice.isEmpty) return;
                    finalSubmission = rawText.isEmpty ? choice : '$choice — $rawText';
                  } else {
                    if (rawText.isEmpty && _recordedAudioPath == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Veuillez saisir votre réponse ou enregistrer un plaidoyer audio.',
                          ),
                        ),
                      );
                      return;
                    }
                    finalSubmission = rawText.isEmpty && _recordedAudioPath != null
                        ? 'Réponse vocale enregistrée'
                        : rawText;
                  }
                  widget.onSubmitted(finalSubmission, _recordedAudioPath);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
