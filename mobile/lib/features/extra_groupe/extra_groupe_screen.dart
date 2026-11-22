import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';

import '../../app/state/app_providers.dart';
import '../../core/models/domain_models.dart';
import '../../core/services/external_link_bridge.dart';
import '../../core/services/pdf_export_service.dart';
import '../../core/services/whatsapp_bridge_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/editorial_widgets.dart';

const _egUuid = Uuid();

class ExtraGroupeScreen extends ConsumerStatefulWidget {
  const ExtraGroupeScreen({super.key});

  @override
  ConsumerState<ExtraGroupeScreen> createState() => _ExtraGroupeScreenState();
}

class _ExtraGroupeScreenState extends ConsumerState<ExtraGroupeScreen> {
  int _tabIndex = 0; // 0: Prochaines rencontres, 1: Archives & Comptes rendus
  final _questionCtrl = TextEditingController();
  final _reportCtrl = TextEditingController();
  String? _selectedMeetingId;

  @override
  void dispose() {
    _questionCtrl.dispose();
    _reportCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eco = ref.watch(ecosystemProvider);
    final profile = ref.watch(authProvider);
    final isAdmin = profile?.role.isEditorOrAbove ?? false;

    final filtered = eco.extraGroupeMeetings
        .where((m) =>
            _tabIndex == 0 ? m.status != 'archived' : m.status == 'archived')
        .toList();

    final ExtraGroupeMeetingModel? active = filtered.isEmpty
        ? null
        : filtered.firstWhere(
            (m) => m.id == _selectedMeetingId,
            orElse: () => filtered.first,
          );

    return Scaffold(
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text('Extra Groupe • Rencontres Mensuelles'),
        ),
        actions: [
          if (isAdmin)
            IconButton(
              tooltip: 'Programmer une rencontre',
              icon: const Icon(Icons.add_circle_outline_rounded),
              onPressed: () => _openCreateMeetingDialog(context),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
        children: [
          const YitteReveal(
            order: 0,
            child: EditorialHeroBanner(
              eyebrow: 'RENCONTRES MENSUELLES AVEC INVITÉ EXTÉRIEUR',
              title: 'Extra Groupe',
              subtitle:
                  'Un espace distinct des échanges hebdomadaires pour recevoir une personnalité inspirante, préparer vos questions et archiver les enseignements.',
            ),
          ),
          const SizedBox(height: 14),
          SegmentedButton<int>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 0, label: Text('Prochaines rencontres')),
              ButtonSegment(value: 1, label: Text('Archives & Comptes rendus')),
            ],
            selected: {_tabIndex},
            onSelectionChanged: (s) => setState(() {
              _tabIndex = s.first;
              _selectedMeetingId = null;
            }),
          ),
          const SizedBox(height: 16),
          if (active == null)
            YitteEmptyState(
              icon: Icons.event_note_outlined,
              title: _tabIndex == 0
                  ? 'Aucune rencontre Extra Groupe programmée'
                  : 'Aucune rencontre archivée pour le moment',
              description:
                  'Les comptes rendus validés apparaîtront ici dès qu’une rencontre mensuelle sera clôturée.',
            )
          else ...[
            if (filtered.length > 1) ...[
              DropdownButtonFormField<String>(
                initialValue: active.id,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Rencontre'),
                items: filtered
                    .map(
                      (m) => DropdownMenuItem(
                        value: m.id,
                        child: Text('${m.guest.fullName} — ${m.theme}'),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _selectedMeetingId = v),
              ),
              const SizedBox(height: 14),
            ],
            // Guest card
            YitteReveal(
              order: 1,
              child: YitteSurfaceCard(
                borderColor: AppTheme.tokensOf(context).borderAccent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: YitteColors.emeraldSoft,
                          child: const Icon(Icons.record_voice_over_rounded,
                              color: YitteColors.emerald),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                active.guest.fullName,
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              Text(
                                active.guest.titleOrRole,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                        YitteStatusPill(
                          label: active.status == 'archived'
                              ? 'Archivée'
                              : 'Programmée',
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      active.theme,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      active.guest.biography,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    if (active.guest.expertiseDomains.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: active.guest.expertiseDomains
                            .map((d) => YitteStatusPill(label: d))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Official presentation & context
            YitteReveal(
              order: 2,
              child: YitteSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'Présentation & Contexte'),
                    const SizedBox(height: 10),
                    Text(active.presentationText),
                    if (active.objectives.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text('Objectifs de la rencontre :',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      ...active.objectives.map((o) => Text('• $o')),
                    ],
                    if (active.programItems.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      const Text('Programme :',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      ...active.programItems
                          .asMap()
                          .entries
                          .map((p) => Text('${p.key + 1}. ${p.value}')),
                    ],
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        YitteStatusPill(
                          icon: Icons.event_available_rounded,
                          label:
                              'Date prévue : ${active.scheduledAt.day.toString().padLeft(2, '0')}/${active.scheduledAt.month.toString().padLeft(2, '0')}/${active.scheduledAt.year}',
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.share_outlined, size: 18),
                          label: const Text('Partager sur WhatsApp'),
                          onPressed: () {
                            final dateLabel =
                                '${active.scheduledAt.day.toString().padLeft(2, '0')}/${active.scheduledAt.month.toString().padLeft(2, '0')}/${active.scheduledAt.year}';
                            final formatted =
                                WhatsAppBridgeService.formatTopicQuestionsDigest(
                              subjectTitle: active.theme,
                              contextLabel:
                                  'Extra Groupe • Invité : ${active.guest.fullName}',
                              subtitle: 'Date prévue : $dateLabel',
                              items: active.questions
                                  .map(
                                    (q) => (
                                      author: q.authorName,
                                      text: q.questionText,
                                      answer: q.answerText,
                                    ),
                                  )
                                  .toList(),
                            );
                            _shareFormattedToWhatsApp(
                              context,
                              formatted,
                              eco.whatsappInviteUrl,
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: active.recordingAuthorized,
                      onChanged: isAdmin
                          ? (v) => ref
                              .read(ecosystemProvider.notifier)
                              .toggleExtraGroupeRecordingConsent(active.id, v)
                          : null,
                      title: const Text(
                        'Autorisation explicite d’enregistrement audio/vidéo',
                        style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(active.practicalInfo),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Questions & Answers
            YitteReveal(
              order: 3,
              child: YitteSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      title: 'Questions Préparées & Échanges',
                      actionLabel: active.questions.isNotEmpty
                          ? 'Partager tout (WhatsApp)'
                          : null,
                      onAction: active.questions.isNotEmpty
                          ? () {
                              final formatted = WhatsAppBridgeService
                                  .formatTopicQuestionsDigest(
                                subjectTitle: active.theme,
                                contextLabel:
                                    'Extra Groupe • Invité : ${active.guest.fullName}',
                                items: active.questions
                                    .map(
                                      (q) => (
                                        author: q.authorName,
                                        text: q.questionText,
                                        answer: q.answerText,
                                      ),
                                    )
                                    .toList(),
                              );
                              _shareFormattedToWhatsApp(
                                context,
                                formatted,
                                eco.whatsappInviteUrl,
                              );
                            }
                          : null,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _questionCtrl,
                            decoration: const InputDecoration(
                              hintText:
                                  'Poser une question réfléchie pour l’invité...',
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: () {
                            final q = _questionCtrl.text.trim();
                            if (q.length < 5) return;
                            ref
                                .read(ecosystemProvider.notifier)
                                .addExtraGroupeQuestion(
                                  active.id,
                                  profile?.fullName ?? 'Membre du cercle',
                                  q,
                                );
                            _questionCtrl.clear();
                          },
                          child: const Text('Envoyer'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (active.questions.isEmpty)
                      const Text(
                        'Aucune question enregistrée pour cette rencontre. Préparez vos questions ci-dessus.',
                      )
                    else
                      ...active.questions.map(
                        (q) => Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppTheme.tokensOf(context).subtleFill,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${q.authorName} :',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Partager cette question sur WhatsApp',
                                    visualDensity: VisualDensity.compact,
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(),
                                    icon: const Icon(
                                      Icons.share_outlined,
                                      size: 18,
                                      color: YitteColors.emerald,
                                    ),
                                    onPressed: () {
                                      final formatted = WhatsAppBridgeService
                                          .formatSingleMemberQuestion(
                                        subjectTitle: active.theme,
                                        contextLabel:
                                            'Extra Groupe • Invité : ${active.guest.fullName}',
                                        authorName: q.authorName,
                                        questionText: q.questionText,
                                        answerText: q.answerText,
                                      );
                                      _shareFormattedToWhatsApp(
                                        context,
                                        formatted,
                                        eco.whatsappInviteUrl,
                                      );
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(q.questionText),
                              if (q.answerText != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Réponse : ${q.answerText}',
                                  style: const TextStyle(
                                      color: YitteColors.emerald,
                                      fontWeight: FontWeight.w600),
                                ),
                              ] else if (isAdmin)
                                TextButton(
                                  onPressed: () =>
                                      _openAnswerDialog(context, active.id, q.id),
                                  child: const Text('Renseigner la réponse'),
                                ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Privacy-gated Participants Roster
            YitteReveal(
              order: 4,
              child: YitteSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionHeader(
                      title:
                          'Participants (${active.registeredParticipants.length})',
                    ),
                    const SizedBox(height: 8),
                    if (isAdmin)
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        value: active.rosterPublicToCircle,
                        onChanged: (v) => ref
                            .read(ecosystemProvider.notifier)
                            .toggleExtraGroupeRosterVisibility(active.id, v),
                        title: const Text(
                          'Autoriser l’affichage de la liste aux membres authentifiés',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    if (!isAdmin &&
                        (!active.rosterPublicToCircle || profile == null))
                      const Text(
                        'Liste des participants protégée par les paramètres de confidentialité (visible uniquement après authentification et autorisation du responsable).',
                      )
                    else
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: active.registeredParticipants
                            .map((name) => YitteStatusPill(label: name))
                            .toList(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            // Summary Report & Archive
            YitteReveal(
              order: 5,
              child: YitteSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SectionHeader(title: 'Compte Rendu & Synthèse'),
                    const SizedBox(height: 8),
                    if (active.meetingReport != null &&
                        active.meetingReport!.isNotEmpty) ...[
                      Text(active.meetingReport!),
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('Exporter compte rendu PDF'),
                        onPressed: () async {
                          final bytes = await PdfExportService.buildSummaryPdf(
                            title: 'Extra Groupe : ${active.guest.fullName}',
                            subtitle: active.theme,
                            bodyMarkdown: active.meetingReport!,
                            bulletPoints: active.objectives,
                          );
                          await PdfExportService.previewAndSharePdf(
                            bytes: bytes,
                            filename: 'extra_groupe_${active.id}.pdf',
                          );
                        },
                      ),
                    ] else
                      const Text(
                        'Aucun compte rendu publié pour l’instant. Le responsable peut le rédiger après la rencontre.',
                      ),
                    if (isAdmin) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: _reportCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Rédiger / mettre à jour le compte rendu',
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              if (_reportCtrl.text.trim().isEmpty) return;
                              ref
                                  .read(ecosystemProvider.notifier)
                                  .updateExtraGroupeMeetingReport(
                                    active.id,
                                    _reportCtrl.text.trim(),
                                    archive: false,
                                  );
                            },
                            child: const Text('Enregistrer compte rendu'),
                          ),
                          OutlinedButton(
                            onPressed: () {
                              ref
                                  .read(ecosystemProvider.notifier)
                                  .updateExtraGroupeMeetingReport(
                                    active.id,
                                    _reportCtrl.text.trim().isNotEmpty
                                        ? _reportCtrl.text.trim()
                                        : (active.meetingReport ??
                                            'Rencontre clôturée et archivée.'),
                                    archive: true,
                                  );
                            },
                            child: const Text('Clôturer & Archiver'),
                          ),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.delete_outline_rounded,
                                size: 18, color: YitteColors.danger),
                            label: const Text('Supprimer cette rencontre'),
                            onPressed: () {
                              ref
                                  .read(ecosystemProvider.notifier)
                                  .deleteExtraGroupeMeeting(active.id);
                              setState(() => _selectedMeetingId = null);
                            },
                          ),
                        ],
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

  void _shareFormattedToWhatsApp(
    BuildContext context,
    String formattedMessage,
    String? inviteUrl,
  ) {
    final url = WhatsAppBridgeService.buildShareUrl(
      formattedMessage,
      groupInviteUrl: inviteUrl,
    );
    Clipboard.setData(ClipboardData(text: formattedMessage));
    ExternalLinkBridge.openUrl(url);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message prêt pour WhatsApp (et copié dans le presse-papiers).'),
      ),
    );
  }

  Future<void> _openAnswerDialog(
      BuildContext context, String meetingId, String questionId) async {
    final ctrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Réponse de l’invité / synthèse'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Réponse'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isEmpty) return;
              ref
                  .read(ecosystemProvider.notifier)
                  .answerExtraGroupeQuestion(meetingId, questionId, ctrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Valider'),
          ),
        ],
      ),
    );
  }

  Future<void> _openCreateMeetingDialog(BuildContext context) async {
    final guestCtrl = TextEditingController();
    final roleCtrl = TextEditingController();
    final themeCtrl = TextEditingController();
    final presCtrl = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Programmer une Rencontre Extra Groupe'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: guestCtrl,
                decoration: const InputDecoration(labelText: 'Nom de l’invité *'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: roleCtrl,
                decoration: const InputDecoration(labelText: 'Qualité / parcours'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: themeCtrl,
                decoration: const InputDecoration(labelText: 'Thème de la rencontre *'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: presCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: 'Présentation'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              if (guestCtrl.text.trim().isEmpty || themeCtrl.text.trim().isEmpty) {
                return;
              }
              final meeting = ExtraGroupeMeetingModel(
                id: _egUuid.v4(),
                guest: ExtraGroupeGuestModel(
                  id: _egUuid.v4(),
                  fullName: guestCtrl.text.trim(),
                  titleOrRole: roleCtrl.text.trim(),
                  biography: roleCtrl.text.trim(),
                ),
                theme: themeCtrl.text.trim(),
                presentationText: presCtrl.text.trim(),
                scheduledAt: DateTime.now().add(const Duration(days: 14)),
                practicalInfo:
                    'Enregistrement autorisé uniquement avec consentement préalable.',
              );
              ref
                  .read(ecosystemProvider.notifier)
                  .createExtraGroupeMeeting(meeting);
              Navigator.pop(ctx);
            },
            child: const Text('Programmer'),
          ),
        ],
      ),
    );
  }
}
