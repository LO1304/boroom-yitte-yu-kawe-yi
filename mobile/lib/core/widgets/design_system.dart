import 'dart:math' as math;

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// Shared motion helper respecting Accessibility Reduce Motion setting.
bool yitteMotionReduced(BuildContext context) {
  return MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}

/// Fluid spring-like page transition for GoRouter routes.
Page<void> yitteTransitionPage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 210),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      if (yitteMotionReduced(context)) return child;
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 0.035),
            end: Offset.zero,
          ).animate(curved),
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.985, end: 1.0).animate(curved),
            child: child,
          ),
        ),
      );
    },
  );
}

/// Atmospheric ambient Aurora Mesh backdrop reacting instantly to theme + UI model.
class YitteAuroraBackdrop extends StatelessWidget {
  final Widget child;

  const YitteAuroraBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.tokensOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final model = tokens.visualModel;

    if (model == UiVisualModel.editorialMinimal) {
      return ColoredBox(color: tokens.canvas, child: child);
    }

    final orbAlphaA = isDark
        ? (model == UiVisualModel.dynamicCommunity ? 0.24 : 0.18)
        : (model == UiVisualModel.dynamicCommunity ? 0.22 : 0.16);
    final orbAlphaB = isDark
        ? (model == UiVisualModel.dynamicCommunity ? 0.19 : 0.14)
        : (model == UiVisualModel.dynamicCommunity ? 0.18 : 0.14);

    return DecoratedBox(
      decoration: BoxDecoration(color: tokens.canvas),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -120,
            right: -90,
            child: IgnorePointer(
              child: Container(
                width: 340,
                height: 340,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      tokens.meshOrbA.withValues(alpha: orbAlphaA),
                      tokens.meshOrbA.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            top: 260,
            left: -130,
            child: IgnorePointer(
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      tokens.meshOrbB.withValues(alpha: orbAlphaB),
                      tokens.meshOrbB.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (model == UiVisualModel.sanctuaryClassic)
            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: SanctuaryGeometryPainter(
                    strokeColor: tokens.goldAccent.withValues(alpha: isDark ? 0.05 : 0.06),
                    accentColor: Colors.transparent,
                  ),
                ),
              ),
            ),
          child,
        ],
      ),
    );
  }
}

/// 3D-lit jewel-tone gradient icon squircle badge — bold, scaled, dimensional.
class YitteIconBadge extends StatelessWidget {
  final IconData? icon;
  final Widget? customIcon;
  final Color color;
  final Color? secondaryColor;
  final double size;
  final double iconSize;

  const YitteIconBadge({
    super.key,
    this.icon,
    this.customIcon,
    required this.color,
    this.secondaryColor,
    this.size = 48,
    this.iconSize = 24,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.tokensOf(context);
    final isMinimal = tokens.visualModel == UiVisualModel.editorialMinimal;
    final radius = size * 0.30;

    if (isMinimal) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Center(
          child: customIcon ?? Icon(icon, color: color, size: iconSize),
        ),
      );
    }

    final hi = secondaryColor ?? Color.lerp(color, Colors.white, 0.26) ?? color;
    final lo = Color.lerp(color, Colors.black, 0.24) ?? color;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [hi, color, lo],
          stops: const [0.0, 0.52, 1.0],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.35),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.34),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Center(
        child: customIcon ??
            Icon(
              icon,
              color: Colors.white,
              size: iconSize,
            ),
      ),
    );
  }
}

/// Animated circular progress ring with glowing rounded sweep.
class YitteProgressRing extends StatelessWidget {
  final double progress; // 0.0..1.0
  final double size;
  final double strokeWidth;
  final Color color;
  final Color? trackColor;
  final Widget child;

