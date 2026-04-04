import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pulse_flutter/core/models/pulse_level_progress.dart';
import 'package:pulse_flutter/core/models/pulse_session_history_entry.dart';
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

    return _buildReconciledProfile(uid: uid, snapshot: snapshot);
  }

  Stream<PulseUserProfile?> watchUserProfile(String uid) {
    return userDocument(uid).snapshots().asyncMap((snapshot) async {
      if (!snapshot.exists) {
        return null;
      }

      return _buildReconciledProfile(uid: uid, snapshot: snapshot);
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
      final PulseLevelProgress levelProgress =
          PulseLevelProgress.fromFirestoreData(existingData);

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
        'totalXp': levelProgress.totalXp,
        'currentLevel': levelProgress.currentLevel,
        'lastSeenAt': FieldValue.serverTimestamp(),
      };

      if (!snapshot.exists || existingData['createdAt'] == null) {
        payload['createdAt'] = FieldValue.serverTimestamp();
      }

      transaction.set(docRef, payload, SetOptions(merge: true));
    });
  }

  Future<PulseUserProfile> _buildReconciledProfile({
    required String uid,
    required DocumentSnapshot<Map<String, dynamic>> snapshot,
  }) async {
    final Map<String, dynamic> data = snapshot.data() ?? <String, dynamic>{};
    final PulseUserProfile profile = PulseUserProfile.fromFirestore(snapshot);
    final List<PulseSessionHistoryEntry> sessionHistory =
        await _readSessionHistory(uid);
    final PulseStreak reconciledStreak = _resolveReconciledStreak(
      storedStreak: profile.streak,
      sessionHistory: sessionHistory,
    );
    final PulseLevelProgress reconciledLevelProgress =
        _resolveReconciledLevelProgress(
          storedLevelProgress: PulseLevelProgress.fromFirestoreData(data),
          sessionHistory: sessionHistory,
        );

    final bool streakNeedsWriteback = !profile.streak.matches(reconciledStreak);
    final bool levelNeedsWriteback =
        profile.totalXp != reconciledLevelProgress.totalXp ||
        profile.currentLevel != reconciledLevelProgress.currentLevel;

    if (streakNeedsWriteback || levelNeedsWriteback) {
      await userDocument(uid).set(<String, Object?>{
        if (streakNeedsWriteback) ...reconciledStreak.toFirestore(),
        if (levelNeedsWriteback) ...reconciledLevelProgress.toFirestore(),
      }, SetOptions(merge: true));
    }

    return profile
        .withStreak(reconciledStreak)
        .withLevelProgress(reconciledLevelProgress);
  }

  Future<List<PulseSessionHistoryEntry>> _readSessionHistory(String uid) async {
    final QuerySnapshot<Map<String, dynamic>> sessionsSnapshot =
        await userDocument(uid).collection('sessions').get();

    return sessionsSnapshot.docs
        .map((snapshot) {
          return PulseSessionHistoryEntry.fromFirestoreData(
            data: snapshot.data(),
            fallbackDate: snapshot.id,
          );
        })
        .toList(growable: false);
  }

  PulseStreak _resolveReconciledStreak({
    required PulseStreak storedStreak,
    required List<PulseSessionHistoryEntry> sessionHistory,
  }) {
    final DateTime now = DateTime.now();

    if (sessionHistory.isEmpty) {
      return storedStreak.effectiveAsOf(now);
    }

    return PulseStreak.fromSessionDates(
      sessionHistory.map((session) => session.date),
      currentDate: now,
    );
  }

  PulseLevelProgress _resolveReconciledLevelProgress({
    required PulseLevelProgress storedLevelProgress,
    required List<PulseSessionHistoryEntry> sessionHistory,
  }) {
    if (sessionHistory.isEmpty) {
      return storedLevelProgress;
    }

    return PulseLevelProgress.fromSessionXpAwards(
      sessionHistory.map((session) => session.earnedXp),
    );
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
