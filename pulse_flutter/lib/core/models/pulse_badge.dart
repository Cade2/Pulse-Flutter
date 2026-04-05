import 'package:flutter/material.dart';
import 'package:pulse_flutter/core/models/pulse_session_history_entry.dart';

enum PulseBadgeCategory { sessions, streak, growth, emotions, context }

enum PulseBadgeCriterion {
  sessionsCompleted,
  longestStreak,
  currentLevel,
  uniqueAcceptedEmotions,
  sessionsWithAnyContext,
  sessionsWithFullContext,
}

class PulseBadgeDefinition {
  const PulseBadgeDefinition({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.criterion,
    required this.target,
    required this.icon,
  });

  final String id;
  final String title;
  final String description;
  final PulseBadgeCategory category;
  final PulseBadgeCriterion criterion;
  final int target;
  final IconData icon;
}

class PulseBadgeProgressSnapshot {
  const PulseBadgeProgressSnapshot({
    this.sessionCount = 0,
    this.longestStreak = 0,
    this.currentLevel = 1,
    this.uniqueAcceptedEmotionCount = 0,
    this.sessionsWithAnyContext = 0,
    this.sessionsWithFullContext = 0,
  });

  factory PulseBadgeProgressSnapshot.fromSessionHistory({
    required Iterable<PulseSessionHistoryEntry> sessionHistory,
    required int longestStreak,
    required int currentLevel,
  }) {
    final List<PulseSessionHistoryEntry> sessions = sessionHistory.toList(
      growable: false,
    );

    final Set<String> uniqueAcceptedEmotions = sessions
        .expand((session) => session.acceptedEmotions)
        .map(_normalizeEmotion)
        .whereType<String>()
        .toSet();

    int sessionsWithAnyContext = 0;
    int sessionsWithFullContext = 0;

    for (final PulseSessionHistoryEntry session in sessions) {
      if (session.hasAnyContextTag) {
        sessionsWithAnyContext += 1;
      }

      if (session.hasFullContextTags) {
        sessionsWithFullContext += 1;
      }
    }

    return PulseBadgeProgressSnapshot(
      sessionCount: sessions.length,
      longestStreak: longestStreak,
      currentLevel: currentLevel,
      uniqueAcceptedEmotionCount: uniqueAcceptedEmotions.length,
      sessionsWithAnyContext: sessionsWithAnyContext,
      sessionsWithFullContext: sessionsWithFullContext,
    );
  }

  final int sessionCount;
  final int longestStreak;
  final int currentLevel;
  final int uniqueAcceptedEmotionCount;
  final int sessionsWithAnyContext;
  final int sessionsWithFullContext;

