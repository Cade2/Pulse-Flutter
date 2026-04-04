import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pulse_flutter/features/swipe_session/models/emotion_card.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_summary.dart';

class SwipeSessionRecord {
  static const Color _fallbackAccentColor = Color(0xFF2ED3E6);

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
    final String date = sessionIdForDate(timestamp);

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

  factory SwipeSessionRecord.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final Map<String, dynamic> data = snapshot.data() ?? <String, dynamic>{};
    final List<EmotionCardResponse> responses = _readResponses(data['swipes']);
    final List<String> acceptedEmotions = _readStringList(
      data['acceptedEmotions'],
    );
    final DateTime completedAt =
        _readTimestamp(data['completedAt']) ?? DateTime.now();

    return SwipeSessionRecord(
      sessionId: _readString(data['sessionId']) ?? snapshot.id,
      date: _readString(data['date']) ?? _formatDate(completedAt),
      completedAt: completedAt,
      responses: responses,
      acceptedEmotions: acceptedEmotions,
      contextSocial: _readString(data['contextSocial']),
      contextEnergy: _readString(data['contextEnergy']),
      contextSleep: _readString(data['contextSleep']),
    );
  }

  int get acceptedCount => acceptedEmotions.length;

  int get rejectedCount => responses.length - acceptedCount;

  int get totalCards => responses.length;

  List<String> get contextTags {
    return <String>[
      if (contextSocial != null) 'Social: $contextSocial',
      if (contextEnergy != null) 'Energy: $contextEnergy',
      if (contextSleep != null) 'Sleep: $contextSleep',
    ];
  }

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

  static String sessionIdForDate(DateTime value) {
    return _formatDate(value);
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

  static String? _readString(Object? value) {
    if (value is! String) {
      return null;
    }

    return _trimToNull(value);
  }

  static DateTime? _readTimestamp(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    return null;
  }

  static List<String> _readStringList(Object? value) {
    if (value is! List) {
      return const <String>[];
    }

    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }

  static List<EmotionCardResponse> _readResponses(Object? value) {
    if (value is! List) {
      return const <EmotionCardResponse>[];
    }

    return value
        .whereType<Map<Object?, Object?>>()
        .map((entry) {
          final String emotionId = _readString(entry['emotionId']) ?? 'unknown';
          final String emotionTitle =
              _readString(entry['emotionTitle']) ?? 'Unknown';
          final String decisionValue =
              _readString(entry['decision']) ?? 'reject';

          final EmotionCardDecision decision = decisionValue == 'accept'
              ? EmotionCardDecision.accept
              : EmotionCardDecision.reject;

          return EmotionCardResponse(
            card: EmotionCard(
              id: emotionId,
              title: emotionTitle,
              headline: emotionTitle,
              description: '',
              reflectionPrompt: '',
              accentColor: _fallbackAccentColor,
            ),
            decision: decision,
          );
        })
        .toList(growable: false);
  }
}
