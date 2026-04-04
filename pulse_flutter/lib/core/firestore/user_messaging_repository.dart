import 'package:cloud_firestore/cloud_firestore.dart';

class UserMessagingRepository {
  const UserMessagingRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> userDocument(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  Future<void> saveFcmToken({
    required String uid,
    required String token,
  }) async {
    await userDocument(uid).set(<String, Object?>{
      'messaging': <String, Object?>{
        'fcmToken': token,
        'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));
  }

  Future<void> clearFcmToken({
    required String uid,
    required String token,
  }) async {
    final DocumentReference<Map<String, dynamic>> docRef = userDocument(uid);
    final DocumentSnapshot<Map<String, dynamic>> snapshot = await docRef.get();
    if (!snapshot.exists) {
      return;
    }

    final Object? storedToken =
        (snapshot.data()?['messaging'] as Map<String, dynamic>?)?['fcmToken'];
    if (storedToken is! String || storedToken.trim() != token.trim()) {
      return;
    }

    await docRef.update(<String, Object?>{
      'messaging.fcmToken': FieldValue.delete(),
      'messaging.fcmTokenUpdatedAt': FieldValue.delete(),
    });
  }
}

class NoopUserMessagingRepository implements UserMessagingRepository {
  const NoopUserMessagingRepository();

  @override
  FirebaseFirestore get _firestore => throw UnimplementedError();

  @override
  Future<void> clearFcmToken({
    required String uid,
    required String token,
  }) async {}

  @override
  Future<void> saveFcmToken({
    required String uid,
    required String token,
  }) async {}

  @override
  DocumentReference<Map<String, dynamic>> userDocument(String uid) {
    throw UnimplementedError();
  }
}
