import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pulse_flutter/core/connectivity/pulse_connectivity_service.dart';
import 'package:pulse_flutter/core/database/pulse_app_database.dart';
import 'package:pulse_flutter/core/models/pulse_badge.dart';
import 'package:pulse_flutter/core/models/pulse_level_progress.dart';
import 'package:pulse_flutter/core/models/pulse_session_history_entry.dart';
import 'package:pulse_flutter/core/models/pulse_streak.dart';
import 'package:pulse_flutter/features/swipe_session/models/pending_swipe_session.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_record.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_reward_details.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_save_result.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_summary.dart';

abstract class SwipeSessionRepository {
  Future<SwipeSessionSaveResult> saveSession({
    required String uid,
    required SwipeSessionSummary summary,
    String? contextSocial,
    String? contextEnergy,
    String? contextSleep,
  });

  Stream<SwipeSessionRecord?> watchSession({
    required String uid,
    required String sessionId,
  });

  Stream<List<SwipeSessionRecord>> watchSessions({required String uid});
}

abstract class RemoteSwipeSessionRepository
    implements SwipeSessionRepository {
  Future<SwipeSessionSaveResult> saveRecord({
    required String uid,
    required SwipeSessionRecord record,
  });
}

class FirestoreSwipeSessionRepository
    implements RemoteSwipeSessionRepository {
  const FirestoreSwipeSessionRepository(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<SwipeSessionSaveResult> saveSession({
    required String uid,
    required SwipeSessionSummary summary,
    String? contextSocial,
    String? contextEnergy,
    String? contextSleep,
  }) {
    return saveRecord(
      uid: uid,
      record: SwipeSessionRecord.fromSummary(
        summary: summary,
        contextSocial: contextSocial,
        contextEnergy: contextEnergy,
        contextSleep: contextSleep,
      ),
    );
  }

  @override
  Future<SwipeSessionSaveResult> saveRecord({
    required String uid,
    required SwipeSessionRecord record,
  }) async {
    final List<PulseSessionHistoryEntry> sessionHistory =
        await _readSessionHistory(uid);
    final PulseSessionHistoryEntry pendingSession = PulseSessionHistoryEntry(
      date: record.sessionId,
      contextSocial: record.contextSocial,
      contextEnergy: record.contextEnergy,
      contextSleep: record.contextSleep,
    );
    final List<PulseSessionHistoryEntry> pendingHistory = _upsertSessionHistory(
      sessionHistory,
      pendingSession,
    );
    final PulseStreak previousStreak = _resolveStreakFromHistory(
      sessionHistory,
    );
    final PulseLevelProgress previousProgress =
        _resolveLevelProgressFromHistory(sessionHistory);
    final List<String> previousUnlockedBadgeIds = _resolveUnlockedBadgeIds(
      sessionHistory,
      previousStreak,
      previousProgress,
    );
    final PulseStreak nextStreak = _resolveStreakFromHistory(pendingHistory);
    final PulseLevelProgress nextProgress = _resolveLevelProgressFromHistory(
      pendingHistory,
    );
    final List<String> nextUnlockedBadgeIds = _resolveUnlockedBadgeIds(
      pendingHistory,
      nextStreak,
      nextProgress,
    );
    final int xpEarned = pendingSession.earnedXp;

    return _firestore.runTransaction((transaction) async {
      final DocumentReference<Map<String, dynamic>> userDocument = _firestore
          .collection('users')
          .doc(uid);
      final DocumentReference<Map<String, dynamic>> sessionDocument =
          userDocument.collection('sessions').doc(record.sessionId);
      final DocumentSnapshot<Map<String, dynamic>> sessionSnapshot =
          await transaction.get(sessionDocument);

      if (sessionSnapshot.exists) {
        final PulseSessionHistoryEntry existingSession =
            PulseSessionHistoryEntry.fromFirestoreData(
              data: sessionSnapshot.data() ?? <String, dynamic>{},
              fallbackDate: sessionSnapshot.id,
            );
        final List<PulseSessionHistoryEntry> existingHistory =
            _upsertSessionHistory(sessionHistory, existingSession);
        final PulseLevelProgress existingProgress =
            _resolveLevelProgressFromHistory(existingHistory);
        final PulseStreak existingStreak = _resolveStreakFromHistory(
          existingHistory,
        );
        final List<String> existingUnlockedBadgeIds = _resolveUnlockedBadgeIds(
          existingHistory,
          existingStreak,
          existingProgress,
        );
        final SwipeSessionRewardDetails reward =
            SwipeSessionRewardDetails.fromTransition(
              xpEarned: 0,
              previousLevelProgress: existingProgress,
              levelProgress: existingProgress,
              previousStreak: existingStreak,
              currentStreak: existingStreak,
              previousUnlockedBadgeIds: existingUnlockedBadgeIds,
              unlockedBadgeIds: existingUnlockedBadgeIds,
            );

        transaction.set(userDocument, <String, Object?>{
          ...existingStreak.toFirestore(),
          ...existingProgress.toFirestore(),
          'unlockedBadgeIds': existingUnlockedBadgeIds,
        }, SetOptions(merge: true));

        return SwipeSessionSaveResult(
          session: SwipeSessionRecord.fromFirestore(sessionSnapshot),
          reward: reward,
        );
      }

      final SwipeSessionRewardDetails reward =
          SwipeSessionRewardDetails.fromTransition(
            xpEarned: xpEarned,
            previousLevelProgress: previousProgress,
            levelProgress: nextProgress,
            previousStreak: previousStreak,
            currentStreak: nextStreak,
            previousUnlockedBadgeIds: previousUnlockedBadgeIds,
            unlockedBadgeIds: nextUnlockedBadgeIds,
          );

      transaction.set(sessionDocument, record.toFirestore());
      transaction.set(userDocument, <String, Object?>{
        ...nextStreak.toFirestore(),
        ...nextProgress.toFirestore(),
        'unlockedBadgeIds': nextUnlockedBadgeIds,
      }, SetOptions(merge: true));

      return SwipeSessionSaveResult(session: record, reward: reward);
    });
  }

  Future<List<PulseSessionHistoryEntry>> _readSessionHistory(String uid) async {
    final QuerySnapshot<Map<String, dynamic>> sessionsSnapshot =
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('sessions')
            .get();

    return sessionsSnapshot.docs
        .map((snapshot) {
          return PulseSessionHistoryEntry.fromFirestoreData(
            data: snapshot.data(),
            fallbackDate: snapshot.id,
          );
        })
        .toList(growable: false);
  }

  List<PulseSessionHistoryEntry> _upsertSessionHistory(
    List<PulseSessionHistoryEntry> sessionHistory,
    PulseSessionHistoryEntry session,
  ) {
    final List<PulseSessionHistoryEntry> updatedHistory = sessionHistory
        .where((entry) => entry.date != session.date)
        .toList(growable: true);
    updatedHistory.add(session);
    return updatedHistory;
  }

  PulseStreak _resolveStreakFromHistory(
    List<PulseSessionHistoryEntry> sessionHistory,
  ) {
    if (sessionHistory.isEmpty) {
      return const PulseStreak();
    }

    return PulseStreak.fromSessionDates(
      sessionHistory.map((session) => session.date),
      currentDate: DateTime.now(),
    );
  }

  PulseLevelProgress _resolveLevelProgressFromHistory(
    List<PulseSessionHistoryEntry> sessionHistory,
  ) {
    if (sessionHistory.isEmpty) {
      return const PulseLevelProgress();
    }

    return PulseLevelProgress.fromSessionXpAwards(
      sessionHistory.map((session) => session.earnedXp),
    );
  }

  List<String> _resolveUnlockedBadgeIds(
    List<PulseSessionHistoryEntry> sessionHistory,
    PulseStreak streak,
    PulseLevelProgress levelProgress,
  ) {
    return PulseBadgeCatalog.unlockedBadgeIds(
      PulseBadgeProgressSnapshot(
        sessionCount: sessionHistory.length,
        longestStreak: streak.longestStreak,
        currentLevel: levelProgress.currentLevel,
      ),
    );
  }

  @override
  Stream<SwipeSessionRecord?> watchSession({
    required String uid,
    required String sessionId,
  }) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .doc(sessionId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) {
            return null;
          }

          return SwipeSessionRecord.fromFirestore(snapshot);
        });
  }

  @override
  Stream<List<SwipeSessionRecord>> watchSessions({required String uid}) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .orderBy('completedAt', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map(SwipeSessionRecord.fromFirestore)
              .toList(growable: false);
        });
  }
}

