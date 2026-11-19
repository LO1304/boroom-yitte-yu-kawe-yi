import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/state/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/editorial_widgets.dart';

class _ZikrFormula {
  final String id;
  final String arabic;
  final String transliteration;
  final String translation;

  const _ZikrFormula({
    required this.id,
    required this.arabic,
    required this.transliteration,
    required this.translation,
  });
}

class ZikrScreen extends ConsumerStatefulWidget {
  const ZikrScreen({super.key});

  @override
  ConsumerState<ZikrScreen> createState() => _ZikrScreenState();
}

class _ZikrScreenState extends ConsumerState<ZikrScreen> {
  static const List<_ZikrFormula> _formulas = [
    _ZikrFormula(
      id: 'sallallahu',
      arabic: 'صَلَّى اللهُ عَلَى مُحَمَّدٍ',
      transliteration: 'Ṣallallāhu ʿalā Muḥammad',
      translation: 'Que la paix et la bénédiction d’Allah soient sur Muḥammad (ﷺ).',
    ),
    _ZikrFormula(
      id: 'subhanallah',
      arabic: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ، سُبْحَانَ اللَّهِ الْعَظِيمِ',
      transliteration: 'SubḥānAllāhi wa bi-ḥamdih, SubḥānAllāhi l-ʿAẓīm',
      translation: 'Gloire et louange à Allah, Gloire à Allah l’Immense.',
    ),
    _ZikrFormula(
      id: 'istighfar',
      arabic: 'أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ وَأَتُوبُ إِلَيْهِ',
      transliteration: 'Astaghfirullāha l-ʿAẓīm wa atūbu ilayh',
      translation: 'Je demande pardon à Allah l’Immense et je me repens à Lui.',
    ),
    _ZikrFormula(
      id: 'tahlil',
      arabic: 'لَا إِلَٰهَ إِلَّا اللَّهُ وَحْدَهُ لَا شَرِيكَ لَهُ',
      transliteration: 'Lā ilāha illAllāhu waḥdahu lā sharīka lah',
      translation: 'Nulle divinité n’est digne d’adoration sauf Allah, Seul, sans associé.',
    ),
    _ZikrFormula(
      id: 'baqiyat',
      arabic: 'سُبْحَانَ اللَّهِ، وَالْحَمْدُ لِلَّهِ، وَلَا إِلَٰهَ إِلَّا اللَّهُ، وَاللَّهُ أَكْبَرُ',
      transliteration: 'SubḥānAllāh, wal-ḥamdu lillāh, wa lā ilāha illAllāh, wallāhu akbar',
      translation: 'Gloire à Allah, louange à Allah, nulle divinité sauf Allah, Allah est le Plus Grand.',
    ),
    _ZikrFormula(
      id: 'hasbunallah',
      arabic: 'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ',
      transliteration: 'ḤasbunAllāhu wa niʿma l-wakīl',
      translation: 'Allah nous suffit, quel excellent Garant.',
    ),
  ];

  int _target = 33;
  String _selectedFormulaId = 'sallallahu';
  String? _customFreeZikr;

  _ZikrFormula get _activeFormula => _formulas.firstWhere(
        (f) => f.id == _selectedFormulaId,
        orElse: () => _formulas.first,
      );

