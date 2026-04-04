import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_flutter/core/firestore/user_messaging_repository.dart';
import 'package:pulse_flutter/core/notifications/pulse_firebase_messaging_service.dart';
import 'package:pulse_flutter/core/notifications/pulse_local_notification_service.dart';
import 'package:pulse_flutter/core/notifications/pulse_push_message.dart';

final pulseMessagingServiceProvider = Provider<PulseMessagingService>((ref) {
  return const NoopPulseMessagingService();
});

final pulseForegroundNotificationPresenterProvider =
    Provider<PulseForegroundNotificationPresenter>((ref) {
      return const NoopPulseReminderService();
    });

final userMessagingRepositoryProvider = Provider<UserMessagingRepository>((
  ref,
) {
  return const NoopUserMessagingRepository();
});

final pulseMessagingControllerProvider = Provider<PulseMessagingController>((
  ref,
) {
  final PulseMessagingController controller = PulseMessagingController(
    messagingService: ref.watch(pulseMessagingServiceProvider),
    userMessagingRepository: ref.watch(userMessagingRepositoryProvider),
    notificationPresenter: ref.watch(
      pulseForegroundNotificationPresenterProvider,
    ),
  );
  ref.onDispose(controller.dispose);
  return controller;
});

final pulseOpenedPushMessageProvider = StreamProvider<PulsePushMessage>((ref) {
  return ref.watch(pulseMessagingControllerProvider).openedMessages;
});
