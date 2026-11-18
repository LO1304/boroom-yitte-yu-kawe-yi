import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';

import '../services/audio_service.dart';
import '../services/backend_repository.dart';
import '../services/speech_bridge.dart';
import '../theme/app_theme.dart';
import 'design_system.dart';

export 'design_studio_widget.dart';
export 'design_system.dart';

/// Custom subtle 8-pointed Islamic geometric star lattice ornament for editorial headers.
class GeometricOrnamentPainter extends CustomPainter {
  final Color color;
  GeometricOrnamentPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;

    final step = 54.0;
    for (double y = 0; y < size.height + step; y += step) {
      for (double x = 0; x < size.width + step; x += step) {
        _drawEightStar(canvas, Offset(x, y), 18, paint);
      }
    }
  }

  void _drawEightStar(Canvas canvas, Offset center, double r, Paint paint) {
    final path = Path();
    const points = 16;
    for (int i = 0; i <= points; i++) {
      final angle = (i * math.pi * 2) / points;
      final radius = i.isEven ? r : r * 0.48;
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
  bool shouldRepaint(covariant GeometricOrnamentPainter oldDelegate) =>
      oldDelegate.color != color;
}

class EditorialHeroBanner extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final List<Widget> actions;
  final Color? accentColor;

  const EditorialHeroBanner({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.actions = const [],
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.tokensOf(context);
    final model = tokens.visualModel;
    final radius = tokens.cardRadius;
    final primary = accentColor ?? Theme.of(context).colorScheme.primary;

    // Model 2: Apple/Notion clean minimal editorial card — zero heavy dark wall.
    if (model == UiVisualModel.editorialMinimal) {
      return Container(
        decoration: BoxDecoration(
          color: tokens.elevated,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: tokens.borderSubtle),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: primary, width: 4.5),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Text(
                        eyebrow.toUpperCase(),
                        style: TextStyle(
                          color: primary,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.9,
                        ),
                      ),
                    ),
                    if (trailing != null) ...[
                      const SizedBox(width: 10),
                      trailing!,
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 5),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (actions.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  Wrap(spacing: 10, runSpacing: 8, children: actions),
                ],
              ],
            ),
          ),
        ),
      );
    }

    final startColor = switch (model) {
      UiVisualModel.dynamicCommunity => accentColor ?? tokens.heroStart,
      UiVisualModel.glassLuxe =>
        accentColor != null ? Color.lerp(accentColor, tokens.heroStart, 0.35)! : tokens.heroStart,
      _ => tokens.heroStart,
    };
    final endColor = switch (model) {
      UiVisualModel.dynamicCommunity =>
        Color.lerp(startColor, tokens.goldAccent, 0.36) ?? tokens.heroEnd,
      UiVisualModel.glassLuxe =>
        Color.lerp(startColor, Colors.black, 0.42) ?? tokens.heroEnd,
      _ => tokens.heroEnd,
    };

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: startColor.withValues(alpha: 0.22),
            blurRadius: model == UiVisualModel.glassLuxe ? 26 : 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [startColor, endColor],
            ),
            border: Border.all(
              color: Colors.white.withValues(
                alpha: model == UiVisualModel.glassLuxe ? 0.20 : 0.14,
              ),
            ),
          ),
          child: Stack(
            children: [
              if (model == UiVisualModel.sanctuaryClassic)
                Positioned.fill(
                  child: CustomPaint(
                    painter: SanctuaryGeometryPainter(
                      strokeColor: tokens.goldAccent.withValues(alpha: 0.095),
                      accentColor: Colors.white.withValues(alpha: 0.035),
                    ),
                  ),
                )
              else ...[
                Positioned(
                  right: -34,
                  top: -38,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          tokens.goldAccent.withValues(alpha: 0.28),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: -24,
                  bottom: -48,
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.12),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ],
              Positioned(
                top: 0,
                left: 22,
                right: 22,
                child: Container(
                  height: 1.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.transparent,
                        Colors.white.withValues(alpha: 0.55),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.26),
                              ),
                            ),
                            child: Text(
                              eyebrow,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.7,
                              ),
                            ),
                          ),
                        ),
                        if (trailing != null) ...[
                          const SizedBox(width: 10),
                          trailing!,
                        ],
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      title,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: Colors.white,
                          ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.86),
                        fontSize: 13,
                        height: 1.44,
                      ),
                    ),
                    if (actions.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Wrap(spacing: 10, runSpacing: 8, children: actions),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final tokens = AppTheme.tokensOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Container(
            width: 3.5,
            height: 20,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [tokens.goldAccent, tokens.goldAccent.withValues(alpha: 0.35)],
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          if (actionLabel != null && onAction != null)
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!),
            ),
        ],
      ),
    );
  }
}

