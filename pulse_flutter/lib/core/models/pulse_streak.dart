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

  static PulseStreak fromSessionDates(
    Iterable<String> sessionDates, {
    DateTime? currentDate,
  }) {
    final List<DateTime> sortedDates =
        sessionDates
            .map(_parseSessionDate)
            .whereType<DateTime>()
            .map(_normalizeDate)
            .toSet()
            .toList(growable: false)
          ..sort((a, b) => a.compareTo(b));

    if (sortedDates.isEmpty) {
      return const PulseStreak();
    }

    int longestRun = 1;
    int activeRun = 1;

    for (int index = 1; index < sortedDates.length; index += 1) {
      final DateTime previousDate = sortedDates[index - 1];
      final DateTime currentRunDate = sortedDates[index];

      if (currentRunDate.difference(previousDate).inDays == 1) {
        activeRun += 1;
      } else {
        activeRun = 1;
      }

      if (activeRun > longestRun) {
        longestRun = activeRun;
      }
    }

    int trailingRun = 1;
    for (int index = sortedDates.length - 1; index > 0; index -= 1) {
      final DateTime currentRunDate = sortedDates[index];
      final DateTime previousDate = sortedDates[index - 1];

      if (currentRunDate.difference(previousDate).inDays == 1) {
        trailingRun += 1;
        continue;
      }

      break;
    }

    final DateTime lastDate = sortedDates.last;
    final DateTime now = _normalizeDate(currentDate ?? DateTime.now());
    final int effectiveCurrentStreak =
        _isCurrentOrPreviousDay(lastDate: lastDate, currentDate: now)
        ? trailingRun
        : 0;

    return PulseStreak(
      currentStreak: effectiveCurrentStreak,
      longestStreak: longestRun,
      lastSessionDate: _formatDate(lastDate),
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

  PulseStreak effectiveAsOf(DateTime currentDate) {
    final DateTime now = _normalizeDate(currentDate);
    final DateTime? lastDate = _parseSessionDate(lastSessionDate);

    if (lastDate == null) {
      return PulseStreak(
        currentStreak: 0,
        longestStreak: longestStreak,
        lastSessionDate: lastSessionDate,
      );
    }

    if (_isCurrentOrPreviousDay(lastDate: lastDate, currentDate: now)) {
      return this;
    }

    return PulseStreak(
      currentStreak: 0,
      longestStreak: longestStreak,
      lastSessionDate: lastSessionDate,
    );
  }

  int? daysSinceLastSession(DateTime currentDate) {
    final DateTime? lastDate = _parseSessionDate(lastSessionDate);
    if (lastDate == null) {
      return null;
    }

    final int difference = _normalizeDate(
      currentDate,
    ).difference(_normalizeDate(lastDate)).inDays;
    if (difference < 0) {
      return 0;
    }

    return difference;
  }

  int missedDaysAsOf(DateTime currentDate) {
    final int? daysSinceLast = daysSinceLastSession(currentDate);
    if (daysSinceLast == null || daysSinceLast <= 1) {
      return 0;
    }

    return daysSinceLast - 1;
  }

  bool matches(PulseStreak other) {
    return currentStreak == other.currentStreak &&
        longestStreak == other.longestStreak &&
        lastSessionDate == other.lastSessionDate;
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

  static bool _isCurrentOrPreviousDay({
    required DateTime lastDate,
    required DateTime currentDate,
  }) {
    final int dayDifference = _normalizeDate(
      currentDate,
    ).difference(_normalizeDate(lastDate)).inDays;
    return dayDifference >= 0 && dayDifference <= 1;
  }

  static DateTime _normalizeDate(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  static String _formatDate(DateTime value) {
    final String year = value.year.toString().padLeft(4, '0');
    final String month = value.month.toString().padLeft(2, '0');
    final String day = value.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
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
