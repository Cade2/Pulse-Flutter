import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_flutter/core/models/pulse_badge.dart';

void main() {
  test('unlockedBadgeIds backfills badges from existing progress', () {
    const PulseBadgeProgressSnapshot snapshot = PulseBadgeProgressSnapshot(
      sessionCount: 7,
      longestStreak: 3,
      currentLevel: 2,
    );

    expect(PulseBadgeCatalog.unlockedBadgeIds(snapshot), <String>[
      'first-pulse',
      'on-a-roll',
      'level-up',
      'seven-check-ins',
    ]);
  });

  test('statuses keep progress hints for locked badges', () {
    const PulseBadgeProgressSnapshot snapshot = PulseBadgeProgressSnapshot(
      sessionCount: 1,
      longestStreak: 2,
      currentLevel: 1,
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
    final PulseBadgeStatus sevenCheckIns = statuses.firstWhere(
      (status) => status.definition.id == 'seven-check-ins',
    );

    expect(firstPulse.isUnlocked, isTrue);
    expect(onARoll.isUnlocked, isFalse);
    expect(onARoll.hintText, '2 / 3 streak days');
    expect(levelUp.hintText, 'Level 1 / 2');
    expect(sevenCheckIns.hintText, '1 / 7 sessions');
  });
}
