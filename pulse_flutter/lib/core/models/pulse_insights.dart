import 'package:pulse_flutter/features/swipe_session/models/swipe_session_record.dart';

enum PulseInsightsAvailability { locked, basic, expanded }

class PulseInsightCount {
  const PulseInsightCount({required this.label, required this.count});

  final String label;
  final int count;

  String get countText => count == 1 ? '1 time' : '$count times';
}

class PulseInsightPattern {
  const PulseInsightPattern({
    required this.emotion,
    required this.contextTag,
    required this.count,
  });

  final String emotion;
  final String contextTag;
  final int count;

  String get countText => count == 1 ? '1 saved match' : '$count saved matches';
}

class PulseInsightsReport {
  static const int basicUnlockSessionCount = 5;
  static const int expandedUnlockSessionCount = 14;

  const PulseInsightsReport({
    this.totalSessions = 0,
    this.totalAcceptedEmotions = 0,
    this.acceptedEmotionFrequency = const <PulseInsightCount>[],
    this.commonContextTags = const <PulseInsightCount>[],
    this.socialContexts = const <PulseInsightCount>[],
    this.energyTags = const <PulseInsightCount>[],
    this.sleepTags = const <PulseInsightCount>[],
    this.weekdaySessions = const <PulseInsightCount>[],
    this.emotionContextPatterns = const <PulseInsightPattern>[],
  });

  final int totalSessions;
  final int totalAcceptedEmotions;
  final List<PulseInsightCount> acceptedEmotionFrequency;
  final List<PulseInsightCount> commonContextTags;
  final List<PulseInsightCount> socialContexts;
  final List<PulseInsightCount> energyTags;
  final List<PulseInsightCount> sleepTags;
  final List<PulseInsightCount> weekdaySessions;
  final List<PulseInsightPattern> emotionContextPatterns;

  factory PulseInsightsReport.fromSessions(List<SwipeSessionRecord> sessions) {
    final List<PulseInsightCount> acceptedEmotionFrequency = _countValues(
      sessions.expand((session) => session.acceptedEmotions),
    );
    final List<PulseInsightCount> commonContextTags = _countValues(
      sessions.expand((session) => session.contextTags),
    );
    final List<PulseInsightCount> socialContexts = _countValues(
      sessions.map((session) => session.contextSocial),
    );
    final List<PulseInsightCount> energyTags = _countValues(
      sessions.map((session) => session.contextEnergy),
    );
    final List<PulseInsightCount> sleepTags = _countValues(
      sessions.map((session) => session.contextSleep),
    );
    final List<PulseInsightCount> weekdaySessions = _countValues(
      sessions.map((session) => _weekdayLabel(session.completedAt.weekday)),
    );
    final List<PulseInsightPattern> emotionContextPatterns =
        _countEmotionContextPatterns(sessions);

    return PulseInsightsReport(
      totalSessions: sessions.length,
      totalAcceptedEmotions: sessions.fold(
        0,
        (sum, session) => sum + session.acceptedEmotions.length,
      ),
      acceptedEmotionFrequency: acceptedEmotionFrequency,
      commonContextTags: commonContextTags,
      socialContexts: socialContexts,
      energyTags: energyTags,
      sleepTags: sleepTags,
      weekdaySessions: weekdaySessions,
      emotionContextPatterns: emotionContextPatterns,
    );
  }

  PulseInsightsAvailability get availability {
    if (totalSessions >= expandedUnlockSessionCount) {
      return PulseInsightsAvailability.expanded;
    }

    if (totalSessions >= basicUnlockSessionCount) {
      return PulseInsightsAvailability.basic;
    }

    return PulseInsightsAvailability.locked;
  }

  bool get hasBasicInsights => availability != PulseInsightsAvailability.locked;

  bool get hasExpandedInsights =>
      availability == PulseInsightsAvailability.expanded;

  int get sessionsUntilBasic => _remainingSessions(basicUnlockSessionCount);

