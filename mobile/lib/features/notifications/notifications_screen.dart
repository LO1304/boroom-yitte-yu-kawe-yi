import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/state/app_providers.dart';
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
        title: const Text('Notifications & Alertes'),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: () =>
                  ref.read(ecosystemProvider.notifier).markAllNotificationsRead(),
              child: const Text('Tout marquer lu'),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          YitteReveal(
            order: 0,
            child: EditorialHeroBanner(
              eyebrow: 'CENTRE D’INFORMATION • $unread NON LUE(S)',
              title: 'Activités & Annonces',
              subtitle:
                  'Les notifications proviennent exclusivement des annonces réelles de la communauté, des rencontres Extra Groupe et des événements programmés.',
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
                    'Aucune alerte artificielle n’est générée. Les annonces diffusées par l’administration et les nouvelles rencontres Extra Groupe apparaîtront ici.',
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
                            .withValues(alpha: 0.4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CircleAvatar(
                          backgroundColor: n.isRead
                              ? YitteColors.stoneMuted
                              : YitteColors.emeraldSoft,
                          child: Icon(
                            n.category == 'extra_groupe'
                                ? Icons.groups_2_rounded
                                : Icons.campaign_rounded,
                            color: n.isRead
                                ? YitteColors.inkMuted
                                : YitteColors.emerald,
                          ),
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
    );
  }
}
