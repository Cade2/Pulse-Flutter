import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_flutter/core/models/pulse_profile_settings.dart';
import 'package:pulse_flutter/core/notifications/pulse_local_notification_service.dart';

void main() {
  test(
    'nextReminderDate keeps today when the reminder time is still ahead',
    () {
      final DateTime nextReminder =
          PulseLocalNotificationService.nextReminderDate(
            reminderTime: const TimeOfDay(hour: 20, minute: 0),
            now: DateTime(2026, 4, 4, 9, 30),
          );

      expect(nextReminder, DateTime(2026, 4, 4, 20));
    },
  );

  test('nextReminderDate rolls to tomorrow when today has already passed', () {
    final DateTime nextReminder =
        PulseLocalNotificationService.nextReminderDate(
          reminderTime: const TimeOfDay(hour: 8, minute: 15),
          now: DateTime(2026, 4, 4, 20, 30),
        );

    expect(nextReminder, DateTime(2026, 4, 5, 8, 15));
  });

  test('upcomingStreakRiskReminderDates returns both reminders before 6pm', () {
    final List<DateTime> reminders =
        PulseLocalNotificationService.upcomingStreakRiskReminderDates(
          now: DateTime(2026, 4, 4, 17, 0),
        );

    expect(reminders, <DateTime>[
      DateTime(2026, 4, 4, 18),
      DateTime(2026, 4, 4, 21),
    ]);
  });

  test(
    'upcomingStreakRiskReminderDates keeps only the final reminder after 6pm',
    () {
      final List<DateTime> reminders =
          PulseLocalNotificationService.upcomingStreakRiskReminderDates(
            now: DateTime(2026, 4, 4, 18, 30),
          );

      expect(reminders, <DateTime>[DateTime(2026, 4, 4, 21)]);
    },
  );

  test('upcomingStreakRiskReminderDates returns none after 9pm', () {
    final List<DateTime> reminders =
        PulseLocalNotificationService.upcomingStreakRiskReminderDates(
          now: DateTime(2026, 4, 4, 21, 30),
        );

    expect(reminders, isEmpty);
  });

  test(
    'nextWeeklySummaryReminderDate keeps the current Sunday evening when still ahead',
    () {
      final DateTime nextReminder =
          PulseLocalNotificationService.nextWeeklySummaryReminderDate(
            now: DateTime(2026, 4, 5, 16, 0),
          );

      expect(nextReminder, DateTime(2026, 4, 5, 19));
    },
  );

  test('nextWeeklySummaryReminderDate rolls to next Sunday when needed', () {
    final DateTime nextReminder =
        PulseLocalNotificationService.nextWeeklySummaryReminderDate(
          now: DateTime(2026, 4, 5, 20, 0),
        );

    expect(nextReminder, DateTime(2026, 4, 12, 19));
  });

  test(
    'syncState forwards settings and incomplete-day state to the reminder service',
    () async {
      final _FakePulseReminderService fakeService = _FakePulseReminderService();
      final PulseReminderSyncController controller =
          PulseReminderSyncController(fakeService);

      await controller.syncState(
        const PulseReminderSyncState(
          uid: 'test-user',
          settings: PulseProfileSettings(
            preferredReminderTime: '18:45',
            dailyRemindersEnabled: true,
            streakRemindersEnabled: true,
            weeklySummaryEnabled: true,
          ),
          hasCompletedToday: false,
        ),
      );

      expect(fakeService.syncCallCount, 1);
      expect(fakeService.lastSettings, isNotNull);
      expect(fakeService.lastSettings!.preferredReminderTime, '18:45');
      expect(fakeService.lastHasCompletedToday, isFalse);
      expect(fakeService.cancelCount, 0);
    },
  );

  test(
    'syncState forwards completed-today state so streak-risk reminders can be skipped',
    () async {
      final _FakePulseReminderService fakeService = _FakePulseReminderService();
      final PulseReminderSyncController controller =
          PulseReminderSyncController(fakeService);

      await controller.syncState(
        const PulseReminderSyncState(
          uid: 'test-user',
          settings: PulseProfileSettings(streakRemindersEnabled: true),
          hasCompletedToday: true,
        ),
      );

      expect(fakeService.syncCallCount, 1);
      expect(fakeService.lastHasCompletedToday, isTrue);
      expect(fakeService.cancelCount, 0);
    },
  );

  test('syncState cancels reminders when the user signs out', () async {
    final _FakePulseReminderService fakeService = _FakePulseReminderService();
    final PulseReminderSyncController controller = PulseReminderSyncController(
      fakeService,
    );

    await controller.syncState(const PulseReminderSyncState.signedOut());

    expect(fakeService.syncCallCount, 0);
    expect(fakeService.cancelCount, 1);
  });
}

class _FakePulseReminderService implements PulseReminderService {
  PulseProfileSettings? lastSettings;
  bool? lastHasCompletedToday;
  int syncCallCount = 0;
  int cancelCount = 0;

  @override
  Future<void> cancelUserReminders() async {
    cancelCount += 1;
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<void> syncReminders({
    required PulseProfileSettings settings,
    required bool hasCompletedToday,
  }) async {
    syncCallCount += 1;
    lastSettings = settings;
    lastHasCompletedToday = hasCompletedToday;
  }
}
