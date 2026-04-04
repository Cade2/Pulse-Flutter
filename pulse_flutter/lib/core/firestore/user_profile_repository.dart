import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pulse_flutter/core/models/pulse_streak.dart';
import 'package:pulse_flutter/core/models/user_profile.dart';

class UserProfileRepository {
  const UserProfileRepository(this._firestore);

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _usersCollection {
    return _firestore.collection('users');
  }

  DocumentReference<Map<String, dynamic>> userDocument(String uid) {
    return _usersCollection.doc(uid);
  }

  Future<PulseUserProfile?> fetchUserProfile(String uid) async {
    final snapshot = await userDocument(uid).get();
    if (!snapshot.exists) {
      return null;
    }

    return PulseUserProfile.fromFirestore(snapshot);
  }

  Stream<PulseUserProfile?> watchUserProfile(String uid) {
    return userDocument(uid).snapshots().map((snapshot) {
      if (!snapshot.exists) {
        return null;
      }

      return PulseUserProfile.fromFirestore(snapshot);
    });
  }

  Future<void> ensureUserProfile(User user) async {
    final docRef = userDocument(user.uid);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      final Map<String, dynamic> existingData =
          snapshot.data() ?? <String, dynamic>{};
      final PulseUserProfile bootstrapProfile = PulseUserProfile.fromAuthUser(
        user,
      );
      final PulseStreak streak = PulseStreak.fromFirestoreData(existingData);

      final Map<String, Object?> payload = <String, Object?>{
        'uid': bootstrapProfile.uid,
        'email': bootstrapProfile.email,
        'displayName': _resolveDisplayName(
          existingData['displayName'],
          bootstrapProfile.displayName,
        ),
        'avatarColour': _resolveAvatarColour(existingData['avatarColour']),
        'currentStreak': streak.currentStreak,
        'longestStreak': streak.longestStreak,
        'lastSessionDate': streak.lastSessionDate,
        'lastSeenAt': FieldValue.serverTimestamp(),
      };

      if (!snapshot.exists || existingData['createdAt'] == null) {
        payload['createdAt'] = FieldValue.serverTimestamp();
      }

      transaction.set(docRef, payload, SetOptions(merge: true));
    });
  }

  String? _resolveDisplayName(Object? existingValue, String? fallbackValue) {
    return _trimToNull(existingValue) ?? fallbackValue;
  }

  String _resolveAvatarColour(Object? existingValue) {
    return _trimToNull(existingValue) ?? PulseUserProfile.defaultAvatarColour;
  }

  String? _trimToNull(Object? value) {
    if (value is! String) {
      return null;
    }

    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }
}
