import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_flutter/app/router.dart';
import 'package:pulse_flutter/app/theme.dart';
import 'package:pulse_flutter/core/models/user_profile.dart';
import 'package:pulse_flutter/core/providers/notification_providers.dart';
import 'package:pulse_flutter/core/providers/user_profile_providers.dart';

class PulseApp extends ConsumerStatefulWidget {
  const PulseApp({super.key});

  @override
  ConsumerState<PulseApp> createState() => _PulseAppState();
}

class _PulseAppState extends ConsumerState<PulseApp> {
  late final ProviderSubscription<AsyncValue<PulseUserProfile?>>
  _profileSubscription;

  @override
  void initState() {
    super.initState();
    _profileSubscription = ref.listenManual<AsyncValue<PulseUserProfile?>>(
      currentUserProfileProvider,
      (previous, next) {
        final PulseUserProfile? previousProfile = previous?.asData?.value;
        final PulseUserProfile? nextProfile = next.asData?.value;
        final bool previousWasData = previous?.hasValue ?? false;

        if (previousWasData &&
            next.hasValue &&
            _hasSameReminderSettings(previousProfile, nextProfile)) {
          return;
        }

        next.whenData((profile) {
          unawaited(
            ref.read(pulseReminderSyncControllerProvider).syncProfile(profile),
          );
        });
      },
      fireImmediately: true,
    );
  }

  @override
  void dispose() {
    _profileSubscription.close();
    super.dispose();
  }

  bool _hasSameReminderSettings(
    PulseUserProfile? previousProfile,
    PulseUserProfile? nextProfile,
  ) {
    if (previousProfile == null || nextProfile == null) {
      return previousProfile == nextProfile;
    }

    return previousProfile.uid == nextProfile.uid &&
        previousProfile.settings.preferredReminderTime ==
            nextProfile.settings.preferredReminderTime &&
        previousProfile.settings.dailyRemindersEnabled ==
            nextProfile.settings.dailyRemindersEnabled;
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
