import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_flutter/core/models/pulse_weekly_pulse_score.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_record.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_summary.dart';

void main() {
  test('weekly pulse score derives from the current week history', () {
    final PulseWeeklyPulseScore score = PulseWeeklyPulseScore.fromHistory(
      <SwipeSessionRecord>[
        _buildWeeklySession(
          date: '2026-04-14',
          acceptedEmotions: const ['Calm', 'Joy'],
        ),
        _buildWeeklySession(
          date: '2026-04-15',
          acceptedEmotions: const ['Hope'],
        ),
        _buildWeeklySession(
          date: '2026-04-16',
          acceptedEmotions: const ['Overwhelm'],
        ),
      ],
      weekStart: DateTime(2026, 4, 16),
    );

    expect(score.weekStart, DateTime(2026, 4, 13));
    expect(score.sessionCount, 3);
    expect(score.daysWithSessions, 3);
    expect(score.acceptedEmotionCount, 4);
    expect(score.score, 63);
    expect(score.dataAvailabilityLabel, '3 / 7 days checked in this week');
  });

  test('weekly pulse score compares with the previous week when available', () {
    final List<SwipeSessionRecord> sessions = <SwipeSessionRecord>[
      _buildWeeklySession(
        date: '2026-04-07',
        acceptedEmotions: const ['Overwhelm'],
      ),
      _buildWeeklySession(
        date: '2026-04-09',
        acceptedEmotions: const ['Vulnerability'],
      ),
      _buildWeeklySession(
        date: '2026-04-14',
        acceptedEmotions: const ['Calm', 'Joy'],
      ),
      _buildWeeklySession(date: '2026-04-15', acceptedEmotions: const ['Hope']),
      _buildWeeklySession(
        date: '2026-04-16',
        acceptedEmotions: const ['Overwhelm'],
      ),
    ];

    final PulseWeeklyPulseScore currentWeek = PulseWeeklyPulseScore.fromHistory(
      sessions,
      weekStart: DateTime(2026, 4, 16),
    );
    final PulseWeeklyPulseScore previousWeek =
        PulseWeeklyPulseScore.fromHistory(
          sessions,
          weekStart: DateTime(2026, 4, 9),
        );
    final PulseWeeklyPulseScoreTrend? trend = currentWeek.compareWith(
      previousWeek,
    );

    expect(previousWeek.score, 32);
    expect(trend, isNotNull);
    expect(trend!.delta, 31);
    expect(trend.label, '+31 vs last week');
  });
}

SwipeSessionRecord _buildWeeklySession({
  required String date,
  List<String> acceptedEmotions = const <String>[],
}) {
  return SwipeSessionRecord(
    sessionId: date,
    date: date,
    completedAt: DateTime.parse('$date 12:00:00'),
    responses: const <EmotionCardResponse>[],
    acceptedEmotions: acceptedEmotions,
  );
}
