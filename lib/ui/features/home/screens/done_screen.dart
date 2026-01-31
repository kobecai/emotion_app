import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../../../../data/local/release_storage.dart';
import '../../../../domain/models/emotion.dart';
import '../../../../domain/models/release_entry.dart';
import '../../../core/themes/app_theme.dart';
import '../widgets/feedback_button.dart';
import '../widgets/release_visualization.dart';

class DoneScreen extends StatefulWidget {
  final Emotion emotion;
  final double duration;

  const DoneScreen({super.key, required this.emotion, required this.duration});

  @override
  State<DoneScreen> createState() => _DoneScreenState();
}

class _DoneScreenState extends State<DoneScreen>
    with SingleTickerProviderStateMixin {
  static const int _minDoneEnableMs = 1200;
  static const int _doneEnableFadeMs = 200;
  static const int _releaseVizStartDelayMs = 300;
  static const int _baseTimelineMs = 3200;
  late int _timelineMs;
  late AnimationController _timelineController;
  late Animation<double> _titleAnimation;
  late Animation<double> _barsAnimation;
  late Animation<double> _subtextAnimation;
  late Animation<double> _questionAnimation;
  late Animation<double> _rememberAnimation;
  late Animation<double> _doneAppearAnimation;
  late Animation<double> _doneEnableAnimation;
  String? _selectedFeedback;
  final TextEditingController _noteController = TextEditingController();
  final ReleaseStorage _storage = ReleaseStorage();
  bool _noteSaved = false;

  @override
  void initState() {
    super.initState();
    final doneEnableStartMs = _computeDoneEnableStartMs();
    _timelineMs = _computeTimelineMs(doneEnableStartMs);
    _timelineController = AnimationController(
      duration: Duration(milliseconds: _timelineMs),
      vsync: this,
    );

    _titleAnimation = _interval(0, 300, Curves.easeOutCubic);
    _barsAnimation = _interval(300, 600, Curves.easeOut);
    _subtextAnimation = _interval(0, 300, Curves.easeOut);
    _questionAnimation = _interval(1200, 1450, Curves.easeOut);
    _rememberAnimation = _interval(2500, 3000, Curves.easeOut);
    _doneAppearAnimation = _interval(1100, 1300, Curves.easeOut);
    _doneEnableAnimation = _interval(
      doneEnableStartMs,
      doneEnableStartMs + _doneEnableFadeMs,
      Curves.easeOut,
    );

    _timelineController.forward();
  }

  @override
  void dispose() {
    _timelineController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Animation<double> _interval(int startMs, int endMs, Curve curve) {
    final start = (startMs / _timelineMs).clamp(0.0, 1.0);
    final end = (endMs / _timelineMs).clamp(0.0, 1.0);
    return CurvedAnimation(
      parent: _timelineController,
      curve: Interval(start, end, curve: curve),
    );
  }

  int _computeDoneEnableStartMs() {
    return _minDoneEnableMs;
  }

  int _computeTimelineMs(int doneEnableStartMs) {
    final endMs = doneEnableStartMs + _doneEnableFadeMs;
    return math.max(_baseTimelineMs, endMs).toInt();
  }

  Widget _buildStaged({
    required Animation<double> animation,
    required double offsetY,
    required Widget child,
    double maxOpacity = 1.0,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, _) {
        final value = animation.value;
        final opacity = (value * maxOpacity).clamp(0.0, 1.0);
        return IgnorePointer(
          ignoring: value == 0,
          child: Opacity(
            opacity: opacity,
            child: Transform.translate(
              offset: Offset(0, (1 - value) * offsetY),
              child: child,
            ),
          ),
        );
      },
      child: child,
    );
  }

  Future<void> _onDone() async {
    final trimmedNote = _noteController.text.trim();
    final entry = ReleaseEntry(
      emotion: widget.emotion,
      durationSeconds: widget.duration,
      createdAt: DateTime.now(),
      feedback: _selectedFeedback,
      note: trimmedNote.isEmpty ? null : trimmedNote,
    );
    await _storage.saveEntry(entry);
    if (!mounted) return;
    Navigator.of(context).pop(entry);
  }

  Future<void> _openRememberModal() async {
    if (_noteSaved) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      barrierColor: Colors.black.withValues(alpha: 0.12),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final bottomInset = MediaQuery.of(context).viewInsets.bottom;
        return Padding(
          padding: EdgeInsets.only(
            left: AppTheme.pageHorizontalPadding,
            right: AppTheme.pageHorizontalPadding,
            top: 20,
            bottom: 24 + bottomInset,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'For next time',
                style: AppTheme.captionStyle.copyWith(
                  fontSize: 12,
                  color: AppTheme.textSecondary.withValues(alpha: 0.8),
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Shown only when you feel this again.',
                style: AppTheme.captionStyle.copyWith(
                  color: AppTheme.textSecondary.withValues(alpha: 0.75),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _noteController,
                minLines: 3,
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'This will pass.',
                  hintStyle: AppTheme.bodyStyle.copyWith(
                    color: AppTheme.textSecondary.withValues(alpha: 0.5),
                    fontStyle: FontStyle.italic,
                  ),
                  filled: true,
                  fillColor: AppTheme.background,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.black.withValues(alpha: 0.05),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppTheme.primaryColor.withValues(alpha: 0.4),
                    ),
                  ),
                ),
                style: AppTheme.bodyStyle.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    if (mounted) {
                      setState(() {
                        _noteSaved = true;
                      });
                    }
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.pageHorizontalPadding,
          ),
          child: Column(
            children: [
              const Spacer(),
              _buildStaged(
                animation: _titleAnimation,
                offsetY: 6,
                child: const Text(
                  'You let it out.',
                  style: AppTheme.headingStyle,
                  textAlign: TextAlign.center,
                ),
              ),
              _buildStaged(
                animation: _subtextAnimation,
                offsetY: 4,
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Text(
                    'You held onto ${widget.emotion.label} for ${widget.duration.toStringAsFixed(1)} seconds.',
                    style: AppTheme.bodyStyle.copyWith(fontSize: 17),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              _buildStaged(
                animation: _barsAnimation,
                offsetY: 4,
                child: Padding(
                  padding: const EdgeInsets.only(top: 28),
                  child: ReleaseVisualization(
                    duration: widget.duration,
                    startDelay:
                        const Duration(milliseconds: _releaseVizStartDelayMs),
                  ),
                ),
              ),
              _buildStaged(
                animation: _questionAnimation,
                offsetY: 0,
                child: const Padding(
                  padding: EdgeInsets.only(top: 40),
                  child: Text('How do you feel now?', style: AppTheme.bodyStyle),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  alignment: WrapAlignment.center,
                  children: [
                    _buildStaged(
                      animation: _interval(1500, 1750, Curves.easeOut),
                      offsetY: 8,
                      child: FeedbackButton(
                        label: 'Lighter',
                        isSelected: _selectedFeedback == 'Lighter',
                        onTap: () {
                          setState(() {
                            _selectedFeedback = 'Lighter';
                          });
                        },
                      ),
                    ),
                    _buildStaged(
                      animation: _interval(1580, 1830, Curves.easeOut),
                      offsetY: 8,
                      child: FeedbackButton(
                        label: 'Same',
                        isSelected: _selectedFeedback == 'Same',
                        onTap: () {
                          setState(() {
                            _selectedFeedback = 'Same';
                          });
                        },
                      ),
                    ),
                    _buildStaged(
                      animation: _interval(1660, 1910, Curves.easeOut),
                      offsetY: 8,
                      child: FeedbackButton(
                        label: 'Still heavy',
                        isSelected: _selectedFeedback == 'Still heavy',
                        onTap: () {
                          setState(() {
                            _selectedFeedback = 'Still heavy';
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
              _buildStaged(
                animation: _rememberAnimation,
                offsetY: 0,
                child: Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: TextButton(
                    onPressed: _noteSaved ? null : _openRememberModal,
                    style: TextButton.styleFrom(
                      foregroundColor: _noteSaved
                          ? AppTheme.textSecondary.withValues(alpha: 0.35)
                          : AppTheme.textSecondary.withValues(alpha: 0.7),
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      _noteSaved
                          ? 'Saved for next time'
                          : 'A note for your future self',
                      style: AppTheme.captionStyle.copyWith(
                        fontSize: 14,
                        color: _noteSaved
                            ? AppTheme.textSecondary.withValues(alpha: 0.35)
                            : AppTheme.textSecondary.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ),
              ),
              const Spacer(),
              AnimatedBuilder(
                animation: Listenable.merge([
                  _doneAppearAnimation,
                  _doneEnableAnimation,
                ]),
                builder: (context, _) {
                  final appearValue = _doneAppearAnimation.value;
                  final enableValue = _doneEnableAnimation.value;
                  final opacity = (0.6 * appearValue + 0.4 * enableValue)
                      .clamp(0.0, 1.0);
                  final isEnabled = enableValue >= 1.0;
                  return IgnorePointer(
                    ignoring: !isEnabled,
                    child: Opacity(
                      opacity: opacity,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isEnabled ? _onDone : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Done',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
