import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_flutter/core/connectivity/pulse_connectivity_service.dart';
import 'package:pulse_flutter/core/database/pulse_app_database.dart';
import 'package:pulse_flutter/core/firestore/swipe_session_repository.dart';
import 'package:pulse_flutter/core/models/pulse_level_progress.dart';
import 'package:pulse_flutter/core/models/pulse_streak.dart';
import 'package:pulse_flutter/core/offline/pending_session_sync_controller.dart';
import 'package:pulse_flutter/features/swipe_session/models/emotion_card.dart';
import 'package:pulse_flutter/features/swipe_session/models/pending_swipe_session.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_record.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_reward_details.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_save_result.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_summary.dart';

void main() {
  group('Offline-first swipe session repository', () {
    late PulseAppDatabase database;

    setUp(() {
      database = PulseAppDatabase.inMemory();
    });

    tearDown(() async {
      await database.close();
    });

    test('queues a session locally when the device is offline', () async {
      final _FakeRemoteSwipeSessionRepository remoteRepository =
          _FakeRemoteSwipeSessionRepository();
      final OfflineFirstSwipeSessionRepository repository =
          OfflineFirstSwipeSessionRepository(
            remoteRepository: remoteRepository,
            database: database,
            connectivityService: const NoopPulseConnectivityService(
              state: PulseConnectivityState.offline(),
            ),
          );

      final SwipeSessionSaveResult result = await repository.saveSession(
        uid: 'user-1',
        summary: _buildSummary(),
        contextSocial: 'Friends',
      );

      final List<PendingSession> rows = await database.readPendingSessions(
        'user-1',
      );

      expect(result.isPendingSync, isTrue);
      expect(remoteRepository.savedRecords, isEmpty);
      expect(rows, hasLength(1));
      expect(rows.single.sessionId, result.session.sessionId);
      expect(rows.single.status, PendingSwipeSessionStatus.pending.storageValue);
    });

    test('syncQueuedSessions replays queued sessions and clears them on success', () async {
      final _FakeRemoteSwipeSessionRepository remoteRepository =
          _FakeRemoteSwipeSessionRepository();
      final OfflineFirstSwipeSessionRepository repository =
          OfflineFirstSwipeSessionRepository(
            remoteRepository: remoteRepository,
            database: database,
            connectivityService: const NoopPulseConnectivityService(
              state: PulseConnectivityState.offline(),
            ),
          );

      final SwipeSessionSaveResult queued = await repository.saveSession(
        uid: 'user-1',
        summary: _buildSummary(),
        contextEnergy: 'Steady',
      );

      final PendingSessionSyncController controller =
          PendingSessionSyncController(
            database: database,
            remoteRepository: remoteRepository,
            connectivityService: const NoopPulseConnectivityService(),
          );

      await controller.syncQueuedSessions('user-1');

      final List<PendingSession> rows = await database.readPendingSessions(
        'user-1',
      );

      expect(rows, isEmpty);
      expect(remoteRepository.savedRecords, hasLength(1));
      expect(
        remoteRepository.savedRecords.single.sessionId,
        queued.session.sessionId,
      );
    });
  });
}

SwipeSessionSummary _buildSummary() {
  return SwipeSessionSummary(
    responses: const <EmotionCardResponse>[
      EmotionCardResponse(
        card: EmotionCard(
          id: 'joy',
          title: 'Joy',
          headline: 'Joy',
          description: 'desc',
          reflectionPrompt: 'prompt',
          accentColor: Color(0xFF2ED3E6),
        ),
        decision: EmotionCardDecision.accept,
      ),
      EmotionCardResponse(
        card: EmotionCard(
          id: 'focus',
          title: 'Focus',
          headline: 'Focus',
          description: 'desc',
          reflectionPrompt: 'prompt',
          accentColor: Color(0xFF2ED3E6),
        ),
        decision: EmotionCardDecision.reject,
      ),
    ],
  );
}

class _FakeRemoteSwipeSessionRepository implements RemoteSwipeSessionRepository {
  final List<SwipeSessionRecord> savedRecords = <SwipeSessionRecord>[];

  @override
  Future<SwipeSessionSaveResult> saveRecord({
    required String uid,
    required SwipeSessionRecord record,
  }) async {
    savedRecords.add(record);
    return SwipeSessionSaveResult(
      session: record,
      reward: const SwipeSessionRewardDetails(
        xpEarned: 50,
        previousLevelProgress: PulseLevelProgress(),
        levelProgress: PulseLevelProgress(totalXp: 50, currentLevel: 1),
        previousStreak: PulseStreak(),
        currentStreak: PulseStreak(currentStreak: 1, longestStreak: 1),
      ),
    );
  }

  @override
  Future<SwipeSessionSaveResult> saveSession({
    required String uid,
    required SwipeSessionSummary summary,
    String? contextSocial,
    String? contextEnergy,
    String? contextSleep,
  }) {
    throw UnimplementedError();
  }

  @override
  Stream<SwipeSessionRecord?> watchSession({
    required String uid,
    required String sessionId,
  }) {
    return Stream<SwipeSessionRecord?>.value(null);
  }

  @override
  Stream<List<SwipeSessionRecord>> watchSessions({required String uid}) {
    return Stream<List<SwipeSessionRecord>>.value(
      <SwipeSessionRecord>[],
    );
  }
}
