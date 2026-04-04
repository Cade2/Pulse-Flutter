import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_flutter/app/router.dart';
import 'package:pulse_flutter/app/theme.dart';
import 'package:pulse_flutter/core/notifications/pulse_local_notification_service.dart';
import 'package:pulse_flutter/core/providers/notification_providers.dart';
import 'package:pulse_flutter/core/providers/user_profile_providers.dart';

class PulseApp extends ConsumerStatefulWidget {
  const PulseApp({super.key});

  @override
  ConsumerState<PulseApp> createState() => _PulseAppState();
}

class _PulseAppState extends ConsumerState<PulseApp> {
  late final ProviderSubscription<PulseReminderSyncState?>
  _reminderSubscription;

  @override
  void initState() {
    super.initState();
    _reminderSubscription = ref.listenManual<PulseReminderSyncState?>(
      pulseReminderSyncStateProvider,
      (previous, next) {
        if (next == null || previous == next) {
          return;
        }

        unawaited(
          ref.read(pulseReminderSyncControllerProvider).syncState(next),
        );
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _reminderSubscription.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final ThemeMode themeMode = ref.watch(currentUserThemeModeProvider);

    return MaterialApp.router(
      title: 'Pulse',
      debugShowCheckedModeBanner: false,
      theme: pulseLightTheme,
      darkTheme: pulseDarkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
