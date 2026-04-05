import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_flutter/app/app.dart';
import 'package:pulse_flutter/core/firestore/user_messaging_repository.dart';
import 'package:pulse_flutter/core/notifications/pulse_firebase_messaging_service.dart';
import 'package:pulse_flutter/core/notifications/pulse_local_notification_service.dart';
import 'package:pulse_flutter/core/providers/messaging_providers.dart';
import 'package:pulse_flutter/core/providers/notification_providers.dart';
import 'package:pulse_flutter/firebase_options.dart';

@pragma('vm:entry-point')
Future<void> pulseFirebaseMessagingBackgroundHandler(
  RemoteMessage message,
) async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  debugPrint('Pulse FCM background message: ${message.messageId}');
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseMessaging.onBackgroundMessage(
    pulseFirebaseMessagingBackgroundHandler,
  );
  final PulseLocalNotificationService notificationService =
      PulseLocalNotificationService();
  final PulseFirebaseMessagingService messagingService =
      PulseFirebaseMessagingService();
  final UserMessagingRepository userMessagingRepository =
      UserMessagingRepository(FirebaseFirestore.instance);
  await notificationService.initialize();
  await messagingService.initialize();
  runApp(
    ProviderScope(
      overrides: [
        pulseReminderServiceProvider.overrideWithValue(notificationService),
        pulseForegroundNotificationPresenterProvider.overrideWithValue(
          notificationService,
        ),
        pulsePushNotificationTapSourceProvider.overrideWithValue(
          notificationService,
        ),
        pulseMessagingServiceProvider.overrideWithValue(messagingService),
        userMessagingRepositoryProvider.overrideWithValue(
          userMessagingRepository,
        ),
      ],
      child: const PulseApp(),
    ),
  );
}
