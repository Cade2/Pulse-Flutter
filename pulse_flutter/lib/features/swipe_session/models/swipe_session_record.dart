import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_summary.dart';

class SwipeSessionRecord {
  SwipeSessionRecord({
    required this.sessionId,
    required this.date,
    required this.completedAt,
    required this.responses,
    required this.acceptedEmotions,
    this.contextSocial,
    this.contextEnergy,
    this.contextSleep,
  });

  final String sessionId;
  final String date;
  final DateTime completedAt;
  final List<EmotionCardResponse> responses;
  final List<String> acceptedEmotions;
  final String? contextSocial;
  final String? contextEnergy;
  final String? contextSleep;

  factory SwipeSessionRecord.fromSummary({
    required SwipeSessionSummary summary,
    String? contextSocial,
    String? contextEnergy,
    String? contextSleep,
    DateTime? completedAt,
  }) {
    final DateTime timestamp = completedAt ?? DateTime.now();
    final String date = _formatDate(timestamp);

    return SwipeSessionRecord(
      sessionId: date,
      date: date,
      completedAt: timestamp,
      responses: List<EmotionCardResponse>.unmodifiable(summary.responses),
      acceptedEmotions: summary.acceptedEmotions,
      contextSocial: _trimToNull(contextSocial),
      contextEnergy: _trimToNull(contextEnergy),
      contextSleep: _trimToNull(contextSleep),
    );
  }

  int get acceptedCount => acceptedEmotions.length;

  int get rejectedCount => responses.length - acceptedCount;

  int get totalCards => responses.length;

  Map<String, Object?> toFirestore() {
    return <String, Object?>{
      'sessionId': sessionId,
      'date': date,
      'completedAt': Timestamp.fromDate(completedAt),
      'swipes': responses
          .map(
            (response) => <String, String>{
              'emotionId': response.card.id,
              'emotionTitle': response.card.title,
              'decision': response.decision.name,
            },
          )
          .toList(growable: false),
      'acceptedEmotions': acceptedEmotions,
      'contextSocial': contextSocial,
      'contextEnergy': contextEnergy,
      'contextSleep': contextSleep,
    };
  }

  static String _formatDate(DateTime value) {
    final String year = value.year.toString().padLeft(4, '0');
    final String month = value.month.toString().padLeft(2, '0');
    final String day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }

  static String? _trimToNull(String? value) {
    final String trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }
}
