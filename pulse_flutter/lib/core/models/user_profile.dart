import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:pulse_flutter/core/models/pulse_streak.dart';

class PulseUserProfile {
  static const String defaultAvatarColour = '#2ED3E6';

  const PulseUserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    this.avatarColour = defaultAvatarColour,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastSessionDate,
    this.createdAt,
    this.lastSeenAt,
  });

  final String uid;
  final String email;
  final String? displayName;
  final String avatarColour;
  final int currentStreak;
  final int longestStreak;
  final String? lastSessionDate;
  final DateTime? createdAt;
  final DateTime? lastSeenAt;

  PulseStreak get streak {
    return PulseStreak(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastSessionDate: lastSessionDate,
    );
  }

  PulseUserProfile withStreak(PulseStreak streak) {
    return PulseUserProfile(
      uid: uid,
      email: email,
      displayName: displayName,
      avatarColour: avatarColour,
      currentStreak: streak.currentStreak,
      longestStreak: streak.longestStreak,
      lastSessionDate: streak.lastSessionDate,
      createdAt: createdAt,
      lastSeenAt: lastSeenAt,
    );
  }

  factory PulseUserProfile.fromAuthUser(User user) {
    return PulseUserProfile(
      uid: user.uid,
      email: user.email?.trim() ?? '',
      displayName: _readNullableString(user.displayName),
    );
  }

  factory PulseUserProfile.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    final Map<String, dynamic> data = snapshot.data() ?? <String, dynamic>{};
    final PulseStreak streak = PulseStreak.fromFirestoreData(data);

    return PulseUserProfile(
      uid: _readNullableString(data['uid']) ?? snapshot.id,
      email: _readNullableString(data['email']) ?? '',
      displayName: _readNullableString(data['displayName']),
      avatarColour:
          _readNullableString(data['avatarColour']) ?? defaultAvatarColour,
      currentStreak: streak.currentStreak,
      longestStreak: streak.longestStreak,
      lastSessionDate: streak.lastSessionDate,
      createdAt: _readTimestamp(data['createdAt']),
      lastSeenAt: _readTimestamp(data['lastSeenAt']),
    );
  }

  Map<String, Object?> toFirestore() {
    return <String, Object?>{
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'avatarColour': avatarColour,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastSessionDate': lastSessionDate,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (lastSeenAt != null) 'lastSeenAt': Timestamp.fromDate(lastSeenAt!),
    };
  }

  static String? _readNullableString(Object? value) {
    if (value is! String) {
      return null;
    }

    final String trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }

  static DateTime? _readTimestamp(Object? value) {
    if (value is Timestamp) {
      return value.toDate();
    }

    return null;
  }
}
