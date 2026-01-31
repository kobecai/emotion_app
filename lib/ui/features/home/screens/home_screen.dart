import 'package:flutter/material.dart';
import '../../../../domain/models/emotion.dart';
import '../../../../domain/models/release_entry.dart';
import '../../../../data/analytics/posthog_analytics.dart';
import '../../../core/themes/app_theme.dart';
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

  @override
  void initState() {
    super.initState();
  }

  void _onEmotionSelected(Emotion emotion) {
    setState(() {
      selectedEmotion = emotion;
    });
    PosthogAnalytics.instance.trackEmotionSelected(emotion.label);
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
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final availableHeight =
        MediaQuery.of(context).size.height -
        MediaQuery.of(context).padding.vertical;
    final isCompactHeight = availableHeight < 680;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final gapScale = isCompactHeight || isLandscape ? 0.08 : 0.12;
    final topGap = (availableHeight * gapScale).clamp(40.0, 140.0);
    final middleGap = (availableHeight * gapScale).clamp(48.0, 160.0);
    final bottomGap = (availableHeight * (gapScale - 0.02)).clamp(40.0, 140.0);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.pageHorizontalPadding,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.vertical,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: topGap),
                    EmotionSelector(
                      selectedEmotion: selectedEmotion,
                      onEmotionSelected: _onEmotionSelected,
                    ),
                    SizedBox(height: middleGap),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 200),
                        opacity: selectedEmotion != null ? 1.0 : 0.0,
                        child: const Text(
                          'Press and hold',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFFC0C0C0),
                            height: 1.4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.center,
                      child: HoldReleaseButton(
                        onRelease: _navigateToAfterScreen,
                        isEnabled: selectedEmotion != null,
                        onHoldStart: selectedEmotion == null
                            ? null
                            : () {
                                PosthogAnalytics.instance.trackHoldStart(
                                  emotionLabel: selectedEmotion!.label,
                                );
                              },
                        onHoldEnd: selectedEmotion == null
                            ? null
                            : (seconds) {
                                PosthogAnalytics.instance.trackHoldReleased(
                                  emotionLabel: selectedEmotion!.label,
                                  durationSeconds: seconds,
                                );
                              },
                      ),
                    ),
                    SizedBox(height: bottomGap),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
