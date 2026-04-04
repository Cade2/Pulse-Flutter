import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_flutter/core/models/user_profile.dart';
import 'package:pulse_flutter/core/notifications/pulse_local_notification_service.dart';
import 'package:pulse_flutter/core/providers/auth_providers.dart';
import 'package:pulse_flutter/core/providers/swipe_session_providers.dart';
import 'package:pulse_flutter/core/providers/user_profile_providers.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_record.dart';

final pulseReminderServiceProvider = Provider<PulseReminderService>((ref) {
  return const NoopPulseReminderService();
});

final pulseReminderSyncControllerProvider =
    Provider<PulseReminderSyncController>((ref) {
      final PulseReminderService reminderService = ref.watch(
        pulseReminderServiceProvider,
      );
      return PulseReminderSyncController(reminderService);
    });

final pulseReminderSyncStateProvider = Provider<PulseReminderSyncState?>((ref) {
  final String? uid = ref.watch(currentUserIdProvider);
  if (uid == null || uid.isEmpty) {
    return const PulseReminderSyncState.signedOut();
  }

  final AsyncValue<PulseUserProfile?> profileAsync = ref.watch(
    currentUserProfileProvider,
  );
  final AsyncValue<SwipeSessionRecord?> todaySessionAsync = ref.watch(
    todaySwipeSessionProvider,
  );

  if (profileAsync.isLoading || todaySessionAsync.isLoading) {
    return null;
  }

  if (profileAsync.hasError || todaySessionAsync.hasError) {
    return null;
  }

  final PulseUserProfile? profile = profileAsync.asData?.value;
  if (profile == null) {
    return const PulseReminderSyncState.signedOut();
  }

  return PulseReminderSyncState(
    uid: uid,
    settings: profile.settings,
    hasCompletedToday: todaySessionAsync.asData?.value != null,
  );
});
