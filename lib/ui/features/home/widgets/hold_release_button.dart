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
  DateTime? _pressStartTime;
  late final Ticker _holdTicker;
  final Stopwatch _holdStopwatch = Stopwatch();
  late final AnimationController _releaseController;
  Duration _lastTickElapsed = Duration.zero;
  double _rotationAngle = 0.0;

  double? _pendingReleaseSeconds;
  double _releaseStartRotation = 0.0;
  double _releaseStartRadius = 0.0;
  double _releaseStartOpacity = 0.0;
  double _releaseStartStroke = 0.0;

  static const double _ringSize = 200.0;
  static const double _ringInset = 10.0;
  static const double _baseRadius = _ringSize / 2 - _ringInset;
  static const double _baseStroke = 5.0;
  static const double _maxStrokeDelta = 2.0;
  static const double _opacityMax = 0.8;
  static const Duration _releaseDuration = Duration(milliseconds: 400);

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
          HapticFeedback.mediumImpact();
          if (seconds != null) {
            widget.onRelease(seconds);
          }
        }
      });
  }

  @override
  void dispose() {
    _holdTicker.dispose();
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
    if (!_holdTicker.isActive) {
      _holdTicker.start();
    }
  }

  void _onPressEnd() {
    if (_pressStartTime == null || !widget.isEnabled) return;

    final duration = DateTime.now().difference(_pressStartTime!);
    final seconds = duration.inMilliseconds / 1000.0;

    _holdStopwatch.stop();
    if (_holdTicker.isActive) {
      _holdTicker.stop();
    }

    final holdSeconds = _holdStopwatch.elapsedMilliseconds / 1000.0;
    _releaseStartRotation = _rotationAngle;
    _releaseStartRadius = _radiusForSeconds(holdSeconds);
    _releaseStartOpacity = _opacityForSeconds(holdSeconds);
    _releaseStartStroke = _strokeForSeconds(holdSeconds);

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
    const double baseRotationsPerSecond = 0.55;
    const double modulationAmplitude = 0.15;
    const double modulationPeriodSeconds = 6.0;
    final double baseSpeed = 2 * math.pi * baseRotationsPerSecond;

    final double modulation = 1.0 +
        modulationAmplitude *
            math.sin((2 * math.pi * t) / modulationPeriodSeconds);
    final double ramp = (t / 1.0).clamp(0.0, 1.0);
    final double easedRamp = Curves.easeOut.transform(ramp);

    return baseSpeed * modulation * (0.5 + 0.5 * easedRamp);
  }

  double _radiusForSeconds(double t) {
    final double phase = (2 * math.pi * t) / 4.5;
    return _baseRadius * (1 + 0.04 * math.sin(phase));
  }

  double _strokeForSeconds(double t) {
    final double thickT = ((t - 1.0) / 0.4).clamp(0.0, 1.0);
    return _baseStroke + _maxStrokeDelta * thickT;
  }

  double _opacityForSeconds(double t) {
    return math.min(_opacityMax, t / 0.8);
  }

  _RingVisual _currentRing() {
    if (_isPressed) {
      final double t = _holdStopwatch.elapsedMilliseconds / 1000.0;
      return _RingVisual(
        rotation: _rotationAngle,
        radius: _radiusForSeconds(t),
        strokeWidth: _strokeForSeconds(t),
        opacity: _opacityForSeconds(t),
      );
    }

    if (_isReleasing) {
      final double t = _releaseController.value;
      return _RingVisual(
        rotation: _releaseStartRotation,
        radius: lerpDouble(_releaseStartRadius, _baseRadius * 1.15, t) ??
            _releaseStartRadius,
        strokeWidth: _releaseStartStroke,
        opacity: lerpDouble(_releaseStartOpacity, 0.0, t) ??
            _releaseStartOpacity,
      );
    }

    return const _RingVisual(
      rotation: 0.0,
      radius: _baseRadius,
      strokeWidth: _baseStroke,
      opacity: 0.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (_isPressed)
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              'Keep holding…',
              style: AppTheme.subtleStyle.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
          ),
        Listener(
          onPointerDown: (_) => _onPressStart(),
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
                  : AppTheme.primaryColor.withValues(alpha: 0.4),
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
                  'HOLD TO\nRELEASE',
                  style: AppTheme.buttonTextStyle,
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

  const _RingVisual({
    required this.rotation,
    required this.radius,
    required this.strokeWidth,
    required this.opacity,
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

    const double sweep = 2 * math.pi * 0.78;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: ring.radius),
      -math.pi / 2 + ring.rotation,
      sweep,
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
