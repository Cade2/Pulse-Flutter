import 'package:cloud_firestore/cloud_firestore.dart';
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

    await _firestore
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .doc(record.sessionId)
        .set(record.toFirestore());

    return record;
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
