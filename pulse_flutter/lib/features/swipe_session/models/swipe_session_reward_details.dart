import 'package:pulse_flutter/core/models/pulse_badge.dart';
import 'package:pulse_flutter/core/models/pulse_level_progress.dart';
import 'package:pulse_flutter/core/models/pulse_streak.dart';

class SwipeSessionRewardDetails {
  static const List<int> _streakMilestones = <int>[3, 7, 14, 30];

  const SwipeSessionRewardDetails({
    required this.xpEarned,
    required this.previousLevelProgress,
    required this.levelProgress,
    required this.previousStreak,
    required this.currentStreak,
    this.newlyUnlockedBadgeIds = const <String>[],
    this.streakMilestoneMessage,
  });

  factory SwipeSessionRewardDetails.fromTransition({
    required int xpEarned,
    required PulseLevelProgress previousLevelProgress,
    required PulseLevelProgress levelProgress,
    required PulseStreak previousStreak,
    required PulseStreak currentStreak,
    required List<String> previousUnlockedBadgeIds,
    required List<String> unlockedBadgeIds,
  }) {
    final Set<String> previousBadgeIds = previousUnlockedBadgeIds.toSet();
    final List<String> newlyUnlockedBadgeIds = PulseBadgeCatalog.sortedBadgeIds(
      unlockedBadgeIds.where((badgeId) => !previousBadgeIds.contains(badgeId)),
    );

    return SwipeSessionRewardDetails(
      xpEarned: xpEarned,
      previousLevelProgress: previousLevelProgress,
      levelProgress: levelProgress,
      previousStreak: previousStreak,
      currentStreak: currentStreak,
      newlyUnlockedBadgeIds: newlyUnlockedBadgeIds,
      streakMilestoneMessage: _resolveStreakMilestoneMessage(
        previousStreak: previousStreak,
        currentStreak: currentStreak,
      ),
    );
  }

  final int xpEarned;
  final PulseLevelProgress previousLevelProgress;
  final PulseLevelProgress levelProgress;
  final PulseStreak previousStreak;
  final PulseStreak currentStreak;
  final List<String> newlyUnlockedBadgeIds;
  final String? streakMilestoneMessage;

  bool get didLevelUp {
    return levelProgress.currentLevel > previousLevelProgress.currentLevel;
  }

  int get levelsGained {
    return levelProgress.currentLevel - previousLevelProgress.currentLevel;
  }

  List<PulseBadgeDefinition> get newlyUnlockedBadges {
    return newlyUnlockedBadgeIds
        .map(PulseBadgeCatalog.definitionForId)
        .whereType<PulseBadgeDefinition>()
        .toList(growable: false);
  }

  bool get hasNewBadgeUnlocks => newlyUnlockedBadgeIds.isNotEmpty;

  static String? _resolveStreakMilestoneMessage({
    required PulseStreak previousStreak,
    required PulseStreak currentStreak,
  }) {
    for (final int milestone in _streakMilestones) {
      if (previousStreak.currentStreak < milestone &&
          currentStreak.currentStreak >= milestone) {
        return 'Streak milestone reached: $milestone days in a row.';
      }
    }

    return null;
  }
}
