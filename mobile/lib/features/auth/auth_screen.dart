import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/state/app_providers.dart';
import '../../core/config/app_config.dart';
import '../../core/services/backend_repository.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/editorial_widgets.dart';

enum _AuthFlowMode { fullName, login, recover }

class AuthScreen extends ConsumerStatefulWidget {
  const AuthScreen({super.key});

  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameQuickCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _usernameCtrl = TextEditingController();
  final _inviteCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();

  _AuthFlowMode _mode = _AuthFlowMode.fullName;
  bool _isRegisterSubmode = false;
  bool _loading = false;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    _fullNameQuickCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _displayNameCtrl.dispose();
    _nameCtrl.dispose();
    _usernameCtrl.dispose();
    _inviteCtrl.dispose();
    _newPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _notice = null;
    });
    try {
      if (_mode == _AuthFlowMode.recover) {
        await BackendRepository.instance.resetPassword(
          email: _emailCtrl.text,
          newPassword: _newPassCtrl.text,
        );
        if (mounted) {
          setState(() {
            _mode = _AuthFlowMode.login;
            _isRegisterSubmode = false;
            _notice = AppConfig.isSupabaseConfigured
                ? 'Un lien de récupération vient d’être envoyé sur votre email.'
                : 'Mot de passe mis à jour sur ce serveur local. Connectez-vous maintenant.';
          });
        }
        return;
      }

      if (_mode == _AuthFlowMode.fullName) {
        final whitelist = ref.read(ecosystemProvider).authorizedGroupMembers;
        await ref.read(authProvider.notifier).signInByFullName(
              fullName: _fullNameQuickCtrl.text,
              inviteCode: _inviteCtrl.text,
              extraAuthorizedNames: whitelist,
            );
      } else if (_isRegisterSubmode) {
        await ref.read(authProvider.notifier).register(
              email: _emailCtrl.text,
              password: _passwordCtrl.text,
              fullName: _nameCtrl.text,
              username: _usernameCtrl.text,
              inviteCode: _inviteCtrl.text,
            );
      } else {
        await ref.read(authProvider.notifier).signIn(
              _emailCtrl.text,
              _passwordCtrl.text,
              displayName: _displayNameCtrl.text,
            );
      }
      final signed = ref.read(authProvider);
      if (signed != null) {
        ref.read(ecosystemProvider.notifier).registerOrTouchMember(signed);
      }
      if (mounted) {
        GoRouter.maybeOf(context)?.go('/');
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCloud = AppConfig.isSupabaseConfigured;
    final eco = ref.watch(ecosystemProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accès Membre Privé'),
        actions: [
          IconButton(
            tooltip: 'Studio Thèmes & Modèles',
            icon: const Icon(Icons.palette_outlined),
            onPressed: () => showDesignStudioSheet(context),
          ),
        ],
      ),
      body: YitteAuroraBackdrop(
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: YitteIconBadge(
                        color: Theme.of(context).colorScheme.primary,
                        size: 56,
                        customIcon: const SanctuaryPrayerIcon(size: 28),
                      ),
                    ),
                  ),
                YitteReveal(
                  order: 0,
                  child: EditorialHeroBanner(
                    eyebrow: isCloud ? 'SUPABASE AUTH • RBAC' : 'ACCÈS GROUPE & STRUCTURE',
                    title: switch (_mode) {
                      _AuthFlowMode.fullName => 'Accès par Nom Complet',
                      _AuthFlowMode.login => _isRegisterSubmode
                          ? 'Créer un Compte Standard'
                          : 'Connexion Standard',
                      _AuthFlowMode.recover => 'Récupération de Mot de Passe',
                    },
                    subtitle: switch (_mode) {
                      _AuthFlowMode.fullName =>
                        'Réservé aux membres reconnus du groupe BOROOM YITTÉ YU KAWÉ YI.',
                      _AuthFlowMode.login => isCloud
                          ? 'Connexion par email et mot de passe pour les personnes extérieures au groupe.'
                          : 'Email + mot de passe ou création de compte (soumis à l’ouverture du cercle).',
                      _AuthFlowMode.recover =>
                        'Réinitialisez le mot de passe d’un compte email enregistré.',
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SegmentedButton<_AuthFlowMode>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment(
                      value: _AuthFlowMode.fullName,
                      label: Text('Nom complet', maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    ButtonSegment(
                      value: _AuthFlowMode.login,
                      label: Text('Standard', maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                    ButtonSegment(
                      value: _AuthFlowMode.recover,
                      label: Text('Récupération', maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
                  ],
                  selected: {_mode},
                  onSelectionChanged: (s) => setState(() {
                    _mode = s.first;
                    _error = null;
                    _notice = null;
                  }),
                ),
                const SizedBox(height: 18),
                YitteReveal(
                  order: 1,
                  child: YitteSurfaceCard(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          if (_mode == _AuthFlowMode.fullName) ...[
                            TextFormField(
                              controller: _fullNameQuickCtrl,
                              textCapitalization: TextCapitalization.words,
                              decoration: const InputDecoration(
                                labelText: 'Votre nom complet (Prénom & Nom) *',
                                hintText: 'Ex. Cheikh Moustapha Lo',
                                prefixIcon: Icon(Icons.badge_outlined),
                              ),
                              validator: (v) => (v == null || v.trim().length < 2)
                                  ? 'Saisissez votre nom complet (min. 2 caractères)'
                                  : null,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _inviteCtrl,
                              decoration: InputDecoration(
                                labelText: 'Code d’invitation (optionnel)',
                                prefixIcon: const Icon(Icons.vpn_key_outlined),
                                helperMaxLines: 2,
                                helperText: eco.generatedInvites.isNotEmpty
                                    ? 'Code actif : ${eco.generatedInvites.first}'
                                    : 'Laissez vide pour entrer directement comme membre.',
                              ),
                            ),
                      ] else ...[
                        if (_mode == _AuthFlowMode.login) ...[
                          Row(
                            children: [
                              Expanded(
                                child: ChoiceChip(
                                  label: const Text('Connexion Email'),
                                  selected: !_isRegisterSubmode,
                                  onSelected: (_) =>
                                      setState(() => _isRegisterSubmode = false),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ChoiceChip(
                                  label: const Text('Inscription complète'),
                                  selected: _isRegisterSubmode,
                                  onSelected: (_) =>
                                      setState(() => _isRegisterSubmode = true),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (_mode == _AuthFlowMode.login && _isRegisterSubmode) ...[
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Nom complet',
                              prefixIcon: Icon(Icons.person_outline_rounded),
                            ),
                            validator: (v) =>
                                (v == null || v.trim().length < 2) ? 'Nom requis' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _usernameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Nom d’utilisateur',
                              prefixIcon: Icon(Icons.alternate_email_rounded),
                            ),
                            validator: (v) => (v == null || v.trim().length < 3)
                                ? 'Min. 3 caractères'
                                : null,
                          ),
                          const SizedBox(height: 12),
                        ],
                        if (_mode == _AuthFlowMode.login && !_isRegisterSubmode) ...[
                          TextFormField(
                            controller: _displayNameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Votre prénom & nom (si 1ʳᵉ connexion)',
                              prefixIcon: Icon(Icons.badge_outlined),
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Adresse email',
                            prefixIcon: Icon(Icons.mail_outline_rounded),
                          ),
                          validator: (v) => (v == null || !v.contains('@'))
                              ? 'Email valide requis'
                              : null,
                        ),
                        const SizedBox(height: 12),
                        if (_mode != _AuthFlowMode.recover)
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Mot de passe',
                              prefixIcon: Icon(Icons.lock_outline_rounded),
                            ),
                            validator: (v) => (v == null || v.length < 6)
                                ? 'Minimum 6 caractères'
                                : null,
                          )
                        else
                          TextFormField(
                            controller: _newPassCtrl,
                            obscureText: true,
                            decoration: const InputDecoration(
                              labelText: 'Nouveau mot de passe',
                              prefixIcon: Icon(Icons.lock_reset_rounded),
                            ),
                            validator: (v) => (v == null || v.length < 6)
                                ? 'Minimum 6 caractères'
                                : null,
                          ),
                        if (_mode == _AuthFlowMode.login && _isRegisterSubmode) ...[
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _inviteCtrl,
                            decoration: InputDecoration(
                              labelText: 'Code d’invitation (fourni par un responsable)',
                              prefixIcon: const Icon(Icons.vpn_key_outlined),
                              helperText: eco.generatedInvites.isNotEmpty
                                  ? 'Code actif disponible sur cette instance : ${eco.generatedInvites.first}'
                                  : null,
                            ),
                          ),
                        ],
                      ],
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          style: const TextStyle(color: YitteColors.danger),
                        ),
                      ],
                      if (_notice != null) ...[
                        const SizedBox(height: 12),
                        YitteStatusPill(
                          icon: Icons.check_circle_outline_rounded,
                          label: _notice!,
                        ),
                      ],
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _submit,
                          child: _loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(switch (_mode) {
                                  _AuthFlowMode.fullName => 'Continuer vers la structure',
                                  _AuthFlowMode.login => _isRegisterSubmode
                                      ? 'Valider mon inscription'
                                      : 'Se connecter',
                                  _AuthFlowMode.recover => 'Réinitialiser le mot de passe',
                                }),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            YitteSurfaceCard(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.verified_user_outlined,
                      color: YitteColors.emerald),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isCloud
                          ? 'Validation de compte : après inscription, le responsable confirme votre rôle RBAC.'
                          : 'Validation de compte locale active : votre compte est validé sur votre instance locale dès l’inscription.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              children: [
                TextButton(
                  onPressed: () => context.push('/splash'),
                  child: const Text('Splash'),
                ),
                TextButton(
                  onPressed: () => context.push('/welcome'),
                  child: const Text('Bienvenue'),
                ),
                TextButton(
                  onPressed: () => context.push('/onboarding'),
                  child: const Text('Présentation'),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  ),
),
);
  }
}
