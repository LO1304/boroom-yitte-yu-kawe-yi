import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/state/app_providers.dart';
import '../../core/config/app_config.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/services/external_link_bridge.dart';
import '../../core/services/speech_bridge.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/editorial_widgets.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authProvider);
    final eco = ref.watch(ecosystemProvider);
    final lang = ref.watch(languageProvider);
    final strings = AppStrings(lang);
    final tokens = AppTheme.tokensOf(context);

    final nextZikr = eco.zikrSessions.first;
    final remaining = nextZikr.scheduledAt.difference(DateTime.now().toUtc());
    final days = remaining.inDays.clamp(0, 30);
    final hours = (remaining.inHours % 24).clamp(0, 23);
    final unreadNotifs = eco.notifications.where((n) => !n.isRead).length;
    final nextExtra = eco.extraGroupeMeetings
        .where((m) => m.status != 'archived')
        .toList();

    final themeMode = ref.watch(themeModeProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final salawatRatio = eco.salawatMonthlyTarget > 0
        ? (eco.salawatMonthlyCount / eco.salawatMonthlyTarget).clamp(0.0, 1.0)
        : 0.0;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text('BOROOM YITTÉ YU KAWÉ YI'),
        ),
        actions: [
          IconButton(
            tooltip: isDark ? 'Mode Clair' : 'Mode Sombre',
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
            onPressed: () {
              final next = (themeMode == ThemeMode.dark ||
                      (themeMode == ThemeMode.system && isDark))
                  ? ThemeMode.light
                  : ThemeMode.dark;
              ref.read(themeModeProvider.notifier).setMode(next);
            },
          ),
          IconButton(
            tooltip: 'Studio Thèmes & Modèles',
            icon: Icon(
              Icons.palette_rounded,
              color: Theme.of(context).colorScheme.primary,
            ),
            onPressed: () => showDesignStudioSheet(context),
          ),
          Stack(
            alignment: Alignment.topRight,
            children: [
              IconButton(
                tooltip: 'Notifications',
                icon: const Icon(Icons.notifications_none_rounded),
                onPressed: () => context.push('/notifications'),
              ),
              if (unreadNotifs > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                    decoration: BoxDecoration(
                      color: YitteColors.danger,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      '$unreadNotifs',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            tooltip: 'Administration',
            icon: const Icon(Icons.admin_panel_settings_outlined),
            onPressed: () => context.push('/admin'),
          ),
          IconButton(
            tooltip: 'Paramètres',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          YitteReveal(
            order: 0,
            child: EditorialHeroBanner(
              eyebrow: AppConfig.isSupabaseConfigured
                  ? strings.t('cloud_badge')
                  : 'CERCLE PRIVÉ • BOROOM YITTÉ',
              title:
                  '${strings.t('home_welcome')}, ${profile?.fullName ?? "Boroom Yitté"}',
              subtitle: strings.t('tagline'),
              trailing: YitteStatusPill(
                label: profile?.role.labelFr ?? 'Membre',
                backgroundColor: tokens.visualModel == UiVisualModel.editorialMinimal
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Colors.white.withValues(alpha: 0.16),
                foregroundColor: tokens.visualModel == UiVisualModel.editorialMinimal
                    ? Theme.of(context).colorScheme.primary
                    : Colors.white,
              ),
              actions: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: tokens.visualModel == UiVisualModel.editorialMinimal
                        ? Theme.of(context).colorScheme.primary
                        : YitteColors.goldBright,
                    foregroundColor: tokens.visualModel == UiVisualModel.editorialMinimal
                        ? Colors.white
                        : YitteColors.inkDark,
                  ),
                  onPressed: () => context.push('/debates'),
                  icon: const Icon(Icons.mic_rounded, size: 18),
                  label: Text(strings.t('face_a_face')),
                ),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: tokens.visualModel == UiVisualModel.editorialMinimal
                        ? Theme.of(context).colorScheme.primary
                        : Colors.white,
                    side: BorderSide(
                      color: tokens.visualModel == UiVisualModel.editorialMinimal
                          ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.4)
                          : Colors.white.withValues(alpha: 0.55),
                    ),
                  ),
                  onPressed: () => context.push('/extra-groupe'),
                  icon: const Icon(Icons.record_voice_over_outlined, size: 18),
                  label: const Text('Extra Groupe'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          YitteReveal(
            order: 1,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: 6,
                    child: YitteSurfaceCard(
                      padding: const EdgeInsets.all(14),
                      onTap: () => context.push('/zikr'),
                      child: Row(
                        children: [
                          YitteProgressRing(
                            progress: salawatRatio,
                            size: 66,
                            strokeWidth: 7,
                            color: YitteDomainAccents.spirituality,
                            child: const SanctuaryPrayerIcon(
                              size: 24,
                              color: YitteDomainAccents.spirituality,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Ṣalawāt',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${eco.salawatMonthlyCount} / ${eco.salawatMonthlyTarget}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13.5,
                                    color: YitteDomainAccents.spirituality,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                InkWell(
                                  borderRadius: BorderRadius.circular(99),
                                  onTap: () => ref
                                      .read(ecosystemProvider.notifier)
                                      .incrementSalawat(step: 33),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: YitteDomainAccents.spirituality
                                          .withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                    child: const Text(
                                      '+33 rapide',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w800,
                                        color: YitteDomainAccents.spirituality,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 5,
                    child: Column(
                      children: [
                        Expanded(
                          child: _DailyPulseChip(
                            icon: Icons.emoji_events_rounded,
                            color: YitteDomainAccents.challenges,
                            label: 'Challenges',
                            value:
                                '${eco.challenges.where((c) => c.userSubmission != null).length}/${eco.challenges.length} relevés',
                            onTap: () => context.go('/challenges'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: _DailyPulseChip(
                            icon: Icons.translate_rounded,
                            color: YitteDomainAccents.english,
                            label: 'English A1–C2',
                            value:
                                '${eco.dailyVocab.where((w) => w.mastered).length}/${eco.dailyVocab.length} mots',
                            onTap: () => context.push('/english-club'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (profile == null) ...[
            YitteReveal(
              order: 1,
              child: YitteSurfaceCard(
                color: tokens.goldSurface,
                borderColor: tokens.borderAccent,
                onTap: () => context.push('/auth'),
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: YitteColors.emeraldSoft,
                      child: Icon(Icons.badge_outlined, color: YitteColors.emerald),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Membres du Groupe : Nom Complet',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Connectez-vous avec votre nom complet pour publier et accéder aux espaces réservés du groupe.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: () => context.push('/auth'),
                      child: const Text('Connexion'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          // Pensée du jour (strictement si contenu validé disponible - Partie VI Section 9)
          if (eco.validatedDailyThought != null) ...[
            YitteReveal(
              order: 1,
              child: YitteSurfaceCard(
                color: tokens.goldSurface,
                borderColor: tokens.borderAccent,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const YitteStatusPill(
                      icon: Icons.lightbulb_outline_rounded,
                      label: 'Pensée du Jour Validée',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      eco.validatedDailyThought!,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (eco.announcements.isNotEmpty) ...[
            const SectionHeader(title: 'Annonces de la Communauté'),
            const SizedBox(height: 8),
            ...eco.announcements.take(3).map(
                  (a) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: YitteSurfaceCard(
                      color: tokens.goldSurface,
                      borderColor: tokens.borderAccent,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.campaign_rounded, color: tokens.goldAccent),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(a.title,
                                    style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 3),
                                Text('${a.body}\nPar ${a.authorName}',
                                    style: Theme.of(context).textTheme.bodyMedium),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            const SizedBox(height: 10),
          ],
          SectionHeader(
            title: strings.t('quick_modules'),
            actionLabel: 'Thèmes & Modèles',
            onAction: () => showDesignStudioSheet(context),
          ),
          const SizedBox(height: 10),
          YitteReveal(
            order: 2,
            child: GridView.count(
              crossAxisCount: MediaQuery.of(context).size.width >= 900
                  ? 4
                  : (MediaQuery.of(context).size.width > 640 ? 3 : 2),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.08,
              children: [
                _SanctuaryModuleTile(
                  icon: Icons.folder_copy_rounded,
                  accentColor: YitteDomainAccents.knowledge,
                  title: 'Bibliothèque Docs',
                  subtitle: '5 domaines & résumés vérifiés',
                  onTap: () => context.push('/documents'),
                ),
                _SanctuaryModuleTile(
                  icon: Icons.groups_2_rounded,
                  accentColor: YitteDomainAccents.community,
                  title: 'Extra Groupe',
                  subtitle: 'Rencontres mensuelles & Q&A',
                  onTap: () => context.push('/extra-groupe'),
                ),
                _SanctuaryModuleTile(
                  icon: Icons.record_voice_over_rounded,
                  accentColor: YitteDomainAccents.debates,
                  title: 'Yitté Face-à-Face',
                  subtitle: 'Débats vocaux & Grille 100 pts',
                  onTap: () => context.push('/debates'),
                ),
                _SanctuaryModuleTile(
                  icon: Icons.emoji_events_rounded,
                  accentColor: YitteDomainAccents.challenges,
                  title: 'Yitté Quiz Arena',
                  subtitle: 'Tournois 8/16/32 & 1v1',
                  onTap: () => context.push('/quiz-arena'),
                ),
                _SanctuaryModuleTile(
                  icon: Icons.mosque_rounded,
                  accentColor: YitteDomainAccents.spirituality,
                  customIcon: const SanctuaryPrayerIcon(
                    size: 26,
                    color: Colors.white,
                  ),
                  title: 'Yitté Zikr',
                  subtitle: 'Salat, Rappel & Tasbih',
                  onTap: () => context.push('/zikr'),
                ),
                _SanctuaryModuleTile(
                  icon: Icons.translate_rounded,
                  accentColor: YitteDomainAccents.english,
                  title: 'English Club',
                  subtitle: 'Programme A1–C2 & Dico API',
                  onTap: () => context.push('/english-club'),
                ),
                _SanctuaryModuleTile(
                  icon: Icons.work_rounded,
                  accentColor: YitteDomainAccents.career,
                  title: 'Yitté Professionnel',
                  subtitle: 'Tous métiers, CV & Projets',
                  onTap: () => context.push('/professional'),
                ),
                _SanctuaryModuleTile(
                  icon: Icons.lock_person_rounded,
                  accentColor: YitteDomainAccents.growth,
                  title: 'Développement Personnel',
                  subtitle: 'Journal privé, Chrono & Lectures',
                  onTap: () => context.push('/personal-growth'),
                ),
              ],
            ),
          ),
          if (nextExtra.isNotEmpty) ...[
            const SizedBox(height: 20),
            SectionHeader(
              title: 'Prochaine Rencontre Extra Groupe',
              actionLabel: 'Ouvrir',
              onAction: () => context.push('/extra-groupe'),
            ),
            const SizedBox(height: 8),
            YitteSurfaceCard(
              borderColor: tokens.borderAccent,
              onTap: () => context.push('/extra-groupe'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  YitteStatusPill(
                    icon: Icons.record_voice_over_rounded,
                    label: 'Invité : ${nextExtra.first.guest.fullName}',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    nextExtra.first.theme,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Préparez vos questions avant la session mensuelle.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 18),
          SectionHeader(
            title: 'Groupe WhatsApp de la Communauté',
            actionLabel: 'Pont & Exports',
            onAction: () => context.go('/community'),
          ),
          const SizedBox(height: 8),
          YitteSurfaceCard(
            onTap: () {
              if (eco.whatsappInviteUrl != null) {
                ExternalLinkBridge.openUrl(eco.whatsappInviteUrl!);
              } else {
                context.go('/community');
              }
            },
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: YitteColors.emeraldSoft,
                  child: Icon(Icons.chat_rounded, color: YitteColors.emerald),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(eco.whatsappGroupName,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(
                        eco.whatsappInviteUrl != null
                            ? 'Lien officiel actif — appuyez pour ouvrir WhatsApp ou partager la structure.'
                            : 'Configurez votre lien chat.whatsapp.com dans Admin/Communauté pour ouvrir le groupe en un clic.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    if (eco.whatsappInviteUrl != null) {
                      ExternalLinkBridge.openUrl(eco.whatsappInviteUrl!);
                    } else {
                      context.go('/community');
                    }
                  },
                  child: Text(eco.whatsappInviteUrl != null ? 'Ouvrir' : 'Lier'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SectionHeader(
            title: 'Prochain Rassemblement Zikr',
            actionLabel: 'Rejoindre',
            onAction: () => context.push('/zikr'),
          ),
          const SizedBox(height: 8),
          YitteSurfaceCard(
            onTap: () => context.push('/zikr'),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: YitteColors.emeraldSoft,
                  child: Icon(Icons.mosque_rounded, color: YitteColors.emerald),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(nextZikr.title,
                          style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(
                        'Dans ${days}j ${hours}h • ${nextZikr.recurrenceLabel}\n${strings.t('zikr_no_rank_notice')}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SectionHeader(
            title: 'Sujet Hebdomadaire — Semaine ${eco.weeklyTopic.weekNumber}',
            actionLabel: 'Contribuer',
            onAction: () => context.go('/reflections'),
          ),
          const SizedBox(height: 8),
          YitteSurfaceCard(
            onTap: () => context.go('/reflections'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  eco.weeklyTopic.title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  eco.weeklyTopic.introduction,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 10),
                YitteStatusPill(
                  label:
                      '${eco.weeklyTopic.contributions.length} contribution(s) • Validation éditoriale',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SectionHeader(
            title: 'Défis en Cours & Activités Récentes',
            actionLabel: 'Voir défis',
            onAction: () => context.go('/challenges'),
          ),
          const SizedBox(height: 8),
          YitteSurfaceCard(
            onTap: () => context.go('/challenges'),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: YitteColors.goldSoft,
                  child: Icon(Icons.psychology_outlined, color: YitteColors.gold),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${eco.challenges.where((c) => c.userSubmission == null).length} défi(s) intellectuel(s) ouvert(s)',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        eco.reflections.isNotEmpty
                            ? 'Dernière réflexion : ${eco.reflections.first.title}'
                            : 'Publiez votre première réflexion ou relevez un défi.',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SectionHeader(
            title: 'Vocabulaire Anglais (${eco.dailyVocab.length} mots)',
            actionLabel: 'Tout explorer',
            onAction: () => context.push('/english-club'),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 124,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: eco.dailyVocab.length,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final w = eco.dailyVocab[i];
                return SizedBox(
                  width: 215,
                  child: YitteSurfaceCard(
                    padding: const EdgeInsets.all(12),
                    onTap: () => context.push('/english-club'),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                w.word,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              icon: const Icon(Icons.volume_up_rounded, size: 17),
                              onPressed: () => SpeechBridge.speak(w.word),
                            ),
                            const SizedBox(width: 4),
                            YitteStatusPill(label: w.cefrLevel),
                          ],
                        ),
                        Text(
                          w.phoneticUk,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          w.definitionFr,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11.5),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyPulseChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _DailyPulseChip({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return YitteSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      onTap: onTap,
      child: Row(
        children: [
          YitteIconBadge(
            icon: icon,
            color: color,
            size: 36,
            iconSize: 18,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SanctuaryModuleTile extends StatelessWidget {
  final IconData icon;
  final Color? accentColor;
  final Widget? customIcon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SanctuaryModuleTile({
    required this.icon,
    this.accentColor,
    this.customIcon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? Theme.of(context).colorScheme.primary;
    final tokens = AppTheme.tokensOf(context);
    final isMinimal = tokens.visualModel == UiVisualModel.editorialMinimal;
    return YitteSurfaceCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -12,
            child: IgnorePointer(
              child: Icon(
                icon,
                size: 62,
                color: accent.withValues(alpha: isMinimal ? 0.04 : 0.075),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  YitteIconBadge(
                    icon: icon,
                    customIcon: customIcon != null && isMinimal
                        ? SanctuaryPrayerIcon(size: 26, color: accent)
                        : customIcon,
                    color: accent,
                    size: 50,
                    iconSize: 25,
                  ),
                  const Spacer(),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.10),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_outward_rounded,
                      size: 15,
                      color: accent,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11.5),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
