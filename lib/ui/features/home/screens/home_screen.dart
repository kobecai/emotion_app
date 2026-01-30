import 'package:flutter/material.dart';
import '../../../../data/local/release_storage.dart';
import '../../../../domain/models/emotion.dart';
import '../../../../domain/models/release_entry.dart';
import '../../../core/themes/app_theme.dart';
import '../../history/screens/history_screen.dart';
import '../widgets/emotion_selector.dart';
import '../widgets/hold_release_button.dart';
import 'done_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Emotion? selectedEmotion;
  String? _matchingNote;
  final ReleaseStorage _storage = ReleaseStorage();

  @override
  void initState() {
    super.initState();
  }

  void _onEmotionSelected(Emotion emotion) {
    setState(() {
      selectedEmotion = emotion;
    });
    _loadMatchingNote();
  }

  Future<void> _loadMatchingNote() async {
    final emotion = selectedEmotion;
    if (emotion == null) {
      if (!mounted) return;
      setState(() {
        _matchingNote = null;
      });
      return;
    }
    final match = await _storage.findLatestMatchingNote(emotion: emotion);
    if (!mounted) return;
    setState(() {
      _matchingNote = match?.note;
    });
  }

  Future<void> _navigateToAfterScreen(double duration) async {
    if (selectedEmotion == null) return;
    final result = await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            DoneScreen(emotion: selectedEmotion!, duration: duration),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
    if (result is ReleaseEntry) {
      setState(() {
        selectedEmotion = null;
        _matchingNote = null;
      });
    }
  }

  void _openHistory() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const HistoryScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.pageHorizontalPadding,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight:
                  MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.vertical,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('LETGO', style: AppTheme.logoStyle),
                    TextButton(
                      onPressed: _openHistory,
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.textSecondary,
                        textStyle: AppTheme.captionStyle,
                      ),
                      child: const Text('Your moments'),
                    ),
                  ],
                ),
                const SizedBox(height: 36),
                const Text(
                  'How are you feeling?',
                  style: AppTheme.headingStyle,
                ),
                const SizedBox(height: 24),
                EmotionSelector(
                  selectedEmotion: selectedEmotion,
                  onEmotionSelected: _onEmotionSelected,
                ),
                if (_matchingNote != null && _matchingNote!.isNotEmpty) ...[
                  const SizedBox(height: 18),
                  const Text(
                    'Last time you felt this way, you told yourself:',
                    style: AppTheme.captionStyle,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '“${_matchingNote!}”',
                    style: AppTheme.captionStyle.copyWith(
                      fontStyle: FontStyle.italic,
                      color: AppTheme.textSecondary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                if (selectedEmotion != null)
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Hold to let it out',
                      style: AppTheme.captionStyle,
                    ),
                  ),
                const SizedBox(height: 24),
                Align(
                  alignment: Alignment.center,
                  child: HoldReleaseButton(
                    onRelease: _navigateToAfterScreen,
                    isEnabled: selectedEmotion != null,
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
