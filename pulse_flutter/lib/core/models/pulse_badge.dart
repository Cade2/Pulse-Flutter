import 'package:flutter/material.dart';

enum PulseBadgeCriterion { sessionsCompleted, longestStreak, currentLevel }

class PulseBadgeDefinition {
  const PulseBadgeDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.criterion,
    required this.target,
    required this.icon,
  });

  final String id;
  final String title;
  final String description;
  final PulseBadgeCriterion criterion;
  final int target;
  final IconData icon;
}

class PulseBadgeProgressSnapshot {
  const PulseBadgeProgressSnapshot({
    this.sessionCount = 0,
    this.longestStreak = 0,
    this.currentLevel = 1,
  });

  final int sessionCount;
  final int longestStreak;
  final int currentLevel;
}

class PulseBadgeStatus {
  const PulseBadgeStatus({
    required this.definition,
    required this.isUnlocked,
    required this.progress,
  });

  final PulseBadgeDefinition definition;
  final bool isUnlocked;
  final int progress;

  String get progressText {
    switch (definition.criterion) {
      case PulseBadgeCriterion.sessionsCompleted:
        return '$progress / ${definition.target} sessions';
      case PulseBadgeCriterion.longestStreak:
        return '$progress / ${definition.target} streak days';
      case PulseBadgeCriterion.currentLevel:
        return 'Level $progress / ${definition.target}';
    }
  }

  String get hintText {
    return isUnlocked ? 'Unlocked' : progressText;
  }
}

abstract final class PulseBadgeCatalog {
  static const List<PulseBadgeDefinition> definitions = <PulseBadgeDefinition>[
    PulseBadgeDefinition(
      id: 'first-pulse',
      title: 'First Pulse',
      description: 'Complete your first Pulse session.',
      criterion: PulseBadgeCriterion.sessionsCompleted,
      target: 1,
      icon: Icons.favorite_rounded,
    ),
    PulseBadgeDefinition(
      id: 'on-a-roll',
      title: 'On A Roll',
      description: 'Reach a 3-day streak.',
      criterion: PulseBadgeCriterion.longestStreak,
      target: 3,
      icon: Icons.local_fire_department_rounded,
    ),
    PulseBadgeDefinition(
      id: 'level-up',
      title: 'Level Up',
      description: 'Reach Level 2.',
      criterion: PulseBadgeCriterion.currentLevel,
      target: 2,
      icon: Icons.rocket_launch_rounded,
    ),
    PulseBadgeDefinition(
      id: 'seven-check-ins',
      title: 'Seven Check-Ins',
      description: 'Complete seven Pulse sessions.',
      criterion: PulseBadgeCriterion.sessionsCompleted,
      target: 7,
      icon: Icons.calendar_month_rounded,
    ),
  ];

  static List<String> unlockedBadgeIds(
    PulseBadgeProgressSnapshot snapshot, {
    Iterable<String> existingUnlockedBadgeIds = const <String>[],
  }) {
    final Set<String> unlockedIds = existingUnlockedBadgeIds
        .where(_isKnownBadgeId)
        .toSet();

    for (final PulseBadgeDefinition definition in definitions) {
      if (_progressFor(definition, snapshot) >= definition.target) {
        unlockedIds.add(definition.id);
      }
    }

    return sortedBadgeIds(unlockedIds);
  }

  static List<PulseBadgeStatus> statuses(
    PulseBadgeProgressSnapshot snapshot, {
    Iterable<String> unlockedBadgeIds = const <String>[],
  }) {
    final Set<String> persistedIds = unlockedBadgeIds
        .where(_isKnownBadgeId)
        .toSet();

    return definitions.map((definition) {
      final int progress = _progressFor(definition, snapshot);
      return PulseBadgeStatus(
        definition: definition,
        isUnlocked:
            persistedIds.contains(definition.id) || progress >= definition.target,
        progress: progress > definition.target ? definition.target : progress,
      );
    }).toList(growable: false);
  }

  static List<String> sortedBadgeIds(Iterable<String> badgeIds) {
    final Set<String> filtered = badgeIds.where(_isKnownBadgeId).toSet();
    return definitions
        .where((definition) => filtered.contains(definition.id))
        .map((definition) => definition.id)
        .toList(growable: false);
  }

  static bool _isKnownBadgeId(String badgeId) {
    return definitions.any((definition) => definition.id == badgeId);
  }

  static int _progressFor(
    PulseBadgeDefinition definition,
    PulseBadgeProgressSnapshot snapshot,
  ) {
    switch (definition.criterion) {
      case PulseBadgeCriterion.sessionsCompleted:
        return snapshot.sessionCount;
      case PulseBadgeCriterion.longestStreak:
        return snapshot.longestStreak;
      case PulseBadgeCriterion.currentLevel:
        return snapshot.currentLevel;
    }
  }
}
