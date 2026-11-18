import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:uuid/uuid.dart';

import '../../app/state/app_providers.dart';
import '../../core/models/domain_models.dart';
import '../../core/services/backend_repository.dart';
import '../../core/services/file_picker_bridge.dart';
import '../../core/services/pdf_export_service.dart';
import '../../core/services/speech_bridge.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/editorial_widgets.dart';

const _docUuid = Uuid();

class DocumentsLibraryScreen extends ConsumerStatefulWidget {
  const DocumentsLibraryScreen({super.key});

  @override
  ConsumerState<DocumentsLibraryScreen> createState() =>
      _DocumentsLibraryScreenState();
}

class _DocumentsLibraryScreenState
    extends ConsumerState<DocumentsLibraryScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedDomain = 'Tous';
  String _selectedSubcategory = 'Toutes';
  String _authorFilter = '';
  bool _onlyValidated = false;
  bool _onlyConsulted = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eco = ref.watch(ecosystemProvider);
    final profile = ref.watch(authProvider);
    final isEditorOrAdmin = profile?.role.isEditorOrAbove ?? true;

    final subcategories = _selectedDomain == 'Tous'
        ? const <String>[]
        : (DocumentCategoryCatalog.domains[_selectedDomain] ?? const []);

    final q = _searchQuery.trim().toLowerCase();
    final a = _authorFilter.trim().toLowerCase();

    final visibleDocs = eco.libraryDocuments.where((doc) {
      if (doc.isPrivate &&
          !isEditorOrAdmin &&
          doc.authorOrContributor != (profile?.fullName ?? '')) {
        return false;
      }
      if (_onlyValidated && doc.validationStatus != 'validated') return false;
      if (_onlyConsulted && doc.viewCount == 0) return false;
      if (_selectedDomain != 'Tous' && doc.domain != _selectedDomain) {
        return false;
      }
      if (_selectedSubcategory != 'Toutes' &&
          doc.subcategory != _selectedSubcategory) {
        return false;
      }
      if (a.isNotEmpty &&
          !doc.authorOrContributor.toLowerCase().contains(a)) {
        return false;
      }
      if (q.isEmpty) return true;
      return doc.title.toLowerCase().contains(q) ||
          doc.description.toLowerCase().contains(q) ||
          doc.sourceReference.toLowerCase().contains(q) ||
          doc.keywords.any((k) => k.toLowerCase().contains(q));
    }).toList();

    final recentDocs = eco.libraryDocuments
        .where((d) => d.lastViewedAt != null)
        .toList()
      ..sort((x, y) => y.lastViewedAt!.compareTo(x.lastViewedAt!));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bibliothèque Documentaire'),
        actions: [
          IconButton(
            tooltip: 'Ajouter un document',
            icon: const Icon(Icons.upload_file_rounded),
            onPressed: () => _openAddDocumentDialog(context),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          const YitteReveal(
            order: 0,
            child: EditorialHeroBanner(
              eyebrow: 'SAVOIR ORGANISÉ • ZÉRO CONTENU INVENTÉ',
              title: 'Archives & Ressources Documentaires',
              subtitle:
                  '5 domaines fondamentaux, 40 sous-catégories, import de fichiers réels et résumés fidèles établis exclusivement à partir du texte source.',
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Rechercher par titre, source, mot-clé...',
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
          DropdownButtonFormField<String>(
            initialValue: _selectedDomain,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Domaine documentaire'),
            items: [
              const DropdownMenuItem(value: 'Tous', child: Text('Tous les domaines')),
              ...DocumentCategoryCatalog.domains.keys.map(
                (d) => DropdownMenuItem(value: d, child: Text(d)),
              ),
            ],
            onChanged: (v) => setState(() {
              _selectedDomain = v ?? 'Tous';
              _selectedSubcategory = 'Toutes';
            }),
          ),
          if (subcategories.isNotEmpty) ...[
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _selectedSubcategory,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Sous-catégorie'),
              items: [
                const DropdownMenuItem(
                    value: 'Toutes', child: Text('Toutes les sous-catégories')),
                ...subcategories.map(
                  (s) => DropdownMenuItem(value: s, child: Text(s)),
                ),
              ],
              onChanged: (v) =>
                  setState(() => _selectedSubcategory = v ?? 'Toutes'),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              FilterChip(
                label: const Text('Validés uniquement'),
                selected: _onlyValidated,
                onSelected: (v) => setState(() => _onlyValidated = v),
              ),
              FilterChip(
                label: const Text('Déjà consultés'),
                selected: _onlyConsulted,
                onSelected: (v) => setState(() => _onlyConsulted = v),
              ),
              ActionChip(
                avatar: const Icon(Icons.person_search_outlined, size: 17),
                label: Text(_authorFilter.isEmpty
                    ? 'Filtrer auteur'
                    : 'Auteur : $_authorFilter'),
                onPressed: () => _openAuthorFilterDialog(context),
              ),
            ],
          ),
          if (recentDocs.isNotEmpty) ...[
            const SizedBox(height: 16),
            const SectionHeader(title: 'Récemment consultés'),
            const SizedBox(height: 8),
            SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: recentDocs.take(5).length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) {
                  final d = recentDocs[i];
                  return SizedBox(
                    width: 220,
                    child: YitteSurfaceCard(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      onTap: () => _openDocumentDetail(context, d),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            d.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${d.format.toUpperCase()} • ${d.viewCount} consultation(s)',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 18),
          SectionHeader(
            title: 'Documents (${visibleDocs.length})',
            actionLabel: '+ Importer',
            onAction: () => _openAddDocumentDialog(context),
          ),
          const SizedBox(height: 10),
          if (visibleDocs.isEmpty)
            YitteEmptyState(
              icon: Icons.folder_copy_outlined,
              title: 'Aucun document enregistré dans cette vue',
              description:
                  'Conformément à la charte anti-invention, aucun document factice n’est généré automatiquement. Importez un vrai fichier (PDF, TXT, MD, DOCX, PPTX, image) ou ajoutez un texte source.',
              actionLabel: 'Ajouter un vrai document',
              onAction: () => _openAddDocumentDialog(context),
            )
          else
            ...visibleDocs.asMap().entries.map((entry) {
              final d = entry.value;
              return YitteReveal(
                order: entry.key + 1,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: YitteSurfaceCard(
                    onTap: () => _openDocumentDetail(context, d),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: YitteColors.emeraldSoft,
                              child: Icon(
                                d.format == 'pdf'
                                    ? Icons.picture_as_pdf_rounded
                                    : Icons.description_outlined,
                                color: YitteColors.emerald,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    d.title,
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  Text(
                                    '${d.domain} › ${d.subcategory}',
                                    style:
                                        Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            YitteStatusPill(
                              label: d.validationStatus == 'validated'
                                  ? 'Validé'
                                  : 'En attente',
                            ),
                          ],
                        ),
                        if (d.description.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            d.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            YitteStatusPill(
                                label:
                                    'Auteur : ${d.authorOrContributor.isEmpty ? "Non précisé" : d.authorOrContributor}'),
                            YitteStatusPill(
                                label:
                                    '${d.format.toUpperCase()} • ${d.summary != null ? "Résumé dispo." : "Sans résumé"}'),
                            if (d.isPrivate)
                              const YitteStatusPill(
                                icon: Icons.lock_outline_rounded,
                                label: 'Privé',
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Future<void> _openAuthorFilterDialog(BuildContext context) async {
    final ctrl = TextEditingController(text: _authorFilter);
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Filtrer par auteur / contributeur'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Nom d’auteur (laisser vide pour tout afficher)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _authorFilter = '');
              Navigator.pop(ctx);
            },
            child: const Text('Effacer'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => _authorFilter = ctrl.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Appliquer'),
          ),
        ],
      ),
    );
  }

  void _openDocumentDetail(BuildContext context, LibraryDocumentModel doc) {
    ref.read(ecosystemProvider.notifier).recordDocumentConsultation(doc.id);
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _DocumentDetailModal(documentId: doc.id),
    );
  }

  Future<void> _openAddDocumentDialog(BuildContext context) async {
    await showDialog<void>(
      context: context,
      builder: (_) => const _AddDocumentDialog(),
    );
  }
}

class _AddDocumentDialog extends ConsumerStatefulWidget {
  const _AddDocumentDialog();

  @override
  ConsumerState<_AddDocumentDialog> createState() => _AddDocumentDialogState();
}

class _AddDocumentDialogState extends ConsumerState<_AddDocumentDialog> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _authorCtrl = TextEditingController();
  final _sourceCtrl = TextEditingController();
  final _dateCtrl = TextEditingController();
  final _keywordsCtrl = TextEditingController();
  final _sourceTextCtrl = TextEditingController();

  String _domain = DocumentCategoryCatalog.domains.keys.first;
  String _subcategory = DocumentCategoryCatalog.domains.values.first.first;
  String _language = 'fr';
  bool _isPrivate = false;
  bool _uploading = false;
  PickedDocumentFile? _picked;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _authorCtrl.dispose();
    _sourceCtrl.dispose();
    _dateCtrl.dispose();
    _keywordsCtrl.dispose();
    _sourceTextCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.read(authProvider);
    final subs = DocumentCategoryCatalog.domains[_domain] ?? const ['Général'];

    return AlertDialog(
      title: const Text('Enregistrer un Document Source'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            OutlinedButton.icon(
              icon: const Icon(Icons.attach_file_rounded),
              label: Text(
                _picked == null
                    ? 'Sélectionner un fichier (PDF, DOCX, PPTX, TXT, Image...)'
                    : '${_picked!.fileName} (${(_picked!.sizeBytes / 1024).toStringAsFixed(1)} Ko)',
              ),
              onPressed: () async {
                final file = await FilePickerBridge.pickDocumentFile();
                if (file == null || !mounted) return;
                setState(() {
                  _picked = file;
                  if (_titleCtrl.text.trim().isEmpty) {
                    _titleCtrl.text =
                        file.fileName.replaceAll(RegExp(r'\.[^.]+$'), '');
                  }
                  if (file.extractedText != null &&
                      _sourceTextCtrl.text.trim().isEmpty) {
                    _sourceTextCtrl.text = file.extractedText!;
                  }
                });
              },
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(labelText: 'Titre du document *'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _domain,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Catégorie principale'),
              items: DocumentCategoryCatalog.domains.keys
                  .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                  .toList(),
              onChanged: (v) => setState(() {
                _domain = v ?? _domain;
                _subcategory = DocumentCategoryCatalog.domains[_domain]!.first;
              }),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: subs.contains(_subcategory) ? _subcategory : subs.first,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Sous-catégorie'),
              items: subs
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (v) => setState(() => _subcategory = v ?? subs.first),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _authorCtrl,
              decoration: InputDecoration(
                labelText: 'Auteur ou contributeur',
                hintText: profile?.fullName ?? 'Nom de l’auteur',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _sourceCtrl,
              decoration: const InputDecoration(
                labelText: 'Source / référence bibliographique *',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _dateCtrl,
              decoration: const InputDecoration(
                labelText: 'Date de publication originale (optionnel)',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _keywordsCtrl,
              decoration: const InputDecoration(
                labelText: 'Mots-clés (séparés par des virgules)',
              ),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: _language,
              decoration: const InputDecoration(labelText: 'Langue du document'),
              items: const [
                DropdownMenuItem(value: 'fr', child: Text('Français')),
                DropdownMenuItem(value: 'en', child: Text('Anglais')),
                DropdownMenuItem(value: 'ar', child: Text('Arabe')),
                DropdownMenuItem(value: 'wo', child: Text('Wolof')),
              ],
              onChanged: (v) => setState(() => _language = v ?? 'fr'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descCtrl,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Description'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _sourceTextCtrl,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Texte extrait ou contenu textuel source',
                hintText:
                    'Utilisé exclusivement pour la consultation et le résumé fidèle sans invention.',
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _isPrivate,
              onChanged: (v) => setState(() => _isPrivate = v),
              title: const Text('Document privé (non public par défaut)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _uploading ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _uploading
              ? null
              : () async {
                  if (_titleCtrl.text.trim().isEmpty) return;
                  if (_picked == null && _sourceTextCtrl.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Importez un fichier réel ou fournissez un contenu textuel source.',
                        ),
                      ),
                    );
                    return;
                  }
                  setState(() => _uploading = true);
                  final fileName = _picked?.fileName ??
                      '${_titleCtrl.text.trim().toLowerCase().replaceAll(RegExp(r"[^a-z0-9]+"), "_")}.txt';
                  final bytes = _picked?.bytes ??
                      _sourceTextCtrl.text.trim().codeUnits;
                  final uploadRes =
                      await BackendRepository.instance.uploadDocumentFile(
                    fileName: fileName,
                    bytes: bytes,
                    providedText: _sourceTextCtrl.text.trim(),
                  );

                  final doc = LibraryDocumentModel(
                    id: _docUuid.v4(),
                    title: _titleCtrl.text.trim(),
                    description: _descCtrl.text.trim(),
                    domain: _domain,
                    subcategory: _subcategory,
                    authorOrContributor: _authorCtrl.text.trim().isNotEmpty
                        ? _authorCtrl.text.trim()
                        : (profile?.fullName ?? 'Membre autorisé'),
                    sourceReference: _sourceCtrl.text.trim(),
                    addedAt: DateTime.now(),
                    publishedDateLabel: _dateCtrl.text.trim().isEmpty
                        ? null
                        : _dateCtrl.text.trim(),
                    keywords: _keywordsCtrl.text
                        .split(',')
                        .map((k) => k.trim())
                        .where((k) => k.isNotEmpty)
                        .toList(),
                    language: _language,
                    fileName: fileName,
                    format: _picked?.extension ?? 'txt',
                    fileSizeBytes:
                        (uploadRes['fileSizeBytes'] as num?)?.toInt() ??
                            bytes.length,
                    storageUrl: uploadRes['storageUrl']?.toString(),
                    extractedText: uploadRes['extractedText']?.toString(),
                    unreadableWarning:
                        uploadRes['unreadableWarning']?.toString(),
                    isPrivate: _isPrivate,
                    validationStatus:
                        (profile?.role.isEditorOrAbove ?? true)
                            ? 'validated'
                            : 'pending',
                  );
                  ref.read(ecosystemProvider.notifier).addLibraryDocument(doc);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                },
          child: Text(_uploading ? 'Enregistrement...' : 'Enregistrer'),
        ),
      ],
    );
  }
}

class _DocumentDetailModal extends ConsumerStatefulWidget {
  final String documentId;

  const _DocumentDetailModal({required this.documentId});

  @override
  ConsumerState<_DocumentDetailModal> createState() =>
      _DocumentDetailModalState();
}

class _DocumentDetailModalState extends ConsumerState<_DocumentDetailModal> {
  bool _generating = false;
  String? _summaryError;

  @override
  Widget build(BuildContext context) {
    final eco = ref.watch(ecosystemProvider);
    final profile = ref.watch(authProvider);
    final doc = eco.libraryDocuments.firstWhere(
      (d) => d.id == widget.documentId,
      orElse: () => eco.libraryDocuments.first,
    );
    final summary = doc.summary;
    final isEditorOrAdmin = (profile?.role.isEditorOrAbove ?? true) ||
        profile?.fullName == doc.authorOrContributor;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      maxChildSize: 0.95,
      builder: (context, scrollCtrl) => ListView(
        controller: scrollCtrl,
        padding: const EdgeInsets.all(20),
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  doc.title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              YitteStatusPill(label: '${doc.domain} › ${doc.subcategory}'),
              YitteStatusPill(label: 'Langue : ${doc.language.toUpperCase()}'),
              YitteStatusPill(label: '${doc.viewCount} consultation(s)'),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Auteur / Contributeur : ${doc.authorOrContributor}\n'
            'Source : ${doc.sourceReference.isEmpty ? "Document importé (${doc.fileName})" : doc.sourceReference}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (doc.unreadableWarning != null) ...[
            const SizedBox(height: 10),
            YitteSurfaceCard(
              color: YitteColors.goldSoft,
              child: Text(
                'Avertissement lecture : ${doc.unreadableWarning}',
                style: const TextStyle(color: YitteColors.inkDark, fontSize: 13),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton.icon(
                onPressed: _generating
                    ? null
                    : () async {
                        setState(() {
                          _generating = true;
                          _summaryError = null;
                        });
                        try {
                          await ref
                              .read(ecosystemProvider.notifier)
                              .generateDocumentSummary(doc.id);
                        } catch (e) {
                          if (mounted) {
                            setState(() => _summaryError = e.toString());
                          }
                        } finally {
                          if (mounted) setState(() => _generating = false);
                        }
                      },
                icon: const Icon(Icons.summarize_outlined),
                label: Text(_generating
                    ? 'Analyse fidèle en cours...'
                    : 'Résumer depuis le document'),
              ),
              if (doc.extractedText != null && kIsWeb)
                OutlinedButton.icon(
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Télécharger texte source'),
                  onPressed: () => SpeechBridge.downloadBytes(
                    Uint8List.fromList(doc.extractedText!.codeUnits),
                    '${doc.fileName}.txt',
                    mimeType: 'text/plain; charset=utf-8',
                  ),
                ),
            ],
          ),
          if (_summaryError != null) ...[
            const SizedBox(height: 10),
            Text(
              _summaryError!,
              style: const TextStyle(color: YitteColors.danger, fontSize: 13),
            ),
          ],
          if (summary != null) ...[
            const SizedBox(height: 16),
            SectionHeader(
              title:
                  'Résumé Structuré (${summary.status == "validated" ? "Validé" : "Brouillon IA à relire"})',
            ),
            const SizedBox(height: 8),
            YitteSurfaceCard(
              borderColor: AppTheme.tokensOf(context).borderAccent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  YitteStatusPill(
                    icon: Icons.verified_user_outlined,
                    label: summary.isAiAssisted
                        ? 'Contenu assisté par IA — rattaché à « ${doc.title} »'
                        : 'Résumé éditorial',
                  ),
                  const SizedBox(height: 10),
                  const Text('1. Résumé général',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  Text(summary.generalSummary),
                  const SizedBox(height: 8),
                  const Text('2. Idées principales',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  ...summary.mainIdeas.map((m) => Text('• $m')),
                  const SizedBox(height: 8),
                  const Text('3. Concepts importants',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  ...summary.importantConcepts.map((c) => Text('• $c')),
                  const SizedBox(height: 8),
                  const Text('4. Définitions',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  ...summary.definitions.map((d) => Text('• $d')),
                  const SizedBox(height: 8),
                  const Text('5. Arguments développés',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  ...summary.developedArguments.map((a) => Text('• $a')),
                  const SizedBox(height: 8),
                  const Text('6. Conclusions de l’auteur',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  ...summary.authorConclusions.map((c) => Text('• $c')),
                  const SizedBox(height: 8),
                  const Text('7. Références citées',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  ...summary.citedReferences.map((r) => Text('• $r')),
                  const SizedBox(height: 8),
                  const Text('8. Questions de compréhension',
                      style: TextStyle(fontWeight: FontWeight.w700)),
                  ...summary.comprehensionQuestions.map((q) => Text('• $q')),
                  if (summary.unreadableNotices.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Précisions de lecture : ${summary.unreadableNotices.join(" | ")}',
                      style: const TextStyle(color: YitteColors.warning),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (isEditorOrAdmin && summary.status != 'validated')
                        ElevatedButton.icon(
                          icon: const Icon(Icons.verified_rounded),
                          label: const Text('Valider ce résumé'),
                          onPressed: () => ref
                              .read(ecosystemProvider.notifier)
                              .validateDocumentSummary(
                                doc.id,
                                profile?.fullName ?? 'Responsable',
                              ),
                        ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.picture_as_pdf_outlined),
                        label: const Text('Exporter PDF du résumé'),
                        onPressed: () async {
                          final bytes = await PdfExportService.buildSummaryPdf(
                            title: 'Résumé : ${doc.title}',
                            subtitle:
                                'Source : ${doc.fileName} • Statut : ${summary.status}',
                            bodyMarkdown: summary.generalSummary,
                            bulletPoints: [
                              ...summary.mainIdeas,
                              ...summary.comprehensionQuestions,
                            ],
                            references: summary.citedReferences,
                          );
                          await PdfExportService.previewAndSharePdf(
                            bytes: bytes,
                            filename: 'resume_${doc.id}.pdf',
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (doc.extractedText != null) ...[
            const SizedBox(height: 18),
            const SectionHeader(title: 'Document Original / Extrait Source'),
            const SizedBox(height: 8),
            YitteSurfaceCard(
              child: SelectableText(
                doc.extractedText!,
                style: const TextStyle(fontSize: 13.5, height: 1.5),
              ),
            ),
          ],
          if (isEditorOrAdmin) ...[
            const SizedBox(height: 18),
            const SectionHeader(title: 'Actions Administrateur / Responsable'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(
                  onPressed: () => ref
                      .read(ecosystemProvider.notifier)
                      .updateDocumentMetadata(doc.id, isPrivate: !doc.isPrivate),
                  child: Text(
                    doc.isPrivate ? 'Rendre communautaire' : 'Passer en privé',
                  ),
                ),
                OutlinedButton(
                  onPressed: () {
                    ref
                        .read(ecosystemProvider.notifier)
                        .deleteLibraryDocument(doc.id);
                    Navigator.pop(context);
                  },
                  child: const Text('Supprimer'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
