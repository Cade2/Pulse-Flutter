import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_flutter/core/notifications/pulse_local_notification_service.dart';

final pulseDailyReminderServiceProvider = Provider<PulseDailyReminderService>((
  ref,
) {
  return const NoopPulseDailyReminderService();
});

final pulseReminderSyncControllerProvider =
    Provider<PulseReminderSyncController>((ref) {
      final PulseDailyReminderService reminderService = ref.watch(
        pulseDailyReminderServiceProvider,
      );
      return PulseReminderSyncController(reminderService);
    });
