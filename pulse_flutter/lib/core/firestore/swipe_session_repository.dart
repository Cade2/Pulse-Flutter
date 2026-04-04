import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pulse_flutter/core/models/pulse_streak.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_record.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_summary.dart';

abstract class SwipeSessionRepository {
  Future<SwipeSessionRecord> saveSession({
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
  Future<SwipeSessionRecord> saveSession({
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
    final PulseStreak nextStreak = await _resolveStreakAfterSave(
      uid: uid,
      sessionDate: record.sessionId,
    );
    final DocumentReference<Map<String, dynamic>> userDocument = _firestore
        .collection('users')
        .doc(uid);
    final DocumentReference<Map<String, dynamic>> sessionDocument = userDocument
        .collection('sessions')
        .doc(record.sessionId);

    await _firestore.runTransaction((transaction) async {
      transaction.set(sessionDocument, record.toFirestore());
      transaction.set(
        userDocument,
        nextStreak.toFirestore(),
        SetOptions(merge: true),
      );
    });

    return record;
  }

  Future<PulseStreak> _resolveStreakAfterSave({
    required String uid,
    required String sessionDate,
  }) async {
    final QuerySnapshot<Map<String, dynamic>> sessionsSnapshot =
        await _firestore
            .collection('users')
            .doc(uid)
            .collection('sessions')
            .get();
    final Set<String> sessionDates = sessionsSnapshot.docs.map((snapshot) {
      final Map<String, dynamic> data = snapshot.data();
      final Object? dateValue = data['date'];

      if (dateValue is String && dateValue.trim().isNotEmpty) {
        return dateValue.trim();
      }

      return snapshot.id;
    }).toSet();

    sessionDates.add(sessionDate);

    return PulseStreak.fromSessionDates(
      sessionDates,
      currentDate: DateTime.now(),
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