class OfflineFirstSwipeSessionRepository implements SwipeSessionRepository {
  const OfflineFirstSwipeSessionRepository({
    required RemoteSwipeSessionRepository remoteRepository,
    required PulseAppDatabase database,
    required PulseConnectivityService connectivityService,
  }) : _remoteRepository = remoteRepository,
       _database = database,
       _connectivityService = connectivityService;

  final RemoteSwipeSessionRepository _remoteRepository;
  final PulseAppDatabase _database;
  final PulseConnectivityService _connectivityService;

  @override
  Future<SwipeSessionSaveResult> saveSession({
    required String uid,
    required SwipeSessionSummary summary,
    String? contextSocial,
    String? contextEnergy,
    String? contextSleep,
  }) async {
    final SwipeSessionRecord record = SwipeSessionRecord.fromSummary(
      summary: summary,
      contextSocial: contextSocial,
      contextEnergy: contextEnergy,
      contextSleep: contextSleep,
    );

    final bool isOffline = !(await _connectivityService.currentState()).isOnline;
    if (isOffline) {
      return _queuePendingSession(uid: uid, record: record);
    }

    try {
      final SwipeSessionSaveResult result = await _remoteRepository.saveRecord(
        uid: uid,
        record: record,
      );
      await _database.removePendingSession(uid: uid, sessionId: record.sessionId);
      return result;
    } on FirebaseException catch (error) {
      if (_isOfflineFailure(error)) {
        return _queuePendingSession(
          uid: uid,
          record: record,
          errorMessage: error.message,
        );
      }

      final bool isOfflineNow =
          !(await _connectivityService.currentState()).isOnline;
      if (isOfflineNow) {
        return _queuePendingSession(
          uid: uid,
          record: record,
          errorMessage: error.message,
        );
      }

      rethrow;
    } catch (_) {
      final bool isOfflineNow =
          !(await _connectivityService.currentState()).isOnline;
      if (isOfflineNow) {
        return _queuePendingSession(uid: uid, record: record);
      }

      rethrow;
    }
  }

