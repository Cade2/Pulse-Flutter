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
    );

    expect(report.availability, PulseInsightsAvailability.locked);
    expect(report.totalSessions, 3);
    expect(report.sessionsUntilBasic, 2);
    expect(report.topAcceptedEmotion?.label, 'Calm');
    expect(report.topAcceptedEmotion?.count, 2);
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
          date: '2026-04-02',
          acceptedEmotions: const ['Calm'],
          contextSocial: 'Friends',
          contextSleep: 'Good',
        ),
        _buildInsightSession(
          date: '2026-04-03',
          acceptedEmotions: const ['Focus'],
          contextEnergy: 'High',
        ),
        _buildInsightSession(
          date: '2026-04-04',
          acceptedEmotions: const ['Calm', 'Hope'],
          contextSocial: 'Solo',
          contextSleep: 'Good',
        ),
        _buildInsightSession(
          date: '2026-04-05',
          acceptedEmotions: const ['Joy'],
          contextSocial: 'Friends',
          contextEnergy: 'Steady',
        ),
      ],
    );

    expect(report.availability, PulseInsightsAvailability.basic);
    expect(report.sessionsUntilExpanded, 9);
    expect(report.topAcceptedEmotion?.label, 'Calm');
    expect(report.topAcceptedEmotion?.count, 3);
    expect(report.topContextTag?.label, 'Social: Friends');
    expect(report.topContextTag?.count, 3);
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
      );

      expect(report.availability, PulseInsightsAvailability.expanded);
      expect(report.totalSessions, 14);
      expect(report.topAcceptedEmotion?.label, 'Calm');
      expect(report.topAcceptedEmotion?.count, 14);
      expect(report.topSocialContext?.label, 'Friends');
      expect(report.topEnergyTag?.label, 'Steady');
      expect(report.topSleepTag?.label, 'Good');
      expect(report.averageAcceptedPerSession, closeTo(23 / 14, 0.0001));
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
