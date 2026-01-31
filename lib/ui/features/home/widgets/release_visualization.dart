import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../core/themes/app_theme.dart';

class ReleaseVisualization extends StatefulWidget {
  final double duration;
  final Duration startDelay;

  const ReleaseVisualization({
    super.key,
    required this.duration,
    this.startDelay = Duration.zero,
  });

  @override
  State<ReleaseVisualization> createState() => _ReleaseVisualizationState();
}

class _ReleaseVisualizationState extends State<ReleaseVisualization>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    if (widget.startDelay == Duration.zero) {
      _controller.forward();
    } else {
      Future.delayed(widget.startDelay, () {
        if (mounted) {
          _controller.forward();
        }
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
    final barCount = (widget.duration / 0.5).clamp(4, 10).toInt();
    const lifePhaseEnd = 700 / 1200;

    return SizedBox(
      height: 120,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(barCount, (index) {
          final delay = index * 0.08;
          final animation = CurvedAnimation(
            parent: _controller,
            curve: Interval(delay, 1.0, curve: Curves.easeOut),
          );

          final heights = [62.0, 90.0, 52.0, 102.0, 72.0, 86.0, 58.0, 96.0, 66.0, 80.0];
          final height = heights[index % heights.length];

          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              final t = animation.value;
              final lifeFactor = t < lifePhaseEnd
                  ? 1.0
                  : (1 - ((t - lifePhaseEnd) / (1 - lifePhaseEnd)))
                      .clamp(0.0, 1.0);
              final wave = math.sin((t * 8 * math.pi) + index * 0.6);
              final settle = Curves.easeOut.transform(t);
              final heightFactor = (1 + 0.12 * wave * lifeFactor).clamp(0.7, 1.3);

              return Container(
                width: 8,
                height: height * settle * heightFactor,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: AppTheme.accentColor.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