  Future<SwipeSessionSaveResult> _queuePendingSession({
    required String uid,
    required SwipeSessionRecord record,
    String? errorMessage,
  }) async {
    final PendingSwipeSession pendingSession = PendingSwipeSession(
      uid: uid,
      session: record,
      status: PendingSwipeSessionStatus.pending,
      errorMessage: errorMessage,
      createdAt: record.completedAt,
      updatedAt: record.completedAt,
    );

    await _database.queuePendingSession(
      uid: uid,
      sessionId: record.sessionId,
      sessionDate: record.date,
      payloadJson: pendingSession.payloadJson,
      status: pendingSession.status.storageValue,
      errorMessage: pendingSession.errorMessage,
      createdAt: pendingSession.createdAt,
    );

    return SwipeSessionSaveResult(
      session: record,
      reward: const SwipeSessionRewardDetails(
        xpEarned: 0,
        previousLevelProgress: PulseLevelProgress(),
        levelProgress: PulseLevelProgress(),
        previousStreak: PulseStreak(),
        currentStreak: PulseStreak(),
      ),
      isPendingSync: true,
    );
  }

  bool _isOfflineFailure(FirebaseException error) {
    return error.code == 'network-request-failed' ||
        error.code == 'unavailable';
  }

  @override
  Stream<SwipeSessionRecord?> watchSession({
    required String uid,
    required String sessionId,
  }) {
    return _remoteRepository.watchSession(uid: uid, sessionId: sessionId);
  }

  @override
  Stream<List<SwipeSessionRecord>> watchSessions({required String uid}) {
    return _remoteRepository.watchSessions(uid: uid);
  }
}
