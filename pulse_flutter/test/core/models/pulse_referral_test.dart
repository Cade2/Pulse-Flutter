import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_flutter/core/models/pulse_referral.dart';

void main() {
  test('generateReferralCode is deterministic for a user uid', () {
    final String first = PulseReferral.generateReferralCode('test-user');
    final String second = PulseReferral.generateReferralCode('test-user');

    expect(first, second);
    expect(first, matches(RegExp(r'^PULSE[A-Z0-9]{8}$')));
  });

  test('resolveReferralCode repairs invalid stored values', () {
    expect(
      PulseReferral.resolveReferralCode('', uid: 'test-user'),
      PulseReferral.generateReferralCode('test-user'),
    );
    expect(
      PulseReferral.resolveReferralCode('not-valid', uid: 'test-user'),
      PulseReferral.generateReferralCode('test-user'),
    );
  });

  test('resolveReferralCount falls back for invalid values', () {
    expect(PulseReferral.resolveReferralCount(null), 0);
    expect(PulseReferral.resolveReferralCount(-1), 0);
    expect(PulseReferral.resolveReferralCount(4), 4);
  });
}
