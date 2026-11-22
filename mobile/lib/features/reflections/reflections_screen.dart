import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/state/app_providers.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/models/domain_models.dart';
import '../../core/services/external_link_bridge.dart';
import '../../core/services/file_picker_bridge.dart';
import '../../core/services/pdf_export_service.dart';
import '../../core/services/whatsapp_bridge_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/editorial_widgets.dart';

class ReflectionsScreen extends ConsumerStatefulWidget {
  const ReflectionsScreen({super.key});

  @override
  ConsumerState<ReflectionsScreen> createState() => _ReflectionsScreenState();
}

class _ReflectionsScreenState extends ConsumerState<ReflectionsScreen> {
  int _tabIndex = 0; // 0: Feed, 1: Weekly Topic & AI Summary, 2: Digital Library
  final _contribCtrl = TextEditingController();
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _filterCategory = 'all';
  bool _showArchived = false;

  static const _filterCategories = {
    'all': 'Toutes',
    'islamic_thought': 'Pensée islamique',
    'philosophy': 'Philosophie',
    'spirituality': 'Spiritualité',
    'ethics': 'Éthique',
    'science': 'Sciences',
    'society': 'Société',
  };

  @override
  void dispose() {
    _contribCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eco = ref.watch(ecosystemProvider);
    final profile = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Réflexions & Savoir'),
        actions: [
          IconButton(
            tooltip: 'Bibliothèque Documentaire',
            icon: const Icon(Icons.folder_copy_outlined),
            onPressed: () => context.push('/documents'),
          ),
          IconButton(
            tooltip: 'Publier / Proposer un sujet',
            icon: const Icon(Icons.edit_note_rounded),
            onPressed: () => _openPublishDialog(context),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              style: SegmentedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                textStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600),
              ),
              segments: const [
                ButtonSegment(value: 0, label: Text('Publications')),
                ButtonSegment(value: 1, label: Text('Sujet Semaine')),
                ButtonSegment(value: 2, label: Text('Bibliothèque')),
              ],
              selected: {_tabIndex},
              onSelectionChanged: (s) => setState(() => _tabIndex = s.first),
            ),
          ),
          Expanded(
            child: _tabIndex == 0
                ? _buildFeed(context, eco.reflections, profile)
                : _tabIndex == 1
                    ? _buildWeeklyTopic(context, eco.weeklyTopic, profile)
                    : _buildLibrary(
                        context,
                        eco.reflections.where((r) => r.isFeaturedInLibrary || r.isSaved).toList(),
                      ),
          ),
        ],
      ),
      floatingActionButton: _tabIndex == 0
          ? FloatingActionButton.extended(
              onPressed: () => _openPublishDialog(context),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Publier'),
            )
          : null,
    );
  }

  Widget _buildFeed(
    BuildContext context,
    List<ReflectionPost> posts,
    UserProfile? profile,
  ) {
    final q = _searchQuery.trim().toLowerCase();
    final filtered = posts.where((p) {
      if (p.isArchived != _showArchived) return false;
      if (_filterCategory != 'all' && p.category != _filterCategory) {
        return false;
      }
      if (q.isEmpty) return true;
      return p.title.toLowerCase().contains(q) ||
          p.body.toLowerCase().contains(q) ||
          p.authorName.toLowerCase().contains(q);
    }).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 90),
      children: [
        TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            hintText: 'Rechercher une réflexion, un thème ou un auteur...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: ChoiceChip(
                  label: const Text('Toutes'),
                  selected: !_showArchived && _filterCategory == 'all',
                  onSelected: (_) => setState(() {
                    _showArchived = false;
                    _filterCategory = 'all';
                  }),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 6),
                child: FilterChip(
                  label: const Text('Archivées'),
                  selected: _showArchived,
                  onSelected: (v) => setState(() => _showArchived = v),
                ),
              ),
              ..._filterCategories.entries
                  .where((e) => e.key != 'all')
                  .map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(e.value),
                        selected: !_showArchived && _filterCategory == e.key,
                        onSelected: (_) => setState(() {
                          _showArchived = false;
                          _filterCategory = e.key;
                        }),
                      ),
                    ),
                  ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                _showArchived
                    ? 'Aucune réflexion archivée pour l’instant.'
                    : 'Aucune publication ne correspond à votre recherche.',
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ...filtered.map(
          (p) => YitteSurfaceCard(
            margin: const EdgeInsets.only(bottom: 14),
            borderColor: p.isHistoricalArchive
                ? AppTheme.tokensOf(context).borderAccent
                : null,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 17,
                      backgroundColor: YitteColors.emeraldSoft,
                      child: Text(
                        p.authorName.isNotEmpty ? p.authorName[0] : 'M',
                        style: const TextStyle(
                            color: YitteColors.emerald, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(p.authorName,
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text(
                            '${AppStrings.categoryLabel(p.category)}${p.discussionDateLabel != null ? " • ${p.discussionDateLabel}" : ""}',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Enregistrer',
                      icon: Icon(
                        p.isSaved ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                        color: p.isSaved ? YitteColors.gold : null,
                      ),
                      onPressed: () =>
                          ref.read(ecosystemProvider.notifier).toggleSaveReflection(p.id),
                    ),
                    if (profile?.role.isEditorOrAbove ?? false)
                      IconButton(
                        tooltip: 'Ajouter à la bibliothèque',
                        icon: Icon(
                          p.isFeaturedInLibrary
                              ? Icons.local_library_rounded
                              : Icons.local_library_outlined,
                          color: p.isFeaturedInLibrary ? YitteColors.emerald : null,
                        ),
                        onPressed: () =>
                            ref.read(ecosystemProvider.notifier).featureInLibrary(p.id),
                      ),
                    IconButton(
                      tooltip: p.isArchived ? 'Désarchiver' : 'Archiver',
                      icon: Icon(
                        p.isArchived
                            ? Icons.unarchive_outlined
                            : Icons.inventory_2_outlined,
                        size: 20,
                      ),
                      onPressed: () =>
                          ref.read(ecosystemProvider.notifier).toggleArchiveReflection(p.id),
                    ),
                    if (profile != null &&
                        (profile.role.isAdminOrAbove ||
                            (!p.isHistoricalArchive &&
                                (p.authorId == profile.id ||
                                    p.authorName == profile.fullName))))
                      IconButton(
                        tooltip: 'Supprimer ce sujet',
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: YitteColors.danger,
                        ),
                        onPressed: () {
                          final ok = ref
                              .read(ecosystemProvider.notifier)
                              .deleteReflection(p.id, actor: profile);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                ok
                                    ? 'Sujet / publication supprimé.'
                                    : 'Action réservée à l’auteur ou à un administrateur.',
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ),
                if (p.isHistoricalArchive || p.validationStatus == 'pending') ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (p.isHistoricalArchive)
                        const YitteStatusPill(
                          icon: Icons.auto_stories_outlined,
                          label: 'Archive communautaire',
                        ),
                      if (p.validationStatus == 'pending')
                        const YitteStatusPill(
                          label: 'Proposition en attente de validation',
                        ),
                    ],
                  ),
                ],
                const SizedBox(height: 10),
                Text(p.title, style: Theme.of(context).textTheme.titleLarge),
                if (p.contextText != null && p.contextText!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text('Contexte : ${p.contextText!}',
                      style: Theme.of(context).textTheme.bodyMedium),
                ],
                const SizedBox(height: 8),
                Text(p.body),
                if (p.reflectionAxes.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text('Axes de discussion :',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 4),
                  ...p.reflectionAxes.map((ax) => Text('• $ax')),
                ],
                if (p.mainQuestions.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text('Questions principales :',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  const SizedBox(height: 4),
                  ...p.mainQuestions.map((mq) => Text('? $mq')),
                ],
                if (p.documentarySources.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: p.documentarySources
                        .map((s) => YitteStatusPill(
                              icon: Icons.menu_book_outlined,
                              label: s,
                            ))
                        .toList(),
                  ),
                ],
                if (p.attachmentName != null) ...[
                  const SizedBox(height: 8),
                  Chip(
                    avatar: const Icon(Icons.attach_file_rounded, size: 16),
                    label: Text(p.attachmentName!),
                  ),
                ],
                const Divider(height: 22),
                Row(
                  children: [
                    TextButton.icon(
                      onPressed: () =>
                          ref.read(ecosystemProvider.notifier).toggleReaction(p.id),
                      icon: const Icon(Icons.thumb_up_alt_outlined, size: 18),
                      label: Text('${p.reactionsCount} Utile'),
                    ),
                    TextButton.icon(
                      onPressed: () => _openCommentDialog(context, p),
                      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 18),
                      label: Text('${p.comments.length} Commenter'),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Partager vers WhatsApp',
                      icon: const Icon(Icons.share_outlined, size: 20),
                      onPressed: () {
                        final eco = ref.read(ecosystemProvider);
                        final formatted =
                            WhatsAppBridgeService.formatReflectionForWhatsApp(
                          title: p.title,
                          authorName: p.authorName,
                          body: p.body,
                          mainQuestions: p.mainQuestions,
                          comments: p.comments
                              .map((c) => (author: c.authorName, body: c.body))
                              .toList(),
                        );
                        _shareFormattedToWhatsApp(
                          context,
                          formatted,
                          eco.whatsappInviteUrl,
                        );
                      },
                    ),
                    IconButton(
                      tooltip: 'Exporter PDF',
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
                      onPressed: () async {
                        final bytes = await PdfExportService.buildSummaryPdf(
                          title: p.title,
                          subtitle: 'Par ${p.authorName} • ${p.category}',
                          bodyMarkdown: p.body,
                        );
                        await PdfExportService.previewAndSharePdf(
                          bytes: bytes,
                          filename: 'reflexion_${p.id}.pdf',
                        );
                      },
                    ),
                  ],
                ),
                if (p.comments.isNotEmpty)
                  ...p.comments.map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.tokensOf(context).subtleFill,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                '${c.authorName} : ${c.body}',
                                style: const TextStyle(fontSize: 12.5),
                              ),
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              tooltip: 'Partager sur WhatsApp',
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(
                                Icons.share_outlined,
                                size: 16,
                                color: YitteColors.emerald,
                              ),
                              onPressed: () {
                                final eco = ref.read(ecosystemProvider);
                                final formatted = WhatsAppBridgeService
                                    .formatSingleMemberQuestion(
                                  subjectTitle: p.title,
                                  contextLabel: 'Réflexion & Échange communautaire',
                                  authorName: c.authorName,
                                  questionText: c.body,
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
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
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

  Widget _buildWeeklyTopic(
    BuildContext context,
    WeeklyTopicModel topic,
    UserProfile? profile,
  ) {
    final eco = ref.read(ecosystemProvider);
    final summary = topic.summary;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        EditorialHeroBanner(
          eyebrow: 'DISCUSSION HEBDOMADAIRE • S${topic.weekNumber}',
          title: topic.title,
          subtitle: topic.introduction,
        ),
        const SizedBox(height: 16),
        SectionHeader(
          title: 'Questions directrices',
          actionLabel: 'Partager sur WhatsApp',
          onAction: () {
            final items = <({String? author, String text, String? answer})>[
              ...topic.guidingQuestions.map(
                (q) => (author: null, text: q, answer: null),
              ),
              ...topic.contributions.map(
                (c) => (author: 'Membre du cercle', text: c, answer: null),
              ),
            ];
            final formatted = WhatsAppBridgeService.formatTopicQuestionsDigest(
              subjectTitle: topic.title,
              contextLabel: 'Débat de la Semaine • S${topic.weekNumber}',
              subtitle: topic.introduction,
              items: items,
            );
            _shareFormattedToWhatsApp(context, formatted, eco.whatsappInviteUrl);
          },
        ),
        const SizedBox(height: 8),
        ...topic.guidingQuestions.map(
          (q) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: const Icon(Icons.help_outline_rounded, color: YitteColors.gold),
              title: Text(q, style: const TextStyle(fontSize: 13.5)),
              trailing: IconButton(
                tooltip: 'Partager cette question sur WhatsApp',
                icon: const Icon(
                  Icons.share_outlined,
                  size: 18,
                  color: YitteColors.emerald,
                ),
                onPressed: () {
                  final formatted =
                      WhatsAppBridgeService.formatSingleMemberQuestion(
                    subjectTitle: topic.title,
                    contextLabel: 'Débat de la Semaine • S${topic.weekNumber}',
                    questionText: q,
                  );
                  _shareFormattedToWhatsApp(
                    context,
                    formatted,
                    eco.whatsappInviteUrl,
                  );
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _contribCtrl,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Apporter votre contribution argumentée',
            hintText: 'Partagez une idée, une référence ou une expérience...',
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            ElevatedButton(
              onPressed: () {
                if (_contribCtrl.text.trim().length < 5) return;
                ref
                    .read(ecosystemProvider.notifier)
                    .addTopicContribution(_contribCtrl.text.trim());
                _contribCtrl.clear();
              },
              child: const Text('Contribuer'),
            ),
            const SizedBox(width: 10),
            OutlinedButton.icon(
              icon: const Icon(Icons.auto_awesome_rounded),
              label: const Text('Générer Synthèse IA'),
              onPressed: () =>
                  ref.read(ecosystemProvider.notifier).generateAiSummaryDraft(),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SectionHeader(
          title: 'Contributions & Validation Éditoriale',
          actionLabel: topic.contributions.isNotEmpty ? 'Tout partager' : null,
          onAction: topic.contributions.isNotEmpty
              ? () {
                  final formatted =
                      WhatsAppBridgeService.formatTopicQuestionsDigest(
                    subjectTitle: topic.title,
                    contextLabel: 'Contributions des membres • S${topic.weekNumber}',
                    items: topic.contributions
                        .map(
                          (c) => (author: 'Membre', text: c, answer: null),
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
        const SizedBox(height: 8),
        ...topic.contributions.map(
          (c) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(c)),
                  IconButton(
                    tooltip: 'Partager cette contribution sur WhatsApp',
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(
                      Icons.share_outlined,
                      size: 18,
                      color: YitteColors.emerald,
                    ),
                    onPressed: () {
                      final formatted =
                          WhatsAppBridgeService.formatSingleMemberQuestion(
                        subjectTitle: topic.title,
                        contextLabel: 'Débat de la Semaine • S${topic.weekNumber}',
                        questionText: c,
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
            ),
          ),
        ),
        if (summary != null) ...[
          const SizedBox(height: 14),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(summary.title,
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                      Chip(
                        label: Text(
                          summary.status == 'published'
                              ? 'Publié (Validé)'
                              : 'En attente de revue éditeur',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(summary.summaryMarkdown),
                  const SizedBox(height: 10),
                  ...summary.takeaways.map((t) => Text('• $t')),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      if (summary.status != 'published' &&
                          (profile?.role.isEditorOrAbove ?? false))
                        ElevatedButton.icon(
                          icon: const Icon(Icons.verified_rounded),
                          label: const Text('Valider & Publier (Éditeur)'),
                          onPressed: () => ref
                              .read(ecosystemProvider.notifier)
                              .approveAndPublishSummary(
                                  profile?.fullName ?? 'Éditeur Yitté'),
                        ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('Exporter PDF'),
                        onPressed: () async {
                          final bytes = await PdfExportService.buildSummaryPdf(
                            title: summary.title,
                            subtitle:
                                'Statut : ${summary.status} • Boroom Yitté Yu Kawé Yi',
                            bodyMarkdown: summary.summaryMarkdown,
                            bulletPoints: summary.takeaways,
                            references: summary.verifiedReferences,
                          );
                          await PdfExportService.previewAndSharePdf(
                            bytes: bytes,
                            filename: 'synthese_semaine_${topic.weekNumber}.pdf',
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLibrary(BuildContext context, List<ReflectionPost> curated) {
    final q = _searchQuery.trim().toLowerCase();
    final filtered = q.isEmpty
        ? curated
        : curated
            .where((item) =>
                item.title.toLowerCase().contains(q) ||
                item.body.toLowerCase().contains(q) ||
                item.authorName.toLowerCase().contains(q))
            .toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
      children: [
        TextField(
          controller: _searchCtrl,
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            hintText: 'Rechercher dans la bibliothèque numérique...',
            prefixIcon: const Icon(Icons.search_rounded),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
          ),
        ),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'La bibliothèque numérique permanente conserve vos publications sauvegardées et les meilleures contributions validées.',
              textAlign: TextAlign.center,
            ),
          )
        else
          ...filtered.map(
            (item) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading:
                    const Icon(Icons.menu_book_rounded, color: YitteColors.emerald),
                title: Text(item.title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${item.authorName} • ${AppStrings.categoryLabel(item.category)}'),
                trailing: IconButton(
                  tooltip: 'Exporter PDF',
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  onPressed: () async {
                    final bytes = await PdfExportService.buildSummaryPdf(
                      title: item.title,
                      subtitle: 'Bibliothèque Permanente • ${item.authorName}',
                      bodyMarkdown: item.body,
                    );
                    await PdfExportService.previewAndSharePdf(
                      bytes: bytes,
                      filename: 'bibliotheque_${item.id}.pdf',
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }

  Future<void> _openPublishDialog(BuildContext context) async {
    final titleCtrl = TextEditingController();
    final contextCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    final questionsCtrl = TextEditingController();
    final axesCtrl = TextEditingController();
    final docCtrl = TextEditingController();
    String category = 'society';
    bool setAsWeeklyDebate = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: const Text('Publier / Importer un Sujet'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.upload_file_outlined, size: 18),
                  label: const Text('Importer un sujet depuis un fichier (.txt, .md...)'),
                  onPressed: () async {
                    final picked = await FilePickerBridge.pickDocumentFile();
                    if (picked == null) return;
                    setModalState(() {
                      if (titleCtrl.text.trim().isEmpty) {
                        titleCtrl.text = picked.fileName
                            .replaceAll(RegExp(r'\.[^.]+$'), '')
                            .replaceAll('_', ' ');
                      }
                      if (picked.extractedText != null &&
                          picked.extractedText!.trim().isNotEmpty) {
                        bodyCtrl.text = picked.extractedText!.trim();
                      }
                      docCtrl.text = picked.fileName;
                    });
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(labelText: 'Titre du sujet *'),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: category,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Catégorie'),
                  items: const [
                    DropdownMenuItem(value: 'islamic_thought', child: Text('Pensée islamique')),
                    DropdownMenuItem(value: 'philosophy', child: Text('Philosophie')),
                    DropdownMenuItem(value: 'spirituality', child: Text('Spiritualité')),
                    DropdownMenuItem(value: 'ethics', child: Text('Éthique')),
                    DropdownMenuItem(value: 'science', child: Text('Sciences')),
                    DropdownMenuItem(value: 'society', child: Text('Société')),
                  ],
                  onChanged: (v) => setModalState(() => category = v ?? 'philosophy'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: contextCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Contexte & faits motivants (optionnel)',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: bodyCtrl,
                  maxLines: 4,
                  decoration: const InputDecoration(
                    labelText: 'Exposé / problématique (texte authentique) *',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: questionsCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Questions principales (une par ligne)',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: axesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Axes de réflexion (un par ligne)',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: docCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Sources documentaires éventuelles',
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: setAsWeeklyDebate,
                  onChanged: (v) =>
                      setModalState(() => setAsWeeklyDebate = v),
                  title: const Text(
                    'Afficher en « Débat de la semaine » (Accueil)',
                    style: TextStyle(fontSize: 13),
                  ),
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
                if (titleCtrl.text.trim().isEmpty || bodyCtrl.text.trim().isEmpty) {
                  return;
                }
                final profile = ref.read(authProvider);
                final qList = questionsCtrl.text
                    .split('\n')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();
                final aList = axesCtrl.text
                    .split('\n')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();
                ref.read(ecosystemProvider.notifier).addReflection(
                      authorId: profile?.id ?? 'local',
                      authorName: profile?.fullName ?? 'Membre Yitté',
                      title: titleCtrl.text.trim(),
                      body: bodyCtrl.text.trim(),
                      category: category,
                      contextText: contextCtrl.text.trim().isEmpty
                          ? null
                          : contextCtrl.text.trim(),
                      mainQuestions: qList,
                      reflectionAxes: aList,
                      documentarySources: docCtrl.text.trim().isEmpty
                          ? const []
                          : [docCtrl.text.trim()],
                      attachmentName:
                          docCtrl.text.trim().isEmpty ? null : docCtrl.text.trim(),
                      validationStatus: 'approved',
                    );
                if (setAsWeeklyDebate) {
                  ref.read(ecosystemProvider.notifier).setWeeklyTopic(
                        title: titleCtrl.text.trim(),
                        introduction: bodyCtrl.text.trim(),
                        guidingQuestions: qList,
                      );
                }
                Navigator.pop(ctx);
              },
              child: const Text('Publier'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCommentDialog(BuildContext context, ReflectionPost post) async {
    final ctrl = TextEditingController();
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajouter un commentaire'),
        content: TextField(
          controller: ctrl,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Votre réponse constructive'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (ctrl.text.trim().isEmpty) return;
              final profile = ref.read(authProvider);
              ref.read(ecosystemProvider.notifier).addComment(
                    post.id,
                    profile?.fullName ?? 'Membre Yitté',
                    ctrl.text.trim(),
                  );
              Navigator.pop(ctx);
            },
            child: const Text('Envoyer'),
          ),
        ],
      ),
    );
  }
}
