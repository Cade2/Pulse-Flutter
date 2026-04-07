import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_flutter/core/models/pulse_streak.dart';
import 'package:pulse_flutter/core/models/pulse_streak_engagement.dart';

void main() {
  test('detects a streak lost after yesterday is missed', () {
    final PulseStreakEngagement engagement = PulseStreakEngagement.fromStreak(
      streak: const PulseStreak(
        currentStreak: 5,
        longestStreak: 8,
        lastSessionDate: '2026-04-05',
      ),
      currentDate: DateTime(2026, 4, 7),
    );

    expect(engagement.kind, PulseStreakEngagementKind.streakLost);
    expect(engagement.missedDays, 1);
    expect(engagement.effectiveStreak.currentStreak, 0);
    expect(engagement.title, 'Your streak needs a restart');
  });

  test('surfaces returning user messaging after multiple missed days', () {
    final PulseStreakEngagement engagement = PulseStreakEngagement.fromStreak(
      streak: const PulseStreak(
        currentStreak: 6,
        longestStreak: 9,
        lastSessionDate: '2026-04-03',
      ),
      currentDate: DateTime(2026, 4, 7),
    );

    expect(engagement.kind, PulseStreakEngagementKind.returning);
    expect(engagement.missedDays, 3);
    expect(engagement.message, contains('3 missed days'));
    expect(engagement.supportingText, 'Longest streak saved: 9 days.');
  });

  test('detects nearby streak milestones', () {
    final PulseStreakEngagement engagement = PulseStreakEngagement.fromStreak(
      streak: const PulseStreak(
        currentStreak: 6,
        longestStreak: 6,
        lastSessionDate: '2026-04-07',
      ),
      currentDate: DateTime(2026, 4, 7),
    );

    expect(engagement.kind, PulseStreakEngagementKind.milestoneNearby);
    expect(engagement.nextMilestone, 7);
    expect(engagement.daysUntilMilestone, 1);
    expect(
      engagement.message,
      'You are 1 day away from a 7-day streak milestone.',
    );
  });

  test('stays quiet when there is no lost streak or nearby milestone', () {
    final PulseStreakEngagement engagement = PulseStreakEngagement.fromStreak(
      streak: const PulseStreak(
        currentStreak: 4,
        longestStreak: 4,
        lastSessionDate: '2026-04-07',
      ),
      currentDate: DateTime(2026, 4, 7),
    );

    expect(engagement.kind, PulseStreakEngagementKind.none);
    expect(engagement.shouldSurface, isFalse);
  });
}
