import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_flutter/core/firestore/swipe_session_repository.dart';
import 'package:pulse_flutter/core/providers/auth_providers.dart';
import 'package:pulse_flutter/core/providers/user_profile_providers.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_record.dart';

final swipeSessionRepositoryProvider = Provider<SwipeSessionRepository>((ref) {
  return FirestoreSwipeSessionRepository(ref.watch(firebaseFirestoreProvider));
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
