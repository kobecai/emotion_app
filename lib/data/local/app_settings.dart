import 'package:shared_preferences/shared_preferences.dart';

class AppSettings {
  static const String _analyticsEnabledKey = 'analytics_enabled';
  static const String _termsAcceptedKey = 'terms_accepted_v1';

  static Future<bool> getAnalyticsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_analyticsEnabledKey) ?? true;
  }

  static Future<void> setAnalyticsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_analyticsEnabledKey, enabled);
  }

  static Future<bool> getTermsAccepted() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_termsAcceptedKey) ?? false;
  }

  static Future<void> setTermsAccepted(bool accepted) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_termsAcceptedKey, accepted);
  }
}
