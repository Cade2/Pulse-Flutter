import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_flutter/core/models/pulse_insights.dart';
import 'package:pulse_flutter/core/models/pulse_share_card_data.dart';
import 'package:pulse_flutter/core/models/pulse_streak.dart';
import 'package:pulse_flutter/features/swipe_session/models/emotion_card.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_record.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_summary.dart';

void main() {
  test('share card data is shaped from real Pulse insights and streak state', () {
    final PulseInsightsReport report = PulseInsightsReport.fromSessions(
      <SwipeSessionRecord>[
        _buildSession(
          date: '2026-04-01',
          acceptedEmotions: const <String>['Calm', 'Joy'],
        ),
        _buildSession(
          date: '2026-04-03',
          acceptedEmotions: const <String>['Calm'],
        ),
        _buildSession(
          date: '2026-04-05',
          acceptedEmotions: const <String>['Hope'],
        ),
      ],
      currentDate: DateTime(2026, 4, 5),
    );

    final PulseShareCardData data = PulseShareCardData.fromInsights(
      report: report,
      streak: const PulseStreak(
        currentStreak: 3,
        longestStreak: 4,
        lastSessionDate: '2026-04-05',
      ),
    );

    expect(data.title, 'My Pulse snapshot');
    expect(data.weeklyScoreLabel, isNot('Building'));
    expect(data.weeklyDataLabel, '3 / 7 days checked in this week');
    expect(data.streakLabel, '3-day streak');
    expect(data.sessionsLabel, '3 sessions saved');
    expect(data.topEmotionSummary, 'Calm • Hope • Joy');
    expect(data.topEmotions.first.label, 'Calm');
    expect(data.toShareText(), contains('Weekly Pulse Score:'));
    expect(data.toShareText(), contains('Current streak: 3-day streak'));
  });
}

SwipeSessionRecord _buildSession({
  required String date,
  required List<String> acceptedEmotions,
}) {
  return SwipeSessionRecord.fromSummary(
    summary: SwipeSessionSummary(
      responses: List<EmotionCardResponse>.generate(8, (index) {
        final bool accepted = index < acceptedEmotions.length;
        final String title = accepted
            ? acceptedEmotions[index]
            : 'Emotion $index';

        return EmotionCardResponse(
          card: EmotionCard(
            id: 'emotion-$index',
            title: title,
            headline: title,
            description: '',
            reflectionPrompt: '',
            accentColor: const Color(0xFF2ED3E6),
          ),
          decision: accepted
              ? EmotionCardDecision.accept
              : EmotionCardDecision.reject,
        );
      }),
    ),
    completedAt: DateTime.parse('$date 12:00:00'),
  );
}
