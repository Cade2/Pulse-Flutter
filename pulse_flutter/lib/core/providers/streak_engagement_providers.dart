import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_flutter/core/models/pulse_streak.dart';
import 'package:pulse_flutter/core/models/pulse_streak_engagement.dart';
import 'package:pulse_flutter/core/models/user_profile.dart';
import 'package:pulse_flutter/core/providers/swipe_session_providers.dart';
import 'package:pulse_flutter/core/providers/user_profile_providers.dart';

final currentUserStreakEngagementProvider = Provider<PulseStreakEngagement>((
  ref,
) {
  final PulseUserProfile? profile = ref
      .watch(currentUserProfileProvider)
      .asData
      ?.value;
  final PulseStreak storedStreak =
      profile?.streak ?? ref.watch(currentUserStreakProvider);

  return PulseStreakEngagement.fromStreak(
    streak: storedStreak,
    currentDate: ref.watch(currentSessionDateProvider),
  );
});
