import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import '../../../core/themes/app_theme.dart';

class HoldReleaseButton extends StatefulWidget {
  final ValueChanged<double> onRelease;
  final bool isEnabled;

  const HoldReleaseButton({
    super.key,
    required this.onRelease,
    required this.isEnabled,
  });

  @override
  State<HoldReleaseButton> createState() => _HoldReleaseButtonState();
}

class _HoldReleaseButtonState extends State<HoldReleaseButton>
    with TickerProviderStateMixin {
  bool _isPressed = false;
  bool _isReleasing = false;
  bool _isDisabledPulse = false;
  DateTime? _pressStartTime;
  late final Ticker _holdTicker;
  final Stopwatch _holdStopwatch = Stopwatch();
  late final AnimationController _breathController;
  late final Animation<double> _breathScale;
  late final Animation<double> _breathOpacity;
  late final AnimationController _releaseController;
  Duration _lastTickElapsed = Duration.zero;
  double _rotationAngle = 0.0;

  double? _pendingReleaseSeconds;
  double _releaseStartRotation = 0.0;
  double _releaseStartRadius = 0.0;
  double _releaseStartOpacity = 0.0;
  double _releaseStartStroke = 0.0;
  double _releaseStartSweep = 0.0;

  static const double _ringSize = 200.0;
  static const double _ringInset = 10.0;
  static const double _baseRadius = _ringSize / 2 - _ringInset;
  static const double _baseStroke = 5.0;
  static const double _holdSweep = 2 * math.pi * 0.78;
  static const Duration _breathDuration = Duration(seconds: 12);
  static const Duration _releaseDuration = Duration(milliseconds: 400);
  static const Duration _releaseCloseDuration = Duration(milliseconds: 120);
  static const double _breathScaleMax = 1.12;
  static const double _breathOpacityMin = 0.6;
  static const double _breathOpacityMax = 0.75;
  static const double _releaseScaleMin = 0.85;
  static const double _rotationCycleSeconds = 6.0;
  static const double _rotationStage1Seconds = 0.6;
  static const double _rotationStage2Seconds = 1.8;
  static const double _rotationStage3Seconds = 1.2;
  static const double _rotationStage4Seconds = 2.4;
  static const double _rotationStartDegPerSec = 80.0;
  static const double _rotationPeakDegPerSec = 160.0;
  static const double _rotationMidLowDegPerSec = 70.0;
  static const double _rotationMidHighDegPerSec = 140.0;
  static const double _rotationEndDegPerSec = 60.0;
  static const Duration _disabledPulseDuration = Duration(milliseconds: 120);


  @override
  void initState() {
    super.initState();
    _holdTicker = createTicker((elapsed) {
      if (!mounted) return;
      if (_isPressed) {
        final double dtSeconds = (elapsed - _lastTickElapsed).inMicroseconds /
            Duration.microsecondsPerSecond;
        if (dtSeconds > 0) {
          final double tSeconds =
              _holdStopwatch.elapsedMilliseconds / 1000.0;
          _rotationAngle += _rotationSpeedForSeconds(tSeconds) * dtSeconds;
          _lastTickElapsed = elapsed;
        }
      }
      if (_isPressed || _isReleasing) {
        setState(() {});
      }
    });
    _breathController = AnimationController(
      vsync: this,
      duration: _breathDuration,
    );
    _breathScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: _breathScaleMax)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 4,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(_breathScaleMax),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: _breathScaleMax, end: 1.0)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 6,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(1.0),
        weight: 1,
      ),
    ]).animate(_breathController);
    _breathOpacity = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: _breathOpacityMin, end: _breathOpacityMax)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 4,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(_breathOpacityMax),
        weight: 1,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: _breathOpacityMax, end: _breathOpacityMin)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 6,
      ),
      TweenSequenceItem(
        tween: ConstantTween<double>(_breathOpacityMin),
        weight: 1,
      ),
    ]).animate(_breathController)
      ..addListener(() {
        if (mounted && _isPressed) {
          setState(() {});
        }
      });
    _releaseController = AnimationController(
      vsync: this,
      duration: _releaseDuration,
    )
      ..addListener(() {
        if (mounted) {
          setState(() {});
        }
      })
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          if (mounted) {
            setState(() {
              _isReleasing = false;
            });
          }
          final seconds = _pendingReleaseSeconds;
          _pendingReleaseSeconds = null;
          if (seconds != null) {
            widget.onRelease(seconds);
          }
        }
      });
  }

  @override
  void dispose() {
    _holdTicker.dispose();
    _breathController.dispose();
    _releaseController.dispose();
    super.dispose();
  }

  void _onPressStart() {
    if (!widget.isEnabled) return;
    setState(() {
      _isPressed = true;
      _isReleasing = false;
      _pressStartTime = DateTime.now();
    });
    _holdStopwatch
      ..reset()
      ..start();
    _lastTickElapsed = Duration.zero;
    _rotationAngle = 0.0;
    _breathController
      ..value = 0.0
      ..repeat();
    if (!_holdTicker.isActive) {
      _holdTicker.start();
    }
  }

  void _onDisabledTap() {
    HapticFeedback.selectionClick();
    if (_isDisabledPulse) return;
    setState(() {
      _isDisabledPulse = true;
    });
    Future<void>.delayed(_disabledPulseDuration, () {
      if (!mounted) return;
      setState(() {
        _isDisabledPulse = false;
      });
    });
  }

  void _onPressEnd() {
    if (_pressStartTime == null || !widget.isEnabled) return;

    final duration = DateTime.now().difference(_pressStartTime!);
    final seconds = duration.inMilliseconds / 1000.0;

    _holdStopwatch.stop();
    if (_holdTicker.isActive) {
      _holdTicker.stop();
    }
    _breathController.stop();

    final holdSeconds = _holdStopwatch.elapsedMilliseconds / 1000.0;
    _releaseStartRotation = _rotationAngle;
    _releaseStartRadius = _radiusForSeconds(holdSeconds);
    _releaseStartOpacity = _opacityForSeconds(holdSeconds);
    _releaseStartStroke = _strokeForSeconds(holdSeconds);
    _releaseStartSweep = _holdSweep;

    HapticFeedback.lightImpact();

    setState(() {
      _isPressed = false;
      _isReleasing = true;
    });

    _pendingReleaseSeconds = seconds;
    _releaseController.forward(from: 0.0);

    _pressStartTime = null;
  }

  double _rotationSpeedForSeconds(double t) {
    final double phase = t % _rotationCycleSeconds;
    double speedDeg;
    if (phase <= _rotationStage1Seconds) {
      final double p = (phase / _rotationStage1Seconds).clamp(0.0, 1.0);
      speedDeg = lerpDouble(
            _rotationStartDegPerSec,
            _rotationPeakDegPerSec,
            Curves.easeOut.transform(p),
          ) ??
          _rotationPeakDegPerSec;
    } else if (phase <= _rotationStage1Seconds + _rotationStage2Seconds) {
      final double p =
          ((phase - _rotationStage1Seconds) / _rotationStage2Seconds)
              .clamp(0.0, 1.0);
      speedDeg = lerpDouble(
            _rotationPeakDegPerSec,
            _rotationMidLowDegPerSec,
            Curves.easeInOut.transform(p),
          ) ??
          _rotationMidLowDegPerSec;
    } else if (phase <=
        _rotationStage1Seconds + _rotationStage2Seconds + _rotationStage3Seconds) {
      final double p =
          ((phase - _rotationStage1Seconds - _rotationStage2Seconds) /
                  _rotationStage3Seconds)
              .clamp(0.0, 1.0);
      speedDeg = lerpDouble(
            _rotationMidLowDegPerSec,
            _rotationMidHighDegPerSec,
            Curves.easeInOut.transform(p),
          ) ??
          _rotationMidHighDegPerSec;
    } else {
      final double p =
          ((phase - _rotationStage1Seconds - _rotationStage2Seconds -
                      _rotationStage3Seconds) /
                  _rotationStage4Seconds)
              .clamp(0.0, 1.0);
      speedDeg = lerpDouble(
            _rotationMidHighDegPerSec,
            _rotationEndDegPerSec,
            Curves.easeInOut.transform(p),
          ) ??
          _rotationEndDegPerSec;
    }
    return speedDeg * math.pi / 180.0;
  }

  double _radiusForSeconds(double t) {
    final double scale = _breathScale.value;
    return _baseRadius * scale;
  }

  double _strokeForSeconds(double t) {
    return _baseStroke;
  }

  double _opacityForSeconds(double t) {
    return _breathOpacity.value;
  }

  _RingVisual _currentRing() {
    if (_isPressed) {
      final double t = _holdStopwatch.elapsedMilliseconds / 1000.0;
      return _RingVisual(
        rotation: _rotationAngle,
        radius: _radiusForSeconds(t),
        strokeWidth: _strokeForSeconds(t),
        opacity: _opacityForSeconds(t),
        sweep: _holdSweep,
      );
    }

    if (_isReleasing) {
      final double t = _releaseController.value;
      final double closePhaseT =
          (_releaseCloseDuration.inMilliseconds / _releaseDuration.inMilliseconds)
              .clamp(0.0, 1.0);
      if (t <= closePhaseT && closePhaseT > 0) {
        final double easedT =
            Curves.easeOutCubic.transform((t / closePhaseT).clamp(0.0, 1.0));
        return _RingVisual(
          rotation: _releaseStartRotation,
          radius: _releaseStartRadius,
          strokeWidth: _releaseStartStroke,
          opacity: _releaseStartOpacity,
          sweep: lerpDouble(_releaseStartSweep, 2 * math.pi, easedT) ??
              _releaseStartSweep,
        );
      }
      final double collapseT =
          ((t - closePhaseT) / (1 - closePhaseT)).clamp(0.0, 1.0);
      return _RingVisual(
        rotation: _releaseStartRotation,
        radius: lerpDouble(
                _releaseStartRadius, _baseRadius * _releaseScaleMin, collapseT) ??
            _releaseStartRadius,
        strokeWidth: lerpDouble(_releaseStartStroke, 0.0, collapseT) ??
            _releaseStartStroke,
        opacity: lerpDouble(_releaseStartOpacity, 0.0, collapseT) ??
            _releaseStartOpacity,
        sweep: 2 * math.pi,
      );
    }

    return const _RingVisual(
      rotation: 0.0,
      radius: _baseRadius,
      strokeWidth: _baseStroke,
      opacity: 0.0,
      sweep: 0.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Listener(
          onPointerDown: (_) {
            if (widget.isEnabled) {
              _onPressStart();
            } else {
              _onDisabledTap();
            }
          },
          onPointerUp: (_) => _onPressEnd(),
          onPointerCancel: (_) => _onPressEnd(),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: _ringSize,
            height: _ringSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: widget.isEnabled
                  ? (_isPressed
                        ? AppTheme.primaryColor.withValues(alpha: 0.9)
                        : AppTheme.primaryColor)
                  : AppTheme.primaryColor.withValues(
                      alpha: _isDisabledPulse ? 0.34 : 0.4,
                    ),
              boxShadow: _isPressed || !widget.isEnabled
                  ? []
                  : [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.3),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
            ),
            transform: Matrix4.diagonal3Values(
              _isPressed ? 0.96 : 1.0,
              _isPressed ? 0.96 : 1.0,
              1.0,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(_ringSize, _ringSize),
                  painter: _ProgressRingPainter(
                    ring: _currentRing(),
                    isActive: _isPressed || _isReleasing,
                  ),
                ),
                const Text(
                  'HOLD',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.2,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RingVisual {
  final double rotation;
  final double radius;
  final double strokeWidth;
  final double opacity;
  final double sweep;

  const _RingVisual({
    required this.rotation,
    required this.radius,
    required this.strokeWidth,
    required this.opacity,
    required this.sweep,
  });
}

class _ProgressRingPainter extends CustomPainter {
  final _RingVisual ring;
  final bool isActive;

  const _ProgressRingPainter({required this.ring, required this.isActive});

  @override
  void paint(Canvas canvas, Size size) {
    if (!isActive || ring.opacity <= 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final ringPaint = Paint()
      ..color = AppTheme.accentColor.withValues(alpha: ring.opacity)
      ..style = PaintingStyle.stroke
      ..strokeWidth = ring.strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: ring.radius),
      -math.pi / 2 + ring.rotation,
      ring.sweep,
      false,
      ringPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ProgressRingPainter oldDelegate) {
    return oldDelegate.ring.rotation != ring.rotation ||
        oldDelegate.ring.radius != ring.radius ||
        oldDelegate.ring.strokeWidth != ring.strokeWidth ||
        oldDelegate.ring.opacity != ring.opacity ||
        oldDelegate.isActive != isActive;
  }
}
