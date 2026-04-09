import 'package:pulse_flutter/core/models/pulse_referral.dart';
import 'package:pulse_flutter/core/models/user_profile.dart';

enum PulseLeaderboardRelationship {
  currentUser,
  invitedYou,
  joinedWithYourCode,
}

class PulseLeaderboardEntry {
  const PulseLeaderboardEntry({
    required this.uid,
    required this.rank,
    required this.name,
    required this.avatarColour,
    required this.avatarInitial,
    required this.currentStreak,
    required this.currentLevel,
    required this.referralCount,
    required this.relationship,
    this.isCurrentUser = false,
  });

  final String uid;
  final int rank;
  final String name;
  final String avatarColour;
  final String avatarInitial;
  final int currentStreak;
  final int currentLevel;
  final int referralCount;
  final PulseLeaderboardRelationship relationship;
  final bool isCurrentUser;

  String get subtitle {
    switch (relationship) {
      case PulseLeaderboardRelationship.currentUser:
        return 'You';
      case PulseLeaderboardRelationship.invitedYou:
        return 'Invited you to Pulse';
      case PulseLeaderboardRelationship.joinedWithYourCode:
        return 'Joined with your code';
    }
  }

  bool get canChallenge => !isCurrentUser;

  factory PulseLeaderboardEntry.currentUser(PulseUserProfile profile) {
    return PulseLeaderboardEntry.fromProfile(
      profile,
      currentStreak: profile.currentStreak,
      currentLevel: profile.currentLevel,
      relationship: PulseLeaderboardRelationship.currentUser,
      isCurrentUser: true,
    );
  }

  factory PulseLeaderboardEntry.fromProfile(
    PulseUserProfile profile, {
    required int currentStreak,
    required int currentLevel,
    required PulseLeaderboardRelationship relationship,
    bool isCurrentUser = false,
  }) {
    return PulseLeaderboardEntry(
      uid: profile.uid,
      rank: 1,
      name: profile.greetingName,
      avatarColour: profile.avatarColour,
      avatarInitial: profile.avatarInitial,
      currentStreak: currentStreak,
      currentLevel: currentLevel,
      referralCount: profile.referralCount,
      relationship: relationship,
      isCurrentUser: isCurrentUser,
    );
  }

  PulseLeaderboardEntry copyWithRank(int rank) {
    return PulseLeaderboardEntry(
      uid: uid,
      rank: rank,
      name: name,
      avatarColour: avatarColour,
      avatarInitial: avatarInitial,
      currentStreak: currentStreak,
      currentLevel: currentLevel,
      referralCount: referralCount,
      relationship: relationship,
      isCurrentUser: isCurrentUser,
    );
  }
}

class PulseLeaderboardChallengeDraft {
  static const List<int> _milestoneTargets = <int>[3, 7, 14, 30];

  const PulseLeaderboardChallengeDraft({
    required this.friendName,
    required this.headline,
    required this.summary,
    required this.targetStreak,
    required this.currentUserStatus,
    required this.friendStatus,
    required this.shareText,
  });

  final String friendName;
  final String headline;
  final String summary;
  final int targetStreak;
  final String currentUserStatus;
  final String friendStatus;
  final String shareText;

