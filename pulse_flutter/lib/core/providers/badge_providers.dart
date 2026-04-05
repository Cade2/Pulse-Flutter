import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_flutter/core/models/pulse_badge.dart';
import 'package:pulse_flutter/core/models/pulse_session_history_entry.dart';
import 'package:pulse_flutter/core/providers/swipe_session_providers.dart';
import 'package:pulse_flutter/core/providers/user_profile_providers.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_record.dart';

final currentUserBadgeStatusesProvider =
    Provider<AsyncValue<List<PulseBadgeStatus>>>((ref) {
      final AsyncValue<List<SwipeSessionRecord>> sessionsAsync = ref.watch(
        userSwipeSessionsProvider,
      );
      final int longestStreak = ref
          .watch(currentUserStreakProvider)
          .longestStreak;
      final int currentLevel = ref
          .watch(currentUserLevelProgressProvider)
          .currentLevel;

      return sessionsAsync.when<AsyncValue<List<PulseBadgeStatus>>>(
        data: (sessions) {
          final PulseBadgeProgressSnapshot snapshot =
              PulseBadgeProgressSnapshot.fromSessionHistory(
                sessionHistory: sessions.map((session) {
                  return PulseSessionHistoryEntry(
                    date: session.date,
                    acceptedEmotions: session.acceptedEmotions,
                    contextSocial: session.contextSocial,
                    contextEnergy: session.contextEnergy,
                    contextSleep: session.contextSleep,
                  );
                }),
                longestStreak: longestStreak,
                currentLevel: currentLevel,
              );
          final List<String> unlockedBadgeIds =
              PulseBadgeCatalog.unlockedBadgeIds(snapshot);

          return AsyncValue.data(
            PulseBadgeCatalog.statuses(
              snapshot,
              unlockedBadgeIds: unlockedBadgeIds,
            ),
          );
        },
        loading: () => const AsyncValue.loading(),
        error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
      );
    });
