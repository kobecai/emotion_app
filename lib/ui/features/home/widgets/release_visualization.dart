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
  late Animation<double> _appearAnimation;
  late Animation<double> _breatheAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _appearAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOut),
    );
    _breatheAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.45, 1.0, curve: Curves.easeInOut),
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
    const heights = [62.0, 90.0, 52.0, 102.0, 72.0, 86.0, 58.0, 96.0, 66.0, 80.0];

    return SizedBox(
      height: 120,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(barCount, (index) {
          final height = heights[index % heights.length];

          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final appear = _appearAnimation.value;
              final breathe = _breatheAnimation.value;
              final breatheScale = 1.06 - (0.06 * breathe);

              return Opacity(
                opacity: appear,
                child: Container(
                  width: 8,
                  height: height * appear * breatheScale,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.accentColor.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
