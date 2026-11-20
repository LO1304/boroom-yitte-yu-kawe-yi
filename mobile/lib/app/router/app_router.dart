import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/editorial_widgets.dart';
import '../../features/admin/admin_dashboard_screen.dart';
import '../../features/auth/auth_screen.dart';
import '../../features/auth/onboarding_screen.dart';
import '../../features/auth/splash_screen.dart';
import '../../features/challenges/challenges_screen.dart';
import '../../features/community/community_screen.dart';
import '../../features/debates/debates_screen.dart';
import '../../features/documents/documents_library_screen.dart';
import '../../features/english_club/english_club_screen.dart';
import '../../features/extra_groupe/extra_groupe_screen.dart';
import '../../features/home/home_dashboard_screen.dart';
import '../../features/learning/learning_hub_screen.dart';
import '../../features/notifications/notifications_screen.dart';
import '../../features/personal_growth/personal_growth_screen.dart';
import '../../features/professional/professional_screen.dart';
import '../../features/quiz_arena/quiz_arena_screen.dart';
import '../../features/reflections/reflections_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/zikr/zikr_screen.dart';
import '../state/app_providers.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final path = state.uri.path;
      const prefix = '/boroom-yitte-yu-kawe-yi';
      if (path == prefix || path == '$prefix/') {
        return '/';
      }
      if (path.startsWith('$prefix/')) {
        final stripped = path.substring(prefix.length);
        return stripped.isEmpty ? '/' : stripped;
      }
      return null;
    },
    errorBuilder: (context, state) => const HomeDashboardScreen(),
    routes: [
      GoRoute(
        path: '/splash',
        pageBuilder: (context, state) => yitteTransitionPage(
          key: state.pageKey,
          child: const SplashScreen(),
        ),
      ),
      GoRoute(
        path: '/welcome',
        pageBuilder: (context, state) => yitteTransitionPage(
          key: state.pageKey,
          child: const WelcomeScreen(),
        ),
      ),
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => yitteTransitionPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
        ),
      ),
      GoRoute(
        path: '/auth',
        pageBuilder: (context, state) => yitteTransitionPage(
          key: state.pageKey,
          child: const AuthScreen(),
        ),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return _MainScaffoldShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => const HomeDashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/reflections',
                builder: (_, _) => const ReflectionsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/challenges',
                builder: (_, _) => const ChallengesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/learning',
                builder: (_, _) => const LearningHubScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/community',
                builder: (_, _) => const CommunityScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/documents',
        pageBuilder: (context, state) => yitteTransitionPage(
          key: state.pageKey,
          child: const DocumentsLibraryScreen(),
        ),
      ),
      GoRoute(
        path: '/extra-groupe',
        pageBuilder: (context, state) => yitteTransitionPage(
          key: state.pageKey,
          child: const ExtraGroupeScreen(),
        ),
      ),
      GoRoute(
        path: '/notifications',
        pageBuilder: (context, state) => yitteTransitionPage(
          key: state.pageKey,
          child: const NotificationsScreen(),
        ),
      ),
      GoRoute(
        path: '/debates',
        pageBuilder: (context, state) => yitteTransitionPage(
          key: state.pageKey,
          child: const DebatesScreen(),
        ),
      ),
      GoRoute(
        path: '/quiz-arena',
        pageBuilder: (context, state) => yitteTransitionPage(
          key: state.pageKey,
          child: const QuizArenaScreen(),
        ),
      ),
      GoRoute(
        path: '/zikr',
        pageBuilder: (context, state) => yitteTransitionPage(
          key: state.pageKey,
          child: const ZikrScreen(),
        ),
      ),
      GoRoute(
        path: '/english-club',
        pageBuilder: (context, state) => yitteTransitionPage(
          key: state.pageKey,
          child: const EnglishClubScreen(),
        ),
      ),
      GoRoute(
        path: '/professional',
        pageBuilder: (context, state) => yitteTransitionPage(
          key: state.pageKey,
          child: const ProfessionalScreen(),
        ),
      ),
      GoRoute(
        path: '/personal-growth',
        pageBuilder: (context, state) => yitteTransitionPage(
          key: state.pageKey,
          child: const PersonalGrowthScreen(),
        ),
      ),
      GoRoute(
        path: '/admin',
        pageBuilder: (context, state) => yitteTransitionPage(
          key: state.pageKey,
          child: const AdminDashboardScreen(),
        ),
      ),
      GoRoute(
        path: '/settings',
        pageBuilder: (context, state) => yitteTransitionPage(
          key: state.pageKey,
          child: const SettingsScreen(),
        ),
      ),
    ],
  );
});

