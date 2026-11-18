import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/state/app_providers.dart';
import '../../core/services/backend_repository.dart';
import '../../core/services/speech_bridge.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/editorial_widgets.dart';

class ZikrScreen extends ConsumerStatefulWidget {
  const ZikrScreen({super.key});

  @override
  ConsumerState<ZikrScreen> createState() => _ZikrScreenState();
}

class _ZikrScreenState extends ConsumerState<ZikrScreen> {
  int _target = 33;
  bool _inLiveRoom = false;
  bool _liveKitConnected = false;
  bool _recitingAudio = false;

  @override
  void dispose() {
    SpeechBridge.stopSpeaking();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final eco = ref.watch(ecosystemProvider);
    final liveKit = ref.watch(liveKitServiceProvider);
    final session = eco.zikrSessions.first;

    return Scaffold(
      appBar: AppBar(title: const Text('YITTÉ ZIKR')),
      body: YitteAuroraBackdrop(
        child: ListView(
          padding: const EdgeInsets.all(16),
        children: [
          YitteReveal(
            order: 0,
            child: EditorialHeroBanner(
              eyebrow: 'SESSIONS SPIRITUELLES COLLECTIVES',
              accentColor: YitteDomainAccents.spirituality,
              title: 'Sérénité, Rappel & Fraternité',
              subtitle:
                  'Aucune compétition, aucun classement ni badge de piété : un espace exclusivement dédié au recueillement et aux références authentiques.',
              trailing: Container(
                padding: const EdgeInsets.only(left: 10, right: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Rappel',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.tokensOf(context).visualModel ==
                                UiVisualModel.editorialMinimal
                            ? Theme.of(context).colorScheme.primary
                            : Colors.white,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Switch(
                      value: eco.zikrReminderEnabled,
                      onChanged: (v) =>
                          ref.read(ecosystemProvider.notifier).toggleZikrReminder(v),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SanctuaryPrayerIcon(size: 28),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          session.title,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(session.recurrenceLabel,
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, color: YitteColors.gold)),
                  const SizedBox(height: 6),
                  Text(session.programDetails,
                      style: Theme.of(context).textTheme.bodyMedium),
                  const Divider(height: 22),
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        session.arabicText,
                        style: AppTheme.arabicStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    session.transliteration,
                    style: const TextStyle(
                        fontStyle: FontStyle.italic, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 6),
                  Text(session.frenchTranslation),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 6,
                    children: session.verifiedReferences
                        .map((r) => Chip(
                              avatar: const Icon(Icons.verified_outlined, size: 16),
                              label: Text(r, style: const TextStyle(fontSize: 11)),
                            ))
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: Icon(_inLiveRoom ? Icons.call_end_rounded : Icons.headset_mic_rounded),
                      label: Text(_inLiveRoom
                          ? 'Quitter le salon audio Zikr'
                          : 'Rejoindre le salon audio en direct'),
                      onPressed: () async {
                        if (_inLiveRoom) {
                          SpeechBridge.stopSpeaking();
                          await liveKit.disconnect();
                          if (mounted) {
                            setState(() {
                              _inLiveRoom = false;
                              _liveKitConnected = false;
                              _recitingAudio = false;
                            });
                          }
                          return;
                        }
                        final creds = await BackendRepository.instance
                            .fetchLiveKitJoinToken(session.id);
                        if (creds == null) {
                          if (!context.mounted) return;
                          setState(() {
                            _inLiveRoom = true;
                            _liveKitConnected = false;
                          });
                          return;
                        }
                        await liveKit.connect(
                          livekitUrl: creds['url']!,
                          token: creds['token']!,
                          publishAudio: false,
                        );
                        if (mounted) {
                          setState(() {
                            _inLiveRoom = true;
                            _liveKitConnected = true;
                          });
                        }
                      },
                    ),
                  ),
                  if (_inLiveRoom) ...[
                    const SizedBox(height: 10),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: YitteColors.emeraldSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _liveKitConnected
                                ? 'Salon audio WebRTC LiveKit actif • Écoute en direct'
                                : 'Salon audio Zikr actif (mode guidé local — LiveKit prêt si configuré)',
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12.5,
                              color: YitteColors.emerald,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              OutlinedButton.icon(
                                icon: Icon(_recitingAudio
                                    ? Icons.stop_rounded
                                    : Icons.volume_up_rounded),
                                label: Text(_recitingAudio
                                    ? 'Arrêter récitation arabe'
                                    : 'Écouter invocation en arabe'),
                                onPressed: () {
                                  if (_recitingAudio) {
                                    SpeechBridge.stopSpeaking();
                                    setState(() => _recitingAudio = false);
                                  } else {
                                    SpeechBridge.speak(
                                      session.arabicText,
                                      locale: 'ar-SA',
                                    );
                                    setState(() => _recitingAudio = true);
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          const SectionHeader(
            title: 'Ouverture Tasbīḥ Quotidienne (Objectif & Durée libres)',
          ),
          const SizedBox(height: 10),
          _DailySalawatGoalCard(
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
            onToggleDailyReminder: (v) => ref
                .read(ecosystemProvider.notifier)
                .toggleDailyTasbihReminder(v),
            onToggleOpenOnLaunch: (v) =>
                ref.read(ecosystemProvider.notifier).toggleOpenTasbihOnLaunch(v),
            onResetCycle: () =>
                ref.read(ecosystemProvider.notifier).resetSalawatCycle(),
          ),
          const SizedBox(height: 18),
          const SectionHeader(title: 'Compteur Personnel de Tasbīḥ (Privé)'),
          const SizedBox(height: 10),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
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
                      trackColor: YitteDomainAccents.spirituality.withValues(alpha: 0.16),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          ref.read(ecosystemProvider.notifier).incrementTasbih();
                          ref
                              .read(ecosystemProvider.notifier)
                              .incrementSalawat(step: 1);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 220),
                          width: 160,
                          height: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.tokensOf(context).heroStart,
                                AppTheme.tokensOf(context).heroEnd,
                              ],
                            ),
                            border: Border.all(
                              color: AppTheme.tokensOf(context)
                                  .goldAccent
                                  .withValues(alpha: 0.65),
                              width: 2.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.36),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
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
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text('Sessions personnelles : ${eco.personalZikrSessionsCount}'),
                      TextButton.icon(
                        icon: const Icon(Icons.refresh_rounded),
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
    'Ṣalātu ʿalā an-Nabī',
    'SubḥānAllāh wa bi-ḥamdih',
    'Astaghfirullāh al-ʿAẓīm',
    'Lā ilāha illAllāh',
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
    final parsedTarget =
        int.tryParse(_targetCtrl.text.trim())?.clamp(1, 10000000) ??
            widget.initialTarget;
    final parsedDays =
        int.tryParse(_daysCtrl.text.trim())?.clamp(1, 3650) ??
            widget.initialDays;
    final dailyPace = (parsedTarget / parsedDays).ceil();

    return AlertDialog(
      title: const Text('Configurer objectif & durée'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choisissez librement votre formule, la quantité cible et le nombre de jours :',
              style: TextStyle(fontSize: 12.5),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _formulaPresets
                  .map(
                    (f) => ChoiceChip(
                      label: Text(f, style: const TextStyle(fontSize: 11.5)),
                      selected: _titleCtrl.text.trim() == f,
                      onSelected: (_) => setState(() => _titleCtrl.text = f),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                labelText: 'Invocation / Formule personnalisée',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _targetCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Objectif total (répétitions)',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _targetPresets
                  .map(
                    (n) => ActionChip(
                      label: Text('$n', style: const TextStyle(fontSize: 11.5)),
                      onPressed: () => setState(() => _targetCtrl.text = '$n'),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _daysCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Durée souhaitée (en jours)',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _durationPresets
                  .map(
                    (d) => ActionChip(
                      label: Text('${d}j', style: const TextStyle(fontSize: 11.5)),
                      onPressed: () => setState(() => _daysCtrl.text = '$d'),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: YitteColors.emeraldSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'Rythme quotidien conseillé : $dailyPace / jour pendant $parsedDays jour(s)',
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: YitteColors.inkDark,
                ),
              ),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _resetProgress,
              onChanged: (v) => setState(() => _resetProgress = v),
              title: const Text(
                'Repartir à zéro pour ce cycle',
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

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 6),
            OutlinedButton.icon(
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: const Text('Configurer objectif & durée'),
              onPressed: onConfigureGoal,
            ),
            const SizedBox(height: 10),
            Directionality(
              textDirection: TextDirection.rtl,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ',
                  style: AppTheme.arabicStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Allāhumma ṣalli ʿalā Muḥammadin wa ʿalā āli Muḥammad',
              style: TextStyle(fontStyle: FontStyle.italic, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            const Text(
              '« Ô Allah, accorde Ta bénédiction à Muḥammad ainsi qu’à sa famille. » — Sahih Muslim n° 408 (aussi numéroté 384) : celui qui prie une fois sur le Prophète (ﷺ), Allah prie dix fois sur lui.',
              style: TextStyle(fontSize: 12),
            ),
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
                color: YitteColors.emerald,
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
              title: const Text('Rappel d’ouverture Tasbīḥ chaque jour (07h00)'),
              subtitle: const Text(
                'Notification locale quotidienne dédiée à votre objectif personnel.',
              ),
              value: dailyReminderEnabled,
              onChanged: onToggleDailyReminder,
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Ouvrir directement sur Yitté Tasbīḥ au lancement'),
              subtitle: const Text(
                'Affiche cet espace serein dès l’ouverture quotidienne de l’application.',
              ),
              value: openOnLaunch,
              onChanged: onToggleOpenOnLaunch,
            ),
          ],
        ),
      ),
    );
  }
}
