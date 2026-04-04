class PulseStreak {
  const PulseStreak({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastSessionDate,
  });

  final int currentStreak;
  final int longestStreak;
  final String? lastSessionDate;

  factory PulseStreak.fromFirestoreData(Map<String, dynamic> data) {
    return PulseStreak(
      currentStreak: _readNonNegativeInt(data['currentStreak']),
      longestStreak: _readNonNegativeInt(data['longestStreak']),
      lastSessionDate: _readSessionDate(data['lastSessionDate']),
    );
  }

  PulseStreak recordCompletion(String sessionDate) {
    final String? previousDate = lastSessionDate;

    if (previousDate == sessionDate) {
      return PulseStreak(
        currentStreak: currentStreak,
        longestStreak: longestStreak,
        lastSessionDate: previousDate,
      );
    }

    final int nextCurrentStreak =
        _isPreviousDay(previousDate: previousDate, currentDate: sessionDate)
        ? currentStreak + 1
        : 1;
    final int nextLongestStreak = nextCurrentStreak > longestStreak
        ? nextCurrentStreak
        : longestStreak;

    return PulseStreak(
      currentStreak: nextCurrentStreak,
      longestStreak: nextLongestStreak,
      lastSessionDate: sessionDate,
    );
  }

  Map<String, Object?> toFirestore() {
    return <String, Object?>{
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      'lastSessionDate': lastSessionDate,
    };
  }

  static bool _isPreviousDay({
    required String? previousDate,
    required String currentDate,
  }) {
    final DateTime? previous = _parseSessionDate(previousDate);
    final DateTime? current = _parseSessionDate(currentDate);

    if (previous == null || current == null) {
      return false;
    }

    return current.difference(previous).inDays == 1;
  }

  static DateTime? _parseSessionDate(String? value) {
    if (value == null) {
      return null;
    }

    final List<String> parts = value.split('-');
    if (parts.length != 3) {
      return null;
    }

    final int? year = int.tryParse(parts[0]);
    final int? month = int.tryParse(parts[1]);
    final int? day = int.tryParse(parts[2]);

    if (year == null || month == null || day == null) {
      return null;
    }

    return DateTime(year, month, day);
  }

  static int _readNonNegativeInt(Object? value) {
    if (value is int && value >= 0) {
      return value;
    }

    return 0;
  }

  static String? _readSessionDate(Object? value) {
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
