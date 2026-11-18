import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/editorial_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _page = 0;

  static const _slides = [
    (
      eyebrow: 'S’ÉLEVER INDIVIDUELLEMENT',
      title: 'Savoir, Spiritualité & Esprit Critique',
      body:
          'Développez votre rigueur intellectuelle, votre maîtrise de l’anglais et votre discipline personnelle dans un cadre exigeant et bienveillant.',
      icon: Icons.auto_awesome_rounded,
    ),
    (
      eyebrow: 'DÉBATTRE AVEC ÉQUITÉ',
      title: 'Yitté Face-à-Face & Quiz Arena',
      body:
          'Participez à des débats vocaux évalués sur une grille transparente de 100 points — centrée uniquement sur la qualité du raisonnement, jamais sur votre accent ou origine.',
      icon: Icons.record_voice_over_rounded,
    ),
    (
      eyebrow: 'GRANDIR COLLECTIVEMENT',
      title: 'Zikr, Réflexions & Avenir Professionnel',
      body:
          'Rejoignez les rassemblements spirituels (Samedi 20h00 GMT sans classement), partagez des synthèses vérifiées et préparez votre carrière avec nos coachs IA.',
      icon: Icons.mosque_rounded,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'BOROOM YITTÉ',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          letterSpacing: 1.2,
                        ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () => context.go('/auth'),
                    child: const Text('Passer'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: PageView.builder(
                  controller: _controller,
                  onPageChanged: (i) => setState(() => _page = i),
                  itemCount: _slides.length,
                  itemBuilder: (context, index) {
                    final s = _slides[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        YitteReveal(
                          order: 0,
                          child: EditorialHeroBanner(
                            eyebrow: s.eyebrow,
                            title: s.title,
                            subtitle: s.body,
                            trailing: Icon(s.icon, color: YitteColors.goldBright, size: 32),
                          ),
                        ),
                        const SizedBox(height: 20),
                        YitteReveal(
                          order: 1,
                          child: YitteSurfaceCard(
                            child: Row(
                              children: [
                                Icon(
                                  Icons.verified_user_rounded,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                const Expanded(
                                  child: Text(
                                    'Valeurs fondamentales : Savoir • Spiritualité • Fraternité • Excellence • Discipline • Entraide',
                                    style: TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 220),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _page == i ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _page == i
                          ? YitteColors.emerald
                          : YitteColors.gold.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (_page < _slides.length - 1) {
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 280),
                        curve: Curves.easeOutCubic,
                      );
                    } else {
                      context.go('/auth');
                    }
                  },
                  child: Text(
                    _page < _slides.length - 1 ? 'Continuer' : 'Accéder à la communauté',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
