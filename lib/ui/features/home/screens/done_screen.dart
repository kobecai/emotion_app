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
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  String? _selectedFeedback;
  final TextEditingController _noteController = TextEditingController();
  bool _showNotePrompt = false;
  final ReleaseStorage _storage = ReleaseStorage();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );

    _animController.forward();
    Future.delayed(const Duration(milliseconds: 2200), () {
      if (!mounted) return;
      setState(() {
        _showNotePrompt = true;
      });
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _noteController.dispose();
    super.dispose();
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
              ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  children: [
                    const Text(
                      'You let it out.',
                      style: AppTheme.headingStyle,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'You held onto ${widget.emotion.label} for ${widget.duration.toStringAsFixed(1)} seconds.',
                      style: AppTheme.bodyStyle.copyWith(fontSize: 17),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Even a small release counts.',
                      style: AppTheme.captionStyle,
                    ),
                    const SizedBox(height: 28),
                    ReleaseVisualization(duration: widget.duration),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              const Text('How do you feel now?', style: AppTheme.bodyStyle),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  FeedbackButton(
                    label: 'Lighter',
                    isSelected: _selectedFeedback == 'Lighter',
                    onTap: () {
                      setState(() {
                        _selectedFeedback = 'Lighter';
                      });
                    },
                  ),
                  FeedbackButton(
                    label: 'Same',
                    isSelected: _selectedFeedback == 'Same',
                    onTap: () {
                      setState(() {
                        _selectedFeedback = 'Same';
                      });
                    },
                  ),
                  FeedbackButton(
                    label: 'Still heavy',
                    isSelected: _selectedFeedback == 'Still heavy',
                    onTap: () {
                      setState(() {
                        _selectedFeedback = 'Still heavy';
                      });
                    },
                  ),
                ],
              ),
              if (_showNotePrompt) ...[
                const SizedBox(height: 28),
                const Text(
                  'Anything you want to remember for next time?',
                  style: AppTheme.bodyStyle,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                TextField(
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
                const SizedBox(height: 6),
                const Text('Only shown to you.', style: AppTheme.captionStyle),
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _onDone,
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
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
