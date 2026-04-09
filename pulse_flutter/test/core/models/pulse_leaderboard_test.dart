import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_flutter/core/models/pulse_leaderboard.dart';
import 'package:pulse_flutter/core/models/user_profile.dart';

void main() {
  test('leaderboard state derives the current user row from profile data', () {
    final PulseUserProfile profile = PulseUserProfile(
      uid: 'test-user',
      email: 'ava@example.com',
      displayName: 'Ava',
      avatarColour: '#EC4899',
      currentStreak: 4,
      longestStreak: 7,
      totalXp: 180,
      currentLevel: 2,
      referralCount: 3,
    );

    final PulseLeaderboardState state = PulseLeaderboardState.fromProfile(
      profile,
    );

    expect(state.referralCode, startsWith('PULSE'));
    expect(state.referralCount, 3);
    expect(state.currentUserEntry.rank, 1);
    expect(state.currentUserEntry.name, 'Ava');
    expect(state.currentUserEntry.currentStreak, 4);
    expect(state.currentUserEntry.currentLevel, 2);
    expect(state.currentUserEntry.referralCount, 3);
    expect(state.hasFriends, isFalse);
  });

  test(
    'leaderboard ranks real referral-circle rows and builds challenge data',
    () {
      final PulseUserProfile currentUser = PulseUserProfile(
        uid: 'test-user',
        email: 'ava@example.com',
        displayName: 'Ava',
        avatarColour: '#EC4899',
        currentStreak: 4,
        longestStreak: 7,
        totalXp: 180,
        currentLevel: 2,
        referralCount: 1,
        referredByUid: 'mentor-user',
      );
      final PulseUserProfile inviter = PulseUserProfile(
        uid: 'mentor-user',
        email: 'mentor@example.com',
        displayName: 'Milo',
        avatarColour: '#10B981',
        currentStreak: 6,
        longestStreak: 9,
        totalXp: 360,
        currentLevel: 4,
        referralCount: 2,
      );
      final PulseUserProfile referredFriend = PulseUserProfile(
        uid: 'friend-user',
        email: 'noah@example.com',
        displayName: 'Noah',
        avatarColour: '#F59E0B',
        currentStreak: 5,
        longestStreak: 5,
        totalXp: 210,
        currentLevel: 3,
        referralCount: 0,
        referredByUid: 'test-user',
      );

      final PulseLeaderboardState state = PulseLeaderboardState.fromProfile(
        currentUser,
        socialProfiles: <PulseUserProfile>[inviter, referredFriend],
      );

      expect(state.hasFriends, isTrue);
      expect(state.totalVisibleEntries, 3);
      expect(state.currentUserEntry.rank, 3);
      expect(state.leaderEntry.name, 'Milo');
      expect(state.joinedWithYourCodeCount, 1);
      expect(state.inviterEntry?.name, 'Milo');
      expect(state.friendEntries.map((entry) => entry.name), <String>[
        'Milo',
        'Noah',
      ]);
      expect(state.friendEntries.first.subtitle, 'Invited you to Pulse');
      expect(state.friendEntries.last.subtitle, 'Joined with your code');

      final PulseLeaderboardChallengeDraft challenge = state.challengeFor(
        state.friendEntries.last,
      );

      expect(challenge.friendName, 'Noah');
      expect(challenge.targetStreak, 7);
      expect(challenge.headline, 'Catch Noah');
      expect(challenge.shareText, contains('Ava vs Noah'));
      expect(challenge.shareText, contains('4 day streak | Level 2'));
      expect(challenge.shareText, contains('5 day streak | Level 3'));
    },
  );
}