  factory PulseLeaderboardChallengeDraft.fromEntries({
    required PulseLeaderboardEntry currentUserEntry,
    required PulseLeaderboardEntry friendEntry,
  }) {
    final int targetStreak = _resolveTargetStreak(
      currentUserEntry.currentStreak,
      friendEntry.currentStreak,
    );
    final int streakGap =
        currentUserEntry.currentStreak - friendEntry.currentStreak;
    final String headline;
    final String summary;

    if (streakGap == 0) {
      headline = 'Tie-breaker time';
      summary =
          'You and ${friendEntry.name} are level on streak momentum. First to '
          '$targetStreak days takes this Pulse round.';
    } else if (streakGap > 0) {
      headline = 'Protect your lead';
      summary =
          'You are $streakGap day${streakGap == 1 ? '' : 's'} ahead of '
          '${friendEntry.name}. First to $targetStreak days wins the next '
          'stretch.';
    } else {
      final int trailingGap = streakGap.abs();
      headline = 'Catch ${friendEntry.name}';
      summary =
          '${friendEntry.name} is $trailingGap day${trailingGap == 1 ? '' : 's'} '
          'ahead right now. First to $targetStreak days wins the rematch.';
    }

    final String currentUserStatus = _buildStatusLine(currentUserEntry);
    final String friendStatus = _buildStatusLine(friendEntry);
    final String shareText =
        'Pulse challenge: ${currentUserEntry.name} vs ${friendEntry.name}.\n'
        'First to a $targetStreak-day streak wins.\n'
        '${currentUserEntry.name}: $currentUserStatus\n'
        '${friendEntry.name}: $friendStatus';

    return PulseLeaderboardChallengeDraft(
      friendName: friendEntry.name,
      headline: headline,
      summary: summary,
      targetStreak: targetStreak,
      currentUserStatus: currentUserStatus,
      friendStatus: friendStatus,
      shareText: shareText,
    );
  }

  static int _resolveTargetStreak(int currentUserStreak, int friendStreak) {
    final int highestStreak = currentUserStreak > friendStreak
        ? currentUserStreak
        : friendStreak;

    for (final int milestone in _milestoneTargets) {
      if (milestone > highestStreak) {
        return milestone;
      }
    }

    return highestStreak + 3;
  }

  static String _buildStatusLine(PulseLeaderboardEntry entry) {
    return '${entry.currentStreak} day streak | Level ${entry.currentLevel}';
  }
}

class PulseLeaderboardState {
  const PulseLeaderboardState({
    required this.referralCode,
    required this.referralCount,
    required this.currentUserEntry,
    required this.joinedWithYourCodeCount,
    this.friendEntries = const <PulseLeaderboardEntry>[],
  });

  final String referralCode;
  final int referralCount;
  final PulseLeaderboardEntry currentUserEntry;
  final int joinedWithYourCodeCount;
  final List<PulseLeaderboardEntry> friendEntries;

  bool get hasFriends => friendEntries.isNotEmpty;

  int get totalVisibleEntries => 1 + friendEntries.length;

  PulseLeaderboardEntry? get inviterEntry {
    for (final PulseLeaderboardEntry entry in friendEntries) {
      if (entry.relationship == PulseLeaderboardRelationship.invitedYou) {
        return entry;
      }
    }

    return null;
  }

  PulseLeaderboardEntry get leaderEntry {
    PulseLeaderboardEntry leader = currentUserEntry;

    for (final PulseLeaderboardEntry entry in friendEntries) {
      if (_compareEntries(entry, leader) < 0) {
        leader = entry;
      }
    }

    return leader;
  }

  String get relationshipSummary {
    final List<String> parts = <String>[];
    final PulseLeaderboardEntry? inviter = inviterEntry;

    if (inviter != null) {
      parts.add('${inviter.name} invited you');
    }

    if (joinedWithYourCodeCount > 0) {
      parts.add(
        joinedWithYourCodeCount == 1
            ? '1 person joined with your code'
            : '$joinedWithYourCodeCount people joined with your code',
      );
    }

    if (parts.isEmpty) {
      return 'Your referral relationships will appear here as your Pulse '
          'circle grows.';
    }

    return parts.join(' | ');
  }

  String get competitionSummary {
    if (!hasFriends) {
      return 'Share your code or join through a friend to unlock live Pulse '
          'competition here.';
    }

    if (currentUserEntry.rank == 1) {
      return totalVisibleEntries == 2
          ? 'You are leading your two-person Pulse circle.'
          : 'You are leading $totalVisibleEntries connected Pulse users.';
    }

    final PulseLeaderboardEntry leader = leaderEntry;
    final int streakGap = leader.currentStreak - currentUserEntry.currentStreak;
    if (streakGap > 0) {
      return '${leader.name} is $streakGap streak '
          'day${streakGap == 1 ? '' : 's'} ahead right now.';
    }

    final int levelGap = leader.currentLevel - currentUserEntry.currentLevel;
    if (levelGap > 0) {
      return '${leader.name} is $levelGap level${levelGap == 1 ? '' : 's'} '
          'ahead. One more strong run could close the gap.';
    }

    return 'The circle is tight right now. One more session could shake up '
        'the rankings.';
  }

