import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_flutter/core/models/pulse_level_progress.dart';
import 'package:pulse_flutter/core/models/pulse_streak.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_reward_details.dart';

void main() {
  test('reward details detect level-up, new badges, and streak milestone', () {
    final SwipeSessionRewardDetails reward =
        SwipeSessionRewardDetails.fromTransition(
          xpEarned: 60,
          previousLevelProgress: const PulseLevelProgress(
            totalXp: 340,
            currentLevel: 4,
          ),
          levelProgress: const PulseLevelProgress(
            totalXp: 400,
            currentLevel: 5,
          ),
          previousStreak: const PulseStreak(
            currentStreak: 2,
            longestStreak: 2,
            lastSessionDate: '2026-04-03',
          ),
          currentStreak: const PulseStreak(
            currentStreak: 3,
            longestStreak: 3,
            lastSessionDate: '2026-04-04',
          ),
          previousUnlockedBadgeIds: const <String>['first-pulse', 'level-up'],
          unlockedBadgeIds: const <String>[
            'first-pulse',
            'on-a-roll',
            'level-up',
            'seven-check-ins',
          ],
        );

    expect(reward.didLevelUp, isTrue);
    expect(reward.levelsGained, 1);
    expect(reward.newlyUnlockedBadgeIds, <String>[
      'on-a-roll',
      'seven-check-ins',
    ]);
    expect(
      reward.streakMilestoneMessage,
      'Streak milestone reached: 3 days in a row.',
    );
  });

  test('reward details stay quiet when no milestone changes happen', () {
    final SwipeSessionRewardDetails reward =
        SwipeSessionRewardDetails.fromTransition(
          xpEarned: 0,
          previousLevelProgress: const PulseLevelProgress(
            totalXp: 180,
            currentLevel: 2,
          ),
          levelProgress: const PulseLevelProgress(
            totalXp: 180,
            currentLevel: 2,
          ),
          previousStreak: const PulseStreak(
            currentStreak: 4,
            longestStreak: 6,
            lastSessionDate: '2026-04-04',
          ),
          currentStreak: const PulseStreak(
            currentStreak: 4,
            longestStreak: 6,
            lastSessionDate: '2026-04-04',
          ),
          previousUnlockedBadgeIds: const <String>['first-pulse'],
          unlockedBadgeIds: const <String>['first-pulse'],
        );

    expect(reward.didLevelUp, isFalse);
    expect(reward.hasNewBadgeUnlocks, isFalse);
    expect(reward.streakMilestoneMessage, isNull);
  });
}
