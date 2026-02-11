import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:upgrader/upgrader.dart';
import '../../../../domain/models/emotion.dart';
import '../../../../data/analytics/posthog_analytics.dart';
import '../../../../data/local/app_settings.dart';
import '../../../core/themes/app_theme.dart';
import '../widgets/emotion_selector.dart';
import '../widgets/hold_release_button.dart';
import '../widgets/info_sheet.dart';
import 'done_screen.dart';

// Debug-only switch for manually testing upgrader UI.
const bool _debugForceShowUpgradeCard = false;

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Emotion? selectedEmotion;
  late final Upgrader _upgrader;
  bool _canShowUpdateCard = false;
  bool _hasCompletedReleaseThisSession = false;
  bool _upgraderReady = false;
  bool _dismissedUpdateCardForSession = false;
  bool _didTrackUpdateCardShown = false;
  bool get _isDebugForcedUpgradeCard =>
      kDebugMode && _debugForceShowUpgradeCard;
  bool get _isUpgradeCardEnabledByReleaseFlow =>
      _canShowUpdateCard && _hasCompletedReleaseThisSession;
  bool get _isUpgradeCardEnabledForCurrentSession =>
      !_dismissedUpdateCardForSession &&
      (_isUpgradeCardEnabledByReleaseFlow || _isDebugForcedUpgradeCard);
  bool get _hasStoreVersion =>
      (_upgrader.currentAppStoreVersion?.isNotEmpty ?? false);
  bool get _canRenderUpgradeCardForNormalUser =>
      _isUpgradeCardEnabledByReleaseFlow && _hasStoreVersion;
  bool get _shouldRenderUpgradeCard {
    if (!_upgraderReady || !_isUpgradeCardEnabledForCurrentSession) {
      return false;
    }
    if (_isDebugForcedUpgradeCard) return true;
    return _canRenderUpgradeCardForNormalUser;
  }

  bool _shouldTrackUpgradeCardShown({required bool display}) {
    if (!display || _didTrackUpdateCardShown) return false;
    return _isUpgradeCardEnabledForCurrentSession;
  }

  @override
  void initState() {
    super.initState();
    _upgrader = Upgrader(
      countryCode: 'US',
      languageCode: 'en',
      durationUntilAlertAgain:
          _isDebugForcedUpgradeCard ? Duration.zero : const Duration(days: 7),
      debugDisplayAlways: _isDebugForcedUpgradeCard,
      debugLogging: _isDebugForcedUpgradeCard,
      messages: _GentleUpgradeMessages(),
      willDisplayUpgrade: ({
        required bool display,
        String? installedVersion,
        UpgraderVersionInfo? versionInfo,
      }) {
        if (!_shouldTrackUpgradeCardShown(display: display)) return;
        _didTrackUpdateCardShown = true;
        PosthogAnalytics.instance.trackUpdateCardShown(
          installedVersion: installedVersion,
          storeVersion: versionInfo?.appStoreVersion?.toString(),
        );
      },
    );
    _initializeUpgraderAndEvaluate();
    _maybeShowSafetyDialog();
    _loadUpdateCardVisibility();
  }

  Future<void> _initializeUpgraderAndEvaluate() async {
    await _upgrader.initialize();
    if (!mounted) return;
    setState(() {
      _upgraderReady = true;
    });
  }

  Future<void> _loadUpdateCardVisibility() async {
    final completed = await AppSettings.getHasCompletedFirstRelease();
    if (!mounted) return;
    setState(() {
      _canShowUpdateCard = completed;
    });
  }

  Future<void> _markFirstReleaseCompleted() async {
    if (_canShowUpdateCard && _hasCompletedReleaseThisSession) return;
    if (!_canShowUpdateCard) {
      await AppSettings.setHasCompletedFirstRelease(true);
    }
    if (!mounted) return;
    setState(() {
      _hasCompletedReleaseThisSession = true;
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

  void _dismissUpdateCardForSession() {
    if (_dismissedUpdateCardForSession) return;
    setState(() {
      _dismissedUpdateCardForSession = true;
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
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            DoneScreen(emotion: emotion, duration: duration),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
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
        child: Stack(
          children: [
            SingleChildScrollView(
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
            if (_shouldRenderUpgradeCard)
              Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppTheme.pageHorizontalPadding,
                    topGap + 52,
                    AppTheme.pageHorizontalPadding,
                    0,
                  ),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 560),
                    child: UpgradeCard(
                      upgrader: _upgrader,
                      margin: EdgeInsets.zero,
                      showIgnore: false,
                      showLater: true,
                      showReleaseNotes: false,
                      onLater: () {
                        _dismissUpdateCardForSession();
                        PosthogAnalytics.instance.trackUpdateLaterTapped(
                          installedVersion: _upgrader.currentInstalledVersion,
                          storeVersion: _upgrader.currentAppStoreVersion,
                        );
                      },
                      onUpdate: () {
                        _dismissUpdateCardForSession();
                        PosthogAnalytics.instance.trackUpdateNowTapped(
                          installedVersion: _upgrader.currentInstalledVersion,
                          storeVersion: _upgrader.currentAppStoreVersion,
                          storeUrl: _upgrader.currentAppStoreListingURL,
                        );
                        return true;
                      },
                    ),
                  ),
                ),
              ),
          ],
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
