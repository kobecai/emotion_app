import 'package:flutter/material.dart';
import '../../../../data/analytics/posthog_analytics.dart';
import '../../../../data/local/app_settings.dart';
import '../../../core/themes/app_theme.dart';

Future<void> showInfoSheet(BuildContext context) async {
  final analyticsEnabled = await AppSettings.getAnalyticsEnabled();
  if (!context.mounted) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppTheme.background,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) {
      bool localAnalyticsEnabled = analyticsEnabled;

      return StatefulBuilder(
        builder: (context, setState) {
          final bottomInset = MediaQuery.of(context).padding.bottom;
          return Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, bottomInset + 24),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppTheme.pillUnselected,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Safety & Privacy', style: AppTheme.headingStyle),
                  const SizedBox(height: 16),
                  Text(
                    'This app is not medical advice and not for emergencies. '
                    'If you are in the U.S. and need immediate help, call or text 988.',
                    style: AppTheme.bodyStyle,
                  ),
                  const SizedBox(height: 20),
                  Text('Privacy', style: AppTheme.subtleStyle),
                  const SizedBox(height: 8),
                  Text(
                    'Your release entries are stored locally on your device. '
                    'If analytics are enabled, we send anonymous usage events '
                    'without your notes or personal identifiers.',
                    style: AppTheme.captionStyle,
                  ),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Share anonymous analytics'),
                    subtitle: const Text('Helps improve the app experience.'),
                    value: localAnalyticsEnabled,
                    onChanged: (value) async {
                      await AppSettings.setAnalyticsEnabled(value);
                      await PosthogAnalytics.instance.setEnabled(value);
                      setState(() => localAnalyticsEnabled = value);
                    },
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'By using this app, you agree to the Terms of Use and Privacy Policy.',
                    style: AppTheme.captionStyle,
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}
