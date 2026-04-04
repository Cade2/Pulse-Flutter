import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_flutter/core/models/user_profile.dart';

void main() {
  test('normalizeAvatarColour falls back for invalid values', () {
    expect(
      PulseUserProfile.normalizeAvatarColour('not-a-color'),
      PulseUserProfile.defaultAvatarColour,
    );
    expect(
      PulseUserProfile.normalizeAvatarColour(null),
      PulseUserProfile.defaultAvatarColour,
    );
  });

  test('normalizeAvatarColour uppercases valid hex values', () {
    expect(PulseUserProfile.normalizeAvatarColour('#ec4899'), '#EC4899');
  });

  test('friendlyNameFromEmail builds a readable fallback name', () {
    expect(
      PulseUserProfile.friendlyNameFromEmail('alex.smith@example.com'),
      'Alex smith',
    );
  });
}
