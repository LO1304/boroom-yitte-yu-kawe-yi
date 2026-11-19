import 'dart:math' as math;

import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../theme/app_theme.dart';

/// Shared motion helper respecting Accessibility Reduce Motion setting.
bool yitteMotionReduced(BuildContext context) {
  return MediaQuery.maybeDisableAnimationsOf(context) ?? false;
}

/// Crisp, restrained editorial page transition for GoRouter routes.
Page<void> yitteTransitionPage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 220),
    reverseTransitionDuration: const Duration(milliseconds: 180),
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
            begin: const Offset(0, 0.02),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Clean matte editorial canvas (Light #F8F7F4 / Dark #0E1110) — zero pastel wash or glowing blobs.
class YitteAuroraBackdrop extends StatelessWidget {
  final Widget child;

  const YitteAuroraBackdrop({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.tokensOf(context);
    return ColoredBox(color: tokens.canvas, child: child);
  }
}

/// Fine monochrome editorial icon frame — crisp 1px border, zero shadows, zero multicolor gradients.
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
    this.size = 44,
    this.iconSize = 21,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.tokensOf(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final isGold = color == YitteColors.gold ||
        color == YitteColors.goldBright ||
        color == tokens.goldAccent;
    final fg = isGold
        ? tokens.goldAccent
        : (isDark ? primary : Theme.of(context).colorScheme.primary);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark ? tokens.canvas : tokens.subtleFill,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tokens.borderSubtle, width: 1),
      ),
      child: Center(
        child: customIcon != null
            ? IconTheme.merge(
                data: IconThemeData(color: fg, size: iconSize),
                child: customIcon!,
              )
            : Icon(
                icon,
                color: fg,
                size: iconSize,
              ),
      ),
    );
  }
}

/// Crisp architectural circular progress ring — zero blur glow.
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
    this.strokeWidth = 6,
    required this.color,
    this.trackColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final clamped = progress.clamp(0.0, 1.0);
    final reduced = yitteMotionReduced(context);
    final tokens = AppTheme.tokensOf(context);
    final bgTrack = trackColor ?? tokens.borderSubtle;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: clamped),
      duration: reduced ? Duration.zero : const Duration(milliseconds: 520),
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
    final arcPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, -math.pi / 2, sweep, false, arcPaint);
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter old) =>
      old.progress != progress || old.color != color || old.trackColor != trackColor;
}

/// Crisp editorial audio player bar with monochrome play button and flat 1px border.
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
    final tokens = AppTheme.tokensOf(context);
    final color = accentColor ?? Theme.of(context).colorScheme.primary;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onToggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: playing ? tokens.subtleFill : tokens.elevated,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: playing ? color : tokens.borderSubtle,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
              ),
              child: Icon(
                playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: _bars.asMap().entries.map((e) {
                final h = 5.0 + e.value * 14.0;
                final active = playing && e.key.isEven;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  width: 2.5,
                  height: active ? h * 1.12 : h,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(
                    color: playing ? color : tokens.borderSubtle,
                    borderRadius: BorderRadius.circular(2),
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
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Architectural 8-point Khatam geometric lattice with delicate hairline strokes.
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
      ..strokeWidth = 0.8;

    final haloPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;

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

/// Subtle, staggered editorial entrance animation with reduced-motion bypass.
class YitteReveal extends StatefulWidget {
  final Widget child;
  final int order;
  final Duration duration;

  const YitteReveal({
    super.key,
    required this.child,
    this.order = 0,
    this.duration = const Duration(milliseconds: 280),
  });

  @override
  State<YitteReveal> createState() => _YitteRevealState();
}

class _YitteRevealState extends State<YitteReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    final curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _opacity = curve;
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(curve);

    final delayMs = (widget.order.clamp(0, 8)) * 35;
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
        child: widget.child,
      ),
    );
  }
}

/// Custom-painted fine monochrome Islamic Salat / Du'a prayer icon inside an arch (mihrab).
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
      ..color = accentColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4 * s
      ..strokeCap = StrokeCap.round;

    final bodyPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.7 * s
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final arch = Path()
      ..moveTo(3.2 * s, 20.5 * s)
      ..lineTo(3.2 * s, 10.5 * s)
      ..quadraticBezierTo(3.2 * s, 4.2 * s, 12.0 * s, 1.8 * s)
      ..quadraticBezierTo(20.8 * s, 4.2 * s, 20.8 * s, 10.5 * s)
      ..lineTo(20.8 * s, 20.5 * s);
    canvas.drawPath(arch, goldPaint);

    canvas.drawLine(Offset(5.5 * s, 20.5 * s), Offset(18.5 * s, 20.5 * s), goldPaint);

    canvas.drawCircle(Offset(13.6 * s, 9.6 * s), 1.8 * s, fillPaint);

    final posture = Path()
      ..moveTo(13.2 * s, 12.0 * s)
      ..quadraticBezierTo(11.6 * s, 14.6 * s, 10.4 * s, 17.6 * s)
      ..lineTo(15.6 * s, 17.6 * s)
      ..moveTo(12.2 * s, 13.8 * s)
      ..lineTo(8.8 * s, 11.4 * s)
      ..lineTo(8.2 * s, 9.6 * s);
    canvas.drawPath(posture, bodyPaint);
  }

  @override
  bool shouldRepaint(covariant _SanctuaryPrayerPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.accentColor != accentColor;
}

/// Crisp concentric hairline pulse for spiritual Tasbīḥ (finite animation, zero blur shadow).
class YittePulseHalo extends StatefulWidget {
  final Widget child;
  final Color color;
  final double maxRadiusBlur;
  final Object? triggerKey;

  const YittePulseHalo({
    super.key,
    required this.child,
    required this.color,
    this.maxRadiusBlur = 24,
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
      duration: const Duration(milliseconds: 420),
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
          scale: 1.0 + (wave * 0.025),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: widget.color.withValues(alpha: 0.14 + (wave * 0.45)),
                width: 1,
              ),
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

/// Strict flat editorial surface card — crisp 1px border, elevation 0, zero blurry shadows.
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
    final reduced = yitteMotionReduced(context);
    final radius = tokens.cardRadius;

    final baseSurface = widget.color ?? tokens.elevated;
    final effectiveBorder = _hovered && widget.onTap != null
        ? tokens.goldAccent
        : (widget.borderColor ?? tokens.borderSubtle);

    final cardBody = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: reduced ? Duration.zero : const Duration(milliseconds: 140),
        curve: Curves.easeOutCubic,
        margin: widget.margin,
        decoration: BoxDecoration(
          color: baseSurface,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: effectiveBorder, width: 1),
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
      scale: _pressed ? 0.99 : 1.0,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOutCubic,
      child: cardBody,
    );
  }
}

/// Editorial status pill — clean 1px border, flat tint, zero shadow.
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
    final bg = backgroundColor ?? tokens.subtleFill;
    final fg = foregroundColor ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: tokens.borderSubtle, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13.5, color: fg),
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
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Sober editorial empty state with monochrome icon frame and direct CTA.
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
    final primary = Theme.of(context).colorScheme.primary;
    return YitteSurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          YitteIconBadge(
            icon: icon,
            color: primary,
            size: 48,
            iconSize: 22,
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

/// Subtle loading indicator banner for async transitions.
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
