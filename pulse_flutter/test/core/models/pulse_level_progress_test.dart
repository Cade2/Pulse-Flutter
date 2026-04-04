import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_flutter/core/models/pulse_level_progress.dart';
import 'package:pulse_flutter/core/models/pulse_session_history_entry.dart';

void main() {
  test('fromTotalXp derives the correct level and progress', () {
    final PulseLevelProgress progress = PulseLevelProgress.fromTotalXp(135);

    expect(progress.currentLevel, 2);
    expect(progress.totalXp, 135);
    expect(progress.xpIntoLevel, 35);
    expect(progress.xpToNextLevel, 65);
  });

  test('sessionXp adds bonus xp for selected context tags', () {
    final int xp = PulseLevelProgress.sessionXp(
      contextSocial: 'Friends',
      contextEnergy: 'High',
      contextSleep: 'Good',
    );

    expect(xp, 65);
  });

  test('addXp updates total xp and level together', () {
    const PulseLevelProgress progress = PulseLevelProgress(
      totalXp: 90,
      currentLevel: 1,
    );

    final PulseLevelProgress updated = progress.addXp(15);

    expect(updated.totalXp, 105);
    expect(updated.currentLevel, 2);
    expect(updated.xpIntoLevel, 5);
  });

  test('session history entries rebuild total xp and level', () {
    const List<PulseSessionHistoryEntry> sessions = <PulseSessionHistoryEntry>[
      PulseSessionHistoryEntry(date: '2026-04-01'),
      PulseSessionHistoryEntry(
        date: '2026-04-02',
        contextSocial: 'Friends',
        contextEnergy: 'High',
      ),
      PulseSessionHistoryEntry(
        date: '2026-04-03',
        contextSocial: 'Family',
        contextEnergy: 'Steady',
        contextSleep: 'Good',
      ),
    ];

    final PulseLevelProgress progress = PulseLevelProgress.fromSessionXpAwards(
      sessions.map((session) => session.earnedXp),
    );

    expect(progress.totalXp, 175);
    expect(progress.currentLevel, 2);
    expect(progress.xpIntoLevel, 75);
    expect(progress.xpToNextLevel, 25);
  });
}
