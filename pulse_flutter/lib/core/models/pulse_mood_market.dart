import 'package:pulse_flutter/core/models/pulse_insights.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_record.dart';

class PulseMoodMarketReport {
  const PulseMoodMarketReport({
    required this.insights,
    required this.firstSessionAt,
    required this.lastSessionAt,
    required this.earlyEmotionFrequency,
    required this.recentEmotionFrequency,
  });

  final PulseInsightsReport insights;
  final DateTime? firstSessionAt;
  final DateTime? lastSessionAt;
  final List<PulseInsightCount> earlyEmotionFrequency;
  final List<PulseInsightCount> recentEmotionFrequency;

  factory PulseMoodMarketReport.fromSessions(
    List<SwipeSessionRecord> sessions, {
    DateTime? currentDate,
  }) {
    final List<SwipeSessionRecord> sortedSessions =
        List<SwipeSessionRecord>.from(sessions)
          ..sort((lhs, rhs) => lhs.completedAt.compareTo(rhs.completedAt));

    if (sortedSessions.isEmpty) {
      return PulseMoodMarketReport(
        insights: PulseInsightsReport.fromSessions(
          sortedSessions,
          currentDate: currentDate,
        ),
        firstSessionAt: null,
        lastSessionAt: null,
        earlyEmotionFrequency: const <PulseInsightCount>[],
        recentEmotionFrequency: const <PulseInsightCount>[],
      );
    }

    final int splitIndex = sortedSessions.length < 2
        ? 0
        : sortedSessions.length ~/ 2;
    final List<SwipeSessionRecord> earlySessions = splitIndex == 0
        ? sortedSessions
        : sortedSessions.take(splitIndex).toList(growable: false);
    final List<SwipeSessionRecord> recentSessions = splitIndex == 0
        ? sortedSessions
        : sortedSessions.skip(splitIndex).toList(growable: false);

    return PulseMoodMarketReport(
      insights: PulseInsightsReport.fromSessions(
        sortedSessions,
        currentDate: currentDate,
      ),
      firstSessionAt: sortedSessions.first.completedAt,
      lastSessionAt: sortedSessions.last.completedAt,
      earlyEmotionFrequency: _countAcceptedEmotions(earlySessions),
      recentEmotionFrequency: _countAcceptedEmotions(recentSessions),
    );
  }

  bool get hasSessions => insights.totalSessions > 0;

  List<PulseInsightCount> get topEmotions {
    if (insights.acceptedEmotionFrequency.length <= 3) {
      return insights.acceptedEmotionFrequency;
    }

    return insights.acceptedEmotionFrequency.sublist(0, 3);
  }

  PulseInsightCount? get leadingEmotion => insights.topAcceptedEmotion;

  PulseInsightCount? get rarestEmotion => insights.rarestAcceptedEmotion;

  PulseInsightCount? get earlyTopEmotion =>
      earlyEmotionFrequency.isEmpty ? null : earlyEmotionFrequency.first;

  PulseInsightCount? get recentTopEmotion =>
      recentEmotionFrequency.isEmpty ? null : recentEmotionFrequency.first;

  PulseInsightPattern? get recurringPattern =>
      insights.topEmotionContextPattern;

  PulseInsightCount? get topSocialContext => insights.topSocialContext;

  PulseInsightCount? get topEnergyTag => insights.topEnergyTag;

  PulseInsightCount? get topSleepTag => insights.topSleepTag;

  PulseInsightCount? get mostActiveWeekday => insights.mostActiveWeekday;

  PulseInsightMonthSummary? get mostActiveMonth => insights.mostActiveMonth;

  PulseInsightTrend? get monthTrend => insights.monthOverMonthTrend;

  bool get hasEmotionShift {
    final PulseInsightCount? early = earlyTopEmotion;
    final PulseInsightCount? recent = recentTopEmotion;
    if (early == null || recent == null) {
      return false;
    }

    return early.label != recent.label;
  }

  String get rangeLabel {
    if (!hasSessions) {
      return 'No saved range yet';
    }

    final DateTime first = firstSessionAt!;
    final DateTime last = lastSessionAt!;
    if (first.year == last.year && first.month == last.month) {
      return _formatMonthYear(first);
    }

    if (first.year == last.year) {
      return '${_formatMonth(first)} - ${_formatMonthYear(last)}';
    }

    return '${_formatMonthYear(first)} - ${_formatMonthYear(last)}';
  }

  String get periodSummary {
    if (!hasSessions) {
      return 'MoodMarket opens once your Pulse history begins.';
    }

    final int activeMonths = insights.activeMonthCount;
    final String monthLabel = activeMonths == 1 ? 'month' : 'months';
    return '${insights.totalSessions} sessions across $activeMonths active $monthLabel';
  }

  String get emotionalShiftHeadline {
    final PulseInsightCount? early = earlyTopEmotion;
    final PulseInsightCount? recent = recentTopEmotion;
    if (early == null || recent == null) {
      return 'Your emotional trail is still forming';
    }

    if (early.label == recent.label) {
      return '${recent.label} has stayed central';
    }

    return 'From ${early.label} to ${recent.label}';
  }

  String get emotionalShiftSupporting {
    final PulseInsightCount? early = earlyTopEmotion;
    final PulseInsightCount? recent = recentTopEmotion;
    if (early == null || recent == null) {
      return 'A clearer before-and-after shift appears once more accepted emotions are saved.';
    }

    if (early.label == recent.label) {
      return '${recent.label} stayed your strongest accepted emotion across both halves of your Pulse history.';
    }

    return 'Your earlier check-ins leaned more toward ${early.label}, while recent sessions lean more toward ${recent.label}.';
  }

  String leadingEmotionShareLabel(PulseInsightCount? emotion) {
    if (emotion == null) {
      return 'No accepted-emotion share yet';
    }

    final int percent = (insights.acceptedEmotionShare(emotion) * 100).round();
    return '$percent% of accepted emotions';
  }

  static List<PulseInsightCount> _countAcceptedEmotions(
    List<SwipeSessionRecord> sessions,
  ) {
    if (sessions.isEmpty) {
      return const <PulseInsightCount>[];
    }

    return PulseInsightsReport.fromSessions(
      sessions,
      currentDate: sessions.last.completedAt,
    ).acceptedEmotionFrequency;
  }

  static String _formatMonth(DateTime date) {
    return _monthNames[date.month - 1];
  }

  static String _formatMonthYear(DateTime date) {
    return '${_formatMonth(date)} ${date.year}';
  }

  static const List<String> _monthNames = <String>[
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
}
