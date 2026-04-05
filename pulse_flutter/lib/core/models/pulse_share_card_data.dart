import 'package:pulse_flutter/core/models/pulse_insights.dart';
import 'package:pulse_flutter/core/models/pulse_streak.dart';
import 'package:pulse_flutter/core/models/pulse_weekly_pulse_score.dart';

class PulseShareCardData {
  const PulseShareCardData({
    required this.title,
    required this.subtitle,
    required this.weeklyScoreLabel,
    required this.weeklyDataLabel,
    required this.streakLabel,
    required this.sessionsLabel,
    required this.topEmotionSummary,
    required this.topEmotions,
    this.trendLabel,
  });

  final String title;
  final String subtitle;
  final String weeklyScoreLabel;
  final String weeklyDataLabel;
  final String streakLabel;
  final String sessionsLabel;
  final String topEmotionSummary;
  final List<PulseInsightCount> topEmotions;
  final String? trendLabel;

  factory PulseShareCardData.fromInsights({
    required PulseInsightsReport report,
    required PulseStreak streak,
  }) {
    final PulseWeeklyPulseScore currentWeekScore = report.currentWeekScore;
    final List<PulseInsightCount> topEmotions = report.acceptedEmotionFrequency
        .take(3)
        .toList(growable: false);
    final PulseInsightCount? topEmotion =
        topEmotions.isEmpty ? null : topEmotions.first;
    final String streakLabel = switch (streak.currentStreak) {
      0 => 'No active streak yet',
      1 => '1-day streak',
      _ => '${streak.currentStreak}-day streak',
    };

    return PulseShareCardData(
      title: 'My Pulse snapshot',
      subtitle: topEmotion == null
          ? 'I\'m building my first Pulse patterns.'
          : 'My top emotion right now is ${topEmotion.label.toLowerCase()}.',
      weeklyScoreLabel: currentWeekScore.hasScore
          ? currentWeekScore.scoreLabel
          : 'Building',
      weeklyDataLabel: currentWeekScore.dataAvailabilityLabel,
      streakLabel: streakLabel,
      sessionsLabel:
          '${report.totalSessions} ${report.totalSessions == 1 ? 'session' : 'sessions'} saved',
      topEmotionSummary: topEmotions.isEmpty
          ? 'No top emotions yet'
          : topEmotions.map((emotion) => emotion.label).join(' • '),
      topEmotions: topEmotions,
      trendLabel: report.weeklyScoreTrend?.label,
    );
  }

  String toShareText() {
    final List<String> lines = <String>[
      title,
      subtitle,
      'Weekly Pulse Score: $weeklyScoreLabel',
      weeklyDataLabel,
      'Current streak: $streakLabel',
      sessionsLabel,
      'Top emotions: $topEmotionSummary',
    ];

    final String? trend = trendLabel;
    if (trend != null && trend.isNotEmpty) {
      lines.add('Trend: $trend');
    }

    return lines.join('\n');
  }
}
