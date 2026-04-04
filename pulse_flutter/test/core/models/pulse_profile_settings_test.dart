import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_flutter/core/models/pulse_profile_settings.dart';

void main() {
  test('profile settings fall back to safe defaults when missing', () {
    const PulseProfileSettings settings = PulseProfileSettings();

    expect(settings.preferredReminderTime, '20:00');
    expect(settings.dailyRemindersEnabled, isTrue);
    expect(settings.streakRemindersEnabled, isTrue);
    expect(settings.weeklySummaryEnabled, isFalse);
    expect(settings.appearanceMode, PulseAppearanceMode.dark);
  });

  test('profile settings normalize invalid stored values', () {
    final PulseProfileSettings settings =
        PulseProfileSettings.fromFirestoreData(<String, Object?>{
          'preferredReminderTime': '8:30',
          'dailyRemindersEnabled': 'yes',
          'streakRemindersEnabled': true,
          'weeklySummaryEnabled': null,
          'appearanceMode': 'LIGHT',
        });

    expect(settings.preferredReminderTime, '08:30');
    expect(settings.dailyRemindersEnabled, isTrue);
    expect(settings.streakRemindersEnabled, isTrue);
    expect(settings.weeklySummaryEnabled, isFalse);
    expect(settings.appearanceMode, PulseAppearanceMode.light);
  });

  test('profile settings expose reminder time helpers', () {
    final PulseProfileSettings settings = PulseProfileSettings(
      preferredReminderTime: PulseProfileSettings.formatStorageTime(
        const TimeOfDay(hour: 6, minute: 15),
      ),
    );

    expect(settings.reminderTimeOfDay.hour, 6);
    expect(settings.reminderTimeOfDay.minute, 15);
    expect(settings.reminderTimeLabel, '6:15 AM');
  });
}
