import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_flutter/core/models/pulse_mood_market.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_record.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_summary.dart';

void main() {
  test('mood market derives a long-view Pulse story from saved sessions', () {
    final PulseMoodMarketReport report = PulseMoodMarketReport.fromSessions(
      <SwipeSessionRecord>[
        _buildSession(
          date: '2026-01-03',
          acceptedEmotions: const ['Calm', 'Joy'],
          contextSocial: 'Friends',
          contextEnergy: 'Steady',
        ),
        _buildSession(
          date: '2026-01-10',
          acceptedEmotions: const ['Calm'],
          contextSocial: 'Friends',
          contextSleep: 'Good',
        ),
        _buildSession(
          date: '2026-02-02',
          acceptedEmotions: const ['Focus', 'Hope'],
          contextSocial: 'Solo',
          contextEnergy: 'High',
        ),
        _buildSession(
          date: '2026-03-15',
          acceptedEmotions: const ['Focus', 'Focus'],
          contextSocial: 'Solo',
          contextEnergy: 'High',
          contextSleep: 'Late',
        ),
        _buildSession(
          date: '2026-04-01',
          acceptedEmotions: const ['Focus', 'Curiosity'],
          contextSocial: 'Solo',
          contextEnergy: 'High',
        ),
      ],
      currentDate: DateTime(2026, 4, 1),
    );

    expect(report.hasSessions, isTrue);
    expect(report.rangeLabel, 'Jan - Apr 2026');
    expect(report.periodSummary, '5 sessions across 4 active months');
    expect(report.leadingEmotion?.label, 'Focus');
    expect(report.topEmotions, hasLength(3));
    expect(report.earlyTopEmotion?.label, 'Calm');
    expect(report.recentTopEmotion?.label, 'Focus');
    expect(report.hasEmotionShift, isTrue);
    expect(report.recurringPattern?.emotion, 'Focus');
    expect(report.topEnergyTag?.label, 'High');
    expect(report.topSocialContext?.label, 'Solo');
    expect(report.mostActiveMonth?.label, 'Jan 2026');
  });

  test('mood market stays steady when the same emotion leads both halves', () {
    final PulseMoodMarketReport report = PulseMoodMarketReport.fromSessions(
      <SwipeSessionRecord>[
        _buildSession(
          date: '2026-04-01',
          acceptedEmotions: const ['Calm', 'Joy'],
        ),
        _buildSession(date: '2026-04-02', acceptedEmotions: const ['Calm']),
        _buildSession(
          date: '2026-04-03',
          acceptedEmotions: const ['Calm', 'Hope'],
        ),
        _buildSession(date: '2026-04-04', acceptedEmotions: const ['Calm']),
      ],
      currentDate: DateTime(2026, 4, 4),
    );

    expect(report.hasEmotionShift, isFalse);
    expect(report.emotionalShiftHeadline, 'Calm has stayed central');
    expect(
      report.emotionalShiftSupporting,
      'Calm stayed your strongest accepted emotion across both halves of your Pulse history.',
    );
  });
}

SwipeSessionRecord _buildSession({
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
