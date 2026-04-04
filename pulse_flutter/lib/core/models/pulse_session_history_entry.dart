import 'package:pulse_flutter/core/models/pulse_level_progress.dart';

class PulseSessionHistoryEntry {
  const PulseSessionHistoryEntry({
    required this.date,
    this.contextSocial,
    this.contextEnergy,
    this.contextSleep,
  });

  final String date;
  final String? contextSocial;
  final String? contextEnergy;
  final String? contextSleep;

  factory PulseSessionHistoryEntry.fromFirestoreData({
    required Map<String, dynamic> data,
    required String fallbackDate,
  }) {
    return PulseSessionHistoryEntry(
      date: _trimToNull(data['date']) ?? fallbackDate,
      contextSocial: _trimToNull(data['contextSocial']),
      contextEnergy: _trimToNull(data['contextEnergy']),
      contextSleep: _trimToNull(data['contextSleep']),
    );
  }

  int get earnedXp {
    return PulseLevelProgress.sessionXp(
      contextSocial: contextSocial,
      contextEnergy: contextEnergy,
      contextSleep: contextSleep,
    );
  }

  static String? _trimToNull(Object? value) {
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
