import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_flutter/core/models/pulse_profile_settings.dart';
import 'package:pulse_flutter/core/models/user_profile.dart';
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

  test(
    'syncProfile schedules daily reminders from saved profile settings',
    () async {
      final _FakePulseDailyReminderService fakeService =
          _FakePulseDailyReminderService();
      final PulseReminderSyncController controller =
          PulseReminderSyncController(fakeService);

      await controller.syncProfile(
        const PulseUserProfile(
          uid: 'test-user',
          email: 'ava@example.com',
          settings: PulseProfileSettings(
            preferredReminderTime: '18:45',
            dailyRemindersEnabled: true,
          ),
        ),
      );

      expect(fakeService.scheduledSettings, isNotNull);
      expect(fakeService.scheduledSettings!.preferredReminderTime, '18:45');
      expect(fakeService.cancelCount, 0);
    },
  );

  test(
    'syncProfile cancels reminders when settings disable daily reminders',
    () async {
      final _FakePulseDailyReminderService fakeService =
          _FakePulseDailyReminderService();
      final PulseReminderSyncController controller =
          PulseReminderSyncController(fakeService);

      await controller.syncProfile(
        const PulseUserProfile(
          uid: 'test-user',
          email: 'ava@example.com',
          settings: PulseProfileSettings(dailyRemindersEnabled: false),
        ),
      );

      expect(fakeService.scheduledSettings, isNull);
      expect(fakeService.cancelCount, 1);
    },
  );

  test(
    'syncProfile cancels reminders when no signed-in profile exists',
    () async {
      final _FakePulseDailyReminderService fakeService =
          _FakePulseDailyReminderService();
      final PulseReminderSyncController controller =
          PulseReminderSyncController(fakeService);

      await controller.syncProfile(null);

      expect(fakeService.scheduledSettings, isNull);
      expect(fakeService.cancelCount, 1);
    },
  );
}

class _FakePulseDailyReminderService implements PulseDailyReminderService {
  PulseProfileSettings? scheduledSettings;
  int cancelCount = 0;

  @override
  Future<void> cancelDailyReminder() async {
    cancelCount += 1;
  }

  @override
  Future<void> initialize() async {}

  @override
  Future<void> scheduleDailyReminder(PulseProfileSettings settings) async {
    scheduledSettings = settings;
  }
}
