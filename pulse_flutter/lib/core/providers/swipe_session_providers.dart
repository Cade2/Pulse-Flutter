import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_flutter/core/firestore/swipe_session_repository.dart';
import 'package:pulse_flutter/core/offline/pending_session_sync_controller.dart';
import 'package:pulse_flutter/core/providers/connectivity_providers.dart';
import 'package:pulse_flutter/core/providers/database_providers.dart';
import 'package:pulse_flutter/core/providers/auth_providers.dart';
import 'package:pulse_flutter/core/providers/user_profile_providers.dart';
import 'package:pulse_flutter/features/swipe_session/models/pending_swipe_session.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_record.dart';

final remoteSwipeSessionRepositoryProvider =
    Provider<FirestoreSwipeSessionRepository>((ref) {
      return FirestoreSwipeSessionRepository(
        ref.watch(firebaseFirestoreProvider),
      );
    });

final offlineQueueEnabledProvider = Provider<bool>((ref) => false);

final swipeSessionRepositoryProvider = Provider<SwipeSessionRepository>((ref) {
  if (!ref.watch(offlineQueueEnabledProvider)) {
    return ref.watch(remoteSwipeSessionRepositoryProvider);
  }

  return OfflineFirstSwipeSessionRepository(
    remoteRepository: ref.watch(remoteSwipeSessionRepositoryProvider),
    database: ref.watch(pulseAppDatabaseProvider),
    connectivityService: ref.watch(pulseConnectivityServiceProvider),
  );
});

final pendingSessionSyncControllerProvider =
    Provider<PendingSessionSyncController>((ref) {
      return PendingSessionSyncController(
        database: ref.watch(pulseAppDatabaseProvider),
        remoteRepository: ref.watch(remoteSwipeSessionRepositoryProvider),
        connectivityService: ref.watch(pulseConnectivityServiceProvider),
      );
    });

final pendingSessionSyncUidProvider = Provider<String?>((ref) {
  if (!ref.watch(offlineQueueEnabledProvider)) {
    return null;
  }

  final String? uid = ref.watch(currentUserIdProvider);
  if (uid == null || uid.isEmpty) {
    return null;
  }

  final bool hasPendingSessions = ref.watch(pendingSwipeSessionsProvider).maybeWhen(
        data: (sessions) => sessions.isNotEmpty,
        orElse: () => false,
      );

  if (!hasPendingSessions) {
    return null;
  }

  return ref.watch(pulseConnectivityStateProvider).maybeWhen(
    data: (state) => state.isOnline ? uid : null,
    orElse: () => null,
  );
});

final pendingSwipeSessionsProvider =
    StreamProvider<List<PendingSwipeSession>>((ref) {
      if (!ref.watch(offlineQueueEnabledProvider)) {
        return Stream.value(const <PendingSwipeSession>[]);
      }

      final String? uid = ref.watch(currentUserIdProvider);

      if (uid == null || uid.isEmpty) {
        return Stream.value(const <PendingSwipeSession>[]);
      }

      return ref
          .watch(pulseAppDatabaseProvider)
          .watchPendingSessions(uid)
          .map(
            (rows) => rows
                .map(PendingSwipeSession.fromDatabaseRow)
                .toList(growable: false),
          );
    });

final pendingTodaySwipeSessionProvider = StreamProvider<SwipeSessionRecord?>((
  ref,
) {
  if (!ref.watch(offlineQueueEnabledProvider)) {
    return Stream.value(null);
  }

  final String? uid = ref.watch(currentUserIdProvider);

  if (uid == null || uid.isEmpty) {
    return Stream.value(null);
  }

  final String sessionId = ref.watch(todaySessionIdProvider);
  return ref
      .watch(pulseAppDatabaseProvider)
      .watchPendingSession(uid: uid, sessionId: sessionId)
      .map(
        (row) => row == null
            ? null
            : PendingSwipeSession.fromDatabaseRow(row).session,
      );
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
  final Stream<SwipeSessionRecord?> remoteStream = ref
      .watch(swipeSessionRepositoryProvider)
      .watchSession(uid: uid, sessionId: sessionId);
  if (!ref.watch(offlineQueueEnabledProvider)) {
    return remoteStream;
  }

  final Stream<SwipeSessionRecord?> pendingStream = ref
      .watch(pulseAppDatabaseProvider)
      .watchPendingSession(uid: uid, sessionId: sessionId)
      .map(
        (row) => row == null
            ? null
            : PendingSwipeSession.fromDatabaseRow(row).session,
      );

  return _combineLatest<
    SwipeSessionRecord?,
    SwipeSessionRecord?,
    SwipeSessionRecord?
  >(
    remoteStream,
    pendingStream,
    (remoteSession, pendingSession) => remoteSession ?? pendingSession,
  );
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

  final Stream<List<SwipeSessionRecord>> remoteStream = ref
      .watch(swipeSessionRepositoryProvider)
      .watchSessions(uid: uid);
  if (!ref.watch(offlineQueueEnabledProvider)) {
    return remoteStream;
  }

  final Stream<List<PendingSwipeSession>> pendingStream = ref
      .watch(pulseAppDatabaseProvider)
      .watchPendingSessions(uid)
      .map(
        (rows) => rows
            .map(PendingSwipeSession.fromDatabaseRow)
            .toList(growable: false),
      );

  return _combineLatest<
    List<SwipeSessionRecord>,
    List<PendingSwipeSession>,
    List<SwipeSessionRecord>
  >(
    remoteStream,
    pendingStream,
    (remoteSessions, pendingSessions) => _mergeSessions(
      remoteSessions,
      pendingSessions.map((session) => session.session).toList(growable: false),
    ),
  );
});

Stream<R> _combineLatest<A, B, R>(
  Stream<A> first,
  Stream<B> second,
  R Function(A firstValue, B secondValue) combine,
) {
  return Stream<R>.multi((controller) {
    A? latestFirst;
    B? latestSecond;
    bool hasFirst = false;
    bool hasSecond = false;

    void emitIfReady() {
      if (hasFirst && hasSecond) {
        controller.add(combine(latestFirst as A, latestSecond as B));
      }
    }

    final StreamSubscription<A> firstSubscription = first.listen(
      (value) {
        latestFirst = value;
        hasFirst = true;
        emitIfReady();
      },
      onError: controller.addError,
    );
    final StreamSubscription<B> secondSubscription = second.listen(
      (value) {
        latestSecond = value;
        hasSecond = true;
        emitIfReady();
      },
      onError: controller.addError,
    );

    controller.onCancel = () async {
      await firstSubscription.cancel();
      await secondSubscription.cancel();
    };
  });
}

List<SwipeSessionRecord> _mergeSessions(
  List<SwipeSessionRecord> remoteSessions,
  List<SwipeSessionRecord> pendingSessions,
) {
  final Map<String, SwipeSessionRecord> merged = <String, SwipeSessionRecord>{
    for (final SwipeSessionRecord session in pendingSessions)
      session.sessionId: session,
    for (final SwipeSessionRecord session in remoteSessions)
      session.sessionId: session,
  };

  final List<SwipeSessionRecord> sessions = merged.values.toList(
    growable: false,
  )..sort((a, b) => b.completedAt.compareTo(a.completedAt));

  return sessions;
}
