import 'package:flutter/material.dart';
import '../../../../domain/models/emotion.dart';
import '../../../../domain/models/release_entry.dart';
import '../../../../data/analytics/posthog_analytics.dart';
import '../../../../data/local/app_settings.dart';
import '../../../core/themes/app_theme.dart';
import '../widgets/emotion_selector.dart';
import '../widgets/hold_release_button.dart';
import '../widgets/info_sheet.dart';
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
    _maybeShowSafetyDialog();
  }

  Future<void> _maybeShowSafetyDialog() async {
    final accepted = await AppSettings.getTermsAccepted();
    if (!mounted || accepted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          return AlertDialog(
            title: const Text('Before you begin'),
            content: const Text(
              'This app is not medical advice and not for emergencies. '
              'If you are in the U.S. and need immediate help, call or text 988.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Not now'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await showInfoSheet(context);
                },
                child: const Text('Details'),
              ),
              FilledButton(
                onPressed: () async {
                  await AppSettings.setTermsAccepted(true);
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                },
                child: const Text('I understand'),
              ),
            ],
          );
        },
      );
    });
  }

  void _onEmotionSelected(Emotion emotion) {
    setState(() {
      selectedEmotion = emotion;
    });
    PosthogAnalytics.instance.trackEmotionSelected(emotion.label);
  }

  Future<void> _navigateToAfterScreen(double duration) async {
    if (selectedEmotion == null) return;
    final emotion = selectedEmotion!;
    setState(() {
      selectedEmotion = null;
    });
    final result = await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            DoneScreen(emotion: emotion, duration: duration),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
    if (result is ReleaseEntry) {
      return;
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('LET GO', style: AppTheme.logoStyle),
                        IconButton(
                          onPressed: () => showInfoSheet(context),
                          icon: const Icon(Icons.info_outline),
                          color: AppTheme.textSecondary,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
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
                            : (seconds, releaseReason) {
                                PosthogAnalytics.instance.trackHoldReleased(
                                  emotionLabel: selectedEmotion!.label,
                                  durationSeconds: seconds,
                                  releaseReason: releaseReason,
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
