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
}
