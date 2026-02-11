import 'package:flutter/material.dart';
import 'package:upgrader/upgrader.dart';
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
  late final Upgrader _upgrader;
  bool _canShowUpdateCard = false;
  bool _didTrackUpdateCardShown = false;

  @override
  void initState() {
    super.initState();
    _upgrader = Upgrader(
      countryCode: 'US',
      languageCode: 'en',
      durationUntilAlertAgain: const Duration(days: 7),
      messages: _GentleUpgradeMessages(),
      willDisplayUpgrade: ({
        required bool display,
        String? installedVersion,
        UpgraderVersionInfo? versionInfo,
      }) {
        if (!display || !_canShowUpdateCard || _didTrackUpdateCardShown) {
          return;
        }
        _didTrackUpdateCardShown = true;
        PosthogAnalytics.instance.trackUpdateCardShown(
          installedVersion: installedVersion,
          storeVersion: versionInfo?.appStoreVersion?.toString(),
        );
      },
    );
    _maybeShowSafetyDialog();
    _loadUpdateCardVisibility();
  }

  Future<void> _loadUpdateCardVisibility() async {
    final completed = await AppSettings.getHasCompletedFirstRelease();
    if (!mounted) return;
    setState(() {
      _canShowUpdateCard = completed;
    });
  }

  Future<void> _markFirstReleaseCompleted() async {
    if (_canShowUpdateCard) return;
    await AppSettings.setHasCompletedFirstRelease(true);
    if (!mounted) return;
    setState(() {
      _canShowUpdateCard = true;
    });
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
    await _markFirstReleaseCompleted();
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
                    if (_canShowUpdateCard)
                      Container(
                        margin: const EdgeInsets.only(top: 12),
                        child: UpgradeCard(
                          upgrader: _upgrader,
                          showIgnore: false,
                          showLater: true,
                          showReleaseNotes: false,
                          onLater: () {
                            PosthogAnalytics.instance.trackUpdateLaterTapped(
                              installedVersion: _upgrader.currentInstalledVersion,
                              storeVersion: _upgrader.currentAppStoreVersion,
                            );
                          },
                          onUpdate: () {
                            PosthogAnalytics.instance.trackUpdateNowTapped(
                              installedVersion: _upgrader.currentInstalledVersion,
                              storeVersion: _upgrader.currentAppStoreVersion,
                              storeUrl: _upgrader.currentAppStoreListingURL,
                            );
                            return true;
                          },
                        ),
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

class _GentleUpgradeMessages extends UpgraderMessages {
  @override
  String get title => 'A small update is available';

  @override
  String get body =>
      'Version {{currentAppStoreVersion}} is available. '
      'You are on {{currentInstalledVersion}}.';

  @override
  String get prompt => 'Update anytime for the latest improvements.';

  @override
  String get buttonTitleLater => 'Not now';

  @override
  String get buttonTitleUpdate => 'Update';
}