  const YitteProgressRing({
    super.key,
    required this.progress,
    this.size = 86,
    this.strokeWidth = 8,
    required this.color,
    this.trackColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    final reduced = yitteMotionReduced(context);
    final bgTrack = trackColor ?? color.withValues(alpha: 0.14);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: clamped),
      duration: reduced ? Duration.zero : const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, value, childWidget) {
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _ProgressRingPainter(
              progress: value,
              strokeWidth: strokeWidth,
              color: color,
              trackColor: bgTrack,
            ),
            child: Center(child: childWidget),
          ),
        );
      },
      child: child,
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color color;
  final Color trackColor;

  _ProgressRingPainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0.001) return;

    final rect = Rect.fromCircle(center: center, radius: radius);
    final sweep = progress * math.pi * 2;
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 4
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawArc(rect, -math.pi / 2, sweep, false, glowPaint);

    final arcPaint = Paint()
      ..shader = SweepGradient(
        startAngle: -math.pi / 2,
        endAngle: 3 * math.pi / 2,
        colors: [
          Color.lerp(color, Colors.white, 0.28) ?? color,
          color,
        ],
      ).createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, sweep, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter old) =>
      old.progress != progress || old.color != color || old.trackColor != trackColor;
}

/// Visual audio voice-note player card with stylized waveform bars & glowing play orb.
class YitteAudioPlayerTile extends StatelessWidget {
  final bool playing;
  final String label;
  final VoidCallback onToggle;
  final Color? accentColor;

  const YitteAudioPlayerTile({
    super.key,
    required this.playing,
    required this.label,
    required this.onToggle,
    this.accentColor,
  });

  static const _bars = [0.35, 0.72, 0.48, 0.95, 0.62, 0.85, 0.42, 0.78, 0.56, 0.90, 0.44, 0.66];

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? Theme.of(context).colorScheme.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: color.withValues(alpha: playing ? 0.16 : 0.09),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: color.withValues(alpha: playing ? 0.45 : 0.22),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Color.lerp(color, Colors.white, 0.18) ?? color, color],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Icon(
                playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: _bars.asMap().entries.map((e) {
                final h = 6.0 + e.value * 16.0;
                final active = playing && e.key.isEven;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 3,
                  height: active ? h * 1.15 : h,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: playing ? 0.92 : 0.48),
                    borderRadius: BorderRadius.circular(99),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(width: 10),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Architectural 8-point Khatam geometric lattice with delicate hairline gold arcs.
class SanctuaryGeometryPainter extends CustomPainter {
  final Color strokeColor;
  final Color accentColor;

  SanctuaryGeometryPainter({
    required this.strokeColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final finePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.9;

    final haloPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.7;

    const step = 68.0;
    for (double y = -step / 2; y < size.height + step; y += step) {
      for (double x = -step / 2; x < size.width + step; x += step) {
        final center = Offset(x, y);
        canvas.drawCircle(center, 22, haloPaint);
        _drawOctagram(canvas, center, 17, finePaint);
      }
    }
  }

  void _drawOctagram(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    const pts = 16;
    for (int i = 0; i <= pts; i++) {
      final angle = (i * math.pi * 2) / pts;
      final radius = i.isEven ? r : r * 0.44;
      final p = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SanctuaryGeometryPainter oldDelegate) =>
      oldDelegate.strokeColor != strokeColor ||
      oldDelegate.accentColor != accentColor;
}

/// Staggered, kinetic spring-feel entrance animation with reduced-motion bypass.
class YitteReveal extends StatefulWidget {
  final Widget child;
  final int order;
  final Duration duration;

  const YitteReveal({
    super.key,
    required this.child,
    this.order = 0,
    this.duration = const Duration(milliseconds: 420),
  });

  @override
  State<YitteReveal> createState() => _YitteRevealState();
}

class _YitteRevealState extends State<YitteReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    final curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _opacity = curve;
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.075),
      end: Offset.zero,
    ).animate(curve);
    _scale = Tween<double>(begin: 0.96, end: 1.0).animate(curve);

    final delayMs = (widget.order.clamp(0, 8)) * 55;
    if (delayMs == 0) {
      _controller.forward();
    } else {
      Future<void>.delayed(Duration(milliseconds: delayMs), () {
        if (mounted) _controller.forward();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (yitteMotionReduced(context)) return widget.child;
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: ScaleTransition(
          scale: _scale,
          child: widget.child,
        ),
      ),
    );
  }
}

/// Custom-painted Islamic Salat / Du'a prayer icon inside an arch (mihrab).
class SanctuaryPrayerIcon extends StatelessWidget {
  final double size;
  final Color? color;
  final Color? accentColor;

  const SanctuaryPrayerIcon({
    super.key,
    this.size = 24,
    this.color,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final fg = color ?? Theme.of(context).colorScheme.primary;
    final gold = accentColor ?? AppTheme.tokensOf(context).goldAccent;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _SanctuaryPrayerPainter(color: fg, accentColor: gold),
      ),
    );
  }
}

