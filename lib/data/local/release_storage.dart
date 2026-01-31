import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/models/emotion.dart';
import '../../domain/models/release_entry.dart';

class ReleaseStorage {
  static const _entriesKey = 'release_entries';
  static const _privacyHintSeenKey = 'release_privacy_hint_seen';

  Future<List<ReleaseEntry>> loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_entriesKey) ?? [];
    return raw
        .map(
          (entry) =>
              ReleaseEntry.fromJson(jsonDecode(entry) as Map<String, dynamic>),
        )
        .toList();
  }

  Future<ReleaseEntry?> loadLatest() async {
    final entries = await loadEntries();
    if (entries.isEmpty) return null;
    return entries.first;
  }

  Future<bool> hasNotes() async {
    final entries = await loadEntries();
    return entries.any((entry) => (entry.note?.trim() ?? '').isNotEmpty);
  }

  Future<ReleaseEntry?> findLatestMatchingNote({
    required Emotion emotion,
  }) async {
    final entries = await loadEntries();
    for (final entry in entries) {
      final note = entry.note?.trim() ?? '';
      if (note.isEmpty) continue;
      if (entry.emotion != emotion) continue;
      return entry;
    }
    return null;
  }

  Future<void> saveEntry(ReleaseEntry entry) async {
    final prefs = await SharedPreferences.getInstance();
    final entries = await loadEntries();
    final updated = [entry, ...entries];
    final encoded = updated
        .take(100)
        .map((item) => jsonEncode(item.toJson()))
        .toList();
    await prefs.setStringList(_entriesKey, encoded);
  }

  Future<bool> isPrivacyHintSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_privacyHintSeenKey) ?? false;
  }

  Future<void> markPrivacyHintSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_privacyHintSeenKey, true);
  }
}
