import 'package:pulse_flutter/core/models/pulse_weekly_pulse_score.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_record.dart';

enum PulseInsightsAvailability { locked, basic, expanded }

enum PulseInsightTrendDirection { up, down, flat }

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

class PulseInsightMonthSummary {
  const PulseInsightMonthSummary({
    required this.monthStart,
    required this.label,
    required this.sessionCount,
    required this.acceptedEmotionCount,
    this.topEmotion,
  });

  final DateTime monthStart;
  final String label;
  final int sessionCount;
  final int acceptedEmotionCount;
  final String? topEmotion;

  String get sessionCountText =>
      sessionCount == 1 ? '1 session' : '$sessionCount sessions';

  String get acceptedEmotionText => acceptedEmotionCount == 1
      ? '1 accepted emotion'
      : '$acceptedEmotionCount accepted emotions';

  String get topEmotionSummary => topEmotion == null
      ? 'No accepted emotions saved'
      : 'Top emotion: $topEmotion';
}

class PulseInsightTrend {
  const PulseInsightTrend({
    required this.currentLabel,
    required this.previousLabel,
    required this.currentValue,
    required this.previousValue,
  }) : delta = currentValue - previousValue,
       direction = currentValue > previousValue
           ? PulseInsightTrendDirection.up
           : currentValue < previousValue
           ? PulseInsightTrendDirection.down
           : PulseInsightTrendDirection.flat;

  final String currentLabel;
  final String previousLabel;
  final int currentValue;
  final int previousValue;
  final int delta;
  final PulseInsightTrendDirection direction;

  String get label {
    switch (direction) {
      case PulseInsightTrendDirection.up:
        return '+$delta sessions vs $previousLabel';
      case PulseInsightTrendDirection.down:
        return '$delta sessions vs $previousLabel';
      case PulseInsightTrendDirection.flat:
        return 'No session change vs $previousLabel';
    }
  }
}

class PulseInsightsReport {
  static const int basicUnlockSessionCount = 5;
  static const int expandedUnlockSessionCount = 14;
  static const int longHorizonUnlockSessionCount = 30;

  const PulseInsightsReport({
    this.totalSessions = 0,
    this.totalAcceptedEmotions = 0,
    this.sessionsWithContextTags = 0,
    this.sessionsWithSocialContext = 0,
    this.sessionsWithEnergyTag = 0,
    this.sessionsWithSleepTag = 0,
    this.acceptedEmotionFrequency = const <PulseInsightCount>[],
    this.commonContextTags = const <PulseInsightCount>[],
    this.socialContexts = const <PulseInsightCount>[],
    this.energyTags = const <PulseInsightCount>[],
    this.sleepTags = const <PulseInsightCount>[],
    this.weekdaySessions = const <PulseInsightCount>[],
    this.emotionContextPatterns = const <PulseInsightPattern>[],
    this.monthlySummaries = const <PulseInsightMonthSummary>[],
    required this.currentWeekScore,
    required this.previousWeekScore,
  });

  final int totalSessions;
  final int totalAcceptedEmotions;
  final int sessionsWithContextTags;
  final int sessionsWithSocialContext;
  final int sessionsWithEnergyTag;
  final int sessionsWithSleepTag;
  final List<PulseInsightCount> acceptedEmotionFrequency;
  final List<PulseInsightCount> commonContextTags;
  final List<PulseInsightCount> socialContexts;
  final List<PulseInsightCount> energyTags;
  final List<PulseInsightCount> sleepTags;
  final List<PulseInsightCount> weekdaySessions;
  final List<PulseInsightPattern> emotionContextPatterns;
  final List<PulseInsightMonthSummary> monthlySummaries;
  final PulseWeeklyPulseScore currentWeekScore;
  final PulseWeeklyPulseScore previousWeekScore;