class _MainScaffoldShell extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;

  const _MainScaffoldShell({required this.navigationShell});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(languageProvider);
    final s = AppStrings(lang);
    final tokens = AppTheme.tokensOf(context);
    final profile = ref.watch(authProvider);
    final eco = ref.watch(ecosystemProvider);

    if (profile != null &&
        !profile.isGroupMember &&
        !profile.role.isAdminOrAbove &&
        eco.restrictAppToGroupOnly) {
      return Scaffold(
        appBar: AppBar(title: const Text('BOROOM YITTÉ YU KAWÉ YI')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: YitteSurfaceCard(
              borderColor: tokens.borderAccent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.lock_person_rounded,
                      size: 42, color: YitteColors.emerald),
                  const SizedBox(height: 12),
                  Text(
                    'Accès Réservé aux Membres du Groupe',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Compte standard enregistré (${profile.fullName}). Pour le moment, l’utilisation de cette plateforme est exclusivement réservée aux membres du groupe BOROOM YITTÉ YU KAWÉ YI.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Changer de compte / Se déconnecter'),
                    onPressed: () async {
                      await ref.read(authProvider.notifier).signOut();
                      if (context.mounted) context.go('/auth');
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width >= 880;
    final floatingBar = tokens.visualModel.floatingNavBar;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);

    void onSelectNav(int index) {
      navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );
    }

    final navItems = [
      (icon: Icons.home_outlined, active: Icons.home_rounded, label: s.t('nav_home')),
      (icon: Icons.forum_outlined, active: Icons.forum_rounded, label: s.t('nav_reflections')),
      (icon: Icons.psychology_outlined, active: Icons.psychology_rounded, label: s.t('nav_challenges')),
      (icon: Icons.school_outlined, active: Icons.school_rounded, label: s.t('nav_learning')),
      (icon: Icons.groups_outlined, active: Icons.groups_rounded, label: s.t('nav_community')),
    ];

    if (isDesktop) {
      final primary = Theme.of(context).colorScheme.primary;
      return Scaffold(
        body: YitteAuroraBackdrop(
          child: Column(
            children: [
              // Barre horizontale supérieure propre (fini la petite colonne étroite)
              Container(
                height: 58,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                decoration: BoxDecoration(
                  color: tokens.elevated,
                  border: Border(
                    bottom: BorderSide(color: tokens.borderSubtle, width: 1),
                  ),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: Row(
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SanctuaryPrayerIcon(size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'BOROOM YITTÉ',
                              style: TextStyle(
                                fontFamily: YitteFonts.display,
                                fontFamilyFallback: YitteFonts.fallback,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                                letterSpacing: 0.9,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: navItems.asMap().entries.map((entry) {
                              final i = entry.key;
                              final item = entry.value;
                              final selected = navigationShell.currentIndex == i;
                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 3),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(8),
                                  onTap: () => onSelectNav(i),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 160),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 13,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: selected
                                          ? primary
                                          : Colors.transparent,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          selected ? item.active : item.icon,
                                          size: 17,
                                          color: selected
                                              ? Colors.white
                                              : Theme.of(context)
                                                  .textTheme
                                                  .bodyMedium
                                                  ?.color,
                                        ),
                                        const SizedBox(width: 7),
                                        Text(
                                          item.label,
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: selected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: selected
                                                ? Colors.white
                                                : Theme.of(context)
                                                    .colorScheme
                                                    .onSurface,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        IconButton(
                          tooltip: isDark ? 'Mode Clair' : 'Mode Sombre',
                          onPressed: () {
                            final next = (themeMode == ThemeMode.dark ||
                                    (themeMode == ThemeMode.system && isDark))
                                ? ThemeMode.light
                                : ThemeMode.dark;
                            ref.read(themeModeProvider.notifier).setMode(next);
                          },
                          icon: Icon(
                            isDark
                                ? Icons.light_mode_outlined
                                : Icons.dark_mode_outlined,
                            size: 19,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Thèmes & Modèles',
                          onPressed: () => showDesignStudioSheet(context),
                          icon: const Icon(Icons.tune_outlined, size: 19),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1080),
                    child: navigationShell,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      extendBody: false,
      body: YitteAuroraBackdrop(child: navigationShell),
      bottomNavigationBar: _YitteCustomBottomDock(
        floating: floatingBar,
        selectedIndex: navigationShell.currentIndex,
        items: navItems,
        onSelected: onSelectNav,
      ),
    );
  }
}

class _YitteCustomBottomDock extends StatelessWidget {
  final bool floating;
  final int selectedIndex;
  final List<({IconData icon, IconData active, String label})> items;
  final ValueChanged<int> onSelected;

  const _YitteCustomBottomDock({
    required this.floating,
    required this.selectedIndex,
    required this.items,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.tokensOf(context);
    final primary = Theme.of(context).colorScheme.primary;
    final muted = Theme.of(context).textTheme.bodyMedium?.color ?? YitteColors.inkMuted;

    final dockContent = Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: tokens.elevated,
        border: Border(top: BorderSide(color: tokens.borderSubtle, width: 1)),
      ),
      child: Row(
        children: items.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final selected = i == selectedIndex;
          return Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => onSelected(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: selected ? tokens.subtleFill : Colors.transparent,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      selected ? item.active : item.icon,
                      size: 21,
                      color: selected ? primary : muted,
                    ),
                    const SizedBox(height: 3),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          item.label,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                            color: selected ? primary : muted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );

    return SafeArea(top: false, child: dockContent);
  }
}
