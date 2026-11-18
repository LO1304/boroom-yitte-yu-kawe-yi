import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/state/app_providers.dart';
import '../../core/services/backend_repository.dart';
import '../../core/services/external_link_bridge.dart';
import '../../core/services/whatsapp_bridge_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/editorial_widgets.dart';

class ProfessionalScreen extends ConsumerStatefulWidget {
  const ProfessionalScreen({super.key});

  @override
  ConsumerState<ProfessionalScreen> createState() => _ProfessionalScreenState();
}

class _ProfessionalScreenState extends ConsumerState<ProfessionalScreen> {
  late final TextEditingController _cvCtrl;
  late final TextEditingController _coverCtrl;
  final _interviewCtrl = TextEditingController();
  final _projectCtrl = TextEditingController();
  String _selectedTrack = 'Agronomie & Sciences agricoles';
  final _customTrackCtrl = TextEditingController();
  String? _aiCareerFeedback;
  String? _mockRecruiterFeedback;
  bool _interviewVoiceConsent = false;
  String? _interviewAudioPath;

  static const _tracks = [
    'Agronomie & Sciences agricoles',
    'Physique & Sciences fondamentales',
    'Électronique & Systèmes embarqués',
    'Informatique & Génie logiciel',
    'Intelligence Artificielle & Data',
    'Médecine & Santé publique',
    'Mathématiques & Modélisation',
    'Génie technique & Industriel',
    'Cybersécurité & Réseaux',
    'Économie, Droit & Gestion',
    'Éducation & Sciences humaines',
    'Communication & Langues',
    'Entrepreneuriat & Artisanat',
    'Autre métier (saisie libre)',
  ];

  String get _effectiveTrack {
    if (_selectedTrack == 'Autre métier (saisie libre)' &&
        _customTrackCtrl.text.trim().isNotEmpty) {
      return _customTrackCtrl.text.trim();
    }
    return _selectedTrack;
  }

  @override
  void initState() {
    super.initState();
    final eco = ref.read(ecosystemProvider);
    _cvCtrl = TextEditingController(text: eco.cvDraft);
    _coverCtrl = TextEditingController(text: eco.coverLetterDraft);
  }

