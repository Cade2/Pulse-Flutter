import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_flutter/core/models/pulse_insights.dart';
import 'package:pulse_flutter/core/providers/swipe_session_providers.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_record.dart';

final currentUserInsightsProvider = Provider<AsyncValue<PulseInsightsReport>>((
  ref,
) {
  final AsyncValue<List<SwipeSessionRecord>> sessionsAsync = ref.watch(
    userSwipeSessionsProvider,
  );
  final DateTime currentDate = ref.watch(currentSessionDateProvider);

  return sessionsAsync.when<AsyncValue<PulseInsightsReport>>(
    data: (sessions) {
      return AsyncValue.data(
        PulseInsightsReport.fromSessions(sessions, currentDate: currentDate),
      );
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});
