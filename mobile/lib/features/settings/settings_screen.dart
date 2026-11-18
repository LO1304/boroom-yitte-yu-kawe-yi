import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/state/app_providers.dart';
import '../../core/config/app_config.dart';
import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/editorial_widgets.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final profile = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres & Studio Design')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 960),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SectionHeader(title: 'Studio Thèmes & Modèles'),
              const SizedBox(height: 10),
              const DesignStudioSection(),
              const SizedBox(height: 22),
              const SectionHeader(title: 'Langue & Direction'),
              const SizedBox(height: 8),
              DropdownButtonFormField<AppLanguage>(
                initialValue: lang,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Langue de l’interface'),
                items: AppLanguage.values
                    .map((l) => DropdownMenuItem(value: l, child: Text(l.label)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    ref.read(languageProvider.notifier).setLanguage(v);
                  }
                },
              ),
              const SizedBox(height: 20),
          const SectionHeader(title: 'Identifiants Externes & Services Cloud'),
          const SizedBox(height: 8),
          ...AppConfig.externalCredentialsChecklist.map(
            (req) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: Icon(
                  req.configured
                      ? Icons.check_circle_rounded
                      : Icons.pending_actions_rounded,
                  color: req.configured ? YitteColors.success : YitteColors.warning,
                ),
                title: Text(req.name,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                subtitle: Text('${req.scope}\n${req.purpose}'),
                isThreeLine: true,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const SectionHeader(title: 'Parcours & Aperçu Écrans'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              OutlinedButton.icon(
                icon: const Icon(Icons.auto_awesome_outlined),
                label: const Text('Splash / Bienvenue'),
                onPressed: () => context.push('/splash'),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.slideshow_outlined),
                label: const Text('Écran de bienvenue'),
                onPressed: () => context.push('/onboarding'),
              ),
              OutlinedButton.icon(
                icon: const Icon(Icons.login_rounded),
                label: const Text('Connexion / Inscription'),
                onPressed: () => context.push('/auth'),
              ),
            ],
          ),
              if (profile != null) ...[
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  icon: const Icon(Icons.logout_rounded),
                  label: const Text('Se déconnecter'),
                  onPressed: () async {
                    await ref.read(authProvider.notifier).signOut();
                    if (context.mounted) context.go('/auth');
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
