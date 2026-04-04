import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_flutter/core/models/pulse_insights.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_record.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_summary.dart';

void main() {
  test('insights stay locked until five sessions are saved', () {
    final PulseInsightsReport report = PulseInsightsReport.fromSessions(
      <SwipeSessionRecord>[
        _buildInsightSession(
          date: '2026-04-01',
          acceptedEmotions: const ['Calm'],
        ),
        _buildInsightSession(
          date: '2026-04-02',
          acceptedEmotions: const ['Calm', 'Joy'],
        ),
        _buildInsightSession(
          date: '2026-04-03',
          acceptedEmotions: const ['Hope'],
        ),
      ],
      currentDate: DateTime(2026, 4, 4),
    );

    expect(report.availability, PulseInsightsAvailability.locked);
    expect(report.totalSessions, 3);
    expect(report.sessionsUntilBasic, 2);
    expect(report.topAcceptedEmotion?.label, 'Calm');
    expect(report.topAcceptedEmotion?.count, 2);
    expect(report.currentWeekScore.score, 86);
    expect(report.weeklyScoreTrend, isNull);
  });

  test('basic insights unlock at five sessions with real rankings', () {
    final PulseInsightsReport report = PulseInsightsReport.fromSessions(
      <SwipeSessionRecord>[
        _buildInsightSession(
          date: '2026-04-01',
          acceptedEmotions: const ['Calm', 'Joy'],
          contextSocial: 'Friends',
          contextEnergy: 'Steady',
        ),
        _buildInsightSession(
          date: '2026-04-03',
          acceptedEmotions: const ['Calm'],
          contextSocial: 'Friends',
          contextSleep: 'Good',
        ),
        _buildInsightSession(
          date: '2026-04-08',
          acceptedEmotions: const ['Focus'],
          contextEnergy: 'High',
        ),
        _buildInsightSession(
          date: '2026-04-10',
          acceptedEmotions: const ['Calm', 'Hope'],
          contextSocial: 'Friends',
          contextSleep: 'Good',
        ),
        _buildInsightSession(
          date: '2026-04-15',
          acceptedEmotions: const ['Joy'],
          contextSocial: 'Friends',
          contextEnergy: 'Steady',
        ),
      ],
      currentDate: DateTime(2026, 4, 15),
    );

    expect(report.availability, PulseInsightsAvailability.basic);
    expect(report.sessionsUntilExpanded, 9);
    expect(report.topAcceptedEmotion?.label, 'Calm');
    expect(report.topAcceptedEmotion?.count, 3);
    expect(report.topContextTag?.label, 'Social: Friends');
    expect(report.topContextTag?.count, 4);
    expect(report.mostActiveWeekday?.label, 'Wednesday');
    expect(report.mostActiveWeekday?.count, 3);
    expect(report.topSocialContext?.label, 'Friends');
    expect(report.topEnergyTag?.label, 'Steady');
    expect(report.topSleepTag?.label, 'Good');
    expect(report.topEmotionContextPattern?.emotion, 'Calm');
    expect(report.topEmotionContextPattern?.contextTag, 'Social: Friends');
    expect(report.topEmotionContextPattern?.count, 3);
    expect(report.currentWeekScore.score, 92);
    expect(report.previousWeekScore.score, 79);
    expect(report.weeklyScoreTrend?.label, '+13 vs last week');
  });

  test(
    'expanded insights unlock at fourteen sessions with pattern signals',
    () {
      final List<SwipeSessionRecord> sessions = <SwipeSessionRecord>[
        for (int index = 1; index <= 9; index++)
          _buildInsightSession(
            date: '2026-04-${index.toString().padLeft(2, '0')}',
            acceptedEmotions: const ['Calm', 'Joy'],
            contextSocial: 'Friends',
            contextEnergy: 'Steady',
            contextSleep: 'Good',
          ),
        for (int index = 10; index <= 14; index++)
          _buildInsightSession(
            date: '2026-04-${index.toString().padLeft(2, '0')}',
            acceptedEmotions: const ['Calm'],
            contextSocial: 'Solo',
            contextEnergy: 'High',
            contextSleep: 'Late',
          ),
      ];

      final PulseInsightsReport report = PulseInsightsReport.fromSessions(
        sessions,
        currentDate: DateTime(2026, 4, 12),
      );

      expect(report.availability, PulseInsightsAvailability.expanded);
      expect(report.totalSessions, 14);
      expect(report.topAcceptedEmotion?.label, 'Calm');
      expect(report.topAcceptedEmotion?.count, 14);
      expect(report.topSocialContext?.label, 'Friends');
      expect(report.topEnergyTag?.label, 'Steady');
      expect(report.topSleepTag?.label, 'Good');
      expect(report.weekdaySessions, isNotEmpty);
      expect(report.topEmotionContextPattern?.emotion, 'Calm');
      expect(report.topEmotionContextPattern?.contextTag, 'Energy: Steady');
      expect(report.topEmotionContextPattern?.count, 9);
      expect(report.averageAcceptedPerSession, closeTo(23 / 14, 0.0001));
      expect(report.currentWeekScore.score, 89);
      expect(report.previousWeekScore.score, 90);
      expect(report.weeklyScoreTrend?.label, '-1 vs last week');
    },
  );
}

SwipeSessionRecord _buildInsightSession({
  required String date,
  List<String> acceptedEmotions = const <String>[],
  String? contextSocial,
  String? contextEnergy,
  String? contextSleep,
}) {
  return SwipeSessionRecord(
    sessionId: date,
    date: date,
    completedAt: DateTime.parse('$date 12:00:00'),
    responses: const <EmotionCardResponse>[],
    acceptedEmotions: acceptedEmotions,
    contextSocial: contextSocial,
    contextEnergy: contextEnergy,
    contextSleep: contextSleep,
  );
}
