import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/editorial_widgets.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _scale = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduced = yitteMotionReduced(context);
    return Scaffold(
      backgroundColor: YitteColors.emeraldDeep,
      body: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: SanctuaryGeometryPainter(
                strokeColor: YitteColors.goldBright.withValues(alpha: 0.08),
                accentColor: Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: FadeTransition(
                  opacity: reduced ? const AlwaysStoppedAnimation(1) : _fade,
                  child: ScaleTransition(
                    scale: reduced ? const AlwaysStoppedAnimation(1) : _scale,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 84,
                          height: 84,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: YitteColors.emerald,
                            border: Border.all(
                              color: YitteColors.goldBright.withValues(alpha: 0.65),
                              width: 1.6,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: YitteColors.goldBright.withValues(alpha: 0.2),
                                blurRadius: 28,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.auto_stories_rounded,
                            color: YitteColors.goldBright,
                            size: 38,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'BOROOM YITTÉ YU KAWÉ YI',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                                color: Colors.white,
                                letterSpacing: 0.9,
                              ),
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "S'élever individuellement, grandir collectivement.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: YitteColors.goldSoft,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 36),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: YitteColors.goldBright,
                            foregroundColor: YitteColors.inkDark,
                          ),
                          onPressed: () => context.go('/welcome'),
                          icon: const Icon(Icons.arrow_forward_rounded),
                          label: const Text('Entrer dans l’espace'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.tokensOf(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Bienvenue')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const YitteReveal(
            order: 0,
            child: EditorialHeroBanner(
              eyebrow: 'COMMUNAUTÉ PRIVÉE & GRATUITE',
              title: 'Savoir, Spiritualité & Excellence Humaine',
              subtitle:
                  'Un environnement apaisé et exigeant dédié au développement spirituel, intellectuel, philosophique, social, personnel et professionnel.',
            ),
          ),
          const SizedBox(height: 18),
          YitteReveal(
            order: 1,
            child: YitteSurfaceCard(
              borderColor: tokens.borderAccent,
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Nos engagements fondateurs',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5),
                  ),
                  SizedBox(height: 10),
                  Text('• Accès privé sur invitation ou validation administrative.'),
                  SizedBox(height: 5),
                  Text('• Aucune invention ni citation non sourcée.'),
                  SizedBox(height: 5),
                  Text('• Zikr apaisé sans classement de piété ni score spirituel.'),
                  SizedBox(height: 5),
                  Text('• Multilingue natif : Français, Anglais, Arabe (RTL) et Wolof.'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.login_rounded),
              label: const Text('Se connecter / Activer une invitation'),
              onPressed: () => context.go('/auth'),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => context.push('/onboarding'),
              child: const Text('Découvrir la présentation complète'),
            ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () => context.go('/'),
            child: const Text('Accéder au tableau de bord'),
          ),
        ],
      ),
    );
  }
}
