import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_flutter/core/models/pulse_streak.dart';

void main() {
  test('recordCompletion increments a streak on consecutive days', () {
    const PulseStreak streak = PulseStreak(
      currentStreak: 3,
      longestStreak: 4,
      lastSessionDate: '2026-04-03',
    );

    final PulseStreak updated = streak.recordCompletion('2026-04-04');

    expect(updated.currentStreak, 4);
    expect(updated.longestStreak, 4);
    expect(updated.lastSessionDate, '2026-04-04');
  });

  test('recordCompletion keeps the streak unchanged on the same day', () {
    const PulseStreak streak = PulseStreak(
      currentStreak: 2,
      longestStreak: 5,
      lastSessionDate: '2026-04-04',
    );

    final PulseStreak updated = streak.recordCompletion('2026-04-04');

    expect(updated.currentStreak, 2);
    expect(updated.longestStreak, 5);
    expect(updated.lastSessionDate, '2026-04-04');
  });

  test('recordCompletion resets the streak after missed days', () {
    const PulseStreak streak = PulseStreak(
      currentStreak: 6,
      longestStreak: 6,
      lastSessionDate: '2026-04-01',
    );

    final PulseStreak updated = streak.recordCompletion('2026-04-04');

    expect(updated.currentStreak, 1);
    expect(updated.longestStreak, 6);
    expect(updated.lastSessionDate, '2026-04-04');
  });
}
