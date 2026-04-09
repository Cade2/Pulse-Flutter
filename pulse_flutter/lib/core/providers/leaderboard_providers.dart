import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_flutter/core/models/pulse_leaderboard.dart';
import 'package:pulse_flutter/core/models/pulse_level_progress.dart';
import 'package:pulse_flutter/core/models/pulse_streak.dart';
import 'package:pulse_flutter/core/models/user_profile.dart';
import 'package:pulse_flutter/core/providers/user_profile_providers.dart';

final currentUserReferralCircleProvider =
    FutureProvider<List<PulseUserProfile>>((ref) async {
      final PulseUserProfile? profile = ref
          .watch(currentUserProfileProvider)
          .asData
          ?.value;
      if (profile == null) {
        return const <PulseUserProfile>[];
      }

      return ref
          .watch(userProfileRepositoryProvider)
          .fetchReferralCircleProfiles(profile);
    });

final currentUserLeaderboardStateProvider =
    Provider<AsyncValue<PulseLeaderboardState?>>((ref) {
      final AsyncValue<PulseUserProfile?> profileAsync = ref.watch(
        currentUserProfileProvider,
      );
      final PulseStreak streak = ref.watch(currentUserStreakProvider);
      final PulseLevelProgress levelProgress = ref.watch(
        currentUserLevelProgressProvider,
      );
      final AsyncValue<List<PulseUserProfile>> socialProfilesAsync = ref.watch(
        currentUserReferralCircleProvider,
      );

      return profileAsync.when(
        data: (profile) {
          if (profile == null) {
            return const AsyncValue<PulseLeaderboardState?>.data(null);
          }

          return socialProfilesAsync.when(
            data: (socialProfiles) {
              return AsyncValue<PulseLeaderboardState?>.data(
                PulseLeaderboardState.fromProfile(
                  profile,
                  currentStreak: streak.currentStreak,
                  currentLevel: levelProgress.currentLevel,
                  socialProfiles: socialProfiles,
                ),
              );
            },
            loading: () => const AsyncValue<PulseLeaderboardState?>.loading(),
            error: (error, stackTrace) =>
                AsyncValue<PulseLeaderboardState?>.error(error, stackTrace),
          );
        },
        loading: () => const AsyncValue<PulseLeaderboardState?>.loading(),
        error: (error, stackTrace) =>
            AsyncValue<PulseLeaderboardState?>.error(error, stackTrace),
      );
    });