  static String? _normalizeEmotion(String emotion) {
    final String trimmed = emotion.trim().toLowerCase();
    if (trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }
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

  int get remainingProgress {
    final int remaining = definition.target - progress;
    return remaining < 0 ? 0 : remaining;
  }

  double get progressRatio {
    if (definition.target <= 0) {
      return 0;
    }

    return progress / definition.target;
  }

  String get categoryLabel {
    switch (definition.category) {
      case PulseBadgeCategory.sessions:
        return 'Sessions';
      case PulseBadgeCategory.streak:
        return 'Streak';
      case PulseBadgeCategory.growth:
        return 'Growth';
      case PulseBadgeCategory.emotions:
        return 'Emotions';
      case PulseBadgeCategory.context:
        return 'Context';
    }
  }

  String get progressText {
    switch (definition.criterion) {
      case PulseBadgeCriterion.sessionsCompleted:
        return '$progress / ${definition.target} sessions';
      case PulseBadgeCriterion.longestStreak:
        return '$progress / ${definition.target} streak days';
      case PulseBadgeCriterion.currentLevel:
        return 'Level $progress / ${definition.target}';
      case PulseBadgeCriterion.uniqueAcceptedEmotions:
        return '$progress / ${definition.target} unique emotions';
      case PulseBadgeCriterion.sessionsWithAnyContext:
        return '$progress / ${definition.target} sessions with context';
      case PulseBadgeCriterion.sessionsWithFullContext:
        return '$progress / ${definition.target} fully tagged sessions';
    }
  }

  String get hintText {
    if (isUnlocked) {
      return 'Unlocked';
    }

    switch (definition.criterion) {
      case PulseBadgeCriterion.sessionsCompleted:
        return 'Complete $remainingProgress more sessions to unlock this badge.';
      case PulseBadgeCriterion.longestStreak:
        return 'Extend your streak by $remainingProgress more day${remainingProgress == 1 ? '' : 's'}.';
      case PulseBadgeCriterion.currentLevel:
        return 'Reach Level ${definition.target} to unlock this badge.';
      case PulseBadgeCriterion.uniqueAcceptedEmotions:
        return 'Accept $remainingProgress more unique emotions to unlock this badge.';
      case PulseBadgeCriterion.sessionsWithAnyContext:
        return 'Add context tags in $remainingProgress more sessions.';
      case PulseBadgeCriterion.sessionsWithFullContext:
        return 'Complete $remainingProgress more sessions with all three context tags.';
    }
  }
}

abstract final class PulseBadgeCatalog {
  static const List<PulseBadgeDefinition> definitions = <PulseBadgeDefinition>[
    PulseBadgeDefinition(
      id: 'first-pulse',
      title: 'First Pulse',
      description: 'Complete your first Pulse session.',
      category: PulseBadgeCategory.sessions,
      criterion: PulseBadgeCriterion.sessionsCompleted,
      target: 1,
      icon: Icons.favorite_rounded,
    ),
    PulseBadgeDefinition(
      id: 'seven-check-ins',
      title: 'Seven Check-Ins',
      description: 'Complete seven Pulse sessions.',
      category: PulseBadgeCategory.sessions,
      criterion: PulseBadgeCriterion.sessionsCompleted,
      target: 7,
      icon: Icons.calendar_month_rounded,
    ),
    PulseBadgeDefinition(
      id: 'fortnight-reflections',
      title: 'Fortnight Reflections',
      description: 'Complete fourteen Pulse sessions.',
      category: PulseBadgeCategory.sessions,
      criterion: PulseBadgeCriterion.sessionsCompleted,
      target: 14,
      icon: Icons.event_repeat_rounded,
    ),
    PulseBadgeDefinition(
      id: 'pulse-practice',
      title: 'Pulse Practice',
      description: 'Complete thirty Pulse sessions.',
      category: PulseBadgeCategory.sessions,
      criterion: PulseBadgeCriterion.sessionsCompleted,
      target: 30,
      icon: Icons.workspace_premium_rounded,
    ),
    PulseBadgeDefinition(
      id: 'on-a-roll',
      title: 'On A Roll',
      description: 'Reach a 3-day streak.',
      category: PulseBadgeCategory.streak,
      criterion: PulseBadgeCriterion.longestStreak,
      target: 3,
      icon: Icons.local_fire_department_rounded,
    ),
    PulseBadgeDefinition(
      id: 'steady-flame',
      title: 'Steady Flame',
      description: 'Reach a 7-day streak.',
      category: PulseBadgeCategory.streak,
      criterion: PulseBadgeCriterion.longestStreak,
      target: 7,
      icon: Icons.whatshot_rounded,
    ),
    PulseBadgeDefinition(
      id: 'two-week-flow',
      title: 'Two-Week Flow',
      description: 'Reach a 14-day streak.',
      category: PulseBadgeCategory.streak,
      criterion: PulseBadgeCriterion.longestStreak,
      target: 14,
      icon: Icons.bolt_rounded,
    ),
    PulseBadgeDefinition(
      id: 'level-up',
      title: 'Level Up',
      description: 'Reach Level 2.',
      category: PulseBadgeCategory.growth,
      criterion: PulseBadgeCriterion.currentLevel,
      target: 2,
      icon: Icons.rocket_launch_rounded,
    ),
    PulseBadgeDefinition(
      id: 'rising-star',
      title: 'Rising Star',
      description: 'Reach Level 4.',
      category: PulseBadgeCategory.growth,
      criterion: PulseBadgeCriterion.currentLevel,
      target: 4,
      icon: Icons.stars_rounded,
    ),
    PulseBadgeDefinition(
      id: 'pulse-master',
      title: 'Pulse Master',
      description: 'Reach Level 8.',
      category: PulseBadgeCategory.growth,
      criterion: PulseBadgeCriterion.currentLevel,
      target: 8,
      icon: Icons.emoji_events_rounded,
    ),
    PulseBadgeDefinition(
      id: 'emotion-cartographer',
      title: 'Emotion Cartographer',
      description: 'Accept seven different emotions across your sessions.',
      category: PulseBadgeCategory.emotions,
      criterion: PulseBadgeCriterion.uniqueAcceptedEmotions,
      target: 7,
      icon: Icons.explore_rounded,
    ),
    PulseBadgeDefinition(
      id: 'full-spectrum',
      title: 'Full Spectrum',
      description: 'Accept all eight current Pulse emotions at least once.',
      category: PulseBadgeCategory.emotions,
      criterion: PulseBadgeCriterion.uniqueAcceptedEmotions,
      target: 8,
      icon: Icons.auto_awesome_rounded,
    ),
    PulseBadgeDefinition(
      id: 'context-curious',
      title: 'Context Curious',
      description: 'Add context tags to five completed sessions.',
      category: PulseBadgeCategory.context,
      criterion: PulseBadgeCriterion.sessionsWithAnyContext,
      target: 5,
      icon: Icons.tune_rounded,
    ),
    PulseBadgeDefinition(
      id: 'fully-present',
      title: 'Fully Present',
      description:
          'Complete three sessions with social, energy, and sleep tags filled in.',
      category: PulseBadgeCategory.context,
      criterion: PulseBadgeCriterion.sessionsWithFullContext,
      target: 3,
      icon: Icons.fact_check_rounded,
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

    return definitions
        .map((definition) {
          final int rawProgress = _progressFor(definition, snapshot);
          final int progress = rawProgress > definition.target
              ? definition.target
              : rawProgress;
          return PulseBadgeStatus(
            definition: definition,
            isUnlocked:
                persistedIds.contains(definition.id) ||
                rawProgress >= definition.target,
            progress: progress,
          );
        })
        .toList(growable: false);
  }

  static List<String> sortedBadgeIds(Iterable<String> badgeIds) {
    final Set<String> filtered = badgeIds.where(_isKnownBadgeId).toSet();
    return definitions
        .where((definition) => filtered.contains(definition.id))
        .map((definition) => definition.id)
        .toList(growable: false);
  }

  static PulseBadgeDefinition? definitionForId(String badgeId) {
    for (final PulseBadgeDefinition definition in definitions) {
      if (definition.id == badgeId) {
        return definition;
      }
    }

    return null;
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
      case PulseBadgeCriterion.uniqueAcceptedEmotions:
        return snapshot.uniqueAcceptedEmotionCount;
      case PulseBadgeCriterion.sessionsWithAnyContext:
        return snapshot.sessionsWithAnyContext;
      case PulseBadgeCriterion.sessionsWithFullContext:
        return snapshot.sessionsWithFullContext;
    }
  }
}
