import 'package:cloud_firestore/cloud_firestore.dart';

abstract class PulseAccountRepository {
  Future<void> deleteUserData(String uid);
}

class FirestorePulseAccountRepository implements PulseAccountRepository {
  const FirestorePulseAccountRepository(this._firestore);

  static const List<String> _ownedSubcollections = <String>['sessions'];
  static const int _maxBatchOperations = 450;

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> userDocument(String uid) {
    return _firestore.collection('users').doc(uid);
  }

  @override
  Future<void> deleteUserData(String uid) async {
    final DocumentReference<Map<String, dynamic>> userRef = userDocument(uid);
    final List<DocumentReference<Map<String, dynamic>>> documentsToDelete =
        <DocumentReference<Map<String, dynamic>>>[];

    for (final String subcollection in _ownedSubcollections) {
      final QuerySnapshot<Map<String, dynamic>> snapshot = await userRef
          .collection(subcollection)
          .get();
      documentsToDelete.addAll(
        snapshot.docs.map((document) => document.reference),
      );
    }

    documentsToDelete.add(userRef);

    for (
      int start = 0;
      start < documentsToDelete.length;
      start += _maxBatchOperations
    ) {
      final int end = start + _maxBatchOperations < documentsToDelete.length
          ? start + _maxBatchOperations
          : documentsToDelete.length;
      final WriteBatch batch = _firestore.batch();

      for (int index = start; index < end; index++) {
        batch.delete(documentsToDelete[index]);
      }

      await batch.commit();
    }
  }
}
