import 'package:flutter/material.dart';
import 'data/analytics/posthog_analytics.dart';
import 'data/local/app_settings.dart';
import 'ui/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final storedAnalyticsEnabled = await AppSettings.getAnalyticsEnabled();
  final analyticsEnabled = storedAnalyticsEnabled;
  await PosthogAnalytics.instance.init(enabled: analyticsEnabled);
  if (analyticsEnabled) {
    PosthogAnalytics.instance.trackAppOpen();
  }
  runApp(const LetGoApp());
}
