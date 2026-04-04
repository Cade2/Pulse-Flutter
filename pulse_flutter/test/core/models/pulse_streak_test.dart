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

  test('fromSessionDates rebuilds current and longest streak values', () {
    final PulseStreak rebuilt = PulseStreak.fromSessionDates(const <String>[
      '2026-04-01',
      '2026-04-02',
      '2026-04-04',
      '2026-04-05',
      '2026-04-06',
    ], currentDate: DateTime(2026, 4, 6));

    expect(rebuilt.currentStreak, 3);
    expect(rebuilt.longestStreak, 3);
    expect(rebuilt.lastSessionDate, '2026-04-06');
  });

  test('fromSessionDates resets current streak after missed days', () {
    final PulseStreak rebuilt = PulseStreak.fromSessionDates(const <String>[
      '2026-04-01',
      '2026-04-02',
      '2026-04-03',
    ], currentDate: DateTime(2026, 4, 6));

    expect(rebuilt.currentStreak, 0);
    expect(rebuilt.longestStreak, 3);
    expect(rebuilt.lastSessionDate, '2026-04-03');
  });

  test('effectiveAsOf zeroes stale current streak while keeping longest', () {
    const PulseStreak streak = PulseStreak(
      currentStreak: 5,
      longestStreak: 7,
      lastSessionDate: '2026-04-02',
    );

    final PulseStreak effective = streak.effectiveAsOf(DateTime(2026, 4, 5));

    expect(effective.currentStreak, 0);
    expect(effective.longestStreak, 7);
    expect(effective.lastSessionDate, '2026-04-02');
  });
}
