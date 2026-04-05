import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_flutter/app/pulse_notification_routing.dart';
import 'package:pulse_flutter/app/router.dart';
import 'package:pulse_flutter/app/theme.dart';
import 'package:pulse_flutter/core/notifications/pulse_firebase_messaging_service.dart';
import 'package:pulse_flutter/core/notifications/pulse_push_message.dart';
import 'package:pulse_flutter/core/providers/auth_providers.dart';
import 'package:pulse_flutter/core/providers/messaging_providers.dart';
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
  late final ProviderSubscription<String?> _messagingUserSubscription;
  late final StreamSubscription<PulsePushMessage> _openedPushMessageSubscription;
  String? _lastHandledOpenedMessageKey;
  bool _hasRenderedFirstFrame = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hasRenderedFirstFrame = true;
    });
    final PulseMessagingController messagingController = ref.read(
      pulseMessagingControllerProvider,
    );
    _openedPushMessageSubscription = messagingController.openedMessages.listen(
      _handleOpenedPushMessage,
    );
    unawaited(_initializeMessaging(messagingController));
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
    _messagingUserSubscription = ref.listenManual<String?>(
      currentUserIdProvider,
      (previous, next) {
        if (previous == next) {
          return;
        }

        unawaited(
          ref.read(pulseMessagingControllerProvider).syncCurrentUser(next),
        );
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _reminderSubscription.close();
    _messagingUserSubscription.close();
    unawaited(_openedPushMessageSubscription.cancel());
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

  Future<void> _initializeMessaging(
    PulseMessagingController messagingController,
  ) async {
    await messagingController.initialize();

    final PulsePushMessage? initialMessage =
        messagingController.lastOpenedMessage;
    if (initialMessage != null) {
      _handleOpenedPushMessage(initialMessage);
    }
  }

  void _handleOpenedPushMessage(PulsePushMessage message) {
    if (_lastHandledOpenedMessageKey == message.routingKey) {
      return;
    }

    _lastHandledOpenedMessageKey = message.routingKey;
    final String location = PulseNotificationRouting.locationForMessage(message);
    debugPrint('Pulse notification routing to $location');

    void routeToNotificationTarget() {
      if (!mounted) {
        return;
      }

      ref.read(appRouterProvider).go(location);
    }

    if (_hasRenderedFirstFrame) {
      routeToNotificationTarget();
      return;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _hasRenderedFirstFrame = true;
      routeToNotificationTarget();
    });
  }
}