  PulseLeaderboardChallengeDraft challengeFor(PulseLeaderboardEntry entry) {
    return PulseLeaderboardChallengeDraft.fromEntries(
      currentUserEntry: currentUserEntry,
      friendEntry: entry,
    );
  }

  factory PulseLeaderboardState.fromProfile(
    PulseUserProfile profile, {
    int? currentStreak,
    int? currentLevel,
    List<PulseUserProfile> socialProfiles = const <PulseUserProfile>[],
  }) {
    final PulseLeaderboardEntry currentUserEntry =
        PulseLeaderboardEntry.fromProfile(
          profile,
          currentStreak: currentStreak ?? profile.currentStreak,
          currentLevel: currentLevel ?? profile.currentLevel,
          relationship: PulseLeaderboardRelationship.currentUser,
          isCurrentUser: true,
        );
    final List<PulseLeaderboardEntry> socialEntries = socialProfiles
        .where((socialProfile) => socialProfile.uid != profile.uid)
        .map((socialProfile) {
          final PulseLeaderboardRelationship relationship =
              socialProfile.uid == profile.referredByUid
              ? PulseLeaderboardRelationship.invitedYou
              : PulseLeaderboardRelationship.joinedWithYourCode;
          return PulseLeaderboardEntry.fromProfile(
            socialProfile,
            currentStreak: socialProfile.currentStreak,
            currentLevel: socialProfile.currentLevel,
            relationship: relationship,
          );
        })
        .toList(growable: false);
    final List<PulseLeaderboardEntry> rankedEntries = <PulseLeaderboardEntry>[
      currentUserEntry,
      ...socialEntries,
    ]..sort(_compareEntries);
    final List<PulseLeaderboardEntry> entriesWithRanks = rankedEntries.indexed
        .map((entry) {
          return entry.$2.copyWithRank(entry.$1 + 1);
        })
        .toList(growable: false);
    final PulseLeaderboardEntry rankedCurrentUserEntry = entriesWithRanks
        .firstWhere((entry) => entry.uid == profile.uid);
    final List<PulseLeaderboardEntry> friendEntries = entriesWithRanks
        .where((entry) => entry.uid != profile.uid)
        .toList(growable: false);

    return PulseLeaderboardState(
      referralCode: PulseReferral.resolveReferralCode(
        profile.referralCode,
        uid: profile.uid,
      ),
      referralCount: PulseReferral.resolveReferralCount(profile.referralCount),
      currentUserEntry: rankedCurrentUserEntry,
      joinedWithYourCodeCount: friendEntries
          .where(
            (entry) =>
                entry.relationship ==
                PulseLeaderboardRelationship.joinedWithYourCode,
          )
          .length,
      friendEntries: friendEntries,
    );
  }

  static int _compareEntries(
    PulseLeaderboardEntry lhs,
    PulseLeaderboardEntry rhs,
  ) {
    final int streakComparison = rhs.currentStreak.compareTo(lhs.currentStreak);
    if (streakComparison != 0) {
      return streakComparison;
    }

    final int levelComparison = rhs.currentLevel.compareTo(lhs.currentLevel);
    if (levelComparison != 0) {
      return levelComparison;
    }

    final int referralComparison = rhs.referralCount.compareTo(
      lhs.referralCount,
    );
    if (referralComparison != 0) {
      return referralComparison;
    }

    final int nameComparison = lhs.name.toLowerCase().compareTo(
      rhs.name.toLowerCase(),
    );
    if (nameComparison != 0) {
      return nameComparison;
    }

    return lhs.uid.compareTo(rhs.uid);
  }
}