  factory PulseInsightsReport.fromSessions(
    List<SwipeSessionRecord> sessions, {
    DateTime? currentDate,
  }) {
    final DateTime scoreAnchor = currentDate ?? DateTime.now();
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
    final List<PulseInsightMonthSummary> monthlySummaries =
        _buildMonthlySummaries(sessions);
    final PulseWeeklyPulseScore currentWeekScore =
        PulseWeeklyPulseScore.fromHistory(
          sessions,
          weekStart: PulseWeeklyPulseScore.startOfWeek(scoreAnchor),
        );
    final PulseWeeklyPulseScore previousWeekScore =
        PulseWeeklyPulseScore.fromHistory(
          sessions,
          weekStart: PulseWeeklyPulseScore.previousWeekStart(scoreAnchor),
        );

    return PulseInsightsReport(
      totalSessions: sessions.length,
      totalAcceptedEmotions: sessions.fold(
        0,
        (sum, session) => sum + session.acceptedEmotions.length,
      ),
      sessionsWithContextTags: sessions
          .where((session) => session.contextTags.isNotEmpty)
          .length,
      sessionsWithSocialContext: sessions
          .where(
            (session) => (session.contextSocial?.trim().isNotEmpty ?? false),
          )
          .length,
      sessionsWithEnergyTag: sessions
          .where(
            (session) => (session.contextEnergy?.trim().isNotEmpty ?? false),
          )
          .length,
      sessionsWithSleepTag: sessions
          .where(
            (session) => (session.contextSleep?.trim().isNotEmpty ?? false),
          )
          .length,
      acceptedEmotionFrequency: acceptedEmotionFrequency,
      commonContextTags: commonContextTags,
      socialContexts: socialContexts,
      energyTags: energyTags,
      sleepTags: sleepTags,
      weekdaySessions: weekdaySessions,
      emotionContextPatterns: emotionContextPatterns,
      monthlySummaries: monthlySummaries,
      currentWeekScore: currentWeekScore,
      previousWeekScore: previousWeekScore,
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

  bool get hasLongHorizonInsights =>
      totalSessions >= longHorizonUnlockSessionCount;

  int get sessionsUntilBasic => _remainingSessions(basicUnlockSessionCount);

  int get sessionsUntilExpanded =>
      _remainingSessions(expandedUnlockSessionCount);

  int get sessionsUntilLongHorizon =>
      _remainingSessions(longHorizonUnlockSessionCount);

  double get averageAcceptedPerSession {
    if (totalSessions == 0) {
      return 0;
    }

    return totalAcceptedEmotions / totalSessions;
  }

  int get uniqueAcceptedEmotionCount => acceptedEmotionFrequency.length;

  int get activeWeekdayCount => weekdaySessions.length;

  int get activeMonthCount => monthlySummaries.length;

  List<PulseInsightMonthSummary> get recentMonthlySummaries {
    if (monthlySummaries.length <= 6) {
      return monthlySummaries;
    }

    return monthlySummaries.sublist(monthlySummaries.length - 6);
  }

  double acceptedEmotionShare(PulseInsightCount? count) {
    if (count == null || totalAcceptedEmotions == 0) {
      return 0;
    }

    return count.count / totalAcceptedEmotions;
  }

  double contextCoverageFor(int sessionsWithValue) {
    if (totalSessions == 0) {
      return 0;
    }

    return sessionsWithValue / totalSessions;
  }

  double weekdayShare(PulseInsightCount? count) {
    if (count == null || totalSessions == 0) {
      return 0;
    }

    return count.count / totalSessions;
  }

  double monthShare(PulseInsightMonthSummary? summary) {
    if (summary == null || totalSessions == 0) {
      return 0;
    }

    return summary.sessionCount / totalSessions;
  }

  PulseInsightCount? get topAcceptedEmotion {
    if (acceptedEmotionFrequency.isEmpty) {
      return null;
    }

    return acceptedEmotionFrequency.first;
  }

  PulseInsightCount? get rarestAcceptedEmotion {
    if (acceptedEmotionFrequency.isEmpty) {
      return null;
    }

    PulseInsightCount rarest = acceptedEmotionFrequency.first;

    for (final PulseInsightCount count in acceptedEmotionFrequency.skip(1)) {
      if (count.count < rarest.count ||
          (count.count == rarest.count &&
              count.label.compareTo(rarest.label) < 0)) {
        rarest = count;
      }
    }

    return rarest;
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

  PulseInsightMonthSummary? get mostActiveMonth {
    if (monthlySummaries.isEmpty) {
      return null;
    }

    PulseInsightMonthSummary mostActive = monthlySummaries.first;

    for (final PulseInsightMonthSummary summary in monthlySummaries.skip(1)) {
      if (summary.sessionCount > mostActive.sessionCount ||
          (summary.sessionCount == mostActive.sessionCount &&
              summary.monthStart.isAfter(mostActive.monthStart))) {
        mostActive = summary;
      }
    }

    return mostActive;
  }

  PulseInsightTrend? get monthOverMonthTrend {
    if (monthlySummaries.length < 2) {
      return null;
    }

    final PulseInsightMonthSummary current = monthlySummaries.last;
    final PulseInsightMonthSummary previous =
        monthlySummaries[monthlySummaries.length - 2];

    return PulseInsightTrend(
      currentLabel: current.label,
      previousLabel: previous.label,
      currentValue: current.sessionCount,
      previousValue: previous.sessionCount,
    );
  }

  PulseWeeklyPulseScoreTrend? get weeklyScoreTrend {
    return currentWeekScore.compareWith(previousWeekScore);
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

  static List<PulseInsightMonthSummary> _buildMonthlySummaries(
    List<SwipeSessionRecord> sessions,
  ) {
    final Map<DateTime, _PulseInsightMonthAccumulator> accumulators =
        <DateTime, _PulseInsightMonthAccumulator>{};

    for (final SwipeSessionRecord session in sessions) {
      final DateTime monthStart = DateTime(
        session.completedAt.year,
        session.completedAt.month,
      );
      final _PulseInsightMonthAccumulator accumulator = accumulators
          .putIfAbsent(monthStart, _PulseInsightMonthAccumulator.new);
      accumulator.sessionCount += 1;
      accumulator.acceptedEmotionCount += session.acceptedEmotions.length;

      for (final String emotion in session.acceptedEmotions) {
        final String normalized = emotion.trim();
        if (normalized.isEmpty) {
          continue;
        }

        accumulator.emotionCounts.update(
          normalized,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }
    }

    final List<PulseInsightMonthSummary> summaries = accumulators.entries
        .map((entry) {
          final DateTime monthStart = entry.key;
          final _PulseInsightMonthAccumulator accumulator = entry.value;
          return PulseInsightMonthSummary(
            monthStart: monthStart,
            label: _monthLabel(monthStart),
            sessionCount: accumulator.sessionCount,
            acceptedEmotionCount: accumulator.acceptedEmotionCount,
            topEmotion: _topCountLabel(accumulator.emotionCounts),
          );
        })
        .toList(growable: false);

    summaries.sort((lhs, rhs) => lhs.monthStart.compareTo(rhs.monthStart));
    return summaries;
  }

  static String? _topCountLabel(Map<String, int> counts) {
    if (counts.isEmpty) {
      return null;
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

    return ranked.first.label;
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

  static String _monthLabel(DateTime monthStart) {
    const List<String> monthNames = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    return '${monthNames[monthStart.month - 1]} ${monthStart.year}';
  }
}

class _PulseInsightMonthAccumulator {
  int sessionCount = 0;
  int acceptedEmotionCount = 0;
  final Map<String, int> emotionCounts = <String, int>{};
}
