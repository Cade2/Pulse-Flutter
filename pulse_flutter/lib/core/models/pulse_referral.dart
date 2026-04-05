abstract final class PulseReferral {
  static const String codePrefix = 'PULSE';
  static const int defaultReferralCount = 0;
  static final RegExp _codePattern = RegExp(r'^PULSE[A-Z0-9]{8}$');

  static String resolveReferralCode(Object? value, {required String uid}) {
    final String? storedCode = _readNullableString(value)?.toUpperCase();
    if (storedCode != null && _codePattern.hasMatch(storedCode)) {
      return storedCode;
    }

    return generateReferralCode(uid);
  }

  static bool needsReferralCodeRepair(Object? value, {required String uid}) {
    final String normalized = resolveReferralCode(value, uid: uid);
    final String? storedCode = _readNullableString(value)?.toUpperCase();
    return storedCode != normalized;
  }

  static int resolveReferralCount(Object? value) {
    if (value is int && value >= 0) {
      return value;
    }

    return defaultReferralCount;
  }

  static bool needsReferralCountRepair(Object? value) {
    return resolveReferralCount(value) != value;
  }

  static String generateReferralCode(String uid) {
    int hash = 0x811C9DC5;

    for (final int codeUnit in uid.codeUnits) {
      hash ^= codeUnit;
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }

    final String encoded = hash.toRadixString(36).toUpperCase().padLeft(8, '0');
    return '$codePrefix${encoded.substring(encoded.length - 8)}';
  }

  static String buildShareText({
    required String referralCode,
    String? displayName,
  }) {
    final String? trimmedName = _readNullableString(displayName);
    final String intro = trimmedName == null
        ? 'Join me on Pulse.'
        : '$trimmedName is inviting you to Pulse.';

    return '$intro\nReferral code: $referralCode';
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
}
