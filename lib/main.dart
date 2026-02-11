import 'package:flutter/material.dart';
import 'data/analytics/posthog_analytics.dart';
import 'data/local/app_settings.dart';
import 'ui/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final analyticsEnabled = await AppSettings.getAnalyticsEnabled();
  await PosthogAnalytics.instance.init(enabled: analyticsEnabled);
  if (analyticsEnabled) {
    PosthogAnalytics.instance.trackAppOpen();
  }
  runApp(const LetGoApp());
}
