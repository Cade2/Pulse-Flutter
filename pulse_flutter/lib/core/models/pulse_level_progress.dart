class PulseLevelProgress {
  static const int xpPerLevel = 100;
  static const int sessionCompletionXp = 50;
  static const int contextTagBonusXp = 5;

  const PulseLevelProgress({this.totalXp = 0, this.currentLevel = 1});

  final int totalXp;
  final int currentLevel;

  factory PulseLevelProgress.fromFirestoreData(Map<String, dynamic> data) {
    final int storedXp = _readNonNegativeInt(data['totalXp']);
    return PulseLevelProgress.fromTotalXp(storedXp);
  }

  factory PulseLevelProgress.fromTotalXp(int totalXp) {
    final int sanitizedXp = totalXp < 0 ? 0 : totalXp;
    return PulseLevelProgress(
      totalXp: sanitizedXp,
      currentLevel: levelForXp(sanitizedXp),
    );
  }

  int get levelFloorXp => (currentLevel - 1) * xpPerLevel;

  int get xpIntoLevel => totalXp - levelFloorXp;

  int get xpToNextLevel => xpPerLevel - xpIntoLevel;

  int get nextLevel => currentLevel + 1;

  double get progressToNextLevel => xpIntoLevel / xpPerLevel;

  PulseLevelProgress addXp(int earnedXp) {
    final int sanitizedXp = earnedXp < 0 ? 0 : earnedXp;
    return PulseLevelProgress.fromTotalXp(totalXp + sanitizedXp);
  }

  bool matches(PulseLevelProgress other) {
    return totalXp == other.totalXp && currentLevel == other.currentLevel;
  }

  Map<String, Object?> toFirestore() {
    return <String, Object?>{'totalXp': totalXp, 'currentLevel': currentLevel};
  }

  static int levelForXp(int totalXp) {
    final int sanitizedXp = totalXp < 0 ? 0 : totalXp;
    return (sanitizedXp ~/ xpPerLevel) + 1;
  }

  static int sessionXp({
    String? contextSocial,
    String? contextEnergy,
    String? contextSleep,
  }) {
    return sessionCompletionXp +
        (_countSelectedContextTags(
              contextSocial: contextSocial,
              contextEnergy: contextEnergy,
              contextSleep: contextSleep,
            ) *
            contextTagBonusXp);
  }

  static int _countSelectedContextTags({
    String? contextSocial,
    String? contextEnergy,
    String? contextSleep,
  }) {
    return <String?>[
      contextSocial,
      contextEnergy,
      contextSleep,
    ].where((value) => value?.trim().isNotEmpty ?? false).length;
  }

  static int _readNonNegativeInt(Object? value) {
    if (value is int && value >= 0) {
      return value;
    }

    return 0;
  }
}
