import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_flutter/core/models/pulse_level_progress.dart';
import 'package:pulse_flutter/core/models/pulse_streak.dart';
import 'package:pulse_flutter/core/models/user_profile.dart';
import 'package:pulse_flutter/core/providers/auth_providers.dart';
import 'package:pulse_flutter/core/firestore/user_profile_repository.dart';

final firebaseFirestoreProvider = Provider<FirebaseFirestore>((ref) {
  return FirebaseFirestore.instance;
});

final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  final FirebaseFirestore firestore = ref.watch(firebaseFirestoreProvider);
  return UserProfileRepository(firestore);
});

final currentUserProfileProvider = StreamProvider<PulseUserProfile?>((ref) {
  final String? uid = ref.watch(currentUserIdProvider);

  if (uid == null || uid.isEmpty) {
    return Stream.value(null);
  }

  return ref.watch(userProfileRepositoryProvider).watchUserProfile(uid);
});

final currentUserStreakProvider = Provider<PulseStreak>((ref) {
  return ref
          .watch(currentUserProfileProvider)
          .asData
          ?.value
          ?.streak
          .effectiveAsOf(DateTime.now()) ??
      const PulseStreak();
});

final currentUserLevelProgressProvider = Provider<PulseLevelProgress>((ref) {
  return ref.watch(currentUserProfileProvider).asData?.value?.levelProgress ??
      const PulseLevelProgress();
});
