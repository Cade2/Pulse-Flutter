import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_flutter/core/firestore/swipe_session_repository.dart';
import 'package:pulse_flutter/core/providers/auth_providers.dart';
import 'package:pulse_flutter/core/providers/user_profile_providers.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_record.dart';

final swipeSessionRepositoryProvider = Provider<SwipeSessionRepository>((ref) {
  return FirestoreSwipeSessionRepository(ref.watch(firebaseFirestoreProvider));
});

final currentSessionDateProvider = Provider<DateTime>((ref) {
  return DateTime.now();
});

final todaySessionIdProvider = Provider<String>((ref) {
  final DateTime currentDate = ref.watch(currentSessionDateProvider);
  return SwipeSessionRecord.sessionIdForDate(currentDate);
});

final todaySwipeSessionProvider = StreamProvider<SwipeSessionRecord?>((ref) {
  final String? uid = ref.watch(currentUserIdProvider);

  if (uid == null || uid.isEmpty) {
    return Stream.value(null);
  }

  final String sessionId = ref.watch(todaySessionIdProvider);

  return ref
      .watch(swipeSessionRepositoryProvider)
      .watchSession(uid: uid, sessionId: sessionId);
});

final hasCompletedTodayProvider = Provider<bool>((ref) {
  return ref.watch(todaySwipeSessionProvider).asData?.value != null;
});

final userSwipeSessionsProvider = StreamProvider<List<SwipeSessionRecord>>((
  ref,
) {
  final String? uid = ref.watch(currentUserIdProvider);

  if (uid == null || uid.isEmpty) {
    return Stream.value(const <SwipeSessionRecord>[]);
  }

  return ref.watch(swipeSessionRepositoryProvider).watchSessions(uid: uid);
});
