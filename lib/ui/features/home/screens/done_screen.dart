import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../data/local/release_storage.dart';
import '../../../../data/analytics/posthog_analytics.dart';
import '../../../../domain/models/emotion.dart';
import '../../../../domain/models/release_entry.dart';
import '../../../core/themes/app_theme.dart';
import '../../history/screens/history_screen.dart';
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
  static const int _noteMaxLength = 150;
  static const int _minDoneEnableMs = 600;
  static const int _doneEnableFadeMs = 200;
  static const int _releaseVizStartDelayMs = 300;
  static const int _baseTimelineMs = 3200;
  static const int _autoExitDelayMs = 4500;
  static const Duration _exitFadeDuration = Duration(milliseconds: 140);
  static const Color _ctaColor = Color(0xFFD0D0D0);
  static const Color _doneBaseColor = Color(0xFFE0E0E0);
  static const Color _doneHoverColor = Color(0xFFCCCCCC);
  late int _timelineMs;
  late AnimationController _timelineController;
  late Animation<double> _titleAnimation;
  late Animation<double> _barsAnimation;
  late Animation<double> _subtextAnimation;
  late Animation<double> _rememberAnimation;
  late Animation<double> _doneAppearAnimation;
  late Animation<double> _doneEnableAnimation;
  final TextEditingController _noteController = TextEditingController();
  final ReleaseStorage _storage = ReleaseStorage();
  bool _entrySaved = false;
  bool _showNoteSavedHint = false;
  bool _hasUserInteracted = false;
  bool _isExiting = false;
  Timer? _autoExitTimer;
  Timer? _noteSavedTimer;
  ReleaseEntry? _savedEntry;

  @override
  void initState() {
    super.initState();
    PosthogAnalytics.instance.trackDoneScreenShown(
      emotionLabel: widget.emotion.label,
      durationSeconds: widget.duration,
    );
    const doneEnableStartMs = _minDoneEnableMs;
    _timelineMs = _computeTimelineMs(doneEnableStartMs);
    _timelineController = AnimationController(
      duration: Duration(milliseconds: _timelineMs),
      vsync: this,
    );

    _titleAnimation = _interval(0, 300, Curves.easeOutCubic);
    _barsAnimation = _interval(300, 600, Curves.easeOut);
    _subtextAnimation = _interval(0, 300, Curves.easeOut);
    _rememberAnimation = _interval(1200, 1500, Curves.easeOut);
    _doneAppearAnimation = _interval(600, 800, Curves.easeOut);
    _doneEnableAnimation = _interval(
      doneEnableStartMs,
      doneEnableStartMs + _doneEnableFadeMs,
      Curves.easeOut,
    );

    _timelineController.forward();
    _autoExitTimer = Timer(const Duration(milliseconds: _autoExitDelayMs), () {
      if (!mounted || _hasUserInteracted || _isExiting) return;
      _onDone();
    });
  }

  @override
  void dispose() {
    _autoExitTimer?.cancel();
    _noteSavedTimer?.cancel();
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
    if (_isExiting) return;
    _isExiting = true;
    if (mounted) {
      setState(() {});
    }
    _autoExitTimer?.cancel();
    await Future<void>.delayed(_exitFadeDuration);
    if (!mounted) return;
    final entry = _entrySaved
        ? _savedEntry
        : ReleaseEntry(
            emotion: widget.emotion,
            durationSeconds: widget.duration,
            createdAt: DateTime.now(),
            feedback: null,
            note: null,
          );
    if (!_entrySaved && entry != null) {
      await _storage.saveEntry(entry);
    }
    if (!mounted) return;
    Navigator.of(context).pop(entry);
  }

  Future<void> _openRememberModal() async {
    if (_entrySaved) return;
    PosthogAnalytics.instance.trackRememberCtaTapped(
      emotionLabel: widget.emotion.label,
    );
    final hasNotes = await _storage.hasNotes();
    if (!mounted) return;
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
        final parentContext = this.context;
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
                'Write a note',
                style: AppTheme.headingStyle.copyWith(fontSize: 18),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _noteController,
                minLines: 3,
                maxLines: 5,
                maxLength: _noteMaxLength,
                inputFormatters: [
                  LengthLimitingTextInputFormatter(_noteMaxLength),
                ],
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFFF5F5F5),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  counterText: '',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Color(0xFFE0E0E0), width: 1),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Color(0xFFE0E0E0), width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: AppTheme.primaryColor.withValues(alpha: 0.4),
                      width: 1,
                    ),
                  ),
                ),
                style: AppTheme.bodyStyle.copyWith(color: AppTheme.textPrimary),
              ),
              if (hasNotes) ...[
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    Future<void>.delayed(Duration.zero, () {
                      if (!parentContext.mounted) return;
                      Navigator.of(parentContext).push(
                        MaterialPageRoute(
                          builder: (_) => const HistoryScreen(),
                        ),
                      );
                    });
                  },
                  child: Text(
                    'Your moments',
                    style: AppTheme.captionStyle.copyWith(
                      color: const Color(0xFF888888),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _noteController,
                  builder: (context, value, _) {
                    final canSave = value.text.trim().isNotEmpty;
                    return TextButton(
                      onPressed: canSave
                          ? () async {
                              final trimmedNote = _noteController.text.trim();
                              final entry = ReleaseEntry(
                                emotion: widget.emotion,
                                durationSeconds: widget.duration,
                                createdAt: DateTime.now(),
                                feedback: null,
                                note: trimmedNote,
                              );
                              await _storage.saveEntry(entry);
                              if (mounted) {
                                setState(() {
                                  _entrySaved = true;
                                  _savedEntry = entry;
                                  _showNoteSavedHint = true;
                                });
                                _noteSavedTimer?.cancel();
                                _noteSavedTimer = Timer(
                                  const Duration(seconds: 1),
                                  () {
                                    if (!mounted) return;
                                    setState(() {
                                      _showNoteSavedHint = false;
                                    });
                                  },
                                );
                              }
                              if (context.mounted) {
                                Navigator.of(context).pop();
                              }
                            }
                          : null,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF888888),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        textStyle: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.6,
                        ),
                      ),
                      child: const Text('Save'),
                    );
                  },
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
        child: Listener(
          onPointerDown: (_) {
            if (_hasUserInteracted) return;
            setState(() {
              _hasUserInteracted = true;
            });
            _autoExitTimer?.cancel();
          },
          child: LayoutBuilder(
            builder: (context, constraints) {
              final availableHeight = constraints.maxHeight;
              final topGap = (availableHeight * 0.08).clamp(24.0, 80.0);
              final sectionGap = (availableHeight * 0.06).clamp(16.0, 32.0);
              final bottomGap = (availableHeight * 0.06).clamp(16.0, 64.0);

              return AnimatedOpacity(
                duration: _exitFadeDuration,
                curve: Curves.easeOut,
                opacity: _isExiting ? 0.0 : 1.0,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppTheme.pageHorizontalPadding,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: availableHeight),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: topGap),
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
                              startDelay: const Duration(
                                milliseconds: _releaseVizStartDelayMs,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: sectionGap),
                        AnimatedBuilder(
                          animation: _rememberAnimation,
                          builder: (context, child) {
                            final value = _isExiting
                                ? 0.0
                                : _rememberAnimation.value;
                            final opacity = value.clamp(0.0, 1.0);
                            return IgnorePointer(
                              ignoring: value == 0,
                              child: Opacity(
                                opacity: opacity,
                                child: child,
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 8),
                            child: _showNoteSavedHint
                                ? Text(
                                    '✓ Note saved',
                                    style: AppTheme.captionStyle.copyWith(
                                      color: _ctaColor,
                                    ),
                                  )
                                : TextButton.icon(
                                    onPressed: _entrySaved
                                        ? null
                                        : _openRememberModal,
                                    icon: Icon(
                                      Icons.edit_outlined,
                                      size: 14,
                                      color: _entrySaved
                                          ? _ctaColor.withValues(alpha: 0.45)
                                          : _ctaColor,
                                    ),
                                    label: Text(
                                      'Save a note',
                                      style: AppTheme.captionStyle.copyWith(
                                        color: _entrySaved
                                            ? _ctaColor.withValues(alpha: 0.45)
                                            : _ctaColor,
                                      ),
                                    ),
                                    style: TextButton.styleFrom(
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(0, 0),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ),
                          ),
                        ),
                        AnimatedBuilder(
                          animation: Listenable.merge([
                            _doneAppearAnimation,
                            _doneEnableAnimation,
                          ]),
                          builder: (context, _) {
                            final appearValue = _doneAppearAnimation.value;
                            final enableValue = _doneEnableAnimation.value;
                            final opacity =
                                (0.6 * appearValue + 0.4 * enableValue).clamp(
                                  0.0,
                                  1.0,
                                );
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
                                      style: ButtonStyle(
                                        backgroundColor:
                                            WidgetStateProperty.resolveWith<
                                              Color
                                            >((states) {
                                              if (states.contains(
                                                    WidgetState.hovered,
                                                  ) ||
                                                  states.contains(
                                                    WidgetState.pressed,
                                                  )) {
                                                return _doneHoverColor;
                                              }
                                              return _doneBaseColor;
                                            }),
                                        foregroundColor:
                                            WidgetStateProperty.all<Color>(
                                              AppTheme.textPrimary,
                                            ),
                                        overlayColor:
                                            WidgetStateProperty.all<Color>(
                                          Colors.transparent,
                                        ),
                                        shadowColor:
                                            WidgetStateProperty.all<Color>(
                                          Colors.transparent,
                                        ),
                                        surfaceTintColor:
                                            WidgetStateProperty.all<Color>(
                                          Colors.transparent,
                                        ),
                                        padding:
                                            WidgetStateProperty.all<EdgeInsets>(
                                          const EdgeInsets.symmetric(
                                            vertical: 18,
                                          ),
                                        ),
                                        shape: WidgetStateProperty.all(
                                          RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              28,
                                            ),
                                          ),
                                        ),
                                        elevation:
                                            WidgetStateProperty.all<double>(0),
                                        splashFactory: NoSplash.splashFactory,
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
                        SizedBox(height: bottomGap),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
