import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/state/app_providers.dart';
import '../../core/models/domain_models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/editorial_widgets.dart';

class _ZikrFormula {
  final String id;
  final String arabic;
  final String transliteration;
  final String french;
  final int defaultTarget;

  const _ZikrFormula({
    required this.id,
    required this.arabic,
    required this.transliteration,
    required this.french,
    this.defaultTarget = 33,
  });
}

class ZikrScreen extends ConsumerStatefulWidget {
  const ZikrScreen({super.key});

  @override
  ConsumerState<ZikrScreen> createState() => _ZikrScreenState();
}

class _ZikrScreenState extends ConsumerState<ZikrScreen> {
  // 0: Chapelet (libre), 1: Communauté (sessions SDM), 2: Créer Session, 3: Historique
  int _tabIndex = 0;
  String? _activeSessionId;
  int _pendingBatch = 0;

  // Chapelet personnel
  int _target = 33;
  int _selectedIndex = 0;
  final List<_ZikrFormula> _customFormulas = [];

  // Formulaire Créer Session Communautaire (inspiré de SDM zikr_communaute_create.html)
  final _sessionTitleCtrl = TextEditingController();
  final _customFormulaCtrl = TextEditingController();
  final _sessionGoalCtrl = TextEditingController(text: '1000');
  bool _createUseCustomFormula = false;
  int _createPresetFormulaIdx = 0;
  bool _createIsPrivate = false;

  static const List<_ZikrFormula> _defaultFormulas = [
    _ZikrFormula(
      id: 'salat-nabi',
      arabic: 'صَلَّى اللهُ عَلَى مُحَمَّدٍ',
      transliteration: 'Ṣallallāhu ʿalā Muḥammad',
      french: 'Que la paix et la bénédiction d’Allah soient sur Muḥammad (ﷺ).',
      defaultTarget: 100,
    ),
    _ZikrFormula(
      id: 'subhanallah-azim',
      arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، سُبْحَانَ اللَّهِ الْعَظِيمِ',
      transliteration: 'Subḥānallāhi wa biḥamdihi, Subḥānallāhi l-ʿAẓīm',
      french: 'Gloire et louange à Allah, Gloire à Allah l’Immense.',
      defaultTarget: 100,
    ),
    _ZikrFormula(
      id: 'istighfar',
      arabic: 'أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ',
      transliteration: 'Astaghfirullāha l-ʿAẓīm',
      french: 'Je demande pardon à Allah, l’Immense.',
      defaultTarget: 100,
    ),
    _ZikrFormula(
      id: 'tahlil',
      arabic: 'لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ',
      transliteration: 'Lā ilāha illallāhu waḥdahu lā sharīka lah',
      french: 'Nulle divinité digne d’adoration sauf Allah, Unique, sans associé.',
      defaultTarget: 100,
    ),
    _ZikrFormula(
      id: 'hawqala',
      arabic: 'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
      transliteration: 'Lā ḥawla wa lā quwwata illā billāh',
      french: 'Il n’y a de force ni de puissance qu’en Allah.',
      defaultTarget: 33,
    ),
    _ZikrFormula(
      id: 'tasbih-short',
      arabic: 'سُبْحَانَ اللَّهِ • الْحَمْدُ لِلَّهِ • اللَّهُ أَكْبَرُ',
      transliteration: 'Subḥānallāh • Al-ḥamdu lillāh • Allāhu Akbar',
      french: 'Gloire à Allah, Louange à Allah, Allah est le Plus Grand.',
      defaultTarget: 33,
    ),
  ];

  List<_ZikrFormula> get _allFormulas => [..._defaultFormulas, ..._customFormulas];

