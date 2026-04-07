import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:pulse_flutter/core/models/pulse_badge.dart';
import 'package:pulse_flutter/core/models/pulse_level_progress.dart';
import 'package:pulse_flutter/core/models/pulse_profile_settings.dart';
import 'package:pulse_flutter/core/models/pulse_referral.dart';
import 'package:pulse_flutter/core/models/pulse_streak.dart';

class PulseUserProfile {
  static const String defaultAvatarColour = '#2ED3E6';
  static const List<String> avatarColourOptions = <String>[
    '#2ED3E6',
    '#10B981',
    '#F59E0B',
    '#F97316',
    '#EC4899',
    '#6366F1',
  ];
  static final RegExp _avatarColourPattern = RegExp(r'^#[0-9A-F]{6}$');

  const PulseUserProfile({
    required this.uid,
    required this.email,
    this.displayName,
    this.avatarColour = defaultAvatarColour,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastSessionDate,
    this.totalXp = 0,
    this.currentLevel = 1,
    this.unlockedBadgeIds = const <String>[],
    this.referralCode,
    this.referralCount = PulseReferral.defaultReferralCount,
    this.referredByUid,
    this.referredByReferralCode,
    this.referredAt,
    this.settings = const PulseProfileSettings(),
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
  final int totalXp;
  final int currentLevel;
  final List<String> unlockedBadgeIds;
  final String? referralCode;
  final int referralCount;
  final String? referredByUid;
  final String? referredByReferralCode;
  final DateTime? referredAt;
  final PulseProfileSettings settings;
  final DateTime? createdAt;
  final DateTime? lastSeenAt;

  PulseStreak get streak {
    return PulseStreak(
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastSessionDate: lastSessionDate,
    );
  }

  PulseLevelProgress get levelProgress {
    return PulseLevelProgress.fromTotalXp(totalXp);
  }

  String get greetingName {
    final String? explicitName = _readNullableString(displayName);
    if (explicitName != null) {
      return explicitName;
    }

    final String? emailName = friendlyNameFromEmail(email);
    if (emailName != null) {
      return emailName;
    }

    return 'there';
  }

  String get avatarInitial {
    final String primaryLabel =
        _readNullableString(displayName) ??
        friendlyNameFromEmail(email) ??
        'Pulse';
    return primaryLabel.substring(0, 1).toUpperCase();
  }

  Color get avatarColor {
    return colorFromHex(avatarColour);
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
      totalXp: totalXp,
      currentLevel: currentLevel,
      unlockedBadgeIds: unlockedBadgeIds,
      referralCode: referralCode,
      referralCount: referralCount,
      referredByUid: referredByUid,
      referredByReferralCode: referredByReferralCode,
      referredAt: referredAt,
      settings: settings,
      createdAt: createdAt,
      lastSeenAt: lastSeenAt,
    );
  }

  PulseUserProfile withLevelProgress(PulseLevelProgress levelProgress) {
    return PulseUserProfile(
      uid: uid,
      email: email,
      displayName: displayName,
      avatarColour: avatarColour,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastSessionDate: lastSessionDate,
      totalXp: levelProgress.totalXp,
      currentLevel: levelProgress.currentLevel,
      unlockedBadgeIds: unlockedBadgeIds,
      referralCode: referralCode,
      referralCount: referralCount,
      referredByUid: referredByUid,
      referredByReferralCode: referredByReferralCode,
      referredAt: referredAt,
      settings: settings,
      createdAt: createdAt,
      lastSeenAt: lastSeenAt,
    );
  }

  PulseUserProfile withUnlockedBadgeIds(List<String> unlockedBadgeIds) {
    return PulseUserProfile(
      uid: uid,
      email: email,
      displayName: displayName,
      avatarColour: avatarColour,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastSessionDate: lastSessionDate,
      totalXp: totalXp,
      currentLevel: currentLevel,
      unlockedBadgeIds: PulseBadgeCatalog.sortedBadgeIds(unlockedBadgeIds),
      referralCode: referralCode,
      referralCount: referralCount,
      referredByUid: referredByUid,
      referredByReferralCode: referredByReferralCode,
      referredAt: referredAt,
      settings: settings,
      createdAt: createdAt,
      lastSeenAt: lastSeenAt,
    );
  }

  PulseUserProfile withSettings(PulseProfileSettings settings) {
    return PulseUserProfile(
      uid: uid,
      email: email,
      displayName: displayName,
      avatarColour: avatarColour,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastSessionDate: lastSessionDate,
      totalXp: totalXp,
      currentLevel: currentLevel,
      unlockedBadgeIds: unlockedBadgeIds,
      referralCode: referralCode,
      referralCount: referralCount,
      referredByUid: referredByUid,
      referredByReferralCode: referredByReferralCode,
      referredAt: referredAt,
      settings: settings,
      createdAt: createdAt,
      lastSeenAt: lastSeenAt,
    );
  }

  PulseUserProfile withReferral({
    required String referralCode,
    required int referralCount,
  }) {
    return PulseUserProfile(
      uid: uid,
      email: email,
      displayName: displayName,
      avatarColour: avatarColour,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      lastSessionDate: lastSessionDate,
      totalXp: totalXp,
      currentLevel: currentLevel,
      unlockedBadgeIds: unlockedBadgeIds,
      referralCode: referralCode,
      referralCount: referralCount,
      referredByUid: referredByUid,
      referredByReferralCode: referredByReferralCode,
      referredAt: referredAt,
      settings: settings,
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
      avatarColour: normalizeAvatarColour(data['avatarColour']),
      currentStreak: streak.currentStreak,
      longestStreak: streak.longestStreak,
      lastSessionDate: streak.lastSessionDate,
      totalXp: _readNonNegativeInt(data['totalXp']),
      currentLevel: _readPositiveInt(data['currentLevel']) ?? 1,
      unlockedBadgeIds: _readStringList(data['unlockedBadgeIds']),
      referralCode: PulseReferral.resolveReferralCode(
        data['referralCode'],
        uid: snapshot.id,
      ),
      referralCount: PulseReferral.resolveReferralCount(data['referralCount']),
      referredByUid: _readNullableString(data['referredByUid']),
      referredByReferralCode: PulseReferral.normalizeReferralCode(
        data['referredByReferralCode'],
      ),
      referredAt: _readTimestamp(data['referredAt']),
      settings: PulseProfileSettings.fromFirestoreData(data['settings']),
      createdAt: _readTimestamp(data['createdAt']),
      lastSeenAt: _readTimestamp(data['lastSeenAt']),
    );
  }

  Map<String, Object?> toFirestore() {
    return <String, Object?>{
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'avatarColour': normalizeAvatarColour(avatarColour),
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastSessionDate': lastSessionDate,
      'totalXp': totalXp,
      'currentLevel': currentLevel,
      'unlockedBadgeIds': PulseBadgeCatalog.sortedBadgeIds(unlockedBadgeIds),
      'referralCode': PulseReferral.resolveReferralCode(referralCode, uid: uid),
      'referralCount': PulseReferral.resolveReferralCount(referralCount),
      'referredByUid': referredByUid,
      'referredByReferralCode': referredByReferralCode,
      if (referredAt != null) 'referredAt': Timestamp.fromDate(referredAt!),
      'settings': settings.toFirestore(),
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (lastSeenAt != null) 'lastSeenAt': Timestamp.fromDate(lastSeenAt!),
    };
  }

  static String normalizeAvatarColour(Object? value) {
    final String? candidate = _readNullableString(value)?.toUpperCase();
    if (candidate == null || !_avatarColourPattern.hasMatch(candidate)) {
      return defaultAvatarColour;
    }

    return candidate;
  }

  static bool needsAvatarColourRepair(Object? value) {
    final String normalized = normalizeAvatarColour(value);
    final String? stored = _readNullableString(value)?.toUpperCase();
    return stored != normalized;
  }

  static Color colorFromHex(String value) {
    final String normalized = normalizeAvatarColour(value);
    final int rgb = int.parse(normalized.substring(1), radix: 16);
    return Color(0xFF000000 | rgb);
  }

  static String? friendlyNameFromEmail(String? value) {
    final String? email = _readNullableString(value);
    if (email == null) {
      return null;
    }

    final String localPart = email.split('@').first.trim();
    if (localPart.isEmpty) {
      return null;
    }

    final String spaced = localPart.replaceAll(RegExp(r'[._-]+'), ' ');
    return spaced.substring(0, 1).toUpperCase() + spaced.substring(1);
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

  static int _readNonNegativeInt(Object? value) {
    if (value is int && value >= 0) {
      return value;
    }

    return 0;
  }

  static int? _readPositiveInt(Object? value) {
    if (value is int && value > 0) {
      return value;
    }

    return null;
  }

  static List<String> _readStringList(Object? value) {
    if (value is! List) {
      return const <String>[];
    }

    return PulseBadgeCatalog.sortedBadgeIds(
      value.whereType<String>().map((item) => item.trim()),
    );
  }
}