class RubricBar extends StatelessWidget {
  final String label;
  final double score;
  final double maxScore;

  const RubricBar({
    super.key,
    required this.label,
    required this.score,
    required this.maxScore,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = maxScore == 0 ? 0.0 : (score / maxScore).clamp(0.0, 1.0);
    final reduced = yitteMotionReduced(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
              ),
              Text(
                '${score.toStringAsFixed(1)} / ${maxScore.toStringAsFixed(0)}',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: ratio),
              duration: reduced ? Duration.zero : const Duration(milliseconds: 420),
              curve: Curves.easeOutCubic,
              builder: (_, animatedVal, _) => LinearProgressIndicator(
                value: animatedVal,
                minHeight: 8,
                backgroundColor:
                    Theme.of(context).colorScheme.primary.withValues(alpha: 0.11),
                valueColor: AlwaysStoppedAnimation<Color>(
                  ratio >= 0.75 ? YitteColors.emerald : YitteColors.gold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Real microphone voice recorder with explicit consent gate, playback, and optional live STT.
class ConsentVoiceRecorderCard extends StatefulWidget {
  final AudioService audioService;
  final int maxSeconds;
  final String prefix;
  final bool consentGranted;
  final ValueChanged<bool> onConsentChanged;
  final void Function(String? path, int durationSeconds) onRecorded;
  final ValueChanged<String>? onLiveTranscript;
  final String speechLocale;

  const ConsentVoiceRecorderCard({
    super.key,
    required this.audioService,
    this.maxSeconds = 180,
    required this.prefix,
    required this.consentGranted,
    required this.onConsentChanged,
    required this.onRecorded,
    this.onLiveTranscript,
    this.speechLocale = 'fr-FR',
  });

  @override
  State<ConsentVoiceRecorderCard> createState() =>
      _ConsentVoiceRecorderCardState();
}

class _ConsentVoiceRecorderCardState extends State<ConsentVoiceRecorderCard> {
  Timer? _timer;
  int _elapsed = 0;
  bool _recording = false;
  bool _uploading = false;
  bool _playing = false;
  bool _dictating = false;
  String? _recordedPath;
  String? _errorMessage;

  @override
  void dispose() {
    _timer?.cancel();
    if (_dictating) SpeechBridge.stopDictation();
    super.dispose();
  }

  Future<void> _startRecordingNow() async {
    try {
      setState(() => _errorMessage = null);
      await widget.audioService.startRecording(prefix: widget.prefix);
      bool dictating = false;
      if (widget.onLiveTranscript != null && SpeechBridge.isSttSupported) {
        dictating = SpeechBridge.startDictation(
          locale: widget.speechLocale,
          onTranscript: (t) => widget.onLiveTranscript?.call(t),
          onError: (_) {},
        );
      }
      if (!mounted) return;
      setState(() {
        _recording = true;
        _dictating = dictating;
        _elapsed = 0;
      });
      _timer = Timer.periodic(const Duration(seconds: 1), (t) {
        if (!mounted) return;
        setState(() => _elapsed++);
        if (_elapsed >= widget.maxSeconds) {
          _stopRecording();
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Microphone indisponible sur cet appareil : $e';
      });
    }
  }

  Future<void> _toggleRecording() async {
    if (_recording) {
      await _stopRecording();
      return;
    }

    if (!widget.consentGranted) {
      setState(() {
        _errorMessage =
            'Veuillez accorder votre consentement explicite avant d’enregistrer.';
      });
      return;
    }

    await _startRecordingNow();
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    if (_dictating) {
      SpeechBridge.stopDictation();
    }
    final path = await widget.audioService.stopRecording();
    if (!mounted) return;
    setState(() {
      _recording = false;
      _dictating = false;
      _recordedPath = path;
      _uploading = path != null;
    });

    var resolvedPath = path;
    if (path != null) {
      try {
        final bytes = await widget.audioService.readRecordedBytes(path);
        if (bytes != null && bytes.isNotEmpty) {
          final ext = path.endsWith('.m4a')
              ? 'm4a'
              : (path.endsWith('.wav') ? 'wav' : 'webm');
          final remoteUrl = await BackendRepository.instance.uploadAudioRecording(
            fileName: '${widget.prefix}_${DateTime.now().millisecondsSinceEpoch}.$ext',
            bytes: bytes,
          );
          if (remoteUrl != null && remoteUrl.isNotEmpty) {
            resolvedPath = remoteUrl;
          }
        }
      } catch (_) {}
    }

    if (!mounted) return;
    setState(() {
      _uploading = false;
      _recordedPath = resolvedPath;
    });
    widget.onRecorded(resolvedPath, _elapsed);
  }

  Future<void> _togglePlayback() async {
    if (_recordedPath == null) return;
    if (_playing) {
      await widget.audioService.stopPlayback();
      if (mounted) setState(() => _playing = false);
      return;
    }
    setState(() {
      _playing = true;
      _errorMessage = null;
    });
    try {
      await widget.audioService.playFile(
        _recordedPath!,
        onEnded: () {
          if (mounted) setState(() => _playing = false);
        },
        onError: (err) {
          if (mounted) {
            setState(() {
              _playing = false;
              _errorMessage = err;
            });
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _playing = false;
          _errorMessage = 'Impossible de lire cet audio : $e';
        });
      }
    }
  }

  String _formatDuration(int sec) {
    final m = (sec ~/ 60).toString().padLeft(2, '0');
    final s = (sec % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: widget.consentGranted,
              onChanged: (v) {
                final granted = v ?? false;
                if (granted && _errorMessage != null) {
                  setState(() => _errorMessage = null);
                }
                widget.onConsentChanged(granted);
              },
              title: const Text(
                'Consentement audio explicite',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
              ),
              subtitle: const Text(
                'J’autorise l’enregistrement vocal temporaire pour transcription STT et évaluation, selon ma politique de rétention.',
                style: TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                ElevatedButton.icon(
                  onPressed: _toggleRecording,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _recording
                        ? YitteColors.danger
                        : Theme.of(context).colorScheme.primary,
                  ),
                  icon: Icon(_recording ? Icons.stop_rounded : Icons.mic_rounded),
                  label: Text(_recording ? 'Arrêter' : 'Enregistrer (max 3 min)'),
                ),
                Text(
                  '${_formatDuration(_elapsed)} / ${_formatDuration(widget.maxSeconds)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
                if (_recordedPath != null && !_recording)
                  OutlinedButton.icon(
                    onPressed: _togglePlayback,
                    icon: Icon(_playing
                        ? Icons.stop_circle_outlined
                        : Icons.play_circle_fill_rounded),
                    label: Text(_playing ? 'Stop' : 'Réécouter'),
                  ),
                if (widget.onLiveTranscript != null && SpeechBridge.isSttSupported && !_recording)
                  TextButton.icon(
                    onPressed: () {
                      if (_dictating) {
                        SpeechBridge.stopDictation();
                        if (mounted) setState(() => _dictating = false);
                        return;
                      }
                      if (!widget.consentGranted) {
                        widget.onConsentChanged(true);
                      }
                      final ok = SpeechBridge.startDictation(
                        locale: widget.speechLocale,
                        onTranscript: (t) => widget.onLiveTranscript?.call(t),
                        onError: (e) {
                          if (mounted) {
                            setState(() {
                              _dictating = false;
                              _errorMessage = e;
                            });
                          }
                        },
                      );
                      if (ok && mounted) {
                        setState(() => _dictating = true);
                      }
                    },
                    icon: Icon(_dictating ? Icons.stop_circle_outlined : Icons.keyboard_voice_outlined, size: 18),
                    label: Text(_dictating ? 'Arrêter dictée' : 'Dicter'),
                  ),
              ],
            ),
            if (_recording)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: YitteStatusPill(
                  icon: Icons.graphic_eq_rounded,
                  label: _dictating
                      ? 'Enregistrement & dictée active — parlez distinctement'
                      : 'Captation micro en cours...',
                  backgroundColor: YitteColors.danger.withValues(alpha: 0.12),
                  foregroundColor: YitteColors.danger,
                ),
              ),
            if (!_recording && _dictating)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: YitteStatusPill(
                  icon: Icons.hearing_rounded,
                  label: 'Dictée vocale en direct active',
                ),
              ),
            if (_recordedPath != null && !_recording)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _uploading
                      ? 'Sauvegarde serveur du vocal (${_elapsed}s)...'
                      : 'Audio capturé (${_elapsed}s) prêt pour réécoute ou évaluation.',
                  style: const TextStyle(
                    color: YitteColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _errorMessage!,
                      style: const TextStyle(
                        color: YitteColors.danger,
                        fontSize: 12,
                      ),
                    ),
                    if (!widget.consentGranted)
                      TextButton.icon(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                        ),
                        onPressed: () async {
                          widget.onConsentChanged(true);
                          await _startRecordingNow();
                        },
                        icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                        label: const Text('Accepter le consentement et démarrer'),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
