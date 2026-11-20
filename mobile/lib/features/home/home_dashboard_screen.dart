import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/state/app_providers.dart';
import '../../core/models/domain_models.dart';
import '../../core/services/calendar_export_service.dart';
import '../../core/services/daily_quotes_catalog.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/editorial_widgets.dart';

class HomeDashboardScreen extends ConsumerStatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  ConsumerState<HomeDashboardScreen> createState() =>
      _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends ConsumerState<HomeDashboardScreen> {
  int _quoteOffset = 0;

  @override
  Widget build(BuildContext context) {
    final eco = ref.watch(ecosystemProvider);
    final profile = ref.watch(authProvider);
    final tokens = AppTheme.tokensOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = MediaQuery.sizeOf(context).width >= 880;

    final unreadNotifs = eco.notifications.where((n) => !n.isRead).length;
    final upcomingExtra = eco.extraGroupeMeetings
        .where((m) => m.status != 'archived')
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    final activeReflections =
        eco.reflections.where((r) => !r.isArchived).toList();
    final writtenInterventions = eco.weeklyTopic.contributions.length +
        activeReflections.fold<int>(
          0,
          (sum, r) => sum + 1 + r.comments.length,
        );
    final vocalInterventions = eco.debates
        .where(
          (d) =>
              (d.userAudioPath != null && d.userAudioPath!.trim().isNotEmpty) ||
              (d.userTranscript != null && d.userTranscript!.trim().isNotEmpty),
        )
        .length;

    final closingLabel = _formatWeekClosingDate(DateTime.now());
    final contributions = _collectLatestContributions(eco);
    final dailyQuote = DailyQuotesCatalog.quoteForDate(
      DateTime.now().add(Duration(days: _quoteOffset)),
    );

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: tokens.canvas,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 50,
        titleSpacing: 16,
        title: Text(
          isDesktop ? 'Tableau de bord' : 'BOROOM YITTÉ',
          style: TextStyle(
            fontFamily: YitteFonts.display,
            fontFamilyFallback: YitteFonts.fallback,
            fontSize: 17.5,
            fontWeight: FontWeight.w700,
            letterSpacing: isDesktop ? 0.2 : 1.0,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Notifications',
            onPressed: () => context.push('/notifications'),
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none_rounded, size: 21),
                if (unreadNotifs > 0)
                  Positioned(
                    right: 1,
                    top: 1,
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: YitteColors.gold,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 6),
            child: IconButton(
              tooltip: 'Profil & Thème',
              onPressed: () => _openProfileAndThemeSheet(
                context,
                profile: profile,
                isDark: isDark,
              ),
              icon: const Icon(Icons.person_outline_rounded, size: 21),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 36),
        children: [
          // 1. GRILLE HORIZONTALE COMPACTE DES 8 ESPACES (4×2 mobile / 8×1 PC — fini la petite colonne!)
          _CompactHorizontalSpacesGrid(
            onOpenRoute: (route) => context.push(route),
          ),

          const SizedBox(height: 16),

          // 2. BLOC « À LA UNE — DÉBAT DE LA SEMAINE » (Format compact, émeraude & or 1px)
          _EditorialBlockLabel(
            label: 'À LA UNE — DÉBAT DE LA SEMAINE',
            trailing: Text(
              'S${eco.weeklyTopic.weekNumber} • ${eco.weeklyTopic.year}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: tokens.goldAccent,
                    letterSpacing: 0.8,
                  ),
            ),
          ),
          const SizedBox(height: 6),
          _WeeklyDebateSignatureCard(
            weekLabel:
                'SEMAINE ${eco.weeklyTopic.weekNumber} • ${eco.weeklyTopic.year}',
            title: eco.weeklyTopic.title,
            writtenCount: writtenInterventions,
            vocalCount: vocalInterventions,
            closingLabel: closingLabel,
            onJoinDebate: () => context.go('/reflections'),
          ),

          const SizedBox(height: 16),

          // 3. BLOC « PROCHAIN RENDEZ-VOUS » & ANNONCES (Format compact)
          _EditorialBlockLabel(
            label: 'PROCHAIN RENDEZ-VOUS',
            trailing: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => _openQuickAnnouncementDialog(
                context,
                profile?.fullName ?? 'Membre',
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  '+ Annonce',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          _NextEventCompactCard(
            upcomingExtra: upcomingExtra.isNotEmpty ? upcomingExtra.first : null,
            pinnedAnnouncement:
                eco.announcements.isNotEmpty ? eco.announcements.first : null,
            onAskQuestion: () => context.push('/extra-groupe'),
            onJoinZikr: () => context.push('/zikr'),
            onExportCalendar: ({
              required String title,
              required String description,
              required DateTime start,
              String? location,
            }) async {
              final ok = await CalendarExportService.addEventToCalendar(
                title: title,
                description: description,
                start: start,
                location: location ?? 'BOROOM YITTÉ YU KAWÉ YI',
              );
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      ok
                          ? 'Événement exporté (.ics) — prêt à ajouter à votre agenda.'
                          : 'Ouverture de votre agenda indisponible sur cet appareil.',
                    ),
                  ),
                );
              }
            },
          ),

          const SizedBox(height: 18),

          // 4. BLOC « DERNIÈRES CONTRIBUTIONS » (Liste éditoriale pure séparée par Divider 1px)
          _EditorialBlockLabel(
            label: 'DERNIÈRES CONTRIBUTIONS',
            trailing: InkWell(
              borderRadius: BorderRadius.circular(6),
              onTap: () => context.go('/reflections'),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                child: Text(
                  'Tout voir',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          if (contributions.isEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(height: 1, thickness: 1, color: tokens.borderSubtle),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Aucune contribution publiée cette semaine.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(width: 10),
                      OutlinedButton(
                        onPressed: () => context.go('/reflections'),
                        child: const Text('Contribuer'),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, thickness: 1, color: tokens.borderSubtle),
              ],
            )
          else
            Column(
              children: [
                Divider(height: 1, thickness: 1, color: tokens.borderSubtle),
                for (int i = 0; i < contributions.length; i++) ...[
                  _EditorialContributionRow(
                    item: contributions[i],
                    onTap: () {
                      final route = contributions[i].route;
                      if (route == '/reflections') {
                        context.go(route);
                      } else {
                        context.push(route);
                      }
                    },
                  ),
                  Divider(height: 1, thickness: 1, color: tokens.borderSubtle),
                ],
              ],
            ),

          const SizedBox(height: 18),

          // Pensée du jour discrète (Masālik al-Jinān / Classiques)
          _EditorialDailyQuoteFoot(
            quote: dailyQuote,
            customThought: eco.validatedDailyThought,
            onNext: () => setState(() => _quoteOffset++),
            onShare: () async {
              final text = eco.validatedDailyThought != null &&
                      eco.validatedDailyThought!.trim().isNotEmpty
                  ? '« ${eco.validatedDailyThought!.trim()} »\n— BOROOM YITTÉ YU KAWÉ YI'
                  : dailyQuote.formatForShare();
              final uri = Uri.parse(
                'https://wa.me/?text=${Uri.encodeComponent(text)}',
              );
              final ok = await launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
              );
              if (!ok) {
                await Clipboard.setData(ClipboardData(text: text));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Citation copiée pour le partage.'),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
    );
  }

  List<_HomeContributionEntry> _collectLatestContributions(
    EcosystemState eco,
  ) {
    final items = <_HomeContributionEntry>[];

    final reflections = eco.reflections.where((r) => !r.isArchived).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (reflections.isNotEmpty) {
      final first = reflections.first;
      items.add(
        _HomeContributionEntry(
          category: 'RÉFLEXION',
          title: first.title,
          meta: 'Par ${first.authorName} • ${_formatShortDate(first.createdAt)}',
          route: '/reflections',
        ),
      );
    }

    if (eco.weeklyTopic.summary != null &&
        eco.weeklyTopic.summary!.summaryMarkdown.trim().isNotEmpty) {
      final s = eco.weeklyTopic.summary!;
      items.add(
        _HomeContributionEntry(
          category: 'SYNTHÈSE',
          title: s.title,
          meta: s.reviewedByName != null
              ? 'Validée par ${s.reviewedByName}'
              : 'Synthèse hebdomadaire',
          route: '/reflections',
        ),
      );
    } else if (reflections.length >= 2) {
      final second = reflections[1];
      items.add(
        _HomeContributionEntry(
          category: 'RÉFLEXION',
          title: second.title,
          meta:
              'Par ${second.authorName} • ${_formatShortDate(second.createdAt)}',
          route: '/reflections',
        ),
      );
    }

    if (eco.careerOpportunities.isNotEmpty) {
      final opp = eco.careerOpportunities.first;
      items.add(
        _HomeContributionEntry(
          category: 'OPPORTUNITÉ',
          title: opp.title,
          meta: '${opp.organization} • ${opp.location}',
          route: '/professional',
        ),
      );
    } else if (eco.libraryDocuments.isNotEmpty) {
      final doc = eco.libraryDocuments.first;
      items.add(
        _HomeContributionEntry(
          category: 'DOCUMENT',
          title: doc.title,
          meta: 'Par ${doc.authorOrContributor} • ${doc.format.toUpperCase()}',
          route: '/documents',
        ),
      );
    } else if (reflections.length >= 3) {
      final third = reflections[2];
      items.add(
        _HomeContributionEntry(
          category: 'RÉFLEXION',
          title: third.title,
          meta: 'Par ${third.authorName} • ${_formatShortDate(third.createdAt)}',
          route: '/reflections',
        ),
      );
    }

    if (items.length < 3 && reflections.length > 1) {
      for (final r in reflections.skip(1)) {
        if (items.length >= 3) break;
        if (items.any((e) => e.title == r.title)) continue;
        items.add(
          _HomeContributionEntry(
            category: 'RÉFLEXION',
            title: r.title,
            meta: 'Par ${r.authorName} • ${_formatShortDate(r.createdAt)}',
            route: '/reflections',
          ),
        );
      }
    }

    return items.take(3).toList();
  }

  Future<void> _openProfileAndThemeSheet(
    BuildContext context, {
    required UserProfile? profile,
    required bool isDark,
  }) async {
    final tokens = AppTheme.tokensOf(context);
    final themeMode = ref.read(themeModeProvider);
    await showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile?.fullName ?? 'Membre BOROOM YITTÉ',
                        style: Theme.of(ctx).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        profile?.role.labelFr ?? 'Accès invité',
                        style: Theme.of(ctx).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Fermer',
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Divider(height: 1, color: tokens.borderSubtle),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Icon(
                isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
                size: 20,
              ),
              title: Text(isDark ? 'Passer en mode Clair' : 'Passer en mode Sombre'),
              onTap: () {
                final next = (themeMode == ThemeMode.dark ||
                        (themeMode == ThemeMode.system && isDark))
                    ? ThemeMode.light
                    : ThemeMode.dark;
                ref.read(themeModeProvider.notifier).setMode(next);
                Navigator.pop(ctx);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.tune_outlined, size: 20),
              title: const Text('Thèmes & Apparence'),
              onTap: () {
                Navigator.pop(ctx);
                showDesignStudioSheet(context);
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.person_outline_rounded, size: 20),
              title: Text(profile == null ? 'Connexion membre' : 'Compte & Profil'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/auth');
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.admin_panel_settings_outlined, size: 20),
              title: const Text('Administration'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/admin');
              },
            ),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.settings_outlined, size: 20),
              title: const Text('Paramètres'),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/settings');
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openQuickAnnouncementDialog(
    BuildContext context,
    String authorName,
  ) async {
    final titleCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    final locationCtrl = TextEditingController();
    DateTime? selectedDate;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Publier une annonce'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Titre de l’annonce *',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: bodyCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Détails essentiels',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: locationCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Lieu ou lien (optionnel)',
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    final now = DateTime.now();
                    final date = await showDatePicker(
                      context: ctx,
                      initialDate:
                          selectedDate ?? now.add(const Duration(days: 1)),
                      firstDate: now.subtract(const Duration(days: 1)),
                      lastDate: now.add(const Duration(days: 365)),
                    );
                    if (date == null || !ctx.mounted) return;
                    final time = await showTimePicker(
                      context: ctx,
                      initialTime: const TimeOfDay(hour: 20, minute: 0),
                    );
                    setDialogState(() {
                      selectedDate = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time?.hour ?? 20,
                        time?.minute ?? 0,
                      );
                    });
                  },
                  icon: const Icon(Icons.calendar_today_outlined, size: 16),
                  label: Text(
                    selectedDate == null
                        ? 'Associer une date (Agenda 1 clic)'
                        : _formatFrenchDateTime(selectedDate!),
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
                final t = titleCtrl.text.trim();
                if (t.isEmpty) return;
                ref.read(ecosystemProvider.notifier).broadcastAnnouncement(
                      t,
                      bodyCtrl.text.trim(),
                      authorName,
                      eventDate: selectedDate,
                      location: locationCtrl.text.trim().isEmpty
                          ? null
                          : locationCtrl.text.trim(),
                    );
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Annonce publiée sur l’Accueil et dans Notifications.',
                    ),
                  ),
                );
              },
              child: const Text('Publier'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grille horizontale compacte 4×2 (mobile) ou 8×1 (PC) inspirée du lanceur SDM,
/// strictement dans la palette éditoriale 3 couleurs (0 ombre floue, icônes monochromes fines).
class _CompactHorizontalSpacesGrid extends StatelessWidget {
  final ValueChanged<String> onOpenRoute;

  const _CompactHorizontalSpacesGrid({required this.onOpenRoute});

  static const _items = [
    (icon: Icons.mosque_outlined, label: 'Yitté Zikr', route: '/zikr', gold: false),
    (icon: Icons.translate_rounded, label: 'English Club', route: '/english-club', gold: false),
    (icon: Icons.folder_copy_outlined, label: 'Bibliothèque', route: '/documents', gold: false),
    (icon: Icons.event_outlined, label: 'Extra Groupe', route: '/extra-groupe', gold: true),
    (icon: Icons.record_voice_over_outlined, label: 'Face-à-Face', route: '/debates', gold: false),
    (icon: Icons.emoji_events_outlined, label: 'Quiz Arena', route: '/quiz-arena', gold: true),
    (icon: Icons.work_outline_rounded, label: 'Professionnel', route: '/professional', gold: false),
    (icon: Icons.lock_outline_rounded, label: 'Dév. Perso', route: '/personal-growth', gold: true),
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.tokensOf(context);
    final primary = Theme.of(context).colorScheme.primary;

    return LayoutBuilder(
      builder: (context, constraints) {
        final cols = constraints.maxWidth >= 760 ? 8 : 4;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: cols == 8 ? 1.12 : 1.08,
          ),
          itemBuilder: (context, i) {
            final item = _items[i];
            final fg = item.gold ? tokens.goldAccent : primary;
            return InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => onOpenRoute(item.route),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                decoration: BoxDecoration(
                  color: tokens.elevated,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: tokens.borderSubtle, width: 1),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: tokens.subtleFill,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: tokens.borderSubtle, width: 1),
                      ),
                      child: Icon(item.icon, size: 17, color: fg),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0,
                          ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _EditorialBlockLabel extends StatelessWidget {
  final String label;
  final Widget? trailing;

  const _EditorialBlockLabel({required this.label, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  letterSpacing: 1.25,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        ?trailing,
      ],
    );
  }
}

class _WeeklyDebateSignatureCard extends StatelessWidget {
  final String weekLabel;
  final String title;
  final int writtenCount;
  final int vocalCount;
  final String closingLabel;
  final VoidCallback onJoinDebate;

  const _WeeklyDebateSignatureCard({
    required this.weekLabel,
    required this.title,
    required this.writtenCount,
    required this.vocalCount,
    required this.closingLabel,
    required this.onJoinDebate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 13, 16, 13),
      decoration: BoxDecoration(
        color: YitteColors.emerald,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: YitteColors.gold, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                weekLabel,
                style: const TextStyle(
                  fontFamily: YitteFonts.ui,
                  fontFamilyFallback: YitteFonts.fallback,
                  color: YitteColors.gold,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
              const Spacer(),
              Text(
                'Clôture : $closingLabel',
                style: TextStyle(
                  fontFamily: YitteFonts.ui,
                  fontFamilyFallback: YitteFonts.fallback,
                  color: YitteColors.ivory.withValues(alpha: 0.78),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: YitteFonts.display,
              fontFamilyFallback: YitteFonts.fallback,
              color: YitteColors.ivory,
              fontSize: 18,
              fontWeight: FontWeight.w700,
              height: 1.24,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _SignatureMetric(
                icon: Icons.edit_note_outlined,
                label: '$writtenCount écrite${writtenCount > 1 ? "s" : ""}',
              ),
              const SizedBox(width: 12),
              _SignatureMetric(
                icon: Icons.mic_none_rounded,
                label: '$vocalCount vocale${vocalCount > 1 ? "s" : ""}',
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: onJoinDebate,
                style: ElevatedButton.styleFrom(
                  backgroundColor: YitteColors.gold,
                  foregroundColor: YitteColors.inkDark,
                  elevation: 0,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 9,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: YitteFonts.ui,
                    fontFamilyFallback: YitteFonts.fallback,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: const Text('Rejoindre le débat →'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SignatureMetric extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SignatureMetric({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: YitteColors.gold),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontFamily: YitteFonts.ui,
            fontFamilyFallback: YitteFonts.fallback,
            color: YitteColors.ivory.withValues(alpha: 0.9),
            fontSize: 11.5,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _NextEventCompactCard extends StatelessWidget {
  final ExtraGroupeMeetingModel? upcomingExtra;
  final AnnouncementModel? pinnedAnnouncement;
  final VoidCallback onAskQuestion;
  final VoidCallback onJoinZikr;
  final Future<void> Function({
    required String title,
    required String description,
    required DateTime start,
    String? location,
  }) onExportCalendar;

  const _NextEventCompactCard({
    required this.upcomingExtra,
    required this.pinnedAnnouncement,
    required this.onAskQuestion,
    required this.onJoinZikr,
    required this.onExportCalendar,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.tokensOf(context);
    final primary = Theme.of(context).colorScheme.primary;
    final hasExtra = upcomingExtra != null;
    final nextSat = _nextSaturdayAt20Gmt();

    final eventTitle = hasExtra
        ? upcomingExtra!.theme
        : 'Zikr collectif — صَلَّى اللهُ عَلَى مُحَمَّدٍ';
    final eventDate = hasExtra ? upcomingExtra!.scheduledAt : nextSat;
    final eventMeta = hasExtra
        ? 'Invité : ${upcomingExtra!.guest.fullName}'
        : 'Samedi 20h00 GMT • Salon spirituel';
    final eventTag = hasExtra ? 'EXTRA GROUPE' : 'ZIKR COLLECTIF';
    final ctaLabel = hasExtra ? 'Poser une question' : 'Rejoindre le salon';

    return YitteSurfaceCard(
      padding: const EdgeInsets.fromLTRB(14, 11, 14, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pinnedAnnouncement != null) ...[
            Row(
              children: [
                Icon(Icons.campaign_outlined, size: 15, color: tokens.goldAccent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    pinnedAnnouncement!.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          fontSize: 12.5,
                        ),
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: () => onExportCalendar(
                    title: pinnedAnnouncement!.title,
                    description: pinnedAnnouncement!.body,
                    start: pinnedAnnouncement!.eventDate ??
                        DateTime.now().add(const Duration(days: 1)),
                    location: pinnedAnnouncement!.location,
                  ),
                  child: const Text('+ Agenda', style: TextStyle(fontSize: 11.5)),
                ),
              ],
            ),
            Divider(height: 14, thickness: 1, color: tokens.borderSubtle),
          ],
          Row(
            children: [
              Text(
                eventTag,
                style: TextStyle(
                  fontFamily: YitteFonts.ui,
                  fontFamilyFallback: YitteFonts.fallback,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  color: tokens.goldAccent,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '•  ${_formatFrenchDateTime(eventDate)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11.5),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            eventTitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontFamily: YitteFonts.display,
                  fontSize: 15,
                  height: 1.28,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  eventMeta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                onPressed: hasExtra ? onAskQuestion : onJoinZikr,
                child: Text(ctaLabel),
              ),
              const SizedBox(width: 6),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  minimumSize: Size.zero,
                ),
                onPressed: () => onExportCalendar(
                  title: eventTitle,
                  description: eventMeta,
                  start: eventDate,
                  location: hasExtra ? upcomingExtra!.practicalInfo : 'En ligne (GMT)',
                ),
                child: Icon(Icons.event_available_outlined, size: 16, color: primary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeContributionEntry {
  final String category;
  final String title;
  final String meta;
  final String route;

  const _HomeContributionEntry({
    required this.category,
    required this.title,
    required this.meta,
    required this.route,
  });
}

class _EditorialContributionRow extends StatelessWidget {
  final _HomeContributionEntry item;
  final VoidCallback onTap;

  const _EditorialContributionRow({
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.tokensOf(context);
    final isGoldTag = item.category == 'SYNTHÈSE' || item.category == 'OPPORTUNITÉ';
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        item.category,
                        style: TextStyle(
                          fontFamily: YitteFonts.ui,
                          fontFamilyFallback: YitteFonts.fallback,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.1,
                          color: isGoldTag
                              ? tokens.goldAccent
                              : Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.meta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Icon(
              Icons.arrow_forward_rounded,
              size: 15,
              color: tokens.goldAccent,
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorialDailyQuoteFoot extends StatelessWidget {
  final DailyWisdomQuote quote;
  final String? customThought;
  final VoidCallback onNext;
  final VoidCallback onShare;

  const _EditorialDailyQuoteFoot({
    required this.quote,
    required this.customThought,
    required this.onNext,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.tokensOf(context);
    final hasCustom = customThought != null && customThought!.trim().isNotEmpty;
    final body = hasCustom ? customThought!.trim() : quote.text;
    final attribution = hasCustom
        ? 'Pensée du jour'
        : '${quote.author} — ${quote.sourceWork}';

    return Container(
      padding: const EdgeInsets.only(top: 12),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: tokens.borderSubtle, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '« $body »',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontFamily: YitteFonts.display,
                  fontSize: 14.5,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w400,
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: Text(
                  attribution,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: tokens.goldAccent,
                      ),
                ),
              ),
              IconButton(
                tooltip: 'Autre citation',
                visualDensity: VisualDensity.compact,
                onPressed: onNext,
                icon: const Icon(Icons.refresh_rounded, size: 16),
              ),
              IconButton(
                tooltip: 'Partager',
                visualDensity: VisualDensity.compact,
                onPressed: onShare,
                icon: const Icon(Icons.ios_share_outlined, size: 16),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

String _formatWeekClosingDate(DateTime now) {
  final daysUntilSunday = DateTime.sunday - now.weekday;
  final sunday = now.add(Duration(days: daysUntilSunday >= 0 ? daysUntilSunday : 0));
  return 'Dim. ${_formatShortDate(sunday)}';
}

DateTime _nextSaturdayAt20Gmt() {
  final now = DateTime.now().toUtc();
  final diff = (DateTime.saturday - now.weekday + 7) % 7;
  final targetDay = now.add(Duration(days: diff == 0 && now.hour >= 20 ? 7 : diff));
  return DateTime.utc(targetDay.year, targetDay.month, targetDay.day, 20, 0);
}

String _formatShortDate(DateTime d) {
  const months = [
    'janv.',
    'févr.',
    'mars',
    'avr.',
    'mai',
    'juin',
    'juil.',
    'août',
    'sept.',
    'oct.',
    'nov.',
    'déc.',
  ];
  return '${d.day} ${months[d.month - 1]}';
}

String _formatFrenchDateTime(DateTime d) {
  final hh = d.hour.toString().padLeft(2, '0');
  final mm = d.minute.toString().padLeft(2, '0');
  return '${_formatShortDate(d)} à ${hh}h$mm';
}
