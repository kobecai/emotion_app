import 'package:flutter/material.dart';
import '../../../core/themes/app_theme.dart';

class ReleaseVisualization extends StatefulWidget {
  final double duration;

  const ReleaseVisualization({super.key, required this.duration});

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
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final barCount = (widget.duration / 0.5).clamp(4, 10).toInt();

    return SizedBox(
      height: 120,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: List.generate(barCount, (index) {
          final delay = index * 0.1;
          final animation = Tween<double>(begin: 0, end: 1).animate(
            CurvedAnimation(
              parent: _controller,
              curve: Interval(delay, 1.0, curve: Curves.easeOut),
            ),
          );

          final heights = [62.0, 90.0, 52.0, 102.0, 72.0, 86.0, 58.0, 96.0, 66.0, 80.0];
          final height = heights[index % heights.length];

          return AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return Container(
                width: 8,
                height: height * animation.value,
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
