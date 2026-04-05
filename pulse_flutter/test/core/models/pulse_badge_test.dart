import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_flutter/core/models/pulse_badge.dart';
import 'package:pulse_flutter/core/models/pulse_session_history_entry.dart';

void main() {
  test('unlockedBadgeIds backfills richer badges from existing progress', () {
    final PulseBadgeProgressSnapshot snapshot =
        PulseBadgeProgressSnapshot.fromSessionHistory(
          sessionHistory: List<PulseSessionHistoryEntry>.generate(14, (index) {
            return PulseSessionHistoryEntry(
              date: '2026-04-${(index + 1).toString().padLeft(2, '0')}',
              acceptedEmotions: <String>[
                'Calm',
                'Joy',
                'Focus',
                'Hope',
                'Confidence',
                'Curiosity',
                if (index.isEven) 'Overwhelm',
                if (index.isOdd) 'Vulnerability',
              ],
              contextSocial: 'Friends',
              contextEnergy: 'Steady',
              contextSleep: 'Good',
            );
          }),
          longestStreak: 14,
          currentLevel: 8,
        );

    expect(PulseBadgeCatalog.unlockedBadgeIds(snapshot), <String>[
      'first-pulse',
      'seven-check-ins',
      'fortnight-reflections',
      'on-a-roll',
      'steady-flame',
      'two-week-flow',
      'level-up',
      'rising-star',
      'pulse-master',
      'emotion-cartographer',
      'full-spectrum',
      'context-curious',
      'fully-present',
    ]);
  });

  test('statuses keep useful progress hints for richer locked badges', () {
    const PulseBadgeProgressSnapshot snapshot = PulseBadgeProgressSnapshot(
      sessionCount: 1,
      longestStreak: 2,
      currentLevel: 1,
      uniqueAcceptedEmotionCount: 3,
      sessionsWithAnyContext: 2,
      sessionsWithFullContext: 1,
    );

    final List<PulseBadgeStatus> statuses = PulseBadgeCatalog.statuses(
      snapshot,
      unlockedBadgeIds: PulseBadgeCatalog.unlockedBadgeIds(snapshot),
    );

    final PulseBadgeStatus firstPulse = statuses.firstWhere(
      (status) => status.definition.id == 'first-pulse',
    );
    final PulseBadgeStatus onARoll = statuses.firstWhere(
      (status) => status.definition.id == 'on-a-roll',
    );
    final PulseBadgeStatus levelUp = statuses.firstWhere(
      (status) => status.definition.id == 'level-up',
    );
    final PulseBadgeStatus emotionCartographer = statuses.firstWhere(
      (status) => status.definition.id == 'emotion-cartographer',
    );
    final PulseBadgeStatus contextCurious = statuses.firstWhere(
      (status) => status.definition.id == 'context-curious',
    );
    final PulseBadgeStatus fullyPresent = statuses.firstWhere(
      (status) => status.definition.id == 'fully-present',
    );

    expect(firstPulse.isUnlocked, isTrue);
    expect(onARoll.hintText, 'Extend your streak by 1 more day.');
    expect(levelUp.progressText, 'Level 1 / 2');
    expect(emotionCartographer.progressText, '3 / 7 unique emotions');
    expect(
      emotionCartographer.hintText,
      'Accept 4 more unique emotions to unlock this badge.',
    );
    expect(contextCurious.progressText, '2 / 5 sessions with context');
    expect(contextCurious.hintText, 'Add context tags in 3 more sessions.');
    expect(fullyPresent.progressText, '1 / 3 fully tagged sessions');
    expect(
      fullyPresent.hintText,
      'Complete 2 more sessions with all three context tags.',
    );
  });
}
