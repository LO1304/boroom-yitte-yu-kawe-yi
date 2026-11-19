import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/state/app_providers.dart';
import '../../core/services/calendar_export_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/editorial_widgets.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eco = ref.watch(ecosystemProvider);
    final unread = eco.notifications.where((n) => !n.isRead).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications & Annonces'),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () =>
                  ref.read(ecosystemProvider.notifier).markAllNotificationsRead(),
              child: const Text('Tout marquer lu'),
            ),
        ],
      ),
      body: YitteAuroraBackdrop(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            YitteReveal(
              order: 0,
              child: EditorialHeroBanner(
                eyebrow: 'CENTRE D’INFORMATION • $unread NON LUE(S)',
                accentColor: YitteDomainAccents.challenges,
                title: 'Annonces & Alertes',
                subtitle:
                    'Toutes les annonces officielles de la communauté apparaissent ici et en premier plan sur l’Accueil, avec ajout en 1 clic à votre agenda.',
              ),
            ),
            const SizedBox(height: 16),
            if (eco.notifications.isEmpty)
              YitteReveal(
                order: 1,
                child: YitteEmptyState(
                  icon: Icons.notifications_none_rounded,
                  title: 'Aucune notification pour le moment',
                  description:
                      'Les annonces publiées depuis l’Accueil ou l’Administration apparaîtront ici avec un bouton d’ajout direct à votre calendrier.',
                  actionLabel: 'Voir Extra Groupe',
                  onAction: () => context.push('/extra-groupe'),
                ),
              )
            else
              ...eco.notifications.asMap().entries.map((entry) {
                final idx = entry.key;
                final n = entry.value;
                return YitteReveal(
                  order: idx + 1,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: YitteSurfaceCard(
                      onTap: () {
                        ref
                            .read(ecosystemProvider.notifier)
                            .markNotificationRead(n.id);
                        if (n.deepLink != null && n.deepLink!.isNotEmpty) {
                          context.push(n.deepLink!);
                        }
                      },
                      borderColor: n.isRead
                          ? null
                          : Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.45),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          YitteIconBadge(
                            icon: n.category == 'extra_groupe'
                                ? Icons.groups_2_rounded
                                : Icons.campaign_rounded,
                            color: n.isRead
                                ? YitteColors.inkMuted
                                : YitteDomainAccents.challenges,
                            size: 44,
                            iconSize: 22,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        n.title,
                                        style: Theme.of(context).textTheme.titleMedium,
                                      ),
                                    ),
                                    if (!n.isRead)
                                      const YitteStatusPill(label: 'Nouveau'),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(n.body,
                                    style: Theme.of(context).textTheme.bodyMedium),
                                if (n.eventDate != null || (n.location?.isNotEmpty ?? false)) ...[
                                  const SizedBox(height: 6),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      if (n.eventDate != null)
                                        YitteStatusPill(
                                          icon: Icons.event_rounded,
                                          label:
                                              '${n.eventDate!.day.toString().padLeft(2, '0')}/${n.eventDate!.month.toString().padLeft(2, '0')}/${n.eventDate!.year} • ${n.eventDate!.hour.toString().padLeft(2, '0')}h${n.eventDate!.minute.toString().padLeft(2, '0')}',
                                        ),
                                      if (n.location != null && n.location!.isNotEmpty)
                                        YitteStatusPill(
                                          icon: Icons.place_outlined,
                                          label: n.location!,
                                        ),
                                    ],
                                  ),
                                ],
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    OutlinedButton.icon(
                                      style: OutlinedButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      onPressed: () async {
                                        await CalendarExportService.addEventToCalendar(
                                          title: n.title,
                                          description: n.body,
                                          start: n.eventDate ?? n.createdAt.add(const Duration(days: 1)),
                                          location: n.location,
                                        );
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              content: Text('Événement agenda (.ics) téléchargé.'),
                                            ),
                                          );
                                        }
                                      },
                                      icon: const Icon(Icons.calendar_month_rounded, size: 16),
                                      label: const Text('Agenda (.ics)'),
                                    ),
                                    TextButton.icon(
                                      style: TextButton.styleFrom(
                                        visualDensity: VisualDensity.compact,
                                      ),
                                      onPressed: () =>
                                          CalendarExportService.addEventToCalendar(
                                        title: n.title,
                                        description: n.body,
                                        start: n.eventDate ?? n.createdAt.add(const Duration(days: 1)),
                                        location: n.location,
                                        preferGoogleCalendar: true,
                                      ),
                                      icon: const Icon(Icons.event_available_rounded, size: 16),
                                      label: const Text('Google Agenda'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
