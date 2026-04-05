import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_flutter/core/models/pulse_leaderboard.dart';
import 'package:pulse_flutter/core/models/pulse_level_progress.dart';
import 'package:pulse_flutter/core/models/pulse_streak.dart';
import 'package:pulse_flutter/core/models/user_profile.dart';
import 'package:pulse_flutter/core/providers/user_profile_providers.dart';

final currentUserLeaderboardStateProvider =
    Provider<AsyncValue<PulseLeaderboardState?>>((ref) {
      final AsyncValue<PulseUserProfile?> profileAsync = ref.watch(
        currentUserProfileProvider,
      );
      final PulseStreak streak = ref.watch(currentUserStreakProvider);
      final PulseLevelProgress levelProgress = ref.watch(
        currentUserLevelProgressProvider,
      );

      return profileAsync.whenData((profile) {
        if (profile == null) {
          return null;
        }

        return PulseLeaderboardState.fromProfile(
          profile,
          currentStreak: streak.currentStreak,
          currentLevel: levelProgress.currentLevel,
        );
      });
    });
