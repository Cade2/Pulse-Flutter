import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PulseUserProfile {
  static const String defaultAvatarColour = '#2ED3E6';

  const PulseUserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    this.avatarColour = defaultAvatarColour,
    this.createdAt,
    this.lastSeenAt,
  });

  final String uid;
  final String email;
  final String? displayName;
  final String avatarColour;
  final DateTime? createdAt;
  final DateTime? lastSeenAt;

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

    return PulseUserProfile(
      uid: _readNullableString(data['uid']) ?? snapshot.id,
      email: _readNullableString(data['email']) ?? '',
      displayName: _readNullableString(data['displayName']),
      avatarColour:
          _readNullableString(data['avatarColour']) ?? defaultAvatarColour,
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