class _SanctuaryPrayerPainter extends CustomPainter {
  final Color color;
  final Color accentColor;

  const _SanctuaryPrayerPainter({
    required this.color,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24.0;

    final goldPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5 * s
      ..strokeCap = StrokeCap.round;

    final bodyPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.9 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Pointed Islamic Mihrab arch
    final arch = Path()
      ..moveTo(3.2 * s, 20.5 * s)
      ..lineTo(3.2 * s, 10.5 * s)
      ..quadraticBezierTo(3.2 * s, 4.2 * s, 12.0 * s, 1.8 * s)
      ..quadraticBezierTo(20.8 * s, 4.2 * s, 20.8 * s, 10.5 * s)
      ..lineTo(20.8 * s, 20.5 * s);
    canvas.drawPath(arch, goldPaint);

    // Subtle prayer mat baseline
    canvas.drawLine(Offset(5.5 * s, 20.5 * s), Offset(18.5 * s, 20.5 * s), goldPaint);

    // Muslim person in Julus / Du'a posture inside the sanctuary arch
    canvas.drawCircle(Offset(13.6 * s, 9.6 * s), 1.9 * s, fillPaint);

    final posture = Path()
      ..moveTo(13.2 * s, 12.0 * s)
      ..quadraticBezierTo(11.6 * s, 14.6 * s, 10.4 * s, 17.6 * s)
      ..lineTo(15.6 * s, 17.6 * s)
      // Hands raised in supplication (Du'a)
      ..moveTo(12.2 * s, 13.8 * s)
      ..lineTo(8.8 * s, 11.4 * s)
      ..lineTo(8.2 * s, 9.6 * s);
    canvas.drawPath(posture, bodyPaint);
  }

  @override
  bool shouldRepaint(covariant _SanctuaryPrayerPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.accentColor != accentColor;
}

/// Concentric tactile shockwave halo for spiritual Tasbīḥ orbs (finite pulse, never stalls tests).
class YittePulseHalo extends StatefulWidget {
  final Widget child;
  final Color color;
  final double maxRadiusBlur;
  final Object? triggerKey;

  const YittePulseHalo({
    super.key,
    required this.child,
    required this.color,
    this.maxRadiusBlur = 30,
    this.triggerKey,
  });

  @override
  State<YittePulseHalo> createState() => _YittePulseHaloState();
}

class _YittePulseHaloState extends State<YittePulseHalo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 580),
    );
    _pulse = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
  }

  @override
  void didUpdateWidget(covariant YittePulseHalo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.triggerKey != null && oldWidget.triggerKey != widget.triggerKey) {
      _ctrl.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (yitteMotionReduced(context)) return widget.child;
    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final wave = math.sin(_pulse.value * math.pi);
        return Transform.scale(
          scale: 1.0 + (wave * 0.035),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withValues(alpha: 0.20 + (wave * 0.24)),
                  blurRadius: 18 + (wave * widget.maxRadiusBlur),
                  spreadRadius: 2 + (wave * 8),
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Multi-model flagship surface card: Glassmorphic Aurora, 3D Tactile, Apple Minimal, or Classic.
class YitteSurfaceCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;
  final Color? borderColor;

  const YitteSurfaceCard({
    super.key,
    required this.child,
    this.onTap,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.color,
    this.borderColor,
  });

  @override
  State<YitteSurfaceCard> createState() => _YitteSurfaceCardState();
}

class _YitteSurfaceCardState extends State<YitteSurfaceCard> {
  bool _pressed = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.tokensOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduced = yitteMotionReduced(context);
    final model = tokens.visualModel;
    final radius = tokens.cardRadius;

    final baseSurface = widget.color ??
        (model == UiVisualModel.glassLuxe
            ? tokens.elevated.withValues(alpha: isDark ? 0.84 : 0.88)
            : tokens.elevated);

    final effectiveBorder = widget.borderColor ??
        (_hovered
            ? tokens.goldAccent.withValues(alpha: 0.65)
            : (model == UiVisualModel.dynamicCommunity
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.26)
                : (model == UiVisualModel.glassLuxe
                    ? (isDark
                        ? Colors.white.withValues(alpha: 0.14)
                        : Colors.white.withValues(alpha: 0.92))
                    : tokens.borderSubtle)));

    final borderWidth = switch (model) {
      UiVisualModel.dynamicCommunity => 1.6,
      UiVisualModel.glassLuxe => 1.35,
      _ => widget.borderColor != null ? 1.4 : 1.0,
    };

    final shadows = switch (model) {
      UiVisualModel.editorialMinimal => <BoxShadow>[
          if (_hovered)
            BoxShadow(
              color: tokens.shadowTint,
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
        ],
      UiVisualModel.dynamicCommunity => <BoxShadow>[
          BoxShadow(
            color: (widget.borderColor ?? Theme.of(context).colorScheme.primary)
                .withValues(alpha: isDark ? 0.34 : 0.18),
            blurRadius: _pressed ? 2 : 0,
            offset: Offset(0, _pressed ? 1 : 4.5),
          ),
          BoxShadow(
            color: tokens.shadowTint,
            blurRadius: _hovered ? 22 : 14,
            offset: const Offset(0, 8),
          ),
        ],
      UiVisualModel.glassLuxe => <BoxShadow>[
          BoxShadow(
            color: _hovered
                ? tokens.goldAccent.withValues(alpha: 0.22)
                : tokens.shadowTint,
            blurRadius: _pressed ? 8 : (_hovered ? 32 : 24),
            offset: Offset(0, _pressed ? 2 : (_hovered ? 12 : 8)),
          ),
        ],
      UiVisualModel.sanctuaryClassic => <BoxShadow>[
          BoxShadow(
            color: _hovered
                ? tokens.goldAccent.withValues(alpha: 0.16)
                : tokens.shadowTint,
            blurRadius: _pressed ? 6 : (_hovered ? 20 : 14),
            offset: Offset(0, _pressed ? 2 : 5),
          ),
        ],
    };

    final cardBody = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: reduced ? Duration.zero : const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: (reduced || widget.onTap == null)
            ? Matrix4.identity()
            : Matrix4.translationValues(0, _hovered && !_pressed ? -3.0 : 0.0, 0),
        margin: widget.margin,
        decoration: BoxDecoration(
          color: baseSurface,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: effectiveBorder, width: borderWidth),
          boxShadow: shadows,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(radius),
            onTap: widget.onTap,
            onTapDown: widget.onTap == null ? null : (_) => setState(() => _pressed = true),
            onTapCancel: widget.onTap == null ? null : () => setState(() => _pressed = false),
            onTapUp: widget.onTap == null ? null : (_) => setState(() => _pressed = false),
            child: Padding(
              padding: widget.padding,
              child: widget.child,
            ),
          ),
        ),
      ),
    );

    if (reduced || widget.onTap == null) return cardBody;
    return AnimatedScale(
      scale: _pressed ? 0.975 : 1.0,
      duration: const Duration(milliseconds: 130),
      curve: Curves.easeOutCubic,
      child: cardBody,
    );
  }
}

/// Editorial status pill with vibrant chromatic clarity.
class YitteStatusPill extends StatelessWidget {
  final String label;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;

  const YitteStatusPill({
    super.key,
    required this.label,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.tokensOf(context);
    final bg = backgroundColor ?? tokens.goldSurface;
    final fg = foregroundColor ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: fg.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: fg,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Serene architectural empty state with dimensional gradient badge.
class YitteEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String? actionLabel;
  final VoidCallback? onAction;

  const YitteEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.tokensOf(context);
    final primary = Theme.of(context).colorScheme.primary;
    return YitteSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
      borderColor: tokens.borderAccent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          YitteIconBadge(
            icon: icon,
            color: primary,
            size: 56,
            iconSize: 28,
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 6),
          Text(
            description,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
          ],
        ],
      ),
    );
  }
}

/// Subtle animated loading indicator banner for async AI / upload transitions.
class YitteLoadingBanner extends StatelessWidget {
  final String message;

  const YitteLoadingBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.tokensOf(context);
    return YitteSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      color: tokens.goldSurface,
      borderColor: tokens.borderAccent,
      child: Row(
        children: [
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ),
        ],
      ),
    );
  }
}
