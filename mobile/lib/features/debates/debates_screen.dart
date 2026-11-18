import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/state/app_providers.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/models/domain_models.dart';
import '../../core/services/pdf_export_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/editorial_widgets.dart';

class DebatesScreen extends ConsumerStatefulWidget {
  const DebatesScreen({super.key});

  @override
  ConsumerState<DebatesScreen> createState() => _DebatesScreenState();
}

class _DebatesScreenState extends ConsumerState<DebatesScreen> {
  String _selectedMatchId = 'deb-1';
  bool _consentGranted = false;
  bool _asOpponent = false;
  String _retentionPolicy = 'thirty_days';
  String? _recordedAudioPath;
  final _transcriptCtrl = TextEditingController();
  bool _evaluating = false;
  int _prepSeconds = 120;
  Timer? _prepTimer;

  @override
  void dispose() {
    _prepTimer?.cancel();
    _transcriptCtrl.dispose();
    super.dispose();
  }

  void _startPrepTimer() {
    _prepTimer?.cancel();
    setState(() => _prepSeconds = 120);
    _prepTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted || _prepSeconds <= 0) {
        t.cancel();
        return;
      }
      setState(() => _prepSeconds--);
    });
  }

  @override
  Widget build(BuildContext context) {
    final eco = ref.watch(ecosystemProvider);
    final audioService = ref.watch(audioServiceProvider);
    final activeMatch = eco.debates.firstWhere(
      (m) => m.id == _selectedMatchId,
      orElse: () => eco.debates.first,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('YITTÉ FACE-À-FACE'),
        actions: [
          IconButton(
            tooltip: 'Créer un match / Défier',
            icon: const Icon(Icons.add_rounded),
            onPressed: () => _openCreateDebateDialog(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const YitteReveal(
            order: 0,
            child: EditorialHeroBanner(
              eyebrow: 'DÉBATS VOCAUX ÉVALUÉS PAR IA • 100 POINTS',
              title: 'Éloquence, Logique & Nuance',
              subtitle:
                  'L’IA évalue uniquement la qualité de votre raisonnement — jamais votre identité, accent, croyance ou opinion minoritaire.',
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ActionChip(
                avatar: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                label: const Text('Défier un ami'),
                onPressed: () => _openCreateDebateDialog(context, presetType: 'friend_challenge'),
              ),
              ActionChip(
                avatar: const Icon(Icons.shuffle_rounded, size: 18),
                label: const Text('Matchmaking'),
                onPressed: () => _openCreateDebateDialog(context, presetType: 'matchmaking'),
              ),
              ActionChip(
                avatar: const Icon(Icons.public_rounded, size: 18),
                label: const Text('Débat public'),
                onPressed: () => _openCreateDebateDialog(context, presetType: 'public'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: activeMatch.id,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Match sélectionné'),
            items: eco.debates
                .map((d) => DropdownMenuItem(
                      value: d.id,
                      child: Text(
                        '${d.topicTitle} (vs ${d.opponentName})',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
            onChanged: (id) {
              if (id != null) setState(() => _selectedMatchId = id);
            },
          ),
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Chip(
                        label: Text(AppStrings.categoryLabel(activeMatch.category)),
                      ),
                      Chip(
                        label: Text('Adversaire : ${activeMatch.opponentName}'),
                      ),
                      TextButton.icon(
                        onPressed: _startPrepTimer,
                        icon: const Icon(Icons.timer_outlined, size: 18),
                        label: Text('Prép ${_prepSeconds}s'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    activeMatch.topicQuestion,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Votre position : ${AppStrings.positionLabel(activeMatch.userPosition)}  •  Adversaire : ${AppStrings.positionLabel(activeMatch.opponentPosition)}',
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  if (activeMatch.isIslamicSubject) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: YitteColors.goldSoft,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'Sujet islamique : distinction stricte entre savoir scripturaire vérifié et interprétation philosophique. Aucune citation fabriquée.',
                        style: TextStyle(fontSize: 12, color: YitteColors.inkDark),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _retentionPolicy,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Politique de rétention audio',
            ),
            items: const [
              DropdownMenuItem(value: 'session_only', child: Text('Session uniquement (suppression immédiate)')),
              DropdownMenuItem(value: 'thirty_days', child: Text('30 jours')),
              DropdownMenuItem(value: 'ninety_days', child: Text('90 jours')),
              DropdownMenuItem(value: 'permanent_with_consent', child: Text('Archivage avec consentement')),
            ],
            onChanged: (v) => setState(() => _retentionPolicy = v ?? 'thirty_days'),
          ),
          const SizedBox(height: 10),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                value: false,
                label: Text('Thèse (${AppStrings.positionLabel(activeMatch.userPosition)})'),
              ),
              ButtonSegment(
                value: true,
                label: Text('Opposition (${AppStrings.positionLabel(activeMatch.opponentPosition)})'),
              ),
            ],
            selected: {_asOpponent},
            onSelectionChanged: (s) => setState(() => _asOpponent = s.first),
          ),
          const SizedBox(height: 10),
          ConsentVoiceRecorderCard(
            audioService: audioService,
            maxSeconds: 180,
            prefix: 'debate_${activeMatch.id}',
            consentGranted: _consentGranted,
            speechLocale: 'fr-FR',
            onConsentChanged: (v) => setState(() => _consentGranted = v),
            onLiveTranscript: (t) => setState(() => _transcriptCtrl.text = t),
            onRecorded: (path, sec) => setState(() => _recordedAudioPath = path),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _transcriptCtrl,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Transcription / Plaidoyer vocal',
              hintText:
                  'Exprimez votre thèse avec connecteurs logiques, exemples vérifiés et nuances...',
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _evaluating
                  ? null
                  : () async {
                      final text = _transcriptCtrl.text.trim();
                      if (text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Dictez ou saisissez votre plaidoyer pour évaluer votre argumentation.',
                            ),
                          ),
                        );
                        return;
                      }
                      setState(() => _evaluating = true);
                      final speakerName = ref.read(authProvider)?.fullName;
                      await ref.read(ecosystemProvider.notifier).submitDebateSpeech(
                            matchId: activeMatch.id,
                            transcriptText: text,
                            audioPath: _recordedAudioPath,
                            consentGranted: _consentGranted,
                            retentionPolicy: _retentionPolicy,
                            asOpponent: _asOpponent,
                            speakerName: speakerName,
                          );
                      if (mounted) setState(() => _evaluating = false);
                    },
              icon: _evaluating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.psychology_rounded),
              label: const Text('Évaluer mon discours (Grille 100 pts)'),
            ),
          ),
          if (activeMatch.userEvaluation != null || activeMatch.opponentEvaluation != null) ...[
            const SizedBox(height: 20),
            _DebateResultCard(
              match: activeMatch,
              onRequestHumanReview: () => _openHumanReviewDialog(context, activeMatch),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _openCreateDebateDialog(
    BuildContext context, {
    String presetType = 'public',
  }) async {
    final titleCtrl = TextEditingController();
    final questionCtrl = TextEditingController();
    final opponentCtrl = TextEditingController();
    String position = 'for';
    bool isIslamic = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: const Text('Nouveau Match Face-à-Face'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Thème du débat'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: questionCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Question centrale'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: opponentCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Adversaire invité (optionnel)',
                    hintText: 'Laisser vide pour débat ouvert à tous',
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: position,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Votre position'),
                  items: const [
                    DropdownMenuItem(value: 'for', child: Text('Pour')),
                    DropdownMenuItem(value: 'against', child: Text('Contre')),
                    DropdownMenuItem(value: 'nuanced', child: Text('Nuancé')),
                  ],
                  onChanged: (v) => setModalState(() => position = v ?? 'for'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: isIslamic,
                  onChanged: (v) => setModalState(() => isIslamic = v),
                  title: const Text('Sujet de pensée islamique'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
            ElevatedButton(
              onPressed: () {
                if (titleCtrl.text.trim().isEmpty || questionCtrl.text.trim().isEmpty) {
                  return;
                }
                ref.read(ecosystemProvider.notifier).createDebateMatch(
                      topicTitle: titleCtrl.text.trim(),
                      topicQuestion: questionCtrl.text.trim(),
                      category: isIslamic ? 'islamic_thought' : 'philosophy',
                      isIslamicSubject: isIslamic,
                      matchType: presetType,
                      opponentName: opponentCtrl.text.trim().isEmpty
                          ? 'Ouvert à un membre'
                          : opponentCtrl.text.trim(),
                      userPosition: position,
                      creatorName: ref.read(authProvider)?.fullName,
                    );
                Navigator.pop(ctx);
              },
              child: const Text('Lancer le match'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openHumanReviewDialog(
      BuildContext context, DebateMatchModel match) async {
    final reasonCtrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Demander une Révision Humaine'),
        content: TextField(
          controller: reasonCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Motif de la contestation',
            hintText: 'Précisez quel critère semble mal évalué...',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (reasonCtrl.text.trim().length < 5) return;
              ref
                  .read(ecosystemProvider.notifier)
                  .requestHumanDebateReview(match.id, reasonCtrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Envoyer au modérateur'),
          ),
        ],
      ),
    );
  }
}

class _DebateResultCard extends StatelessWidget {
  final DebateMatchModel match;
  final VoidCallback onRequestHumanReview;

  const _DebateResultCard({
    required this.match,
    required this.onRequestHumanReview,
  });

  @override
  Widget build(BuildContext context) {
    final r = match.userEvaluation ?? match.opponentEvaluation!;
    final hasBoth =
        match.userEvaluation != null && match.opponentEvaluation != null;
    return YitteSurfaceCard(
      borderColor: AppTheme.tokensOf(context).borderAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Résultat : ${match.winnerLabel ?? "Évalué"}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Chip(
                  label: Text('${r.totalScore.toStringAsFixed(1)} / 100',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            if (r.isLocalPreview)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Text(
                  'Analyse structurelle locale (connectez Supabase + YITTE_DEBATE_AI pour évaluation IA cloud).',
                  style: TextStyle(fontSize: 12, color: YitteColors.warning),
                ),
              ),
            const Divider(),
            RubricBar(label: 'Pertinence', score: r.relevance, maxScore: 20),
            RubricBar(label: 'Raisonnement logique', score: r.logicalReasoning, maxScore: 25),
            RubricBar(label: 'Profondeur d’analyse', score: r.depthOfAnalysis, maxScore: 20),
            RubricBar(label: 'Arguments & exemples', score: r.argumentsAndExamples, maxScore: 15),
            RubricBar(label: 'Esprit critique & nuance', score: r.criticalNuance, maxScore: 10),
            RubricBar(label: 'Clarté de communication', score: r.clarity, maxScore: 10),
            const SizedBox(height: 8),
            Text(r.explanation),
            if (hasBoth) ...[
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: YitteColors.emeraldSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Comparatif Face-à-Face :\n'
                  '• Thèse (${match.creatorName ?? "Proposant"}) : ${match.userEvaluation!.totalScore.toStringAsFixed(1)} / 100\n'
                  '• Opposition (${match.opponentName}) : ${match.opponentEvaluation!.totalScore.toStringAsFixed(1)} / 100',
                  style: const TextStyle(fontSize: 12.5, color: YitteColors.inkDark),
                ),
              ),
            ],
            if (r.recommendations.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text('Recommandations :',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              ...r.recommendations.map((rec) => Text('• $rec')),
            ],
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.gavel_rounded, size: 18),
                  label: Text(match.humanReviewRequested
                      ? 'Révision demandée'
                      : 'Demander révision humaine'),
                  onPressed: match.humanReviewRequested ? null : onRequestHumanReview,
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                  label: const Text('Exporter PDF'),
                  onPressed: () async {
                    final bytes = await PdfExportService.buildDebateEvaluationPdf(
                      match: match,
                      rubric: r,
                    );
                    await PdfExportService.previewAndSharePdf(
                      bytes: bytes,
                      filename: 'debat_${match.id}.pdf',
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      );
  }
}
