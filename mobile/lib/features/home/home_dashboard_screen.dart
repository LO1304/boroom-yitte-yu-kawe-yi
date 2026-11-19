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
  String _spaceFilter = 'Tous';

  @override
  Widget build(BuildContext context) {
    final eco = ref.watch(ecosystemProvider);
    final profile = ref.watch(authProvider);
    final tokens = AppTheme.tokensOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final unreadNotifs = eco.notifications.where((n) => !n.isRead).length;
    final upcomingExtra = eco.extraGroupeMeetings
        .where((m) => m.status != 'archived')
        .toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));

    // Real written & vocal intervention counts for the active weekly debate
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
        titleSpacing: 20,
        title: Text(
          'BOROOM YITTÉ',
          style: TextStyle(
            fontFamily: YitteFonts.display,
            fontFamilyFallback: YitteFonts.fallback,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
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
                const Icon(Icons.notifications_none_rounded, size: 22),
                if (unreadNotifs > 0)
                  Positioned(
                    right: 1,
                    top: 1,
                    child: Container(
                      width: 8,
                      height: 8,
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
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              tooltip: 'Profil & Thème',
              onPressed: () => _openProfileAndThemeSheet(
                context,
                profile: profile,
                isDark: isDark,
              ),
              icon: const Icon(Icons.person_outline_rounded, size: 22),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
        children: [
          // 1. BLOC « À LA UNE — DÉBAT DE LA SEMAINE »
          _EditorialBlockLabel(
            label: 'À LA UNE — DÉBAT DE LA SEMAINE',
            trailing: Text(
              'S${eco.weeklyTopic.weekNumber} • ${eco.weeklyTopic.year}',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: tokens.goldAccent,
                    letterSpacing: 1.0,
                  ),
            ),
          ),
          const SizedBox(height: 10),
          _WeeklyDebateSignatureCard(
            weekLabel:
                'SEMAINE ${eco.weeklyTopic.weekNumber} • ${eco.weeklyTopic.year}',
            title: eco.weeklyTopic.title,
            introduction: eco.weeklyTopic.introduction,
            writtenCount: writtenInterventions,
            vocalCount: vocalInterventions,
            closingLabel: closingLabel,
            onJoinDebate: () => context.go('/reflections'),
          ),

          const SizedBox(height: 28),

          // 2. BLOC « PROCHAIN RENDEZ-VOUS »
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
          const SizedBox(height: 10),
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

          const SizedBox(height: 28),

          // 3. BLOC « VOS ESPACES » — Index organisé par pôles (accès 1 clic sans carrés multicolores)
          _EditorialBlockLabel(
            label: 'VOS ESPACES — ACCÈS ORGANISÉ',
            trailing: Text(
              '8 modules',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: tokens.goldAccent,
                  ),
            ),
          ),
          const SizedBox(height: 10),
          _OrganizedSpacesSection(
            selectedFilter: _spaceFilter,
            onFilterChanged: (f) => setState(() => _spaceFilter = f),
            onOpenRoute: (route) => context.push(route),
          ),

          const SizedBox(height: 28),

          // 4. BLOC « DERNIÈRES CONTRIBUTIONS »
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
          const SizedBox(height: 8),
          if (contributions.isEmpty)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Divider(height: 1, thickness: 1, color: tokens.borderSubtle),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Aucune contribution publiée cette semaine. Partagez la première réflexion du cercle.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(width: 12),
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

          // Note éditoriale discrète : Pensée du jour (Masālik al-Jinān / Classiques)
          const SizedBox(height: 28),
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
          excerpt: first.body.replaceAll('\n', ' ').trim(),
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
          excerpt: s.summaryMarkdown.replaceAll('\n', ' ').trim(),
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
          excerpt: second.body.replaceAll('\n', ' ').trim(),
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
          excerpt: opp.description.replaceAll('\n', ' ').trim(),
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
          excerpt: doc.description.trim().isNotEmpty
              ? doc.description.trim()
              : doc.domain,
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
          excerpt: third.body.replaceAll('\n', ' ').trim(),
          meta: 'Par ${third.authorName} • ${_formatShortDate(third.createdAt)}',
          route: '/reflections',
        ),
      );
    }

    // Backfill up to 3 if more reflections/opportunities exist
    if (items.length < 3 && reflections.length > 1) {
      for (final r in reflections.skip(1)) {
        if (items.length >= 3) break;
        if (items.any((e) => e.title == r.title)) continue;
        items.add(
          _HomeContributionEntry(
            category: 'RÉFLEXION',
            title: r.title,
            excerpt: r.body.replaceAll('\n', ' ').trim(),
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
            const SizedBox(height: 12),
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
                  maxLines: 3,
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
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () async {
                    final now = DateTime.now();
                    final date = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDate ?? now.add(const Duration(days: 1)),
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
                  icon: const Icon(Icons.calendar_today_outlined, size: 17),
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
                  letterSpacing: 1.35,
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
  final String introduction;
  final int writtenCount;
  final int vocalCount;
  final String closingLabel;
  final VoidCallback onJoinDebate;

  const _WeeklyDebateSignatureCard({
    required this.weekLabel,
    required this.title,
    required this.introduction,
    required this.writtenCount,
    required this.vocalCount,
    required this.closingLabel,
    required this.onJoinDebate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: YitteColors.emerald,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: YitteColors.gold, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            weekLabel,
            style: const TextStyle(
              fontFamily: YitteFonts.ui,
              fontFamilyFallback: YitteFonts.fallback,
              color: YitteColors.gold,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontFamily: YitteFonts.display,
              fontFamilyFallback: YitteFonts.fallback,
              color: YitteColors.ivory,
              fontSize: 23,
              fontWeight: FontWeight.w700,
              height: 1.24,
              letterSpacing: -0.2,
            ),
          ),
          if (introduction.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              introduction.trim(),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: YitteFonts.ui,
                fontFamilyFallback: YitteFonts.fallback,
                color: YitteColors.ivory.withValues(alpha: 0.84),
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
          ],
          const SizedBox(height: 18),
          Container(
            height: 1,
            color: YitteColors.gold.withValues(alpha: 0.30),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _SignatureMetric(
                icon: Icons.edit_note_outlined,
                label: '$writtenCount écrite${writtenCount > 1 ? "s" : ""}',
              ),
              _SignatureMetric(
                icon: Icons.mic_none_rounded,
                label: '$vocalCount vocale${vocalCount > 1 ? "s" : ""}',
              ),
              _SignatureMetric(
                icon: Icons.schedule_outlined,
                label: 'Clôture : $closingLabel',
              ),
            ],
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onJoinDebate,
              style: ElevatedButton.styleFrom(
                backgroundColor: YitteColors.gold,
                foregroundColor: YitteColors.inkDark,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                textStyle: const TextStyle(
                  fontFamily: YitteFonts.ui,
                  fontFamilyFallback: YitteFonts.fallback,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              ),
              child: const Text('Rejoindre le débat →'),
            ),
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
        Icon(icon, size: 15, color: YitteColors.gold),
        const SizedBox(width: 5),
        Text(
          label,
          style: TextStyle(
            fontFamily: YitteFonts.ui,
            fontFamilyFallback: YitteFonts.fallback,
            color: YitteColors.ivory.withValues(alpha: 0.92),
            fontSize: 12,
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
        ? 'Invité : ${upcomingExtra!.guest.fullName} (${upcomingExtra!.guest.titleOrRole})'
        : 'Tous les samedis à 20h00 GMT • Salon spirituel communautaire';
    final eventTag = hasExtra ? 'EXTRA GROUPE' : 'ZIKR COLLECTIF';
    final ctaLabel = hasExtra ? 'Poser une question' : 'Rejoindre le salon';

    return YitteSurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (pinnedAnnouncement != null) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(Icons.campaign_outlined, size: 16, color: tokens.goldAccent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pinnedAnnouncement!.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  onPressed: () => onExportCalendar(
                    title: pinnedAnnouncement!.title,
                    description: pinnedAnnouncement!.body,
                    start: pinnedAnnouncement!.eventDate ??
                        DateTime.now().add(const Duration(days: 1)),
                    location: pinnedAnnouncement!.location,
                  ),
                  child: const Text('+ Agenda'),
                ),
              ],
            ),
            Divider(height: 20, thickness: 1, color: tokens.borderSubtle),
          ],
          Row(
            children: [
              Text(
                eventTag,
                style: TextStyle(
                  fontFamily: YitteFonts.ui,
                  fontFamilyFallback: YitteFonts.fallback,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: tokens.goldAccent,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '•  ${_formatFrenchDateTime(eventDate)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            eventTitle,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            eventMeta,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              ElevatedButton(
                onPressed: hasExtra ? onAskQuestion : onJoinZikr,
                child: Text(ctaLabel),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => onExportCalendar(
                  title: eventTitle,
                  description: eventMeta,
                  start: eventDate,
                  location: hasExtra ? upcomingExtra!.practicalInfo : 'En ligne (GMT)',
                ),
                icon: Icon(Icons.event_available_outlined, size: 16, color: primary),
                label: const Text('Agenda'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrganizedSpacesSection extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<String> onOpenRoute;

  const _OrganizedSpacesSection({
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.onOpenRoute,
  });

  static const _filters = [
    'Tous',
    'Spiritualité',
    'Savoir',
    'Arènes',
  ];

  static const _spaces = [
    (
      category: 'Spiritualité',
      icon: Icons.mosque_outlined,
      title: 'Yitté Zikr',
      subtitle: 'صَلَّى اللهُ عَلَى مُحَمَّدٍ & objectif libre',
      route: '/zikr',
      gold: false,
    ),
    (
      category: 'Spiritualité',
      icon: Icons.event_outlined,
      title: 'Extra Groupe',
      subtitle: 'Rencontres mensuelles, invités & Q&A',
      route: '/extra-groupe',
      gold: true,
    ),
    (
      category: 'Savoir',
      icon: Icons.translate_rounded,
      title: 'English Club',
      subtitle: 'Cours A1–C2, LanguageTool & Dico MIT',
      route: '/english-club',
      gold: false,
    ),
    (
      category: 'Savoir',
      icon: Icons.folder_copy_outlined,
      title: 'Bibliothèque Docs',
      subtitle: '5 domaines & synthèses documentaires',
      route: '/documents',
      gold: false,
    ),
    (
      category: 'Savoir',
      icon: Icons.work_outline_rounded,
      title: 'Yitté Professionnel',
      subtitle: 'Projets libres, CV & opportunités',
      route: '/professional',
      gold: false,
    ),
    (
      category: 'Spiritualité',
      icon: Icons.lock_outline_rounded,
      title: 'Développement Personnel',
      subtitle: 'Journal privé, habitudes & lectures',
      route: '/personal-growth',
      gold: true,
    ),
    (
      category: 'Arènes',
      icon: Icons.record_voice_over_outlined,
      title: 'Face-à-Face',
      subtitle: 'Débats vocaux & grille 100 pts',
      route: '/debates',
      gold: false,
    ),
    (
      category: 'Arènes',
      icon: Icons.emoji_events_outlined,
      title: 'Quiz Arena',
      subtitle: 'Matchs 1v1 & tournois 8/16/32',
      route: '/quiz-arena',
      gold: true,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.tokensOf(context);
    final primary = Theme.of(context).colorScheme.primary;
    final visible = selectedFilter == 'Tous'
        ? _spaces
        : _spaces.where((s) => s.category == selectedFilter).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _filters.map((f) {
              final active = f == selectedFilter;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(f),
                  selected: active,
                  showCheckmark: false,
                  selectedColor: YitteColors.emerald,
                  labelStyle: TextStyle(
                    fontFamily: YitteFonts.ui,
                    fontFamilyFallback: YitteFonts.fallback,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: active
                        ? YitteColors.ivory
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                  onSelected: (_) => onFilterChanged(f),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 10),
        YitteSurfaceCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (int i = 0; i < visible.length; i++) ...[
                InkWell(
                  onTap: () => onOpenRoute(visible[i].route),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: tokens.subtleFill,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: tokens.borderSubtle,
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            visible[i].icon,
                            size: 18,
                            color: visible[i].gold ? tokens.goldAccent : primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                visible[i].title,
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                visible[i].subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: tokens.goldAccent,
                        ),
                      ],
                    ),
                  ),
                ),
                if (i < visible.length - 1)
                  Divider(height: 1, thickness: 1, color: tokens.borderSubtle),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _HomeContributionEntry {
  final String category;
  final String title;
  final String excerpt;
  final String meta;
  final String route;

  const _HomeContributionEntry({
    required this.category,
    required this.title,
    required this.excerpt,
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
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.category,
                    style: TextStyle(
                      fontFamily: YitteFonts.ui,
                      fontFamilyFallback: YitteFonts.fallback,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: isGoldTag
                          ? tokens.goldAccent
                          : Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (item.excerpt.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      item.excerpt,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                  const SizedBox(height: 5),
                  Text(
                    item.meta,
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Padding(
              padding: const EdgeInsets.only(top: 18),
              child: Icon(
                Icons.arrow_forward_rounded,
                size: 16,
                color: tokens.goldAccent,
              ),
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
        ? 'Pensée éditoriale du cercle'
        : '${quote.author} — ${quote.sourceWork}';

    return Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: tokens.borderSubtle, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '« $body »',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                  fontWeight: FontWeight.w400,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  attribution,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: tokens.goldAccent,
                      ),
                ),
              ),
              IconButton(
                tooltip: 'Autre citation',
                visualDensity: VisualDensity.compact,
                onPressed: onNext,
                icon: const Icon(Icons.refresh_rounded, size: 17),
              ),
              IconButton(
                tooltip: 'Partager',
                visualDensity: VisualDensity.compact,
                onPressed: onShare,
                icon: const Icon(Icons.ios_share_outlined, size: 17),
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
