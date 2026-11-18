import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/state/app_providers.dart';
import '../../core/models/domain_models.dart';
import '../../core/services/audio_service.dart';
import '../../core/services/backend_repository.dart';
import '../../core/services/external_link_bridge.dart';
import '../../core/services/file_picker_bridge.dart';
import '../../core/services/pdf_export_service.dart';
import '../../core/services/whatsapp_bridge_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/editorial_widgets.dart';

class CommunityScreen extends ConsumerStatefulWidget {
  const CommunityScreen({super.key});

  @override
  ConsumerState<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends ConsumerState<CommunityScreen> {
  final _msgCtrl = TextEditingController();
  final _roomTitleCtrl = TextEditingController();
  final _waImportCtrl = TextEditingController();
  String? _connectedRoomId;
  bool _micEnabled = false;
  String _selectedChannel = 'Cercle Général';
  bool _recordingVoice = false;
  bool _uploadingVoice = false;
  int _voiceSeconds = 0;
  Timer? _voiceTimer;
  String? _playingMessageId;

  @override
  void dispose() {
    _voiceTimer?.cancel();
    _msgCtrl.dispose();
    _roomTitleCtrl.dispose();
    _waImportCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleVoiceNote(
    AudioService audioService,
    String senderName,
  ) async {
    if (_recordingVoice) {
      _voiceTimer?.cancel();
      final duration = _voiceSeconds;
      final localPath = await audioService.stopRecording();
      if (!mounted) return;
      setState(() {
        _recordingVoice = false;
        _uploadingVoice = localPath != null;
      });
      if (localPath == null) {
        if (mounted) setState(() => _uploadingVoice = false);
        return;
      }
      var finalUrl = localPath;
      try {
        final bytes = await audioService.readRecordedBytes(localPath);
        if (bytes != null && bytes.isNotEmpty) {
          final ext = localPath.endsWith('.m4a')
              ? 'm4a'
              : (localPath.endsWith('.wav') ? 'wav' : 'webm');
          final remoteUrl = await BackendRepository.instance.uploadAudioRecording(
            fileName: 'community_${DateTime.now().millisecondsSinceEpoch}.$ext',
            bytes: bytes,
          );
          if (remoteUrl != null && remoteUrl.isNotEmpty) {
            finalUrl = remoteUrl;
          }
        }
      } catch (_) {}
      final caption = _msgCtrl.text.trim();
      ref.read(ecosystemProvider.notifier).sendMessage(
            _selectedChannel,
            senderName,
            caption.isEmpty ? 'Note vocale (${duration}s)' : caption,
            audioUrl: finalUrl,
            audioDurationSeconds: duration,
          );
      _msgCtrl.clear();
      if (mounted) {
        setState(() {
          _uploadingVoice = false;
          _voiceSeconds = 0;
        });
      }
      return;
    }

    try {
      await audioService.startRecording(prefix: 'msg_vocal');
      if (!mounted) return;
      setState(() {
        _recordingVoice = true;
        _voiceSeconds = 0;
      });
      _voiceTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (!mounted) return;
        setState(() => _voiceSeconds++);
        if (_voiceSeconds >= 120) {
          _toggleVoiceNote(audioService, senderName);
        }
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Micro indisponible : $e')),
      );
    }
  }

  Future<void> _togglePlayMessageAudio(
    AudioService audioService,
    ChatMessageModel msg,
  ) async {
    final url = msg.audioUrl;
    if (url == null || url.isEmpty) return;
    if (_playingMessageId == msg.id) {
      await audioService.stopPlayback();
      if (mounted) setState(() => _playingMessageId = null);
      return;
    }
    setState(() => _playingMessageId = msg.id);
    await audioService.playFile(
      url,
      onEnded: () {
        if (mounted) setState(() => _playingMessageId = null);
      },
      onError: (err) {
        if (mounted) {
          setState(() => _playingMessageId = null);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(err)),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final eco = ref.watch(ecosystemProvider);
    final profile = ref.watch(authProvider);
    final liveKit = ref.watch(liveKitServiceProvider);
    final audioService = ref.watch(audioServiceProvider);

    final visibleMessages = eco.messages
        .where((m) =>
            m.channelName == _selectedChannel &&
            !eco.blockedUsers.contains(m.senderName))
        .toList();

    VoiceRoomModel? activeRoom;
    for (final room in eco.voiceRooms) {
      if (room.id == _connectedRoomId) {
        activeRoom = room;
        break;
      }
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Communauté & Salons Live')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          YitteReveal(
            order: 0,
            child: EditorialHeroBanner(
              eyebrow: 'FRATERNITÉ, ÉCHANGES & EXTRA GROUPE',
              accentColor: YitteDomainAccents.community,
              title: 'Vie Communautaire',
              subtitle:
                  'Salons vocaux en direct, rencontres mensuelles Extra Groupe, annuaire vérifié et messagerie par canaux.',
              actions: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.tokensOf(context).visualModel ==
                            UiVisualModel.editorialMinimal
                        ? Theme.of(context).colorScheme.primary
                        : YitteColors.goldBright,
                    foregroundColor: AppTheme.tokensOf(context).visualModel ==
                            UiVisualModel.editorialMinimal
                        ? Colors.white
                        : YitteColors.inkDark,
                  ),
                  icon: const Icon(Icons.groups_2_rounded, size: 18),
                  label: const Text('Extra Groupe'),
                  onPressed: () => context.push('/extra-groupe'),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTheme.tokensOf(context).visualModel ==
                            UiVisualModel.editorialMinimal
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white,
                    side: BorderSide(
                      color: AppTheme.tokensOf(context).visualModel ==
                              UiVisualModel.editorialMinimal
                          ? Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                  icon: const Icon(Icons.folder_copy_outlined, size: 18),
                  label: const Text('Bibliothèque Docs'),
                  onPressed: () => context.push('/documents'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const SectionHeader(title: 'Liaison Groupe WhatsApp'),
          const SizedBox(height: 8),
          YitteSurfaceCard(
            borderColor: AppTheme.tokensOf(context).borderAccent,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const YitteIconBadge(
                      icon: Icons.chat_rounded,
                      color: Color(0xFF16A34A),
                      size: 46,
                      iconSize: 23,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            eco.whatsappGroupName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          YitteStatusPill(
                            icon: eco.whatsappInviteUrl != null
                                ? Icons.check_circle_outline_rounded
                                : Icons.link_off_rounded,
                            label: eco.whatsappInviteUrl != null
                                ? 'Lien officiel actif'
                                : 'Lien à configurer dans Admin',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  'Transformez les discussions du groupe en savoir durable : importez un export (.txt) vers Réflexions ou vers la Bibliothèque Docs (avec résumé structuré), exportez un bulletin PDF prêt pour WhatsApp ou ouvrez le groupe en un clic.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.open_in_new_rounded, size: 18),
                      label: Text(eco.whatsappInviteUrl != null
                          ? 'Ouvrir le groupe WhatsApp'
                          : 'Configurer lien WhatsApp'),
                      onPressed: () {
                        if (eco.whatsappInviteUrl != null) {
                          ExternalLinkBridge.openUrl(eco.whatsappInviteUrl!);
                        } else {
                          context.push('/admin');
                        }
                      },
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.auto_awesome_mosaic_outlined, size: 18),
                      label: const Text('Importer & Archiver (.txt)'),
                      onPressed: () => _openWhatsAppImportDialog(context),
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                      label: const Text('Exporter Digest PDF'),
                      onPressed: () async {
                        final waMsgs = eco.messages
                            .where((m) => m.channelName == 'Groupe WhatsApp')
                            .toList();
                        final bullets = waMsgs.isNotEmpty
                            ? waMsgs
                                .map((m) => '${m.senderName} : ${m.body}')
                                .toList()
                            : eco.reflections
                                .take(5)
                                .map((r) => '${r.title} (${r.authorName})')
                                .toList();
                        final bytes = await PdfExportService.buildSummaryPdf(
                          title: 'Bulletin Communautaire — ${eco.whatsappGroupName}',
                          subtitle:
                              'Synthèse des échanges prêts pour partage WhatsApp',
                          bodyMarkdown: waMsgs.isNotEmpty
                              ? '${waMsgs.length} intervention(s) extraite(s) du fil Groupe WhatsApp.'
                              : 'Sélection des dernières réflexions de la structure BOROOM YITTÉ YU KAWÉ YI.',
                          bulletPoints: bullets,
                          references: [
                            if (eco.whatsappInviteUrl != null)
                              eco.whatsappInviteUrl!,
                          ],
                        );
                        await PdfExportService.previewAndSharePdf(
                          bytes: bytes,
                          filename: 'digest_whatsapp_boroom_yitte.pdf',
                        );
                      },
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(Icons.share_outlined, size: 18),
                      label: const Text('Copier & Partager Bulletin'),
                      onPressed: () async {
                        final latestRef = eco.reflections.isNotEmpty
                            ? eco.reflections.first.title
                            : 'Nouvelles réflexions disponibles';
                        final bulletin =
                            '*BOROOM YITTÉ YU KAWÉ YI — Bulletin*\n'
                            '• Dernière réflexion : $latestRef\n'
                            '• Rencontre Extra Groupe : ${eco.extraGroupeMeetings.isNotEmpty ? eco.extraGroupeMeetings.first.guest.fullName : "À venir"}\n'
                            '• Connexion membre (Nom complet) : /#/auth';
                        await Clipboard.setData(ClipboardData(text: bulletin));
                        final shareUrl = WhatsAppBridgeService.buildShareUrl(
                          bulletin,
                          groupInviteUrl: eco.whatsappInviteUrl,
                        );
                        await ExternalLinkBridge.openUrl(shareUrl);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (activeRoom != null) ...[
            Card(
              color: YitteColors.emeraldDarkSurface,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.graphic_eq_rounded,
                            color: YitteColors.goldBright),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Salon actif : ${activeRoom.title}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _micEnabled
                                ? YitteColors.gold
                                : Colors.white24,
                            foregroundColor: _micEnabled
                                ? YitteColors.inkDark
                                : Colors.white,
                          ),
                          icon: Icon(
                              _micEnabled ? Icons.mic_rounded : Icons.mic_off_rounded),
                          label: Text(_micEnabled ? 'Micro actif' : 'Activer micro'),
                          onPressed: () async {
                            if (!_micEnabled) {
                              final granted = await audioService
                                  .ensureMicrophonePermission();
                              if (liveKit.isConnected) {
                                await liveKit.toggleMic();
                              }
                              if (mounted) {
                                setState(() => _micEnabled = granted);
                              }
                            } else {
                              if (liveKit.isConnected) {
                                await liveKit.toggleMic();
                              }
                              if (mounted) setState(() => _micEnabled = false);
                            }
                          },
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white54),
                          ),
                          icon: const Icon(Icons.call_end_rounded),
                          label: const Text('Quitter'),
                          onPressed: () async {
                            final leftId = _connectedRoomId;
                            await liveKit.disconnect();
                            if (leftId != null) {
                              ref
                                  .read(ecosystemProvider.notifier)
                                  .leaveVoiceRoom(leftId);
                            }
                            if (mounted) {
                              setState(() {
                                _connectedRoomId = null;
                                _micEnabled = false;
                                _selectedChannel = 'Cercle Général';
                              });
                            }
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          SectionHeader(
            title: 'Salons Vocaux en Direct (WebRTC)',
            actionLabel: '+ Salon',
            onAction: () => _openCreateRoomDialog(context, profile?.fullName ?? 'Hôte'),
          ),
          const SizedBox(height: 8),
          ...eco.voiceRooms.map(
            (r) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: YitteColors.emeraldSoft,
                  child: const Icon(Icons.spatial_audio_off_rounded,
                      color: YitteColors.emerald),
                ),
                title: Text(r.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  'Hôte : ${r.hostName} • ${r.participantsCount} participants'
                  '${r.cefrFilter != null ? " • CEFR ${r.cefrFilter}" : ""}',
                ),
                trailing: ElevatedButton(
                  onPressed: () async {
                    if (_connectedRoomId == r.id) {
                      await liveKit.disconnect();
                      ref.read(ecosystemProvider.notifier).leaveVoiceRoom(r.id);
                      if (mounted) {
                        setState(() {
                          _connectedRoomId = null;
                          _micEnabled = false;
                          _selectedChannel = 'Cercle Général';
                        });
                      }
                      return;
                    }
                    if (_connectedRoomId != null) {
                      ref
                          .read(ecosystemProvider.notifier)
                          .leaveVoiceRoom(_connectedRoomId!);
                    }
                    final creds = await BackendRepository.instance
                        .fetchLiveKitJoinToken(r.id);
                    if (creds == null) {
                      final hasMic =
                          await audioService.ensureMicrophonePermission();
                      if (!mounted) return;
                      ref.read(ecosystemProvider.notifier).joinVoiceRoom(r.id);
                      setState(() {
                        _connectedRoomId = r.id;
                        _micEnabled = hasMic;
                        _selectedChannel = r.title;
                      });
                      return;
                    }
                    await liveKit.connect(
                      livekitUrl: creds['url']!,
                      token: creds['token']!,
                    );
                    if (mounted) {
                      ref.read(ecosystemProvider.notifier).joinVoiceRoom(r.id);
                      setState(() {
                        _connectedRoomId = r.id;
                        _micEnabled = true;
                        _selectedChannel = r.title;
                      });
                    }
                  },
                  child: Text(_connectedRoomId == r.id ? 'Quitter' : 'Rejoindre'),
                ),
              ),
            ),
          ),
          const SizedBox(height: 18),
          SectionHeader(title: 'Membres Inscrits (${eco.members.length})'),
          const SizedBox(height: 8),
          if (eco.members.isEmpty)
            YitteEmptyState(
              icon: Icons.person_outline_rounded,
              title: 'Aucun membre enregistré sur ce serveur',
              description:
                  'Connectez-vous ou inscrivez un compte pour rejoindre l’annuaire vérifié des membres.',
              actionLabel: 'Se connecter / S’inscrire',
              onAction: () => context.push('/auth'),
            )
          else
            YitteSurfaceCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: eco.members
                    .map(
                      (m) => ListTile(
                        leading: CircleAvatar(
                          backgroundColor: YitteColors.emeraldSoft,
                          child: Text(
                            m.fullName.isNotEmpty
                                ? m.fullName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: YitteColors.emerald,
                            ),
                          ),
                        ),
                        title: Text(m.fullName,
                            style: const TextStyle(fontWeight: FontWeight.w700)),
                        subtitle: Text('@${m.username} • ${m.roleCode}'),
                      ),
                    )
                    .toList(),
              ),
            ),
          const SizedBox(height: 18),
          SectionHeader(title: 'Messagerie — $_selectedChannel'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: <String>{
              'Cercle Général',
              'Groupe WhatsApp',
              if (_connectedRoomId != null && activeRoom != null) activeRoom.title,
            }
                .map(
                  (ch) => ChoiceChip(
                    label: Text(ch),
                    selected: _selectedChannel == ch,
                    onSelected: (_) => setState(() => _selectedChannel = ch),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  if (visibleMessages.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Aucun message dans ce canal pour l’instant. Démarrez la discussion ci-dessous.',
                      ),
                    ),
                  ...visibleMessages.map(
                    (m) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(m.senderName,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.body),
                          if (m.audioUrl != null && m.audioUrl!.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: YitteAudioPlayerTile(
                                playing: _playingMessageId == m.id,
                                label: _playingMessageId == m.id
                                    ? 'Arrêter la lecture'
                                    : 'Vocal • ${m.audioDurationSeconds ?? 0}s',
                                accentColor: YitteDomainAccents.community,
                                onToggle: () =>
                                    _togglePlayMessageAudio(audioService, m),
                              ),
                            ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (act) {
                          if (act == 'report') {
                            ref
                                .read(ecosystemProvider.notifier)
                                .submitReport('message', 'Contenu signalé par un membre');
                          } else if (act == 'block') {
                            ref.read(ecosystemProvider.notifier).blockUser(m.senderName);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'report', child: Text('Signaler')),
                          PopupMenuItem(value: 'block', child: Text('Bloquer cet utilisateur')),
                        ],
                      ),
                    ),
                  ),
                  if (_recordingVoice)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: YitteStatusPill(
                        icon: Icons.graphic_eq_rounded,
                        label: 'Enregistrement vocal en cours (${_voiceSeconds}s)... appuyez sur Stop pour envoyer',
                        backgroundColor: YitteColors.danger.withValues(alpha: 0.12),
                        foregroundColor: YitteColors.danger,
                      ),
                    ),
                  if (_uploadingVoice)
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: LinearProgressIndicator(),
                    ),
                  const Divider(),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _msgCtrl,
                          decoration: InputDecoration(
                            hintText: 'Écrire dans $_selectedChannel...',
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton.outlined(
                        tooltip: _recordingVoice
                            ? 'Arrêter et envoyer le vocal'
                            : 'Enregistrer une note vocale',
                        style: _recordingVoice
                            ? IconButton.styleFrom(
                                backgroundColor: YitteColors.danger.withValues(alpha: 0.14),
                                foregroundColor: YitteColors.danger,
                              )
                            : null,
                        onPressed: _uploadingVoice
                            ? null
                            : () => _toggleVoiceNote(
                                  audioService,
                                  profile?.fullName ?? 'Membre',
                                ),
                        icon: Icon(
                          _recordingVoice ? Icons.stop_rounded : Icons.mic_rounded,
                        ),
                      ),
                      const SizedBox(width: 6),
                      IconButton.filled(
                        onPressed: () {
                          if (_msgCtrl.text.trim().isEmpty) return;
                          ref.read(ecosystemProvider.notifier).sendMessage(
                                _selectedChannel,
                                profile?.fullName ?? 'Membre',
                                _msgCtrl.text.trim(),
                              );
                          _msgCtrl.clear();
                        },
                        icon: const Icon(Icons.send_rounded),
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

  Future<void> _openCreateRoomDialog(BuildContext context, String hostName) async {
    String type = 'community';
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ouvrir un Salon Vocal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _roomTitleCtrl,
              decoration: const InputDecoration(labelText: 'Titre du salon'),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              initialValue: type,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Type'),
              items: const [
                DropdownMenuItem(value: 'community', child: Text('Discussion Communautaire')),
                DropdownMenuItem(value: 'english_conversation', child: Text('English Conversation')),
                DropdownMenuItem(value: 'workshop', child: Text('Atelier en ligne')),
              ],
              onChanged: (v) => type = v ?? 'community',
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () {
              if (_roomTitleCtrl.text.trim().isEmpty) return;
              ref.read(ecosystemProvider.notifier).createVoiceRoom(
                    _roomTitleCtrl.text.trim(),
                    type,
                    hostName,
                  );
              _roomTitleCtrl.clear();
              Navigator.pop(ctx);
            },
            child: const Text('Créer'),
          ),
        ],
      ),
    );
  }