  @override
  void dispose() {
    _cvCtrl.dispose();
    _coverCtrl.dispose();
    _interviewCtrl.dispose();
    _projectCtrl.dispose();
    _customTrackCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eco = ref.watch(ecosystemProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('YITTÉ PROFESSIONNEL')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const YitteReveal(
            order: 0,
            child: EditorialHeroBanner(
              eyebrow: 'TOUS MÉTIERS & COMPLÉMENTARITÉ',
              accentColor: YitteDomainAccents.career,
              title: 'Excellence Professionnelle',
              subtitle:
                  'Agronomie, physique, électronique, informatique, médecine, mathématiques, génie technique et entrepreneuriat : valorisez tous les métiers de la communauté.',
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
            initialValue: _selectedTrack,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Domaine / Métier'),
            items: _tracks
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) =>
                setState(() => _selectedTrack = v ?? _tracks.first),
          ),
          if (_selectedTrack == 'Autre métier (saisie libre)') ...[
            const SizedBox(height: 10),
            TextField(
              controller: _customTrackCtrl,
              decoration: const InputDecoration(
                labelText: 'Précisez votre métier ou spécialité',
              ),
            ),
          ],
          const SizedBox(height: 16),
          const SectionHeader(title: 'CV & Lettre de Motivation'),
          const SizedBox(height: 8),
          TextField(
            controller: _cvCtrl,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Résumé de CV'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _coverCtrl,
            maxLines: 3,
            decoration: const InputDecoration(labelText: 'Lettre de motivation'),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: () {
                  ref.read(ecosystemProvider.notifier).updateCareerDocs(
                        cv: _cvCtrl.text,
                        coverLetter: _coverCtrl.text,
                      );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Profil carrière sauvegardé.')),
                  );
                },
                child: const Text('Sauvegarder'),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.auto_awesome_rounded),
                label: const Text('Revue YITTE_CAREER_COACH'),
                onPressed: () async {
                  final res = await BackendRepository.instance.callAiAgent(
                    agentName: 'YITTE_CAREER_COACH',
                    prompt:
                        'Analyse ce CV pour $_effectiveTrack : ${_cvCtrl.text}',
                  );
                  if (mounted) setState(() => _aiCareerFeedback = res);
                },
              ),
            ],
          ),
          if (_aiCareerFeedback != null)
            Card(
              margin: const EdgeInsets.only(top: 10),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Text(_aiCareerFeedback!),
              ),
            ),
          const SizedBox(height: 18),
          const SectionHeader(title: 'Simulateur d’Entretien (Recruteur IA)'),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Question Recruteur ($_effectiveTrack) : « Présentez un projet technique ou organisationnel complexe que vous avez mené à terme et les compromis choisis. »',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  ConsentVoiceRecorderCard(
                    audioService: ref.watch(audioServiceProvider),
                    maxSeconds: 180,
                    prefix: 'mock_interview',
                    consentGranted: _interviewVoiceConsent,
                    speechLocale: 'fr-FR',
                    onConsentChanged: (v) =>
                        setState(() => _interviewVoiceConsent = v),
                    onLiveTranscript: (t) =>
                        setState(() => _interviewCtrl.text = t),
                    onRecorded: (p, _) => setState(() => _interviewAudioPath = p),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _interviewCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Votre réponse structurée (méthode STAR) ou transcript',
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () async {
                      final text = _interviewCtrl.text.trim().isNotEmpty
                          ? _interviewCtrl.text.trim()
                          : (_interviewAudioPath != null
                              ? 'Réponse orale enregistrée ($_interviewAudioPath) pour entretien $_effectiveTrack.'
                              : '');
                      if (text.isEmpty) return;
                      final reply = await BackendRepository.instance.callAiAgent(
                        agentName: 'YITTE_CAREER_COACH',
                        prompt:
                            'Évalue cette réponse d’entretien ($_effectiveTrack) selon la méthode STAR : $text',
                      );
                      if (mounted) {
                        setState(() => _mockRecruiterFeedback = reply);
                      }
                    },
                    child: const Text('Obtenir le feedback du Recruteur IA'),
                  ),
                  if (_mockRecruiterFeedback != null) ...[
                    const SizedBox(height: 10),
                    Text(_mockRecruiterFeedback!),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          SectionHeader(
            title: 'Projets & Initiatives Libres (${eco.portfolioProjects.length})',
            actionLabel: '+ Projet détaillé',
            onAction: () => _openDetailedProjectDialog(context),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _projectCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Publier n’importe quel projet, idée ou réalisation',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  if (_projectCtrl.text.trim().isEmpty) return;
                  ref.read(ecosystemProvider.notifier).addPortfolioProject(
                        '${_projectCtrl.text.trim()} ($_effectiveTrack)',
                      );
                  _projectCtrl.clear();
                },
                child: const Text('Ajouter'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (eco.portfolioProjects.isEmpty)
            YitteEmptyState(
              icon: Icons.rocket_launch_outlined,
              title: 'Aucun projet publié pour le moment',
              description:
                  'Proposez librement n’importe quel projet d’agronomie, médecine, électronique, informatique, mathématiques, technique ou autre.',
              actionLabel: 'Créer un projet complet',
              onAction: () => _openDetailedProjectDialog(context),
            )
          else
            ...eco.portfolioProjects.asMap().entries.map((entry) {
              final idx = entry.key;
              final proj = entry.value;
              return YitteSurfaceCard(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: YitteColors.emeraldSoft,
                    child: Icon(
                      Icons.rocket_launch_outlined,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  title: Text(proj),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Partager le projet sur WhatsApp',
                        icon: const Icon(Icons.share_outlined, size: 19),
                        onPressed: () {
                          final url = WhatsAppBridgeService.buildShareUrl(
                            'BOROOM YITTÉ — Projet Professionnel\n$proj',
                            groupInviteUrl: eco.whatsappInviteUrl,
                          );
                          ExternalLinkBridge.openUrl(url);
                        },
                      ),
                      IconButton(
                        tooltip: 'Supprimer ce projet',
                        icon: const Icon(
                          Icons.delete_outline_rounded,
                          size: 20,
                          color: YitteColors.danger,
                        ),
                        onPressed: () => ref
                            .read(ecosystemProvider.notifier)
                            .deletePortfolioProject(idx),
                      ),
                    ],
                  ),
                ),
              );
            }),
          const SizedBox(height: 18),
          const SectionHeader(title: 'Opportunités, Stages & Certifications'),
          const SizedBox(height: 8),
          ...eco.careerOpportunities.map(
            (op) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text(op.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${op.organization} • ${op.location}\n${op.description}'),
                isThreeLine: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openDetailedProjectDialog(BuildContext context) async {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final collabCtrl = TextEditingController();
    String domain = _effectiveTrack;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: const Text('Nouveau Projet Professionnel Libre'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Titre du projet / initiative *',
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: _tracks.contains(domain) ? domain : _tracks.last,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Métier / Filière'),
                  items: _tracks
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) =>
                      setModalState(() => domain = v ?? _tracks.first),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: descCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Objectif, problème résolu & avancement',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: collabCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Complémentarité / compétences recherchées ou lien',
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
                final title = titleCtrl.text.trim();
                if (title.isEmpty) return;
                final author = ref.read(authProvider)?.fullName ?? 'Membre';
                final parts = [
                  '$title [$domain] — par $author',
                  if (descCtrl.text.trim().isNotEmpty) descCtrl.text.trim(),
                  if (collabCtrl.text.trim().isNotEmpty)
                    'Collaboration / Réf : ${collabCtrl.text.trim()}',
                ];
                ref
                    .read(ecosystemProvider.notifier)
                    .addPortfolioProject(parts.join('\n'));
                Navigator.pop(ctx);
              },
              child: const Text('Publier le projet'),
            ),
          ],
        ),
      ),
    );
  }
}
