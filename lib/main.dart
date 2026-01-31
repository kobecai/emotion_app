import 'package:flutter/material.dart';
import 'data/analytics/posthog_analytics.dart';
import 'ui/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await PosthogAnalytics.instance.init();
  PosthogAnalytics.instance.trackAppOpen();
  runApp(const LetGoApp());
}
