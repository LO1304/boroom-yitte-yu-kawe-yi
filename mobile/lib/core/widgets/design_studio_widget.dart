import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../app/state/app_providers.dart';
import '../theme/app_theme.dart';
import 'design_system.dart';

/// Opens the live translucent Design Studio sheet so users see themes & models update live.
Future<void> showDesignStudioSheet(BuildContext context) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    barrierColor: Colors.black.withValues(alpha: 0.28),
    builder: (ctx) => DraggableScrollableSheet(
      initialChildSize: 0.78,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollCtrl) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
        child: ListView(
          controller: scrollCtrl,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4.5,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Theme.of(ctx).dividerColor,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Row(
              children: [
                YitteIconBadge(
                  icon: Icons.palette_rounded,
                  color: Theme.of(ctx).colorScheme.primary,
                  size: 44,
                  iconSize: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Studio Thèmes & Modèles',
                        style: Theme.of(ctx).textTheme.titleLarge,
                      ),
                      Text(
                        '8 univers visuels × 4 modèles × Clair / Sombre en direct',
                        style: Theme.of(ctx).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Fermer',
                  onPressed: () => Navigator.pop(ctx),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const DesignStudioSection(),
          ],
        ),
      ),
    ),
  );
}

/// Interactive theme + UI model selector with live visual previews.
class DesignStudioSection extends ConsumerWidget {
  const DesignStudioSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final palette = ref.watch(themePaletteProvider);
    final model = ref.watch(uiVisualModelProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Luminosité', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<ThemeMode>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(
                value: ThemeMode.light,
                icon: Icon(Icons.light_mode_rounded, size: 17),
                label: Text('Clair'),
              ),
              ButtonSegment(
                value: ThemeMode.dark,
                icon: Icon(Icons.dark_mode_rounded, size: 17),
                label: Text('Sombre'),
              ),
              ButtonSegment(
                value: ThemeMode.system,
                icon: Icon(Icons.brightness_auto_rounded, size: 17),
                label: Text('Auto'),
              ),
            ],
            selected: {themeMode},
            onSelectionChanged: (s) =>
                ref.read(themeModeProvider.notifier).setMode(s.first),
          ),
        ),
        const SizedBox(height: 22),
        Text(
          'Modèle Structurel (${UiVisualModel.values.length} architectures)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth > 540 ? 4 : 2;
            return GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.98,
              children: UiVisualModel.values.map((m) {
                final selected = m == model;
                return YitteSurfaceCard(
                  padding: const EdgeInsets.all(12),
                  borderColor: selected ? palette.primary : null,
                  onTap: () => ref.read(uiVisualModelProvider.notifier).setModel(m),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _MiniModelPreview(
                        model: m,
                        primary: palette.primary,
                        accent: palette.accent,
                        orb: palette.meshOrbA,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              m.labelFr,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          if (selected)
                            Icon(
                              Icons.check_circle_rounded,
                              size: 18,
                              color: palette.primary,
                            ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Expanded(
                        child: Text(
                          m.descriptionFr,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            );
          },
        ),
        const SizedBox(height: 22),
        Text(
          'Univers de Couleurs (${SanctuaryPalette.values.length} thèmes)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth > 620 ? 4 : 2;
            return GridView.count(
              crossAxisCount: cols,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.38,
              children: SanctuaryPalette.values.map((p) {
                final selected = p == palette;
                return GestureDetector(
                  onTap: () =>
                      ref.read(themePaletteProvider.notifier).setPalette(p),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: p.primary,
                      border: Border.all(
                        color: selected
                            ? p.accent
                            : p.primaryDeep,
                        width: selected ? 2.0 : 1.0,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: p.accent,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.65),
                                  width: 1,
                                ),
                              ),
                              child: selected
                                  ? const Icon(Icons.check_rounded,
                                      size: 13, color: Colors.white)
                                  : null,
                            ),
                            const Spacer(),
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: p.canvasLight,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.4),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: p.accent,
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          p.labelFr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          p.descriptionFr,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.78),
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }
}

class _MiniModelPreview extends StatelessWidget {
  final UiVisualModel model;
  final Color primary;
  final Color accent;
  final Color orb;

  const _MiniModelPreview({
    required this.model,
    required this.primary,
    required this.accent,
    required this.orb,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = switch (model) {
      UiVisualModel.editorialMinimal =>
        isDark ? const Color(0xFF12151C) : const Color(0xFFF8FAFC),
      UiVisualModel.sanctuaryClassic =>
        isDark ? const Color(0xFF18221E) : const Color(0xFFF6F2E9),
      _ => isDark ? const Color(0xFF0D1420) : Color.lerp(Colors.white, orb, 0.14)!,
    };
    return Container(
      height: 64,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: primary.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Container(
            height: 18,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(4),
              color: isDark ? const Color(0xFF161B19) : Colors.white,
              border: Border(
                left: BorderSide(color: primary, width: 3),
                top: BorderSide(color: primary.withValues(alpha: 0.18)),
                right: BorderSide(color: primary.withValues(alpha: 0.18)),
                bottom: BorderSide(color: primary.withValues(alpha: 0.18)),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF202938) : Colors.white,
                      borderRadius: BorderRadius.circular(
                        model == UiVisualModel.editorialMinimal ? 4 : 8,
                      ),
                      border: Border.all(
                        color: model == UiVisualModel.dynamicCommunity
                            ? accent
                            : primary.withValues(alpha: 0.18),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF202938) : Colors.white,
                      borderRadius: BorderRadius.circular(
                        model == UiVisualModel.editorialMinimal ? 4 : 8,
                      ),
                      border: Border.all(
                        color: model == UiVisualModel.dynamicCommunity
                            ? orb
                            : primary.withValues(alpha: 0.18),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (model.floatingNavBar) ...[
            const SizedBox(height: 4),
            Container(
              height: 7,
              width: 54,
              decoration: BoxDecoration(
                color: primary.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(99),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
