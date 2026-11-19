import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/state/app_providers.dart';
import '../../core/models/domain_models.dart';
import '../../core/services/external_link_bridge.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/editorial_widgets.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  final _broadcastTitleCtrl = TextEditingController();
  final _broadcastBodyCtrl = TextEditingController();
  final _broadcastLocationCtrl = TextEditingController();
  DateTime? _broadcastEventDate;
  final _dailyThoughtCtrl = TextEditingController();
  final _waNameCtrl = TextEditingController();
  final _waInviteCtrl = TextEditingController();
  final _waWebhookCtrl = TextEditingController();
  final _groupMemberAddCtrl = TextEditingController();
  bool _waInitialized = false;
  String _inviteRole = 'member';

  @override
  void dispose() {
    _broadcastTitleCtrl.dispose();
    _broadcastBodyCtrl.dispose();
    _broadcastLocationCtrl.dispose();
    _dailyThoughtCtrl.dispose();
    _waNameCtrl.dispose();
    _waInviteCtrl.dispose();
    _waWebhookCtrl.dispose();
    _groupMemberAddCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(authProvider);
    final eco = ref.watch(ecosystemProvider);
    if (!_waInitialized) {
      _waNameCtrl.text = eco.whatsappGroupName;
      _waInviteCtrl.text = eco.whatsappInviteUrl ?? '';
      _waWebhookCtrl.text = eco.whatsappWebhookUrl ?? '';
      _waInitialized = true;
    }
    final role = profile?.role ?? AppRole.member;
    final pendingProposals = eco.reflections
        .where((r) => r.validationStatus == 'pending')
        .toList();
    final pendingDocs = eco.libraryDocuments
        .where((d) =>
            d.validationStatus == 'pending' ||
            (d.summary != null && d.summary!.status != 'validated'))
        .toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Administration & Gouvernance')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          YitteReveal(
            order: 0,
            child: EditorialHeroBanner(
              eyebrow: 'RBAC SERVEUR • ${role.labelFr.toUpperCase()}',
              title: 'Console d’Administration & Éditoriale',
              subtitle:
                  'Contrôle des invitations, propositions de sujets, bibliothèque documentaire, validation des résumés IA, Extra Groupe et modération.',
            ),
          ),
          const SizedBox(height: 14),
          const SectionHeader(title: 'Générer une Invitation'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _inviteRole,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Rôle attribué'),
                  items: AppRole.values
                      .map((r) => DropdownMenuItem(value: r.code, child: Text(r.labelFr)))
                      .toList(),
                  onChanged: (v) => setState(() => _inviteRole = v ?? 'member'),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () =>
                    ref.read(ecosystemProvider.notifier).generateInviteCode(_inviteRole),
                child: const Text('Générer'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: eco.generatedInvites
                .map((c) => Chip(label: Text(c)))
                .toList(),
          ),
          const SizedBox(height: 16),
          const SectionHeader(title: 'Statistiques de la Plateforme'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _StatChip(label: 'Membres', value: '${eco.members.length}'),
              _StatChip(label: 'Réflexions', value: '${eco.reflections.length}'),
              _StatChip(label: 'Documents', value: '${eco.libraryDocuments.length}'),
              _StatChip(label: 'Extra Groupe', value: '${eco.extraGroupeMeetings.length}'),
              _StatChip(label: 'Défis', value: '${eco.challenges.length}'),
              _StatChip(label: 'Débats', value: '${eco.debates.length}'),
              _StatChip(label: 'Signalements', value: '${eco.reports.length}'),
              _StatChip(label: 'Invitations', value: '${eco.generatedInvites.length}'),
            ],
          ),
          const SizedBox(height: 16),
          const SectionHeader(title: 'Raccourcis de Gouvernance'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.folder_copy_outlined, size: 18),
                label: const Text('Gérer Bibliothèque'),
                onPressed: () => context.push('/documents'),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.groups_2_outlined, size: 18),
                label: const Text('Gérer Extra Groupe'),
                onPressed: () => context.push('/extra-groupe'),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const SectionHeader(title: 'Pensée du Jour Validée (Accueil)'),
          const SizedBox(height: 8),
          YitteSurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _dailyThoughtCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Pensée du jour personnalisée (Accueil)',
                    hintText: 'Laisser vide pour afficher la sélection classique quotidienne.',
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        ref
                            .read(ecosystemProvider.notifier)
                            .publishValidatedDailyThought(_dailyThoughtCtrl.text);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Pensée du jour mise à jour.')),
                        );
                      },
                      child: const Text('Publier sur l’Accueil'),
                    ),
                    if (eco.validatedDailyThought != null)
                      OutlinedButton(
                        onPressed: () {
                          _dailyThoughtCtrl.clear();
                          ref
                              .read(ecosystemProvider.notifier)
                              .publishValidatedDailyThought(null);
                        },
                        child: const Text('Retirer'),
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SectionHeader(title: 'Liaison Groupe WhatsApp'),
          const SizedBox(height: 8),
          YitteSurfaceCard(
            borderColor: AppTheme.tokensOf(context).borderAccent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _waNameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Nom du groupe WhatsApp communautaire',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _waInviteCtrl,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Lien officiel d’invitation (https://chat.whatsapp.com/...)',
                    hintText: 'Collez ici le lien réel généré par votre groupe WhatsApp',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _waWebhookCtrl,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                    labelText: 'Endpoint Webhook / Cloud API (optionnel)',
                    hintText: 'Uniquement si pont serveur WhatsApp Business API configuré',
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.link_rounded),
                      label: const Text('Enregistrer le lien WhatsApp'),
                      onPressed: () {
                        try {
                          ref.read(ecosystemProvider.notifier).updateWhatsAppConfig(
                                groupName: _waNameCtrl.text,
                                inviteUrl: _waInviteCtrl.text,
                                webhookUrl: _waWebhookCtrl.text,
                              );
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Configuration WhatsApp enregistrée.'),
                            ),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                      },
                    ),
                    if (eco.whatsappInviteUrl != null)
                      OutlinedButton.icon(
                        icon: const Icon(Icons.open_in_new_rounded, size: 18),
                        label: const Text('Tester le lien'),
                        onPressed: () =>
                            ExternalLinkBridge.openUrl(eco.whatsappInviteUrl!),
                      ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.upload_file_outlined, size: 18),
                      label: const Text('Importer export .txt'),
                      onPressed: () => context.push('/community'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SectionHeader(title: 'Accès Exclusif & Membres Reconnus du Groupe'),
          const SizedBox(height: 8),
          YitteSurfaceCard(
            borderColor: AppTheme.tokensOf(context).borderAccent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: eco.restrictAppToGroupOnly,
                  onChanged: (v) => ref
                      .read(ecosystemProvider.notifier)
                      .toggleRestrictAppToGroupOnly(v),
                  title: const Text(
                    'Réserver l’application aux membres du groupe uniquement',
                    style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                  ),
                  subtitle: const Text(
                    'Les comptes standard créés par des personnes extérieures restent en attente tant que ce verrou est actif.',
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _groupMemberAddCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Ajouter un membre officiel (Nom complet)',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () {
                        if (_groupMemberAddCtrl.text.trim().length < 2) return;
                        ref
                            .read(ecosystemProvider.notifier)
                            .addAuthorizedGroupMember(_groupMemberAddCtrl.text);
                        _groupMemberAddCtrl.clear();
                      },
                      child: const Text('Ajouter'),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Membres autorisés pour connexion par nom complet (${eco.authorizedGroupMembers.length}) :',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: eco.authorizedGroupMembers
                      .map(
                        (name) => InputChip(
                          label: Text(name, style: const TextStyle(fontSize: 12)),
                          onDeleted: () => ref
                              .read(ecosystemProvider.notifier)
                              .removeAuthorizedGroupMember(name),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          const SectionHeader(title: 'Propositions de Sujets & Documents à Valider'),
          const SizedBox(height: 8),
          if (pendingProposals.isEmpty && pendingDocs.isEmpty)
            const YitteSurfaceCard(
              child: Text('Aucune proposition ni résumé documentaire en attente.'),
            )
          else ...[
            ...pendingProposals.map(
              (p) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: YitteSurfaceCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(p.title),
                    subtitle: Text('Proposé par ${p.authorName}'),
                    trailing: ElevatedButton(
                      onPressed: () => ref
                          .read(ecosystemProvider.notifier)
                          .approveReflectionProposal(p.id, 'approved'),
                      child: const Text('Approuver'),
                    ),
                  ),
                ),
              ),
            ),
            ...pendingDocs.map(
              (d) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: YitteSurfaceCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(d.title),
                    subtitle: Text('${d.domain} • ${d.validationStatus}'),
                    trailing: d.summary != null
                        ? ElevatedButton(
                            onPressed: () => ref
                                .read(ecosystemProvider.notifier)
                                .validateDocumentSummary(
                                  d.id,
                                  profile?.fullName ?? 'Éditeur',
                                ),
                            child: const Text('Valider résumé'),
                          )
                        : ElevatedButton(
                            onPressed: () => ref
                                .read(ecosystemProvider.notifier)
                                .updateDocumentMetadata(
                                  d.id,
                                  validationStatus: 'validated',
                                ),
                            child: const Text('Valider doc'),
                          ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 18),
          const SectionHeader(title: 'Validation des Résumés IA (Éditeur)'),
          const SizedBox(height: 8),
          YitteSurfaceCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                eco.weeklyTopic.summary?.title ?? 'Aucun résumé en attente',
              ),
              subtitle: Text(
                'Statut : ${eco.weeklyTopic.summary?.status ?? "à rédiger"}',
              ),
              trailing: eco.weeklyTopic.summary != null &&
                      eco.weeklyTopic.summary!.status != 'published'
                  ? ElevatedButton(
                      onPressed: () => ref
                          .read(ecosystemProvider.notifier)
                          .approveAndPublishSummary(profile?.fullName ?? 'Admin'),
                      child: const Text('Valider'),
                    )
                  : const Icon(Icons.verified_rounded, color: YitteColors.success),
            ),
          ),
          const SizedBox(height: 18),
          const SectionHeader(title: 'Modération & Signalements'),
          const SizedBox(height: 8),
          if (eco.reports.isEmpty)
            const YitteSurfaceCard(
              child: Text('Aucun signalement ouvert.'),
            )
          else
            ...eco.reports.map(
              (rep) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: YitteSurfaceCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('${rep.targetType} • ${rep.status}'),
                    subtitle: Text(rep.reason),
                    trailing: rep.status == 'open'
                        ? TextButton(
                            onPressed: () => ref
                                .read(ecosystemProvider.notifier)
                                .resolveReport(rep.id),
                            child: const Text('Résoudre'),
                          )
                        : const Icon(Icons.check_circle, color: YitteColors.success),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 18),
          const SectionHeader(title: 'Diffusion d’Annonce & Agenda'),
          const SizedBox(height: 8),
          TextField(
            controller: _broadcastTitleCtrl,
            decoration: const InputDecoration(labelText: 'Titre de l’annonce'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _broadcastBodyCtrl,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Message / Détails'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _broadcastLocationCtrl,
            decoration: const InputDecoration(
              labelText: 'Lieu ou lien visio (optionnel — pour l’agenda)',
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.event_rounded, size: 18),
                label: Text(
                  _broadcastEventDate == null
                      ? 'Choisir date & heure (optionnel)'
                      : 'Date : ${_broadcastEventDate!.day.toString().padLeft(2, '0')}/${_broadcastEventDate!.month.toString().padLeft(2, '0')}/${_broadcastEventDate!.year} ${_broadcastEventDate!.hour.toString().padLeft(2, '0')}h${_broadcastEventDate!.minute.toString().padLeft(2, '0')}',
                ),
                onPressed: () async {
                  final now = DateTime.now();
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _broadcastEventDate ?? now.add(const Duration(days: 1)),
                    firstDate: now.subtract(const Duration(days: 1)),
                    lastDate: now.add(const Duration(days: 365 * 2)),
                  );
                  if (pickedDate == null || !context.mounted) return;
                  final pickedTime = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 20, minute: 0),
                  );
                  setState(() {
                    _broadcastEventDate = DateTime(
                      pickedDate.year,
                      pickedDate.month,
                      pickedDate.day,
                      pickedTime?.hour ?? 20,
                      pickedTime?.minute ?? 0,
                    );
                  });
                },
              ),
              ElevatedButton.icon(
                icon: const Icon(Icons.campaign_outlined),
                label: const Text('Diffuser l’annonce'),
                onPressed: () async {
                  final title = _broadcastTitleCtrl.text.trim();
                  final body = _broadcastBodyCtrl.text.trim();
                  if (title.isEmpty) return;
                  await ref.read(ecosystemProvider.notifier).broadcastAnnouncement(
                        title,
                        body,
                        profile?.fullName ?? 'Administration',
                        eventDate: _broadcastEventDate,
                        location: _broadcastLocationCtrl.text.trim(),
                      );
                  _broadcastTitleCtrl.clear();
                  _broadcastBodyCtrl.clear();
                  _broadcastLocationCtrl.clear();
                  setState(() => _broadcastEventDate = null);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Annonce diffusée en premier plan & dans les notifications : $title',
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 18),
          const SectionHeader(title: 'Journal d’Audit (Audit Logs)'),
          const SizedBox(height: 8),
          ...eco.auditLogs.take(8).map(
                (log) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: YitteSurfaceCard(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.history_rounded, size: 18),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(log, style: const TextStyle(fontSize: 12.5)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  const _StatChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.tokensOf(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: tokens.elevated,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: tokens.borderSubtle),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Theme.of(context).colorScheme.primary)),
          Text(label, style: const TextStyle(fontSize: 11.5)),
        ],
      ),
    );
  }
}
