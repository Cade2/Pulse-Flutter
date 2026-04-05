import 'package:pulse_flutter/core/models/pulse_referral.dart';
import 'package:pulse_flutter/core/models/user_profile.dart';

class PulseLeaderboardEntry {
  const PulseLeaderboardEntry({
    required this.rank,
    required this.name,
    required this.avatarColour,
    required this.avatarInitial,
    required this.currentStreak,
    required this.currentLevel,
    required this.referralCount,
    this.isCurrentUser = false,
    this.subtitle,
  });

  final int rank;
  final String name;
  final String avatarColour;
  final String avatarInitial;
  final int currentStreak;
  final int currentLevel;
  final int referralCount;
  final bool isCurrentUser;
  final String? subtitle;

  factory PulseLeaderboardEntry.currentUser(PulseUserProfile profile) {
    return PulseLeaderboardEntry.fromProfile(
      profile,
      currentStreak: profile.currentStreak,
      currentLevel: profile.currentLevel,
    );
  }

  factory PulseLeaderboardEntry.fromProfile(
    PulseUserProfile profile, {
    required int currentStreak,
    required int currentLevel,
  }) {
    return PulseLeaderboardEntry(
      rank: 1,
      name: profile.greetingName,
      avatarColour: profile.avatarColour,
      avatarInitial: profile.avatarInitial,
      currentStreak: currentStreak,
      currentLevel: currentLevel,
      referralCount: profile.referralCount,
      isCurrentUser: true,
      subtitle: 'You',
    );
  }
}

class PulseLeaderboardState {
  const PulseLeaderboardState({
    required this.referralCode,
    required this.referralCount,
    required this.currentUserEntry,
    this.friendEntries = const <PulseLeaderboardEntry>[],
  });

  final String referralCode;
  final int referralCount;
  final PulseLeaderboardEntry currentUserEntry;
  final List<PulseLeaderboardEntry> friendEntries;

  bool get hasFriends => friendEntries.isNotEmpty;

  int get totalVisibleEntries => 1 + friendEntries.length;

  factory PulseLeaderboardState.fromProfile(
    PulseUserProfile profile, {
    int? currentStreak,
    int? currentLevel,
  }) {
    return PulseLeaderboardState(
      referralCode: PulseReferral.resolveReferralCode(
        profile.referralCode,
        uid: profile.uid,
      ),
      referralCount: PulseReferral.resolveReferralCount(profile.referralCount),
      currentUserEntry: PulseLeaderboardEntry.fromProfile(
        profile,
        currentStreak: currentStreak ?? profile.currentStreak,
        currentLevel: currentLevel ?? profile.currentLevel,
      ),
    );
  }
}
