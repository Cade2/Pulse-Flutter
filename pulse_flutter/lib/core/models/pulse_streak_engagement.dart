import 'package:pulse_flutter/core/models/pulse_streak.dart';

enum PulseStreakEngagementKind { none, streakLost, returning, milestoneNearby }

class PulseStreakEngagement {
  static const List<int> milestoneTargets = <int>[3, 7, 14, 30];

  const PulseStreakEngagement({
    required this.kind,
    required this.effectiveStreak,
    required this.missedDays,
    this.nextMilestone,
    this.daysUntilMilestone,
  });

  factory PulseStreakEngagement.fromStreak({
    required PulseStreak streak,
    required DateTime currentDate,
  }) {
    final PulseStreak effectiveStreak = streak.effectiveAsOf(currentDate);
    final int missedDays = streak.missedDaysAsOf(currentDate);

    if (missedDays >= 2) {
      return PulseStreakEngagement(
        kind: PulseStreakEngagementKind.returning,
        effectiveStreak: effectiveStreak,
        missedDays: missedDays,
      );
    }

    if (missedDays == 1) {
      return PulseStreakEngagement(
        kind: PulseStreakEngagementKind.streakLost,
        effectiveStreak: effectiveStreak,
        missedDays: missedDays,
      );
    }

    final int? nextMilestone = _nextMilestoneFor(effectiveStreak.currentStreak);
    final int? daysUntilMilestone = nextMilestone == null
        ? null
        : nextMilestone - effectiveStreak.currentStreak;

    if (daysUntilMilestone != null &&
        daysUntilMilestone > 0 &&
        daysUntilMilestone <= 2) {
      return PulseStreakEngagement(
        kind: PulseStreakEngagementKind.milestoneNearby,
        effectiveStreak: effectiveStreak,
        missedDays: 0,
        nextMilestone: nextMilestone,
        daysUntilMilestone: daysUntilMilestone,
      );
    }

    return PulseStreakEngagement(
      kind: PulseStreakEngagementKind.none,
      effectiveStreak: effectiveStreak,
      missedDays: 0,
      nextMilestone: nextMilestone,
      daysUntilMilestone: daysUntilMilestone,
    );
  }

  final PulseStreakEngagementKind kind;
  final PulseStreak effectiveStreak;
  final int missedDays;
  final int? nextMilestone;
  final int? daysUntilMilestone;

  bool get shouldSurface => kind != PulseStreakEngagementKind.none;

  String get title {
    switch (kind) {
      case PulseStreakEngagementKind.returning:
        return 'Welcome back to Pulse';
      case PulseStreakEngagementKind.streakLost:
        return 'Your streak needs a restart';
      case PulseStreakEngagementKind.milestoneNearby:
        return 'Milestone nearby';
      case PulseStreakEngagementKind.none:
        return 'Pulse streak';
    }
  }

  String get message {
    switch (kind) {
      case PulseStreakEngagementKind.returning:
        return 'It has been $missedDays missed days since your last check-in. Start with one gentle session today to rebuild your rhythm.';
      case PulseStreakEngagementKind.streakLost:
        return 'You missed yesterday, so the active streak has reset. Your longest streak is still saved.';
      case PulseStreakEngagementKind.milestoneNearby:
        final int remaining = daysUntilMilestone ?? 0;
        final int milestone = nextMilestone ?? 0;
        return remaining == 1
            ? 'You are 1 day away from a $milestone-day streak milestone.'
            : 'You are $remaining days away from a $milestone-day streak milestone.';
      case PulseStreakEngagementKind.none:
        return '';
    }
  }

  String get supportingText {
    switch (kind) {
      case PulseStreakEngagementKind.returning:
      case PulseStreakEngagementKind.streakLost:
        final int longestStreak = effectiveStreak.longestStreak;
        if (longestStreak <= 0) {
          return 'A new streak starts with your next completed session.';
        }

        return 'Longest streak saved: $longestStreak ${longestStreak == 1 ? 'day' : 'days'}.';
      case PulseStreakEngagementKind.milestoneNearby:
        return 'Complete today\'s session to keep moving toward it.';
      case PulseStreakEngagementKind.none:
        return '';
    }
  }

  static int? _nextMilestoneFor(int currentStreak) {
    if (currentStreak <= 0) {
      return null;
    }

    for (final int milestone in milestoneTargets) {
      if (currentStreak < milestone) {
        return milestone;
      }
    }

    return null;
  }
}