  int get sessionsUntilExpanded =>
      _remainingSessions(expandedUnlockSessionCount);

  double get averageAcceptedPerSession {
    if (totalSessions == 0) {
      return 0;
    }

    return totalAcceptedEmotions / totalSessions;
  }

  PulseInsightCount? get topAcceptedEmotion {
    if (acceptedEmotionFrequency.isEmpty) {
      return null;
    }

    return acceptedEmotionFrequency.first;
  }

  PulseInsightCount? get topContextTag {
    if (commonContextTags.isEmpty) {
      return null;
    }

    return commonContextTags.first;
  }

  PulseInsightCount? get topSocialContext {
    if (socialContexts.isEmpty) {
      return null;
    }

    return socialContexts.first;
  }

  PulseInsightCount? get topEnergyTag {
    if (energyTags.isEmpty) {
      return null;
    }

    return energyTags.first;
  }

  PulseInsightCount? get topSleepTag {
    if (sleepTags.isEmpty) {
      return null;
    }

    return sleepTags.first;
  }

  PulseInsightCount? get mostActiveWeekday {
    if (weekdaySessions.isEmpty) {
      return null;
    }

    return weekdaySessions.first;
  }

  PulseInsightPattern? get topEmotionContextPattern {
    if (emotionContextPatterns.isEmpty) {
      return null;
    }

    return emotionContextPatterns.first;
  }

  int progressToward(int unlockSessionCount) {
    if (totalSessions >= unlockSessionCount) {
      return unlockSessionCount;
    }

    return totalSessions;
  }

  int _remainingSessions(int unlockSessionCount) {
    final int remaining = unlockSessionCount - totalSessions;
    return remaining > 0 ? remaining : 0;
  }

  static List<PulseInsightCount> _countValues(Iterable<String?> values) {
    final Map<String, int> counts = <String, int>{};

    for (final String? value in values) {
      final String normalized = value?.trim() ?? '';
      if (normalized.isEmpty) {
        continue;
      }

      counts.update(normalized, (count) => count + 1, ifAbsent: () => 1);
    }

    final List<PulseInsightCount> ranked = counts.entries
        .map((entry) => PulseInsightCount(label: entry.key, count: entry.value))
        .toList(growable: false);

    ranked.sort((lhs, rhs) {
      final int countCompare = rhs.count.compareTo(lhs.count);
      if (countCompare != 0) {
        return countCompare;
      }

      return lhs.label.compareTo(rhs.label);
    });

    return ranked;
  }

  static List<PulseInsightPattern> _countEmotionContextPatterns(
    List<SwipeSessionRecord> sessions,
  ) {
    final Map<String, PulseInsightPattern> patterns =
        <String, PulseInsightPattern>{};

    for (final SwipeSessionRecord session in sessions) {
      if (session.acceptedEmotions.isEmpty || session.contextTags.isEmpty) {
        continue;
      }

      for (final String emotion in session.acceptedEmotions) {
        for (final String contextTag in session.contextTags) {
          final String key = '$emotion|$contextTag';
          final PulseInsightPattern? existing = patterns[key];
          patterns[key] = PulseInsightPattern(
            emotion: emotion,
            contextTag: contextTag,
            count: existing == null ? 1 : existing.count + 1,
          );
        }
      }
    }

    final List<PulseInsightPattern> ranked = patterns.values.toList(
      growable: false,
    );

    ranked.sort((lhs, rhs) {
      final int countCompare = rhs.count.compareTo(lhs.count);
      if (countCompare != 0) {
        return countCompare;
      }

      final int emotionCompare = lhs.emotion.compareTo(rhs.emotion);
      if (emotionCompare != 0) {
        return emotionCompare;
      }

      return lhs.contextTag.compareTo(rhs.contextTag);
    });

    return ranked;
  }

  static String _weekdayLabel(int weekday) {
    const List<String> weekdayNames = <String>[
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    return weekdayNames[weekday - 1];
  }
}
