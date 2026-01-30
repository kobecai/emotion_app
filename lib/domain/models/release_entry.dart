import 'emotion.dart';

class ReleaseEntry {
  final Emotion emotion;
  final double durationSeconds;
  final DateTime createdAt;
  final String? feedback;
  final String? note;

  const ReleaseEntry({
    required this.emotion,
    required this.durationSeconds,
    required this.createdAt,
    this.feedback,
    this.note,
  });

  Map<String, dynamic> toJson() {
    return {
      'emotion': emotion.name,
      'durationSeconds': durationSeconds,
      'createdAt': createdAt.toIso8601String(),
      'feedback': feedback,
      'note': note,
    };
  }

  factory ReleaseEntry.fromJson(Map<String, dynamic> json) {
    return ReleaseEntry(
      emotion: Emotion.values.firstWhere(
        (value) => value.name == json['emotion'],
        orElse: () => Emotion.sad,
      ),
      durationSeconds: (json['durationSeconds'] as num?)?.toDouble() ?? 0,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      feedback: json['feedback'] as String?,
      note: json['note'] as String?,
    );
  }
}
