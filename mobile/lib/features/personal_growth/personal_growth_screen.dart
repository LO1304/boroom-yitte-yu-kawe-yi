import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/state/app_providers.dart';
import '../../core/services/backend_repository.dart';
import '../../core/services/pdf_export_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/editorial_widgets.dart';

class PersonalGrowthScreen extends ConsumerStatefulWidget {
  const PersonalGrowthScreen({super.key});

  @override
  ConsumerState<PersonalGrowthScreen> createState() =>
      _PersonalGrowthScreenState();
}

class _PersonalGrowthScreenState extends ConsumerState<PersonalGrowthScreen> {
  final _noteTitleCtrl = TextEditingController();
  final _noteBodyCtrl = TextEditingController();
  final _goalCtrl = TextEditingController();
  final _mentorPromptCtrl = TextEditingController();
  String? _mentorReply;
  double _focusAssessment = 7;
  int _deepWorkMinutes = 45;
  int _focusSecondsLeft = 45 * 60;
  bool _focusRunning = false;
  Timer? _focusTimer;

  @override
  void dispose() {
    _focusTimer?.cancel();
    _noteTitleCtrl.dispose();
    _noteBodyCtrl.dispose();
    _goalCtrl.dispose();
    _mentorPromptCtrl.dispose();
    super.dispose();
  }

