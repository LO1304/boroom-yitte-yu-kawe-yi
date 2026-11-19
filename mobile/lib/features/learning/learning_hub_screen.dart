import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/editorial_widgets.dart';

class LearningHubScreen extends StatelessWidget {
  const LearningHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(title: const Text('Apprentissage & Évolution')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
        children: [
          const YitteReveal(
            order: 0,
            child: EditorialHeroBanner(
              eyebrow: 'DÉVELOPPEMENT CONTINU',
              accentColor: YitteDomainAccents.english,
              title: 'Anglais, Carrière & Discipline',
              subtitle:
                  'Bibliothèque documentaire, programme d’anglais structuré A1–C2, tous métiers professionnels et journal personnel confidentiel.',
            ),
          ),
          const SizedBox(height: 16),
          YitteReveal(
            order: 1,
            child: _PillarTile(
              icon: Icons.folder_copy_outlined,
              color: YitteDomainAccents.knowledge,
              title: 'Bibliothèque Documentaire (5 Domaines)',
              subtitle:
                  'Import réel PDF/DOCX/PPTX/TXT, recherche avancée, consultation et résumés fidèles vérifiés.',
              onTap: () => context.push('/documents'),
            ),
          ),
          const SizedBox(height: 12),
          _PillarTile(
            icon: Icons.translate_rounded,
            color: YitteDomainAccents.english,
            title: 'Yitté English Club (A1 → C2)',
            subtitle:
                'Programme complet par paliers, dictionnaire open-source MIT avec audio UK/US, verbes irréguliers et coach oral IA.',
            onTap: () => context.push('/english-club'),
          ),
          const SizedBox(height: 12),
          _PillarTile(
            icon: Icons.work_outline_rounded,
            color: YitteDomainAccents.career,
            title: 'Yitté Professionnel & Carrière',
            subtitle:
                'Agronomie, physique, électronique, informatique, médecine, mathématiques, CV, entretien vocal IA et projets libres.',
            onTap: () => context.push('/professional'),
          ),
          const SizedBox(height: 12),
          _PillarTile(
            icon: Icons.lock_person_rounded,
            color: YitteDomainAccents.growth,
            title: 'Yitté Développement Personnel (Privé)',
            subtitle:
                'Journal confidentiel, objectifs hebdomadaires, suivi d’habitudes, lectures, gestion du temps et mentor IA socratique.',
            onTap: () => context.push('/personal-growth'),
          ),
          const SizedBox(height: 12),
          _PillarTile(
            icon: Icons.mosque_outlined,
            customIcon: const SanctuaryPrayerIcon(size: 24),
            color: YitteDomainAccents.spirituality,
            title: 'Yitté Zikr & Ressources Spirituelles',
            subtitle:
                'Choix libre du dhikr (صَلَّى اللهُ عَلَى مُحَمَّدٍ), objectif personnel et compteur Tasbīḥ.',
            onTap: () => context.push('/zikr'),
          ),
        ],
      ),
    );
  }
}

class _PillarTile extends StatelessWidget {
  final IconData icon;
  final Widget? customIcon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PillarTile({
    required this.icon,
    this.customIcon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.tokensOf(context);
    return YitteSurfaceCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          YitteIconBadge(
            icon: icon,
            customIcon: customIcon,
            color: color,
            size: 46,
            iconSize: 22,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 4),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right_rounded,
            size: 20,
            color: tokens.goldAccent,
          ),
        ],
      ),
    );
  }
}
