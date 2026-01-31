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
  static const int _timelineMs = 6300;
  late AnimationController _timelineController;
  late Animation<double> _titleAnimation;
  late Animation<double> _barsAnimation;
  late Animation<double> _subtextAnimation;
  late Animation<double> _questionAnimation;
  late Animation<double> _promptAnimation;
  late Animation<double> _inputAnimation;
  late Animation<double> _helperAnimation;
  late Animation<double> _doneAppearAnimation;
  late Animation<double> _doneEnableAnimation;
  String? _selectedFeedback;
  final TextEditingController _noteController = TextEditingController();
  final ReleaseStorage _storage = ReleaseStorage();
  bool _showHelper = false;

  @override
  void initState() {
    super.initState();
    _timelineController = AnimationController(
      duration: const Duration(milliseconds: _timelineMs),
      vsync: this,
    );

    _titleAnimation = _interval(300, 700, Curves.easeOutCubic);
    _barsAnimation = _interval(300, 700, Curves.easeOut);
    _subtextAnimation = _interval(1200, 1550, Curves.easeOut);
    _questionAnimation = _interval(2600, 2900, Curves.easeOut);
    _promptAnimation = _interval(4200, 4500, Curves.easeOut);
    _inputAnimation = _interval(4700, 5000, Curves.easeOut);
    _helperAnimation = _interval(5200, 5400, Curves.easeOut);
    _doneAppearAnimation = _interval(3400, 3700, Curves.easeOut);
    _doneEnableAnimation = _interval(6000, 6300, Curves.easeOut);

    _timelineController.forward();
    _loadHelperVisibility();
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

  Future<void> _loadHelperVisibility() async {
    final seen = await _storage.isPrivacyHintSeen();
    if (!mounted) return;
    setState(() {
      _showHelper = !seen;
    });
    if (!seen) {
      await _storage.markPrivacyHintSeen();
    }
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
                    startDelay: const Duration(milliseconds: 300),
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
                      animation: _interval(3000, 3250, Curves.easeOut),
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
                      animation: _interval(3080, 3330, Curves.easeOut),
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
                      animation: _interval(3160, 3410, Curves.easeOut),
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
                animation: _promptAnimation,
                offsetY: 0,
                child: const Padding(
                  padding: EdgeInsets.only(top: 28),
                  child: Text(
                    'Anything you want to remember for next time?',
                    style: AppTheme.bodyStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              _buildStaged(
                animation: _inputAnimation,
                offsetY: 6,
                child: Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: TextField(
                    controller: _noteController,
                    maxLength: 80,
                    maxLines: 1,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      hintText: 'This will pass.',
                      hintStyle: AppTheme.bodyStyle.copyWith(
                        color: AppTheme.textSecondary.withValues(alpha: 0.5),
                        fontStyle: FontStyle.italic,
                      ),
                      counterText: '',
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.transparent),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(color: Colors.transparent),
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
                ),
              ),
              SizedBox(
                height: 20,
                child: Visibility(
                  visible: _showHelper,
                  maintainSize: true,
                  maintainAnimation: true,
                  maintainState: true,
                  child: _buildStaged(
                    animation: _helperAnimation,
                    offsetY: 0,
                    maxOpacity: 0.5,
                    child: const Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text('Only shown to you.', style: AppTheme.captionStyle),
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
