import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pulse_flutter/core/models/pulse_badge.dart';
import 'package:pulse_flutter/core/models/pulse_level_progress.dart';
import 'package:pulse_flutter/core/models/pulse_session_history_entry.dart';
import 'package:pulse_flutter/core/models/pulse_streak.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_record.dart';
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

class FirestoreSwipeSessionRepository implements SwipeSessionRepository {
  const FirestoreSwipeSessionRepository(this._firestore);

  final FirebaseFirestore _firestore;

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
    final List<PulseSessionHistoryEntry> sessionHistory =
        await _readSessionHistory(uid);
    final PulseSessionHistoryEntry pendingSession = PulseSessionHistoryEntry(
      date: record.sessionId,
      contextSocial: contextSocial,
      contextEnergy: contextEnergy,
      contextSleep: contextSleep,
    );
    final List<PulseSessionHistoryEntry> pendingHistory = _upsertSessionHistory(
      sessionHistory,
      pendingSession,
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

        transaction.set(userDocument, <String, Object?>{
          ...existingStreak.toFirestore(),
          ...existingProgress.toFirestore(),
          'unlockedBadgeIds': existingUnlockedBadgeIds,
        }, SetOptions(merge: true));

        return SwipeSessionSaveResult(
          session: SwipeSessionRecord.fromFirestore(sessionSnapshot),
          xpEarned: 0,
          levelProgress: existingProgress,
        );
      }

      transaction.set(sessionDocument, record.toFirestore());
      transaction.set(userDocument, <String, Object?>{
        ...nextStreak.toFirestore(),
        ...nextProgress.toFirestore(),
        'unlockedBadgeIds': nextUnlockedBadgeIds,
      }, SetOptions(merge: true));

      return SwipeSessionSaveResult(
        session: record,
        xpEarned: xpEarned,
        levelProgress: nextProgress,
      );
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