  Future<void> _openWhatsAppImportDialog(BuildContext context) async {
    final topicTitleCtrl = TextEditingController();
    String destination = 'both_archive_doc';
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          title: const Text('Exploiter un export WhatsApp (.txt)'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ne perdez plus les échanges riches du groupe : importez le fichier _chat.txt ou collez une discussion pour la transformer en Archive Réflexion + Synthèse Bibliothèque.',
                  style: TextStyle(fontSize: 13),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: topicTitleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Titre du thème / résumé (ex. Échanges sur la discipline)',
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: destination,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Action dans la structure'),
                  items: const [
                    DropdownMenuItem(
                      value: 'both_archive_doc',
                      child: Text('Archiver en Réflexion + Résumer en Bibliothèque Docs'),
                    ),
                    DropdownMenuItem(
                      value: 'reflection_only',
                      child: Text('Transformer en sujet dans Réflexions & Savoir'),
                    ),
                    DropdownMenuItem(
                      value: 'chat_only',
                      child: Text('Importer uniquement dans le fil Groupe WhatsApp'),
                    ),
                  ],
                  onChanged: (v) => setModalState(() => destination = v ?? 'both_archive_doc'),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  icon: const Icon(Icons.attach_file_rounded),
                  label: const Text('Choisir un fichier _chat.txt'),
                  onPressed: () async {
                    final picked = await FilePickerBridge.pickDocumentFile();
                    if (picked == null) return;
                    final text = picked.extractedText ??
                        utf8.decode(picked.bytes, allowMalformed: true);
                    if (text.trim().isNotEmpty) {
                      _waImportCtrl.text = text;
                    }
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _waImportCtrl,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Contenu export WhatsApp (.txt)',
                    hintText: 'Ex. 18/11/2026, 20:15 - Sokhna Diarra : Bonsoir à tous...',
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
              onPressed: () async {
                final raw = _waImportCtrl.text.trim();
                final parsed = WhatsAppBridgeService.parseWhatsAppChatExport(raw);
                final count = ref
                    .read(ecosystemProvider.notifier)
                    .importWhatsAppChatExport(
                      rawText: raw,
                      channelName: 'Groupe WhatsApp',
                    );
                final customTitle = topicTitleCtrl.text.trim().isNotEmpty
                    ? topicTitleCtrl.text.trim()
                    : 'Synthèse discussion WhatsApp (${DateTime.now().day}/${DateTime.now().month})';

                if (parsed.isNotEmpty && destination != 'chat_only') {
                  final authors = parsed.map((e) => e.sender).toSet().toList();
                  final compiledBody = parsed
                      .map((m) => '${m.sender} : ${m.body}')
                      .join('\n');
                  final currentUser = ref.read(authProvider);

                  ref.read(ecosystemProvider.notifier).addReflection(
                        authorId: currentUser?.id ?? 'whatsapp-bridge',
                        authorName: currentUser?.fullName ?? authors.first,
                        title: customTitle,
                        body: compiledBody,
                        category: 'society',
                        contextText:
                            'Archive issue des échanges du groupe WhatsApp (${authors.length} intervenant(s) : ${authors.join(", ")}).',
                        documentarySources: const ['Export réel WhatsApp (.txt)'],
                        validationStatus: 'approved',
                      );

                  if (destination == 'both_archive_doc') {
                    final doc = LibraryDocumentModel(
                      id: 'wa-doc-${DateTime.now().millisecondsSinceEpoch}',
                      title: customTitle,
                      description:
                          'Discussion WhatsApp archivée (${parsed.length} message(s), intervenants : ${authors.join(", ")}).',
                      fileName: 'whatsapp_export.txt',
                      format: 'txt',
                      domain: 'Société et civilisation',
                      subcategory: 'Enjeux contemporains',
                      authorOrContributor: authors.join(', '),
                      sourceReference: 'Export Groupe WhatsApp BOROOM YITTÉ',
                      language: 'fr',
                      keywords: const ['WhatsApp', 'Archive', 'Communauté'],
                      extractedText: compiledBody,
                      validationStatus: 'validated',
                      addedAt: DateTime.now(),
                    );
                    ref.read(ecosystemProvider.notifier).addLibraryDocument(doc);
                    try {
                      await ref
                          .read(ecosystemProvider.notifier)
                          .generateDocumentSummary(doc.id);
                    } catch (_) {
                      // Skip summary cleanly if excerpt < 20 chars
                    }
                  }
                }

                _waImportCtrl.clear();
                if (count > 0 && mounted) {
                  setState(() => _selectedChannel = 'Groupe WhatsApp');
                }
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(this.context).showSnackBar(
                    SnackBar(
                      content: Text(
                        count > 0
                            ? destination == 'both_archive_doc'
                                ? '$count message(s) importé(s), archivé(s) en Réflexion et résumé(s) dans Bibliothèque Docs.'
                                : '$count message(s) WhatsApp exploité(s) avec succès.'
                            : 'Aucun message au format export WhatsApp (.txt) reconnu.',
                      ),
                    ),
                  );
                }
              },
              child: const Text('Lancer'),
            ),
          ],
        ),
      ),
    );
  }
}
