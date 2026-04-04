import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_flutter/app/app.dart';
import 'package:pulse_flutter/core/notifications/pulse_local_notification_service.dart';
import 'package:pulse_flutter/core/providers/notification_providers.dart';
import 'package:pulse_flutter/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final PulseLocalNotificationService notificationService =
      PulseLocalNotificationService();
  await notificationService.initialize();
  runApp(
    ProviderScope(
      overrides: [
        pulseDailyReminderServiceProvider.overrideWithValue(
          notificationService,
        ),
      ],
      child: const PulseApp(),
    ),
  );
}