  Future<void> _openCustomZikrDialog(BuildContext context) async {
    final ctrl = TextEditingController(text: _customFreeZikr ?? '');
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Zikr personnel libre'),
        content: TextField(
          controller: ctrl,
          maxLines: 2,
          decoration: const InputDecoration(
            labelText: 'Écrivez le Zikr que vous souhaitez pratiquer',
            hintText: 'Ex. صَلَّى اللهُ عَلَى مُحَمَّدٍ ou autre invocation...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              final clean = ctrl.text.trim();
              setState(() {
                _customFreeZikr = clean.isEmpty ? null : clean;
              });
              Navigator.pop(ctx);
            },
            child: const Text('Choisir'),
          ),
        ],
      ),
    );
    ctrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eco = ref.watch(ecosystemProvider);
    final activeArabic = _customFreeZikr ?? _activeFormula.arabic;

    return Scaffold(
      appBar: AppBar(title: const Text('YITTÉ ZIKR')),
      body: YitteAuroraBackdrop(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const YitteReveal(
              order: 0,
              child: EditorialHeroBanner(
                eyebrow: 'ZIKR LIBRE & OBJECTIF PERSONNEL',
                accentColor: YitteDomainAccents.spirituality,
                title: 'Sérénité, Rappel & Recueillement',
                subtitle:
                    'Aucune compétition, aucun classement ni badge de piété : choisissez librement votre Zikr et votre objectif, à votre rythme, sans horaire imposé.',
              ),
            ),
            const SizedBox(height: 16),
            SectionHeader(
              title: 'Choisir votre Zikr',
              actionLabel: '+ Zikr libre',
              onAction: () => _openCustomZikrDialog(context),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ..._formulas.map((f) {
                    final selected =
                        _customFreeZikr == null && _selectedFormulaId == f.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(
                          f.arabic,
                          style: AppTheme.arabicStyle(
                            color: selected
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface,
                            fontSize: 15,
                          ),
                        ),
                        selected: selected,
                        onSelected: (_) => setState(() {
                          _selectedFormulaId = f.id;
                          _customFreeZikr = null;
                        }),
                      ),
                    );
                  }),
                  if (_customFreeZikr != null)
                    ChoiceChip(
                      label: Text(_customFreeZikr!),
                      selected: true,
                      onSelected: (_) => _openCustomZikrDialog(context),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const SectionHeader(
              title: 'Objectif Personnel (Libre)',
            ),
            const SizedBox(height: 10),
            _DailySalawatGoalCard(
              arabicFormula: activeArabic,
              transliteration: _customFreeZikr != null
                  ? 'Formule personnelle sélectionnée'
                  : _activeFormula.transliteration,
              translation: _customFreeZikr != null
                  ? 'Pratique libre selon votre intention et votre rythme.'
                  : _activeFormula.translation,
              monthlyCount: eco.salawatMonthlyCount,
              monthlyTarget: eco.salawatMonthlyTarget,
              durationDays: eco.salawatDurationDays,
              customTitle: eco.salawatCustomTitle,
              todayCount: eco.salawatTodayCount,
              cycleStartIso: eco.salawatCycleStartIso,
              dailyReminderEnabled: eco.dailyTasbihReminderEnabled,
              openOnLaunch: eco.openTasbihOnLaunch,
              onAddStep: (step) {
                HapticFeedback.lightImpact();
                ref.read(ecosystemProvider.notifier).incrementSalawat(step: step);
              },
              onConfigureGoal: () => _openGoalConfigDialog(context, eco),
              onToggleDailyReminder: (enabled) => ref
                  .read(ecosystemProvider.notifier)
                  .toggleDailyTasbihReminder(enabled),
              onToggleOpenOnLaunch: (enabled) => ref
                  .read(ecosystemProvider.notifier)
                  .toggleOpenTasbihOnLaunch(enabled),
              onResetCycle: () =>
                  ref.read(ecosystemProvider.notifier).resetSalawatCycle(),
            ),
            const SizedBox(height: 18),
            const SectionHeader(title: 'Compteur Tasbīḥ (Privé)'),
            const SizedBox(height: 10),
            YitteSurfaceCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Text(
                      activeArabic,
                      textAlign: TextAlign.center,
                      style: AppTheme.arabicStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontSize: 22,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
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
                  const SizedBox(height: 18),
                  YittePulseHalo(
                    color: YitteDomainAccents.spirituality,
                    triggerKey: eco.personalTasbihCount,
                    child: YitteProgressRing(
                      progress: _target > 0
                          ? ((eco.personalTasbihCount % _target == 0 &&
                                      eco.personalTasbihCount > 0)
                                  ? 1.0
                                  : (eco.personalTasbihCount % _target) / _target)
                          : 0.0,
                      size: 196,
                      strokeWidth: 9,
                      color: AppTheme.tokensOf(context).goldAccent,
                      trackColor:
                          YitteDomainAccents.spirituality.withValues(alpha: 0.16),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          ref.read(ecosystemProvider.notifier).incrementTasbih();
                          ref
                              .read(ecosystemProvider.notifier)
                              .incrementSalawat(step: 1);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: YitteColors.emerald,
                            border: Border.all(
                              color: AppTheme.tokensOf(context).goldAccent,
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SanctuaryPrayerIcon(
                                size: 28,
                                color: Colors.white,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '${eco.personalTasbihCount}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                '/ $_target',
                                style: TextStyle(
                                  color: AppTheme.tokensOf(context).goldAccent,
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 12,
                    runSpacing: 6,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment: WrapAlignment.center,
                    children: [
                      Text(
                        'Sessions personnelles : ${eco.personalZikrSessionsCount}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      TextButton.icon(
                        icon: const Icon(Icons.check_circle_outline_rounded),
                        label: const Text('Clôturer & réinitialiser'),
                        onPressed: () => ref
                            .read(ecosystemProvider.notifier)
                            .resetTasbihAndLogSession(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openGoalConfigDialog(
    BuildContext context,
    EcosystemState eco,
  ) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _GoalConfigDialog(
        initialTitle: eco.salawatCustomTitle,
        initialTarget: eco.salawatMonthlyTarget,
        initialDays: eco.salawatDurationDays,
        onApply: (title, target, days, resetProgress) {
          ref.read(ecosystemProvider.notifier).updateSalawatGoal(
                target: target,
                durationDays: days,
                title: title,
                resetProgress: resetProgress,
              );
        },
      ),
    );
  }
}

class _GoalConfigDialog extends StatefulWidget {
  final String initialTitle;
  final int initialTarget;
  final int initialDays;
  final void Function(String title, int target, int days, bool reset) onApply;

  const _GoalConfigDialog({
    required this.initialTitle,
    required this.initialTarget,
    required this.initialDays,
    required this.onApply,
  });

  @override
  State<_GoalConfigDialog> createState() => _GoalConfigDialogState();
}

class _GoalConfigDialogState extends State<_GoalConfigDialog> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _targetCtrl;
  late final TextEditingController _daysCtrl;
  bool _resetProgress = false;

  static const _targetPresets = [1000, 3000, 10000, 33000, 100000];
  static const _durationPresets = [7, 15, 30, 40, 90, 365];
  static const _formulaPresets = [
    'صَلَّى اللهُ عَلَى مُحَمَّدٍ',
    'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
    'أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ',
    'لَا إِلَٰهَ إِلَّا اللَّهُ',
  ];

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.initialTitle);
    _targetCtrl = TextEditingController(text: '${widget.initialTarget}');
    _daysCtrl = TextEditingController(text: '${widget.initialDays}');
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _targetCtrl.dispose();
    _daysCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final parsedTarget = int.tryParse(_targetCtrl.text.trim()) ?? widget.initialTarget;
    final parsedDays = (int.tryParse(_daysCtrl.text.trim()) ?? widget.initialDays)
        .clamp(1, 3650);
    final dailyAvg = (parsedTarget / parsedDays).ceil().clamp(1, parsedTarget);

    return AlertDialog(
      title: const Text('Personnaliser mon objectif de Zikr'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choisissez librement votre formule, votre objectif et votre durée.',
              style: TextStyle(fontSize: 12.5),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Formule / intitulé du Zikr',
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _formulaPresets
                  .map(
                    (f) => ActionChip(
                      label: Text(f, style: const TextStyle(fontSize: 12)),
                      onPressed: () => setState(() => _titleCtrl.text = f),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _targetCtrl,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Objectif total (répétitions)',
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _targetPresets
                  .map(
                    (v) => ActionChip(
                      label: Text('$v'),
                      onPressed: () => setState(() => _targetCtrl.text = '$v'),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _daysCtrl,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Durée souhaitée (en jours)',
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _durationPresets
                  .map(
                    (d) => ActionChip(
                      label: Text('${d}j'),
                      onPressed: () => setState(() => _daysCtrl.text = '$d'),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 10),
            Text(
              'Rythme indicatif : ~$dailyAvg répétitions / jour sur $parsedDays jour(s).',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: _resetProgress,
              onChanged: (v) => setState(() => _resetProgress = v ?? false),
              title: const Text(
                'Repartir de 0 pour ce nouveau cycle',
                style: TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onApply(
              _titleCtrl.text,
              parsedTarget,
              parsedDays,
              _resetProgress,
            );
            Navigator.pop(context);
          },
          child: const Text('Appliquer'),
        ),
      ],
    );
  }
}

class _DailySalawatGoalCard extends StatelessWidget {
  final String arabicFormula;
  final String transliteration;
  final String translation;
  final int monthlyCount;
  final int monthlyTarget;
  final int durationDays;
  final String customTitle;
  final int todayCount;
  final String cycleStartIso;
  final bool dailyReminderEnabled;
  final bool openOnLaunch;
  final void Function(int step) onAddStep;
  final VoidCallback onConfigureGoal;
  final ValueChanged<bool> onToggleDailyReminder;
  final ValueChanged<bool> onToggleOpenOnLaunch;
  final VoidCallback onResetCycle;

  const _DailySalawatGoalCard({
    required this.arabicFormula,
    required this.transliteration,
    required this.translation,
    required this.monthlyCount,
    required this.monthlyTarget,
    required this.durationDays,
    required this.customTitle,
    required this.todayCount,
    required this.cycleStartIso,
    required this.dailyReminderEnabled,
    required this.openOnLaunch,
    required this.onAddStep,
    required this.onConfigureGoal,
    required this.onToggleDailyReminder,
    required this.onToggleOpenOnLaunch,
    required this.onResetCycle,
  });

  @override
  Widget build(BuildContext context) {
    final safeDays = durationDays.clamp(1, 3650);
    final startDate = DateTime.tryParse(cycleStartIso) ?? DateTime.now();
    final elapsedDays =
        DateTime.now().difference(startDate).inDays.clamp(0, safeDays - 1);
    final remainingDays = (safeDays - elapsedDays).clamp(1, safeDays);
    final remainingCount = (monthlyTarget - monthlyCount).clamp(0, monthlyTarget);
    final suggestedDaily = (remainingCount / remainingDays).ceil();
    final monthlyRatio =
        monthlyTarget > 0 ? (monthlyCount / monthlyTarget).clamp(0.0, 1.0) : 0.0;
    final dailyQuota = (monthlyTarget / safeDays).ceil().clamp(1, monthlyTarget);
    final todayRatio = (todayCount / dailyQuota).clamp(0.0, 1.0);

    return YitteSurfaceCard(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '$customTitle — $monthlyTarget sur $safeDays jour(s)',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Chip(
                label: Text('${(monthlyRatio * 100).toStringAsFixed(1)}%'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.tune_rounded, size: 18),
            label: const Text('Configurer objectif & durée'),
            onPressed: onConfigureGoal,
          ),
          const SizedBox(height: 12),
          Directionality(
            textDirection: TextDirection.rtl,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                arabicFormula,
                style: AppTheme.arabicStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 24,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            transliteration,
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(translation, style: const TextStyle(fontSize: 12.5)),
          const Divider(height: 22),
          Text(
            'Progression du cycle (privée) : $monthlyCount / $monthlyTarget',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: monthlyRatio,
              minHeight: 10,
              backgroundColor: YitteColors.emeraldSoft,
              color: YitteDomainAccents.spirituality,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Aujourd’hui : $todayCount / $dailyQuota conseillés • Reste $remainingCount sur $remainingDays jour(s) (~$suggestedDaily/j)',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 12.5),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: todayRatio,
              minHeight: 7,
              backgroundColor: YitteColors.goldSoft,
              color: YitteColors.gold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: () => onAddStep(1),
                child: const Text('+1'),
              ),
              OutlinedButton(
                onPressed: () => onAddStep(33),
                child: const Text('+33'),
              ),
              OutlinedButton(
                onPressed: () => onAddStep(100),
                child: const Text('+100'),
              ),
              TextButton(
                onPressed: onResetCycle,
                child: Text('Nouveau cycle (${safeDays}j)'),
              ),
            ],
          ),
          const Divider(height: 20),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Activer un rappel personnel discret'),
            subtitle: const Text(
              'Notification locale dédiée à votre objectif personnel (sans horaire imposé).',
            ),
            value: dailyReminderEnabled,
            onChanged: onToggleDailyReminder,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Ouvrir directement sur Yitté Zikr au lancement'),
            subtitle: const Text(
              'Affiche cet espace serein dès l’ouverture de l’application.',
            ),
            value: openOnLaunch,
            onChanged: onToggleOpenOnLaunch,
          ),
        ],
      ),
    );
  }
}