  @override
  void dispose() {
    _sessionTitleCtrl.dispose();
    _customFormulaCtrl.dispose();
    _sessionGoalCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eco = ref.watch(ecosystemProvider);
    final profile = ref.watch(authProvider);
    final memberName = profile?.fullName ?? 'Membre Yitté';
    final tokens = AppTheme.tokensOf(context);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('YITTÉ ZIKR'),
      ),
      body: Column(
        children: [
          // BARRE D'ORGANISATION UNIFIÉE 4 ONGLETS (inspirée de SDM Zikr Communauté)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: tokens.elevated,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: tokens.borderSubtle, width: 1),
              ),
              child: Row(
                children: [
                  _ZikrTopTab(
                    icon: Icons.fingerprint_rounded,
                    label: 'Chapelet',
                    active: _tabIndex == 0,
                    onTap: () => setState(() {
                      _tabIndex = 0;
                      _activeSessionId = null;
                    }),
                  ),
                  _ZikrTopTab(
                    icon: Icons.groups_outlined,
                    label: 'Communauté',
                    active: _tabIndex == 1,
                    onTap: () => setState(() => _tabIndex = 1),
                  ),
                  _ZikrTopTab(
                    icon: Icons.add_circle_outline_rounded,
                    label: 'Créer',
                    active: _tabIndex == 2,
                    onTap: () => setState(() {
                      _tabIndex = 2;
                      _activeSessionId = null;
                    }),
                  ),
                  _ZikrTopTab(
                    icon: Icons.bar_chart_rounded,
                    label: 'Historique',
                    active: _tabIndex == 3,
                    onTap: () => setState(() {
                      _tabIndex = 3;
                      _activeSessionId = null;
                    }),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: switch (_tabIndex) {
              0 => _buildChapeletTab(context, eco),
              1 => _buildCommunityTab(context, eco, memberName),
              2 => _buildCreateSessionTab(context, memberName),
              _ => _buildHistoryTab(context, eco, memberName),
            },
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ONGLET 0 : CHAPELET LIBRE & OBJECTIF PERSONNEL
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildChapeletTab(BuildContext context, EcosystemState eco) {
    final tokens = AppTheme.tokensOf(context);
    final formulas = _allFormulas;
    final active = formulas[_selectedIndex.clamp(0, formulas.length - 1)];

    final ratio = eco.salawatMonthlyTarget > 0
        ? (eco.salawatMonthlyCount / eco.salawatMonthlyTarget).clamp(0.0, 1.0)
        : 0.0;
    final pct = (ratio * 100).toStringAsFixed(1);
    final dailyGoal = eco.salawatDurationDays > 0
        ? (eco.salawatMonthlyTarget / eco.salawatDurationDays).ceil()
        : eco.salawatMonthlyTarget;
    final remaining = (eco.salawatMonthlyTarget - eco.salawatMonthlyCount)
        .clamp(0, eco.salawatMonthlyTarget);

    final startDate =
        DateTime.tryParse(eco.salawatCycleStartIso) ?? DateTime.now();
    final elapsedDays = DateTime.now().difference(startDate).inDays;
    final remainingDays =
        (eco.salawatDurationDays - elapsedDays).clamp(1, eco.salawatDurationDays);
    final remainingDailyRate =
        remaining == 0 ? 0 : (remaining / remainingDays).ceil();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
      children: [
        // Encart sobre non-compétitif (compact)
        YitteSurfaceCard(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              const SanctuaryPrayerIcon(size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Aucune compétition, aucun classement ni badge de piété : choisissez librement votre Zikr et votre objectif.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Sélecteur horizontal des formules (avec صَلَّى اللهُ عَلَى مُحَمَّدٍ en premier + Zikr libre)
        Row(
          children: [
            Expanded(
              child: Text(
                'FORMULE DU ZIKR',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            TextButton.icon(
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              onPressed: () => _openAddCustomZikrDialog(context),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Zikr libre'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: formulas.asMap().entries.map((entry) {
              final idx = entry.key;
              final f = entry.value;
              final selected = idx == _selectedIndex;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  selected: selected,
                  showCheckmark: false,
                  selectedColor: YitteColors.emerald,
                  label: Text(
                    f.arabic,
                    textDirection: TextDirection.rtl,
                    style: AppTheme.arabicStyle(
                      color: selected
                          ? YitteColors.ivory
                          : Theme.of(context).colorScheme.onSurface,
                      fontSize: 15,
                    ),
                  ),
                  onSelected: (_) => setState(() {
                    _selectedIndex = idx;
                    _target = f.defaultTarget;
                  }),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        // Bloc Objectif Personnel (Libre)
        YitteSurfaceCard(
          borderColor: tokens.borderAccent,
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${eco.salawatCustomTitle} — ${eco.salawatMonthlyTarget} sur ${eco.salawatDurationDays} jour(s)',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  YitteStatusPill(label: '$pct%'),
                ],
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  active.arabic,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: AppTheme.arabicStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 25,
                  ),
                ),
              ),
              if (active.transliteration.isNotEmpty) ...[
                const SizedBox(height: 2),
                Center(
                  child: Text(
                    active.transliteration,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontStyle: FontStyle.italic,
                      fontSize: 12.5,
                      color: tokens.goldAccent,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              Text(
                'Progression du cycle (privée) : ${eco.salawatMonthlyCount} / ${eco.salawatMonthlyTarget}',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 8,
                  backgroundColor: tokens.subtleFill,
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(YitteColors.emerald),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Aujourd’hui : ${eco.salawatTodayCount} / $dailyGoal conseillés • Reste $remaining sur $remainingDays jour(s) (~$remainingDailyRate/j)',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      ref.read(ecosystemProvider.notifier).incrementSalawat(step: 1);
                    },
                    child: const Text('+1'),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      ref
                          .read(ecosystemProvider.notifier)
                          .incrementSalawat(step: 33);
                    },
                    child: const Text('+33'),
                  ),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () {
                      HapticFeedback.mediumImpact();
                      ref
                          .read(ecosystemProvider.notifier)
                          .incrementSalawat(step: 100);
                    },
                    child: const Text('+100'),
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: () => _openGoalConfigDialog(context, eco),
                    icon: const Icon(Icons.tune_outlined, size: 15),
                    label: const Text('Configurer objectif & durée'),
                  ),
                  TextButton(
                    onPressed: () => ref
                        .read(ecosystemProvider.notifier)
                        .resetSalawatCycle(),
                    child: Text('Nouveau cycle (${eco.salawatDurationDays}j)'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Compteur Chapelet Tactile
        YitteSurfaceCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SegmentedButton<int>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: 33, label: Text('33')),
                  ButtonSegment(value: 99, label: Text('99')),
                  ButtonSegment(value: 100, label: Text('100')),
                  ButtonSegment(value: 334, label: Text('334')),
                ],
                selected: {_target},
                onSelectionChanged: (s) => setState(() => _target = s.first),
              ),
              const SizedBox(height: 16),
              YittePulseHalo(
                color: YitteColors.emerald,
                triggerKey: eco.personalTasbihCount,
                child: YitteProgressRing(
                  progress: _target > 0
                      ? ((eco.personalTasbihCount % _target == 0 &&
                                  eco.personalTasbihCount > 0)
                              ? 1.0
                              : (eco.personalTasbihCount % _target) / _target)
                      : 0.0,
                  size: 184,
                  strokeWidth: 7,
                  color: tokens.goldAccent,
                  trackColor: tokens.borderSubtle,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      ref.read(ecosystemProvider.notifier).incrementTasbih();
                      ref
                          .read(ecosystemProvider.notifier)
                          .incrementSalawat(step: 1);
                    },
                    child: Container(
                      width: 152,
                      height: 152,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: YitteColors.emerald,
                        border: Border.all(
                          color: tokens.goldAccent,
                          width: 1.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SanctuaryPrayerIcon(
                            size: 24,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${eco.personalTasbihCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          Text(
                            '/ $_target',
                            style: TextStyle(
                              color: tokens.goldAccent,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 10,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => ref
                        .read(ecosystemProvider.notifier)
                        .resetTasbihAndLogSession(),
                    icon: const Icon(Icons.refresh_rounded, size: 17),
                    label: const Text('Clôturer & réinitialiser'),
                  ),
                  YitteStatusPill(
                    icon: Icons.check_circle_outline_rounded,
                    label:
                        'Sessions personnelles : ${eco.personalZikrSessionsCount}',
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ONGLET 1 : COMMUNAUTÉ (Inspiré de SDM zikr_communaute_list + detail)
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildCommunityTab(
    BuildContext context,
    EcosystemState eco,
    String memberName,
  ) {
    final sessions = eco.communityZikrSessions;
    final activeSession = _activeSessionId == null
        ? null
        : sessions.where((s) => s.id == _activeSessionId).firstOrNull;

    if (activeSession != null) {
      return _buildCommunitySessionDetail(context, activeSession, memberName);
    }

    final mySessions = sessions
        .where(
          (s) =>
              s.creatorName == memberName ||
              s.contributions.containsKey(memberName),
        )
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
      children: [
        // Bandeau d'action compact façon SDM Communauté
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: YitteColors.emerald,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: YitteColors.gold, width: 1),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'BÉNÉDICTION COLLECTIVE',
                      style: TextStyle(
                        color: YitteColors.gold,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    const Text(
                      'Zikr en Communauté',
                      style: TextStyle(
                        fontFamily: YitteFonts.display,
                        color: YitteColors.ivory,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Créez un Zikr & un objectif collectif ou rejoignez une session active.',
                      style: TextStyle(
                        color: YitteColors.ivory.withValues(alpha: 0.82),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: YitteColors.gold,
                  foregroundColor: YitteColors.inkDark,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                onPressed: () => setState(() => _tabIndex = 2),
                icon: const Icon(Icons.add_rounded, size: 17),
                label: const Text('Créer'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        if (mySessions.isNotEmpty) ...[
          SectionHeader(
            title: 'Vos Sessions & Participations (${mySessions.length})',
          ),
          const SizedBox(height: 8),
          _buildSessionsGrid(context, mySessions, memberName),
          const SizedBox(height: 16),
        ],

        SectionHeader(
          title: 'Sessions Actives de la Communauté (${sessions.length})',
          actionLabel: '+ Créer',
          onAction: () => setState(() => _tabIndex = 2),
        ),
        const SizedBox(height: 8),
        if (sessions.isEmpty)
          YitteEmptyState(
            icon: Icons.groups_outlined,
            title: 'Aucune session collective en cours',
            description:
                'Lancez la première session de Zikr communautaire et partagez l’objectif avec le cercle.',
            actionLabel: 'Créer une session',
            onAction: () => setState(() => _tabIndex = 2),
          )
        else
          _buildSessionsGrid(context, sessions, memberName),
      ],
    );
  }

  Widget _buildSessionsGrid(
    BuildContext context,
    List<CommunityZikrSessionModel> sessions,
    String memberName,
  ) {
    final tokens = AppTheme.tokensOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final twoCols = constraints.maxWidth >= 620;
        if (!twoCols) {
          return Column(
            children: sessions
                .map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildSessionCard(context, s, memberName, tokens),
                  ),
                )
                .toList(),
          );
        }
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: sessions.map((s) {
            return SizedBox(
              width: (constraints.maxWidth - 12) / 2,
              child: _buildSessionCard(context, s, memberName, tokens),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSessionCard(
    BuildContext context,
    CommunityZikrSessionModel s,
    String memberName,
    YitteSurfaceTokens tokens,
  ) {
    final pct = (s.progressRatio * 100).round();
    final isCreator =
        s.creatorName == memberName || s.creatorName == 'BOROOM YITTÉ';
    return YitteSurfaceCard(
      padding: const EdgeInsets.all(14),
      borderColor: s.isCompleted ? tokens.borderSubtle : tokens.borderAccent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  s.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const SizedBox(width: 6),
              YitteStatusPill(
                label: s.isCompleted ? 'Terminé' : 'Actif',
                backgroundColor: s.isCompleted
                    ? tokens.subtleFill
                    : YitteColors.emeraldSoft,
                foregroundColor: s.isCompleted
                    ? Theme.of(context).textTheme.bodySmall?.color
                    : YitteColors.emerald,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            s.formulaArabic.isNotEmpty ? s.formulaArabic : s.formulaLabel,
            textDirection: s.formulaArabic.isNotEmpty
                ? TextDirection.rtl
                : TextDirection.ltr,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTheme.arabicStyle(
              color: tokens.goldAccent,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: s.progressRatio,
              minHeight: 7,
              backgroundColor: tokens.subtleFill,
              valueColor: AlwaysStoppedAnimation<Color>(
                s.isCompleted ? tokens.goldAccent : YitteColors.emerald,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${s.currentCount} / ${s.targetCount} grains',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              Text(
                '$pct%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: tokens.goldAccent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(vertical: 9),
                  ),
                  onPressed: () => setState(() {
                    _activeSessionId = s.id;
                    _pendingBatch = 0;
                  }),
                  icon: const Icon(Icons.fingerprint_rounded, size: 16),
                  label: Text(
                    s.isCompleted ? 'Voir le rapport' : 'Rejoindre & Compter',
                  ),
                ),
              ),
              if (isCreator) ...[
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Supprimer la session',
                  onPressed: () => ref
                      .read(ecosystemProvider.notifier)
                      .deleteCommunityZikrSession(s.id),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 19,
                    color: YitteColors.danger,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // Vue détail session active inspirée de SDM zikr_communaute_detail.html
  Widget _buildCommunitySessionDetail(
    BuildContext context,
    CommunityZikrSessionModel s,
    String memberName,
  ) {
    final tokens = AppTheme.tokensOf(context);
    final mySaved = s.contributions[memberName] ?? 0;
    final displayedGlobal = (s.currentCount + _pendingBatch).clamp(0, s.targetCount);
    final displayedPersonal = mySaved + _pendingBatch;
    final ratio =
        s.targetCount <= 0 ? 0.0 : (displayedGlobal / s.targetCount).clamp(0.0, 1.0);
    final participants = s.contributions.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    void addCount(int step) {
      if (displayedGlobal >= s.targetCount) return;
      HapticFeedback.lightImpact();
      setState(() {
        final room = s.targetCount - (s.currentCount + _pendingBatch);
        _pendingBatch += step > room ? room : step;
      });
    }

    void saveBatch() {
      if (_pendingBatch <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Votre contribution est déjà à jour.')),
        );
        return;
      }
      final toCommit = _pendingBatch;
      ref.read(ecosystemProvider.notifier).contributeToCommunityZikrSession(
            sessionId: s.id,
            memberName: memberName,
            count: toCommit,
          );
      setState(() => _pendingBatch = 0);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('+$toCommit grains enregistrés dans « ${s.title} ».')),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
      children: [
        // En-tête Session (Retour + Inviter)
        Row(
          children: [
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
              onPressed: () {
                if (_pendingBatch > 0) saveBatch();
                setState(() => _activeSessionId = null);
              },
              icon: const Icon(Icons.arrow_back_rounded, size: 16),
              label: const Text('Sessions'),
            ),
            const Spacer(),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
              onPressed: () async {
                final text =
                    'Rejoignez la session Zikr « ${s.title} » (${s.formulaArabic}) — Objectif : ${s.targetCount} grains${s.isPrivate ? " • Code : ${s.shareCode}" : ""}\nBOROOM YITTÉ YU KAWÉ YI';
                final uri =
                    Uri.parse('https://wa.me/?text=${Uri.encodeComponent(text)}');
                final ok =
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                if (!ok) {
                  await Clipboard.setData(ClipboardData(text: text));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Invitation copiée.')),
                    );
                  }
                }
              },
              icon: const Icon(Icons.share_outlined, size: 16),
              label: const Text('Inviter'),
            ),
          ],
        ),
        const SizedBox(height: 10),

        // Carte Formule & Progression Globale (Vert Émeraude + Or 1px)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: YitteColors.emerald,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: YitteColors.gold, width: 1),
          ),
          child: Column(
            children: [
              Text(
                s.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: YitteFonts.display,
                  color: YitteColors.ivory,
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              if (s.formulaArabic.isNotEmpty)
                Text(
                  s.formulaArabic,
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.center,
                  style: AppTheme.arabicStyle(
                    color: YitteColors.gold,
                    fontSize: 26,
                  ),
                ),
              if (s.formulaLabel.isNotEmpty)
                Text(
                  s.formulaLabel,
                  style: TextStyle(
                    color: YitteColors.ivory.withValues(alpha: 0.85),
                    fontSize: 12.5,
                  ),
                ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PROGRESSION GLOBALE',
                    style: TextStyle(
                      color: YitteColors.ivory.withValues(alpha: 0.72),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.1,
                    ),
                  ),
                  Text(
                    'Objectif : ${s.targetCount}',
                    style: const TextStyle(
                      color: YitteColors.gold,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '$displayedGlobal',
                style: const TextStyle(
                  color: YitteColors.gold,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 8,
                  backgroundColor: Colors.white.withValues(alpha: 0.16),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(YitteColors.gold),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Zone de comptage tactile + lots (+10 / +33 / +100) + Enregistrer
        YitteSurfaceCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Votre contribution :',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  YitteStatusPill(label: '$displayedPersonal grains'),
                ],
              ),
              const SizedBox(height: 14),
              if (displayedGlobal >= s.targetCount)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: YitteColors.emeraldSoft,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: YitteColors.emerald),
                  ),
                  child: const Text(
                    'Al-ḥamdu lillāh ! Objectif collectif atteint. Qu’Allah accepte notre Zikr.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: YitteColors.emerald,
                    ),
                  ),
                )
              else ...[
                GestureDetector(
                  onTap: () => addCount(1),
                  child: Container(
                    width: 132,
                    height: 132,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: YitteColors.gold,
                      border: Border.all(color: YitteColors.emerald, width: 2),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.fingerprint_rounded,
                          size: 38,
                          color: YitteColors.inkDark,
                        ),
                        SizedBox(height: 4),
                        Text(
                          '+1 GRAIN',
                          style: TextStyle(
                            color: YitteColors.inkDark,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Ajout rapide (si récité sur votre chapelet) :',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => addCount(10),
                        child: const Text('+10'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => addCount(33),
                        child: const Text('+33'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => addCount(100),
                        child: const Text('+100'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: saveBatch,
                    icon: const Icon(Icons.save_outlined, size: 18),
                    label: Text(
                      _pendingBatch > 0
                          ? 'Enregistrer ma contribution (+$_pendingBatch)'
                          : 'Enregistrer ma contribution',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Participants de la session (liste fraternelle sobre avec Divider 1px)
        YitteSurfaceCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PARTICIPANTS (${participants.length})',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.2,
                      color: tokens.goldAccent,
                    ),
              ),
              const SizedBox(height: 8),
              if (participants.isEmpty)
                Text(
                  'Aucun grain enregistré pour l’instant. Commencez la session !',
                  style: Theme.of(context).textTheme.bodySmall,
                )
              else
                ...participants.asMap().entries.map((entry) {
                  final e = entry.value;
                  final isMe = e.key == memberName;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Text(
                                    e.key,
                                    style: Theme.of(context).textTheme.titleSmall,
                                  ),
                                  if (isMe) ...[
                                    const SizedBox(width: 6),
                                    const YitteStatusPill(label: 'VOUS'),
                                  ],
                                ],
                              ),
                            ),
                            Text(
                              '${e.value} grains',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: tokens.goldAccent,
                                fontFeatures: const [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (entry.key < participants.length - 1)
                        Divider(height: 1, color: tokens.borderSubtle),
                    ],
                  );
                }),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ONGLET 2 : CRÉER UNE SESSION COLLECTIVE (Inspiré de SDM zikr_communaute_create)
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildCreateSessionTab(BuildContext context, String memberName) {
    final tokens = AppTheme.tokensOf(context);
    final formulas = _allFormulas;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
      children: [
        YitteSurfaceCard(
          padding: const EdgeInsets.all(16),
          borderColor: tokens.borderAccent,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CRÉER UN ZIKR & OBJECTIF COLLECTIF',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.2,
                      color: tokens.goldAccent,
                    ),
              ),
              const SizedBox(height: 12),

              // 1. Titre
              Text(
                '1. Titre de la session *',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _sessionTitleCtrl,
                decoration: const InputDecoration(
                  hintText: 'Ex : Grand Zikr du Vendredi, Hadiya...',
                ),
              ),
              const SizedBox(height: 14),

              // 2. Formule du Zikr
              Text(
                '2. Formule du Zikr à réciter *',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Choisir dans la liste')),
                      selected: !_createUseCustomFormula,
                      showCheckmark: false,
                      selectedColor: YitteColors.emerald,
                      labelStyle: TextStyle(
                        color: !_createUseCustomFormula
                            ? YitteColors.ivory
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) =>
                          setState(() => _createUseCustomFormula = false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('Créer un Zikr libre')),
                      selected: _createUseCustomFormula,
                      showCheckmark: false,
                      selectedColor: YitteColors.emerald,
                      labelStyle: TextStyle(
                        color: _createUseCustomFormula
                            ? YitteColors.ivory
                            : Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                      onSelected: (_) =>
                          setState(() => _createUseCustomFormula = true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (!_createUseCustomFormula)
                DropdownButtonFormField<int>(
                  initialValue: _createPresetFormulaIdx.clamp(0, formulas.length - 1),
                  isExpanded: true,
                  items: formulas.asMap().entries.map((e) {
                    return DropdownMenuItem<int>(
                      value: e.key,
                      child: Text(
                        '${e.value.arabic} — ${e.value.transliteration}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (v) =>
                      setState(() => _createPresetFormulaIdx = v ?? 0),
                )
              else
                TextField(
                  controller: _customFormulaCtrl,
                  decoration: const InputDecoration(
                    hintText: 'Ex : صَلَّى اللهُ عَلَى مُحَمَّدٍ, Lā ilāha illallāh...',
                  ),
                ),
              const SizedBox(height: 14),

              // 3. Objectif à atteindre + Presets SDM (100, 313, 1 000, 10 000, 100 000)
              Text(
                '3. Objectif global à atteindre *',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _sessionGoalCtrl,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [100, 313, 1000, 10000, 100000].map((val) {
                  return OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    ),
                    onPressed: () =>
                        setState(() => _sessionGoalCtrl.text = '$val'),
                    child: Text('$val'),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _createIsPrivate,
                onChanged: (v) => setState(() => _createIsPrivate = v ?? false),
                title: const Text(
                  'Session privée (avec code d’invitation)',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                subtitle: const Text(
                  'Laissez décoché pour que tous les membres puissent participer librement.',
                  style: TextStyle(fontSize: 11.5),
                ),
              ),
              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: YitteColors.gold,
                    foregroundColor: YitteColors.inkDark,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    final title = _sessionTitleCtrl.text.trim();
                    final goal = int.tryParse(_sessionGoalCtrl.text.trim()) ?? 0;
                    if (title.isEmpty || goal <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Indiquez un titre et un objectif valide.',
                          ),
                        ),
                      );
                      return;
                    }
                    final preset = formulas[
                        _createPresetFormulaIdx.clamp(0, formulas.length - 1)];
                    final custom = _customFormulaCtrl.text.trim();
                    if (_createUseCustomFormula && custom.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Saisissez votre formule de Zikr.'),
                        ),
                      );
                      return;
                    }
                    final created = ref
                        .read(ecosystemProvider.notifier)
                        .createCommunityZikrSession(
                          title: title,
                          formulaArabic:
                              _createUseCustomFormula ? custom : preset.arabic,
                          formulaLabel: _createUseCustomFormula
                              ? custom
                              : preset.transliteration,
                          transliteration: _createUseCustomFormula
                              ? ''
                              : preset.transliteration,
                          targetCount: goal,
                          creatorName: memberName,
                          isPrivate: _createIsPrivate,
                        );
                    _sessionTitleCtrl.clear();
                    _customFormulaCtrl.clear();
                    setState(() {
                      _tabIndex = 1;
                      _activeSessionId = created.id;
                      _pendingBatch = 0;
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Session « ${created.title} » lancée !'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                  label: const Text('Enregistrer le Zikr & Lancer l’Objectif'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ONGLET 3 : HISTORIQUE & BILAN PERSONNEL
  // ═══════════════════════════════════════════════════════════════════════
  Widget _buildHistoryTab(
    BuildContext context,
    EcosystemState eco,
    String memberName,
  ) {
    final tokens = AppTheme.tokensOf(context);
    final totalComm = eco.communityZikrSessions.fold<int>(
      0,
      (sum, s) => sum + (s.contributions[memberName] ?? 0),
    );
    final completedComm =
        eco.communityZikrSessions.where((s) => s.isCompleted).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 40),
      children: [
        Row(
          children: [
            Expanded(
              child: YitteSurfaceCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CYCLE PERSONNEL',
                        style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 6),
                    Text(
                      '${eco.salawatMonthlyCount}',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: YitteColors.emerald,
                          ),
                    ),
                    Text(
                      'sur ${eco.salawatMonthlyTarget} grains',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: YitteSurfaceCard(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('PART COMMUNAUTÉ',
                        style: Theme.of(context).textTheme.labelSmall),
                    const SizedBox(height: 6),
                    Text(
                      '$totalComm',
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: tokens.goldAccent,
                          ),
                    ),
                    Text(
                      '${eco.personalZikrSessionsCount} chapelet(s) clôturés',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        SectionHeader(
          title: 'Sessions Collectives (${eco.communityZikrSessions.length})',
        ),
        const SizedBox(height: 8),
        YitteSurfaceCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (int i = 0; i < eco.communityZikrSessions.length; i++) ...[
                ListTile(
                  title: Text(eco.communityZikrSessions[i].title,
                      style: Theme.of(context).textTheme.titleSmall),
                  subtitle: Text(
                    '${eco.communityZikrSessions[i].currentCount} / ${eco.communityZikrSessions[i].targetCount} grains • Votre part : ${eco.communityZikrSessions[i].contributions[memberName] ?? 0}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  trailing: YitteStatusPill(
                    label: eco.communityZikrSessions[i].isCompleted
                        ? 'Atteint'
                        : 'En cours',
                  ),
                  onTap: () => setState(() {
                    _tabIndex = 1;
                    _activeSessionId = eco.communityZikrSessions[i].id;
                  }),
                ),
                if (i < eco.communityZikrSessions.length - 1)
                  Divider(height: 1, color: tokens.borderSubtle),
              ],
            ],
          ),
        ),
        if (completedComm.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            '${completedComm.length} objectif(s) collectif(s) déjà accomplis.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }

  Future<void> _openAddCustomZikrDialog(BuildContext context) async {
    final formulaCtrl = TextEditingController();
    final translitCtrl = TextEditingController();
    final targetCtrl = TextEditingController(text: '100');

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ajouter un Zikr libre'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: formulaCtrl,
                decoration: const InputDecoration(
                  labelText: 'Formule du Zikr (arabe ou français) *',
                  hintText: 'Ex : يَا لَطِيفُ ou Astaghfirullāh',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: translitCtrl,
                decoration: const InputDecoration(
                  labelText: 'Translittération / sens (optionnel)',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: targetCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Objectif de répétitions',
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
              final f = formulaCtrl.text.trim();
              if (f.isEmpty) return;
              final tgt = int.tryParse(targetCtrl.text.trim()) ?? 100;
              setState(() {
                _customFormulas.add(
                  _ZikrFormula(
                    id: 'custom-${DateTime.now().millisecondsSinceEpoch}',
                    arabic: f,
                    transliteration: translitCtrl.text.trim(),
                    french: '',
                    defaultTarget: tgt.clamp(1, 1000000),
                  ),
                );
                _selectedIndex = _allFormulas.length - 1;
                _target = tgt.clamp(1, 1000000);
              });
              Navigator.pop(ctx);
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  Future<void> _openGoalConfigDialog(
    BuildContext context,
    EcosystemState eco,
  ) async {
    final titleCtrl = TextEditingController(text: eco.salawatCustomTitle);
    final targetCtrl =
        TextEditingController(text: eco.salawatMonthlyTarget.toString());
    final daysCtrl =
        TextEditingController(text: eco.salawatDurationDays.toString());
    bool resetProgress = false;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Personnaliser mon objectif'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Intitulé libre du Zikr',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: targetCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Objectif total (répétitions)',
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: daysCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Durée souhaitée (en jours)',
                  ),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: resetProgress,
                  onChanged: (v) =>
                      setDialogState(() => resetProgress = v ?? false),
                  title: const Text(
                    'Repartir de 0 pour ce nouvel objectif',
                    style: TextStyle(fontSize: 13),
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
              onPressed: () async {
                final target = int.tryParse(targetCtrl.text.trim()) ??
                    eco.salawatMonthlyTarget;
                final days = int.tryParse(daysCtrl.text.trim()) ??
                    eco.salawatDurationDays;
                await ref.read(ecosystemProvider.notifier).updateSalawatGoal(
                      target: target,
                      durationDays: days,
                      title: titleCtrl.text.trim(),
                      resetProgress: resetProgress,
                    );
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Appliquer'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZikrTopTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _ZikrTopTab({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.tokensOf(context);
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: active ? YitteColors.emerald : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 17,
                color: active ? YitteColors.gold : tokens.goldAccent,
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                    color: active
                        ? YitteColors.ivory
                        : Theme.of(context).colorScheme.onSurface,
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
