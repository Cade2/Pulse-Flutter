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
    final DocumentReference<Map<String, dynamic>> userDocument = _firestore
        .collection('users')
        .doc(uid);
    final DocumentReference<Map<String, dynamic>> sessionDocument = userDocument
        .collection('sessions')
        .doc(record.sessionId);

    await _firestore.runTransaction((transaction) async {
      final DocumentSnapshot<Map<String, dynamic>> userSnapshot =
          await transaction.get(userDocument);
      final Map<String, dynamic> userData =
          userSnapshot.data() ?? <String, dynamic>{};
      final PulseStreak nextStreak = PulseStreak.fromFirestoreData(
        userData,
      ).recordCompletion(record.sessionId);

      transaction.set(sessionDocument, record.toFirestore());
      transaction.set(
        userDocument,
        nextStreak.toFirestore(),
        SetOptions(merge: true),
      );
    });

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