  void _toggleFocusTimer() {
    if (_focusRunning) {
      _focusTimer?.cancel();
      setState(() => _focusRunning = false);
      return;
    }
    setState(() => _focusRunning = true);
    _focusTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      if (_focusSecondsLeft <= 1) {
        t.cancel();
        setState(() {
          _focusSecondsLeft = 0;
          _focusRunning = false;
        });
        ref.read(ecosystemProvider.notifier).addPrivateNote(
              'focus_block',
              'Session Deep Work ($_deepWorkMinutes min)',
              'Bloc terminé avec auto-évaluation ${_focusAssessment.toStringAsFixed(0)}/10.',
            );
      } else {
        setState(() => _focusSecondsLeft--);
      }
    });
  }

  void _resetFocusTimer() {
    _focusTimer?.cancel();
    setState(() {
      _focusRunning = false;
      _focusSecondsLeft = _deepWorkMinutes * 60;
    });
  }

  String _formatChrono(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final eco = ref.watch(ecosystemProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Développement Personnel'),
        actions: [
          IconButton(
            tooltip: 'Exporter mon bilan PDF',
            icon: const Icon(Icons.picture_as_pdf_outlined),
            onPressed: () async {
              final bytes = await PdfExportService.buildSummaryPdf(
                title: 'Rapport Personnel de Progression',
                subtitle: 'Document confidentiel — Boroom Yitté Yu Kawé Yi',
                bodyMarkdown:
                    'Objectifs actifs : ${eco.personalGoals.length}\n'
                    'Habitudes suivies : ${eco.habits.length}\n'
                    'Notes privées enregistrées : ${eco.privateNotes.length}',
                bulletPoints: eco.personalGoals
                    .map((g) => '${g.title} (${g.progressPercent}%)')
                    .toList(),
              );
              await PdfExportService.previewAndSharePdf(
                bytes: bytes,
                filename: 'rapport_progression_personnel.pdf',
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const YitteReveal(
            order: 0,
            child: EditorialHeroBanner(
              eyebrow: 'ESPACE STRICTEMENT PRIVÉ (RLS PERSONNEL)',
              title: 'Discipline, Clarté & Constance',
              subtitle:
                  'Vos notes privées, réflexions quotidiennes et auto-évaluations ne sont visibles par aucun autre membre ni administrateur.',
              trailing: Icon(Icons.lock_rounded, color: YitteColors.goldBright),
            ),
          ),
          const SizedBox(height: 16),
          const SectionHeader(title: 'Objectifs Hebdomadaires'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _goalCtrl,
                  decoration: const InputDecoration(labelText: 'Nouvel objectif'),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  if (_goalCtrl.text.trim().isEmpty) return;
                  ref
                      .read(ecosystemProvider.notifier)
                      .addPersonalGoal(_goalCtrl.text.trim(), 'weekly');
                  _goalCtrl.clear();
                },
                child: const Text('Ajouter'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...eco.personalGoals.map(
            (g) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(g.title),
                subtitle: LinearProgressIndicator(value: g.progressPercent / 100),
                trailing: TextButton(
                  onPressed: () =>
                      ref.read(ecosystemProvider.notifier).bumpGoalProgress(g.id),
                  child: Text('${g.progressPercent}% +'),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SectionHeader(
            title: 'Suivi d’Habitudes & Discipline',
            actionLabel: '+ Habitude',
            onAction: () => _openAddHabitDialog(context),
          ),
          const SizedBox(height: 8),
          ...eco.habits.map(
            (h) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: CheckboxListTile(
                value: h.completedToday,
                onChanged: (_) =>
                    ref.read(ecosystemProvider.notifier).toggleHabitToday(h.id),
                title: Text(h.name),
                subtitle: Text('Série actuelle : ${h.streakDays} jour(s)'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          SectionHeader(
            title: 'Suivi de Lecture',
            actionLabel: '+ Livre',
            onAction: () => _openAddBookDialog(context),
          ),
          const SizedBox(height: 8),
          ...eco.books.map(
            (b) {
              final ratio = b.totalPages > 0
                  ? (b.currentPage / b.totalPages).clamp(0.0, 1.0)
                  : 0.0;
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.auto_stories_rounded,
                              color: YitteColors.emerald),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(b.title,
                                    style: const TextStyle(fontWeight: FontWeight.w700)),
                                Text(
                                  '${b.author} • Page ${b.currentPage}/${b.totalPages} (${(ratio * 100).round()}%)',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: '-10 pages',
                            icon: const Icon(Icons.remove_circle_outline_rounded),
                            onPressed: () => ref
                                .read(ecosystemProvider.notifier)
                                .updateBookProgress(b.id, -10),
                          ),
                          IconButton(
                            tooltip: '+10 pages',
                            icon: const Icon(Icons.add_circle_outline_rounded),
                            onPressed: () => ref
                                .read(ecosystemProvider.notifier)
                                .updateBookProgress(b.id, 10),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(value: ratio),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          const SectionHeader(title: 'Gestion du Temps & Auto-Évaluation'),
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
                          'Bloc de travail profond : $_deepWorkMinutes min',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      Chip(
                        avatar: const Icon(Icons.timer_outlined, size: 16),
                        label: Text(
                          _formatChrono(_focusSecondsLeft),
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontFeatures: [FontFeature.tabularFigures()],
                          ),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _deepWorkMinutes.toDouble(),
                    min: 15,
                    max: 120,
                    divisions: 7,
                    label: '$_deepWorkMinutes min',
                    onChanged: _focusRunning
                        ? null
                        : (v) => setState(() {
                              _deepWorkMinutes = v.round();
                              _focusSecondsLeft = _deepWorkMinutes * 60;
                            }),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _toggleFocusTimer,
                        icon: Icon(_focusRunning
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded),
                        label: Text(_focusRunning ? 'Pause' : 'Démarrer le chrono'),
                      ),
                      OutlinedButton.icon(
                        onPressed: _resetFocusTimer,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: const Text('Réinitialiser'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text('Auto-évaluation discipline du jour : ${_focusAssessment.toStringAsFixed(0)} / 10'),
                  Slider(
                    value: _focusAssessment,
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: _focusAssessment.toStringAsFixed(0),
                    onChanged: (v) => setState(() => _focusAssessment = v),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const SectionHeader(title: 'Mentor Personnel IA (YITTE_PERSONAL_MENTOR)'),
          const SizedBox(height: 8),
          TextField(
            controller: _mentorPromptCtrl,
            decoration: const InputDecoration(
              labelText: 'Décrivez un défi de discipline ou de gestion du temps',
            ),
          ),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            icon: const Icon(Icons.psychology_alt_rounded),
            label: const Text('Consulter mon Mentor IA'),
            onPressed: () async {
              if (_mentorPromptCtrl.text.trim().isEmpty) return;
              final reply = await BackendRepository.instance.callAiAgent(
                agentName: 'YITTE_PERSONAL_MENTOR',
                prompt: _mentorPromptCtrl.text.trim(),
              );
              if (mounted) setState(() => _mentorReply = reply);
            },
          ),
          if (_mentorReply != null)
            Card(
              margin: const EdgeInsets.only(top: 10),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(_mentorReply!),
              ),
            ),
          const SizedBox(height: 18),
          const SectionHeader(title: 'Journal Privé & Notes Confidentielles'),
          const SizedBox(height: 8),
          TextField(
            controller: _noteTitleCtrl,
            decoration: const InputDecoration(labelText: 'Titre de la note privée'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _noteBodyCtrl,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Contenu confidentiel'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () {
              if (_noteTitleCtrl.text.trim().isEmpty ||
                  _noteBodyCtrl.text.trim().isEmpty) {
                return;
              }
              ref.read(ecosystemProvider.notifier).addPrivateNote(
                    'journal',
                    _noteTitleCtrl.text.trim(),
                    _noteBodyCtrl.text.trim(),
                  );
              _noteTitleCtrl.clear();
              _noteBodyCtrl.clear();
            },
            child: const Text('Enregistrer en privé'),
          ),
          const SizedBox(height: 10),
          ...eco.privateNotes.map(
            (n) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: const Icon(Icons.lock_outline_rounded),
                title: Text(n.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(n.content),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddHabitDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _AddHabitDialog(
        onAdd: (name) =>
            ref.read(ecosystemProvider.notifier).addHabit(name),
      ),
    );
  }

  Future<void> _openAddBookDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _AddBookDialog(
        onAdd: (title, author, pages) {
          ref.read(ecosystemProvider.notifier).addBook(title, author, pages);
        },
      ),
    );
  }
}

class _AddBookDialog extends StatefulWidget {
  final void Function(String title, String author, int pages) onAdd;

  const _AddBookDialog({required this.onAdd});

  @override
  State<_AddBookDialog> createState() => _AddBookDialogState();
}

class _AddBookDialogState extends State<_AddBookDialog> {
  final _titleCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();
  final _pagesCtrl = TextEditingController(text: '240');

  @override
  void dispose() {
    _titleCtrl.dispose();
    _authorCtrl.dispose();
    _pagesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ajouter un livre à suivre'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: 'Titre du livre'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _authorCtrl,
            decoration: const InputDecoration(labelText: 'Auteur'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _pagesCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Nombre total de pages'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            final title = _titleCtrl.text.trim();
            final author = _authorCtrl.text.trim();
            final pages = int.tryParse(_pagesCtrl.text.trim()) ?? 200;
            if (title.isEmpty) return;
            widget.onAdd(
              title,
              author.isEmpty ? 'Auteur non précisé' : author,
              pages,
            );
            Navigator.pop(context);
          },
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}

class _AddHabitDialog extends StatefulWidget {
  final ValueChanged<String> onAdd;

  const _AddHabitDialog({required this.onAdd});

  @override
  State<_AddHabitDialog> createState() => _AddHabitDialogState();
}

class _AddHabitDialogState extends State<_AddHabitDialog> {
  final _nameCtrl = TextEditingController();

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nouvelle Habitude Quotidienne'),
      content: TextField(
        controller: _nameCtrl,
        decoration: const InputDecoration(
          labelText: 'Nom de l’habitude (ex. Lecture 15 pages)',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            final name = _nameCtrl.text.trim();
            if (name.isEmpty) return;
            widget.onAdd(name);
            Navigator.pop(context);
          },
          child: const Text('Ajouter'),
        ),
      ],
    );
  }
}
