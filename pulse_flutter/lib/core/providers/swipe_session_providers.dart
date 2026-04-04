import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_flutter/core/firestore/swipe_session_repository.dart';
import 'package:pulse_flutter/core/providers/user_profile_providers.dart';

final swipeSessionRepositoryProvider = Provider<SwipeSessionRepository>((ref) {
  return FirestoreSwipeSessionRepository(ref.watch(firebaseFirestoreProvider));
});
