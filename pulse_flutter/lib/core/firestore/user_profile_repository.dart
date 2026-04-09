import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pulse_flutter/core/models/pulse_badge.dart';
import 'package:pulse_flutter/core/models/pulse_level_progress.dart';
import 'package:pulse_flutter/core/models/pulse_profile_settings.dart';
import 'package:pulse_flutter/core/models/pulse_referral.dart';
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

  Future<void> ensureUserProfile(User user, {String? referralCode}) async {
    final String? normalizedReferralCode = _normalizeOptionalReferralCode(
      referralCode,
    );
    final _ReferralOwner? referralOwner = normalizedReferralCode == null
        ? null
        : await _findReferralOwner(normalizedReferralCode);

    if (normalizedReferralCode != null && referralOwner == null) {
      throw PulseReferralRedemptionException.notFound();
    }

    if (referralOwner?.uid == user.uid) {
      throw PulseReferralRedemptionException.selfReferral();
    }

    final docRef = userDocument(user.uid);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      final Map<String, dynamic> existingData =
          snapshot.data() ?? <String, dynamic>{};
      DocumentSnapshot<Map<String, dynamic>>? referrerSnapshot;
      if (referralOwner != null) {
        referrerSnapshot = await transaction.get(referralOwner.document);
        if (!referrerSnapshot.exists) {
          throw PulseReferralRedemptionException.notFound();
        }

        final String storedReferrerCode = _resolveReferralCode(
          referrerSnapshot.data()?['referralCode'],
          uid: referralOwner.uid,
        );
        if (storedReferrerCode != normalizedReferralCode) {
          throw PulseReferralRedemptionException.notFound();
        }

        if (referrerSnapshot.id == user.uid) {
          throw PulseReferralRedemptionException.selfReferral();
        }
      }

      final PulseUserProfile bootstrapProfile = PulseUserProfile.fromAuthUser(
        user,
      );
      final PulseStreak streak = PulseStreak.fromFirestoreData(existingData);
      final PulseLevelProgress levelProgress =
          PulseLevelProgress.fromFirestoreData(existingData);
      final PulseProfileSettings settings = _resolveSettings(
        existingData['settings'],
      );
      final String ownReferralCode = _resolveReferralCode(
        existingData['referralCode'],
        uid: bootstrapProfile.uid,
      );
      final int referralCount = _resolveReferralCount(
        existingData['referralCount'],
      );
      final String? existingReferredByUid = _trimToNull(
        existingData['referredByUid'],
      );
      final String? existingReferredByReferralCode =
          PulseReferral.normalizeReferralCode(
            existingData['referredByReferralCode'],
          );
      final bool shouldRecordReferral =
          referralOwner != null && existingReferredByUid == null;

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
        'unlockedBadgeIds': _resolveStoredBadgeIds(
          existingData['unlockedBadgeIds'],
        ),
        'referralCode': ownReferralCode,
        'referralCount': referralCount,
        if (shouldRecordReferral) ...<String, Object?>{
          'referredByUid': referralOwner.uid,
          'referredByReferralCode': normalizedReferralCode,
          'referredAt': FieldValue.serverTimestamp(),
        } else ...<String, Object?>{
          'referredByUid': ?existingReferredByUid,
          'referredByReferralCode': ?existingReferredByReferralCode,
        },
        'settings': settings.toFirestore(),
        'lastSeenAt': FieldValue.serverTimestamp(),
      };

      if (!snapshot.exists || existingData['createdAt'] == null) {
        payload['createdAt'] = FieldValue.serverTimestamp();
      }

      transaction.set(docRef, payload, SetOptions(merge: true));

      if (shouldRecordReferral && referrerSnapshot != null) {
        final int referrerReferralCount = _resolveReferralCount(
          referrerSnapshot.data()?['referralCount'],
        );
        transaction.set(referralOwner.document, <String, Object?>{
          'referralCount': referrerReferralCount + 1,
        }, SetOptions(merge: true));
      }
    });
  }

  Future<void> validateReferralCodeForRegistration(String referralCode) async {
    final String normalizedReferralCode = _normalizeRequiredReferralCode(
      referralCode,
    );
    final _ReferralOwner? referralOwner = await _findReferralOwner(
      normalizedReferralCode,
    );

    if (referralOwner == null) {
      throw PulseReferralRedemptionException.notFound();
    }
  }

  Future<void> updateProfile({
    required String uid,
    String? displayName,
    required String avatarColour,
    required PulseProfileSettings settings,
  }) async {
    await userDocument(uid).set(<String, Object?>{
      'displayName': _trimToNull(displayName),
      'avatarColour': PulseUserProfile.normalizeAvatarColour(avatarColour),
      'settings': settings.toFirestore(),
    }, SetOptions(merge: true));
  }

  Future<List<PulseUserProfile>> fetchReferralCircleProfiles(
    PulseUserProfile profile,
  ) async {
    final List<PulseUserProfile> socialProfiles = <PulseUserProfile>[];
    final Set<String> seenUids = <String>{profile.uid};

    final String? referredByUid = profile.referredByUid;
    if (referredByUid != null && referredByUid.isNotEmpty) {
      final PulseUserProfile? referrerProfile = await fetchUserProfile(
        referredByUid,
      );
      if (referrerProfile != null && seenUids.add(referrerProfile.uid)) {
        socialProfiles.add(referrerProfile);
      }
    }

    final QuerySnapshot<Map<String, dynamic>> referredUsersSnapshot =
        await _usersCollection
            .where('referredByUid', isEqualTo: profile.uid)
            .get();
    final List<PulseUserProfile> referredProfiles = await Future.wait(
      referredUsersSnapshot.docs.map((snapshot) {
        return _buildReconciledProfile(uid: snapshot.id, snapshot: snapshot);
      }),
    );

    for (final PulseUserProfile referredProfile in referredProfiles) {
      if (seenUids.add(referredProfile.uid)) {
        socialProfiles.add(referredProfile);
      }
    }

    return socialProfiles;
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
    final List<String> reconciledBadgeIds = _resolveReconciledBadgeIds(
      sessionHistory: sessionHistory,
      streak: reconciledStreak,
      levelProgress: reconciledLevelProgress,
    );
    final PulseProfileSettings reconciledSettings = _resolveSettings(
      data['settings'],
    );
    final String reconciledReferralCode = _resolveReferralCode(
      data['referralCode'],
      uid: uid,
    );
    final int reconciledReferralCount = _resolveReferralCount(
      data['referralCount'],
    );

    final bool streakNeedsWriteback = !profile.streak.matches(reconciledStreak);
    final bool levelNeedsWriteback =
        profile.totalXp != reconciledLevelProgress.totalXp ||
        profile.currentLevel != reconciledLevelProgress.currentLevel;
    final bool badgesNeedWriteback = !_badgeIdsMatch(
      profile.unlockedBadgeIds,
      reconciledBadgeIds,
    );
    final bool avatarNeedsWriteback = PulseUserProfile.needsAvatarColourRepair(
      data['avatarColour'],
    );
    final bool settingsNeedWriteback = PulseProfileSettings.needsRepair(
      data['settings'],
    );
    final bool referralCodeNeedsWriteback =
        PulseReferral.needsReferralCodeRepair(data['referralCode'], uid: uid);
    final bool referralCountNeedsWriteback =
        PulseReferral.needsReferralCountRepair(data['referralCount']);

    if (streakNeedsWriteback ||
        levelNeedsWriteback ||
        badgesNeedWriteback ||
        avatarNeedsWriteback ||
        settingsNeedWriteback ||
        referralCodeNeedsWriteback ||
        referralCountNeedsWriteback) {
      await userDocument(uid).set(<String, Object?>{
        if (streakNeedsWriteback) ...reconciledStreak.toFirestore(),
        if (levelNeedsWriteback) ...reconciledLevelProgress.toFirestore(),
        if (badgesNeedWriteback) 'unlockedBadgeIds': reconciledBadgeIds,
        if (avatarNeedsWriteback) 'avatarColour': profile.avatarColour,
        if (settingsNeedWriteback) 'settings': reconciledSettings.toFirestore(),
        if (referralCodeNeedsWriteback) 'referralCode': reconciledReferralCode,
        if (referralCountNeedsWriteback)
          'referralCount': reconciledReferralCount,
      }, SetOptions(merge: true));
    }

    return profile
        .withStreak(reconciledStreak)
        .withLevelProgress(reconciledLevelProgress)
        .withUnlockedBadgeIds(reconciledBadgeIds)
        .withReferral(
          referralCode: reconciledReferralCode,
          referralCount: reconciledReferralCount,
        )
        .withSettings(reconciledSettings);
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

  List<String> _resolveReconciledBadgeIds({
    required List<PulseSessionHistoryEntry> sessionHistory,
    required PulseStreak streak,
    required PulseLevelProgress levelProgress,
  }) {
    return PulseBadgeCatalog.unlockedBadgeIds(
      PulseBadgeProgressSnapshot.fromSessionHistory(
        sessionHistory: sessionHistory,
        longestStreak: streak.longestStreak,
        currentLevel: levelProgress.currentLevel,
      ),
    );
  }

  String? _resolveDisplayName(Object? existingValue, String? fallbackValue) {
    return _trimToNull(existingValue) ?? fallbackValue;
  }

  String _resolveAvatarColour(Object? existingValue) {
    return PulseUserProfile.normalizeAvatarColour(existingValue);
  }

  PulseProfileSettings _resolveSettings(Object? existingValue) {
    return PulseProfileSettings.fromFirestoreData(existingValue);
  }

  String _resolveReferralCode(Object? existingValue, {required String uid}) {
    return PulseReferral.resolveReferralCode(existingValue, uid: uid);
  }

  int _resolveReferralCount(Object? existingValue) {
    return PulseReferral.resolveReferralCount(existingValue);
  }

  Future<_ReferralOwner?> _findReferralOwner(String referralCode) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _usersCollection
        .where('referralCode', isEqualTo: referralCode)
        .limit(1)
        .get();

    if (snapshot.docs.isEmpty) {
      return null;
    }

    final QueryDocumentSnapshot<Map<String, dynamic>> doc = snapshot.docs.first;
    return _ReferralOwner(uid: doc.id, document: doc.reference);
  }

  String? _normalizeOptionalReferralCode(String? referralCode) {
    final String? trimmedReferralCode = _trimToNull(referralCode);
    if (trimmedReferralCode == null) {
      return null;
    }

    return _normalizeRequiredReferralCode(trimmedReferralCode);
  }

  String _normalizeRequiredReferralCode(String referralCode) {
    final String? normalizedReferralCode = PulseReferral.normalizeReferralCode(
      referralCode,
    );
    if (normalizedReferralCode == null) {
      throw PulseReferralRedemptionException.invalidCode();
    }

    return normalizedReferralCode;
  }

  List<String> _resolveStoredBadgeIds(Object? value) {
    if (value is! List) {
      return const <String>[];
    }

    return PulseBadgeCatalog.sortedBadgeIds(
      value.whereType<String>().map((item) => item.trim()),
    );
  }

  bool _badgeIdsMatch(List<String> lhs, List<String> rhs) {
    if (lhs.length != rhs.length) {
      return false;
    }

    for (int index = 0; index < lhs.length; index++) {
      if (lhs[index] != rhs[index]) {
        return false;
      }
    }

    return true;
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

class _ReferralOwner {
  const _ReferralOwner({required this.uid, required this.document});

  final String uid;
  final DocumentReference<Map<String, dynamic>> document;
}
