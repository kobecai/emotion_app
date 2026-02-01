import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class PosthogAnalytics {
  PosthogAnalytics._internal();

  static final PosthogAnalytics instance = PosthogAnalytics._internal();

  static const String _apiKey =
      'phc_258P7vnDroFF41mcfkMWwGJQGLfLHtINOq0TXnFg4mh';
  static const String _host = 'https://us.i.posthog.com';
  static const String _deviceIdKey = 'analytics_device_id';

  final http.Client _client = http.Client();
  final Uuid _uuid = const Uuid();

  String? _deviceId;
  String? _sessionId;
  DateTime? _appStartTime;
  DateTime? _emotionSelectedTime;
  bool _initialized = false;
  bool _enabled = false;

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
    _initialized = true;
  }

  Future<void> setEnabled(bool enabled) async {
    _enabled = enabled;
    if (!_enabled) return;
    if (_deviceId != null) return;
    final prefs = await SharedPreferences.getInstance();
    final storedId = prefs.getString(_deviceIdKey);
    if (storedId != null && storedId.isNotEmpty) {
      _deviceId = storedId;
    } else {
      _deviceId = _uuid.v4();
      await prefs.setString(_deviceIdKey, _deviceId!);
    }
  }

  void trackAppOpen() {
    _appStartTime = DateTime.now();
    _sessionId = _uuid.v4();
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
    _track(
      'hold_start',
      properties: {
        'emotion': emotionLabel,
        'session_id': _sessionId,
        'since_app_open_ms': _msSince(_appStartTime),
        'since_emotion_selected_ms': _msSince(_emotionSelectedTime),
      },
    );
  }

  void trackHoldReleased({
    required String emotionLabel,
    required double durationSeconds,
  }) {
    _track(
      'hold_released',
      properties: {
        'emotion': emotionLabel,
        'session_id': _sessionId,
        'duration_seconds': durationSeconds,
        'short_hold': durationSeconds < 2.0,
        'since_emotion_selected_ms': _msSince(_emotionSelectedTime),
      },
    );
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

  int? _msSince(DateTime? start) {
    if (start == null) return null;
    return DateTime.now().difference(start).inMilliseconds;
  }

  Future<void> _track(String event, {Map<String, dynamic>? properties}) async {
    if (!_initialized || !_enabled || _deviceId == null) return;

    final payload = <String, dynamic>{
      'api_key': _apiKey,
      'event': event,
      'properties': {
        'distinct_id': _deviceId,
        r'$lib': 'flutter',
        r'$lib_version': '1.0.0',
        r'$timezone': DateTime.now().timeZoneName,
        r'$timestamp': DateTime.now().toIso8601String(),
        if (properties != null) ...properties,
      },
    };

    try {
      await _client.post(
        Uri.parse('$_host/capture'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
    } catch (error) {
      if (kDebugMode) {
        debugPrint('PostHog tracking failed: $error');
      }
    }
  }
}
