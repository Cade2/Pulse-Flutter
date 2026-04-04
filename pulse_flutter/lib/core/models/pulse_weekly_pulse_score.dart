import 'package:pulse_flutter/features/swipe_session/models/swipe_session_record.dart';

enum PulseWeeklyScoreTrendDirection { up, down, flat }

class PulseWeeklyPulseScoreTrend {
  const PulseWeeklyPulseScoreTrend({
    required this.currentScore,
    required this.previousScore,
  }) : delta = currentScore - previousScore,
       direction = currentScore > previousScore
           ? PulseWeeklyScoreTrendDirection.up
           : currentScore < previousScore
           ? PulseWeeklyScoreTrendDirection.down
           : PulseWeeklyScoreTrendDirection.flat;

  final int currentScore;
  final int previousScore;
  final int delta;
  final PulseWeeklyScoreTrendDirection direction;

  String get label {
    switch (direction) {
      case PulseWeeklyScoreTrendDirection.up:
        return '+$delta vs last week';
      case PulseWeeklyScoreTrendDirection.down:
        return '$delta vs last week';
      case PulseWeeklyScoreTrendDirection.flat:
        return 'No change vs last week';
    }
  }
}

class PulseWeeklyPulseScore {
  // Lightweight 0-100 emotion weights for the current Pulse starter catalog.
  // More grounded/uplifting emotions land higher, tender/heavier emotions land
  // lower, and sessions with no accepted emotions fall back to a neutral score.
  static const Map<String, int> _emotionWeights = <String, int>{
    'Calm': 88,
    'Joy': 92,
    'Focus': 74,
    'Hope': 80,
    'Confidence': 86,
    'Curiosity': 68,
    'Vulnerability': 44,
    'Overwhelm': 20,
  };
  static const int _neutralSessionScore = 50;
  static const int _unknownEmotionScore = 60;

  const PulseWeeklyPulseScore({
    required this.weekStart,
    this.score,
    this.sessionCount = 0,
    this.daysWithSessions = 0,
    this.acceptedEmotionCount = 0,
  });

  final DateTime weekStart;
  final int? score;
  final int sessionCount;
  final int daysWithSessions;
  final int acceptedEmotionCount;

  factory PulseWeeklyPulseScore.fromHistory(
    List<SwipeSessionRecord> sessions, {
    required DateTime weekStart,
  }) {
    final DateTime normalizedWeekStart = startOfWeek(weekStart);
    final DateTime weekEnd = normalizedWeekStart.add(const Duration(days: 7));
    final List<SwipeSessionRecord> weeklySessions = sessions
        .where((session) {
          final DateTime completedAt = _dateOnly(session.completedAt);
          return !completedAt.isBefore(normalizedWeekStart) &&
              completedAt.isBefore(weekEnd);
        })
        .toList(growable: false);

    if (weeklySessions.isEmpty) {
      return PulseWeeklyPulseScore(weekStart: normalizedWeekStart);
    }

    final Set<String> uniqueDays = weeklySessions
        .map(
          (session) => SwipeSessionRecord.sessionIdForDate(session.completedAt),
        )
        .toSet();
    final int acceptedEmotionCount = weeklySessions.fold(
      0,
      (sum, session) => sum + session.acceptedEmotions.length,
    );
    final List<int> sessionScores = weeklySessions
        .map(_sessionScoreFromAcceptedEmotions)
        .toList(growable: false);
    final int score =
        (sessionScores.reduce((a, b) => a + b) / sessionScores.length).round();

    return PulseWeeklyPulseScore(
      weekStart: normalizedWeekStart,
      score: score,
      sessionCount: weeklySessions.length,
      daysWithSessions: uniqueDays.length,
      acceptedEmotionCount: acceptedEmotionCount,
    );
  }

  bool get hasScore => score != null;

  String get scoreLabel => hasScore ? '${score!}' : '--';

  String get dataAvailabilityLabel =>
      '$daysWithSessions / 7 days checked in this week';

  String get dataAvailabilityMessage {
    if (sessionCount == 0) {
      return 'No sessions saved this week yet. Complete a Pulse session to start this week\'s signal.';
    }

    if (daysWithSessions == 1) {
      return '1 of 7 days checked in this week. Your weekly score is an early signal.';
    }

    if (daysWithSessions < 4) {
      return '$daysWithSessions of 7 days checked in this week. More daily check-ins will make the score steadier.';
    }

    return '$daysWithSessions of 7 days checked in this week. You have enough data for a steadier weekly signal.';
  }

  PulseWeeklyPulseScoreTrend? compareWith(PulseWeeklyPulseScore previousWeek) {
    if (!hasScore || !previousWeek.hasScore) {
      return null;
    }

    return PulseWeeklyPulseScoreTrend(
      currentScore: score!,
      previousScore: previousWeek.score!,
    );
  }

  static DateTime startOfWeek(DateTime value) {
    final DateTime normalized = _dateOnly(value);
    return normalized.subtract(
      Duration(days: normalized.weekday - DateTime.monday),
    );
  }

  static DateTime previousWeekStart(DateTime value) {
    return startOfWeek(value).subtract(const Duration(days: 7));
  }

  static int _sessionScoreFromAcceptedEmotions(SwipeSessionRecord session) {
    if (session.acceptedEmotions.isEmpty) {
      return _neutralSessionScore;
    }

    final List<int> emotionScores = session.acceptedEmotions
        .map(
          (emotion) => _emotionWeights[emotion.trim()] ?? _unknownEmotionScore,
        )
        .toList(growable: false);

    return (emotionScores.reduce((a, b) => a + b) / emotionScores.length)
        .round();
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
