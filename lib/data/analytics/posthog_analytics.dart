import 'dart:convert';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class PosthogAnalytics {
  PosthogAnalytics._internal();

  static final PosthogAnalytics instance = PosthogAnalytics._internal();

  static const String _apiKey =
      'phc_258P7vnDroFF41mcfkMWwGJQGLfLHtINOq0TXnFg4mh';
  static const String _host = 'https://us.i.posthog.com';
  static const String _deviceIdKey = 'analytics_device_id';

  http.Client? _client;
  final Uuid _uuid = const Uuid();

  String? _deviceId;
  String? _sessionId;
  DateTime? _appStartTime;
  DateTime? _emotionSelectedTime;
  String? _currentHoldAttemptId;
  String _appVersion = 'unknown';
  String _appBuild = 'unknown';
  String _platform = 'unknown';
  String _osVersion = 'unknown';
  String _deviceModel = 'unknown';
  bool _initialized = false;
  bool _enabled = false;

  http.Client _ensureClient() {
    return _client ??= http.Client();
  }

  void _closeClient() {
    _client?.close();
    _client = null;
  }

  Future<void> init({required bool enabled}) async {
    if (_initialized) return;
    _enabled = enabled;
    if (!_enabled) {
      _initialized = true;
      return;
    }
    final prefs = await SharedPreferences.getInstance();
    final storedId = prefs.getString(_deviceIdKey);
    if (storedId != null && storedId.isNotEmpty) {
      _deviceId = storedId;
    } else {
      _deviceId = _uuid.v4();
      await prefs.setString(_deviceIdKey, _deviceId!);
    }
    await _loadAppAndDeviceContext();
    _initialized = true;
  }

  Future<void> setEnabled(bool enabled) async {
    final wasEnabled = _enabled;
    if (wasEnabled && !enabled) {
      _track(
        'analytics_disabled',
        properties: {'session_id': _sessionId, 'source': 'settings_toggle'},
      );
    }
    _enabled = enabled;
    if (!enabled) {
      _sessionId = null;
      _appStartTime = null;
      _emotionSelectedTime = null;
      _currentHoldAttemptId = null;
      _closeClient();
      return;
    }
    if (_deviceId == null) {
      final prefs = await SharedPreferences.getInstance();
      final storedId = prefs.getString(_deviceIdKey);
      if (storedId != null && storedId.isNotEmpty) {
        _deviceId = storedId;
      } else {
        _deviceId = _uuid.v4();
        await prefs.setString(_deviceIdKey, _deviceId!);
      }
    }
    await _loadAppAndDeviceContext();
    _initialized = true;
    if (!wasEnabled && enabled) {
      _sessionId ??= _uuid.v4();
      _appStartTime ??= DateTime.now();
      _track(
        'analytics_enabled',
        properties: {'session_id': _sessionId, 'source': 'settings_toggle'},
      );
    }
  }

  void dispose() {
    _enabled = false;
    _initialized = false;
    _sessionId = null;
    _appStartTime = null;
    _emotionSelectedTime = null;
    _closeClient();
  }

  void trackAppOpen() {
    _appStartTime = DateTime.now();
    _sessionId = _uuid.v4();
    _currentHoldAttemptId = null;
    _track(
      'app_open',
      properties: {'session_id': _sessionId, 'source': 'cold_start'},
    );
  }

  void trackEmotionSelected(String emotionLabel) {
    _emotionSelectedTime = DateTime.now();
    _track(
      'emotion_selected',
      properties: {
        'emotion': emotionLabel,
        'session_id': _sessionId,
        'since_app_open_ms': _msSince(_appStartTime),
      },
    );
  }

  void trackHoldStart({required String emotionLabel}) {
    final holdAttemptId = _uuid.v4();
    _currentHoldAttemptId = holdAttemptId;
    _track(
      'hold_start',
      properties: {
        'emotion': emotionLabel,
        'session_id': _sessionId,
        'hold_attempt_id': holdAttemptId,
        'since_app_open_ms': _msSince(_appStartTime),
        'since_emotion_selected_ms': _msSince(_emotionSelectedTime),
      },
    );
  }

  void trackHoldReleased({
    required String emotionLabel,
    required double durationSeconds,
    required String releaseReason,
  }) {
    final holdAttemptId = _currentHoldAttemptId ?? _uuid.v4();
    _track(
      'hold_released',
      properties: {
        'emotion': emotionLabel,
        'session_id': _sessionId,
        'hold_attempt_id': holdAttemptId,
        'release_reason': releaseReason,
        'duration_seconds': durationSeconds,
        'short_hold': durationSeconds < 2.0,
        'since_emotion_selected_ms': _msSince(_emotionSelectedTime),
      },
    );
    _currentHoldAttemptId = null;
  }

  void trackDoneScreenShown({
    required String emotionLabel,
    required double durationSeconds,
  }) {
    _track(
      'done_screen_shown',
      properties: {
        'emotion': emotionLabel,
        'session_id': _sessionId,
        'duration_seconds': durationSeconds,
      },
    );
  }

  void trackRememberCtaTapped({required String emotionLabel}) {
    _track(
      'remember_cta_tapped',
      properties: {
        'emotion': emotionLabel,
        'session_id': _sessionId,
        'since_app_open_ms': _msSince(_appStartTime),
      },
    );
  }

  void trackUpdateCardShown({
    String? installedVersion,
    String? storeVersion,
  }) {
    _track(
      'update_card_shown',
      properties: {
        'session_id': _sessionId,
        'installed_version': installedVersion,
        'store_version': storeVersion,
      },
    );
  }

  void trackUpdateLaterTapped({
    String? installedVersion,
    String? storeVersion,
  }) {
    _track(
      'update_later_tapped',
      properties: {
        'session_id': _sessionId,
        'installed_version': installedVersion,
        'store_version': storeVersion,
      },
    );
  }

  void trackUpdateNowTapped({
    String? installedVersion,
    String? storeVersion,
    String? storeUrl,
  }) {
    _track(
      'update_now_tapped',
      properties: {
        'session_id': _sessionId,
        'installed_version': installedVersion,
        'store_version': storeVersion,
        'store_url': storeUrl,
      },
    );
  }

  int? _msSince(DateTime? start) {
    if (start == null) return null;
    return DateTime.now().difference(start).inMilliseconds;
  }

  Future<void> _loadAppAndDeviceContext() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      _appVersion = packageInfo.version;
      _appBuild = packageInfo.buildNumber;
    } catch (_) {
      _appVersion = 'unknown';
      _appBuild = 'unknown';
    }

    _platform = defaultTargetPlatform.name;
    try {
      final deviceInfo = DeviceInfoPlugin();
      switch (defaultTargetPlatform) {
        case TargetPlatform.android:
          final info = await deviceInfo.androidInfo;
          _osVersion = info.version.release;
          _deviceModel = '${info.manufacturer} ${info.model}'.trim();
          break;
        case TargetPlatform.iOS:
          final info = await deviceInfo.iosInfo;
          _osVersion = info.systemVersion;
          _deviceModel = info.utsname.machine;
          break;
        case TargetPlatform.macOS:
          final info = await deviceInfo.macOsInfo;
          _osVersion = info.osRelease;
          _deviceModel = info.model;
          break;
        case TargetPlatform.windows:
          final info = await deviceInfo.windowsInfo;
          _osVersion = info.displayVersion;
          _deviceModel = info.computerName;
          break;
        case TargetPlatform.linux:
          final info = await deviceInfo.linuxInfo;
          _osVersion = info.version ?? 'unknown';
          _deviceModel = info.prettyName;
          break;
        case TargetPlatform.fuchsia:
          _osVersion = 'unknown';
          _deviceModel = 'unknown';
          break;
      }
    } catch (_) {
      _osVersion = 'unknown';
      _deviceModel = 'unknown';
    }
  }

  Future<void> _track(String event, {Map<String, dynamic>? properties}) async {
    if (!_initialized || !_enabled || _deviceId == null) return;

    final payload = <String, dynamic>{
      'api_key': _apiKey,
      'event': event,
      'properties': {
        'distinct_id': _deviceId,
        r'$lib': 'flutter',
        r'$lib_version': _appVersion,
        r'$timezone': DateTime.now().timeZoneName,
        r'$timestamp': DateTime.now().toIso8601String(),
        'app_version': _appVersion,
        'app_build': _appBuild,
        'platform': _platform,
        'os_version': _osVersion,
        'device_model': _deviceModel,
        if (properties != null) ...properties,
      },
    };

    try {
      final response = await _ensureClient().post(
        Uri.parse('$_host/capture'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 8));
      if (kDebugMode && response.statusCode >= 300) {
        debugPrint(
          'PostHog tracking failed: ${response.statusCode} ${response.body}',
        );
      }
    } catch (error) {
      if (kDebugMode) {
        debugPrint('PostHog tracking failed: $error');
      }
    }
  }
}
