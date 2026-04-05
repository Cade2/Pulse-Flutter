import 'package:pulse_flutter/core/models/pulse_level_progress.dart';

class PulseSessionHistoryEntry {
  const PulseSessionHistoryEntry({
    required this.date,
    this.acceptedEmotions = const <String>[],
    this.contextSocial,
    this.contextEnergy,
    this.contextSleep,
  });

  final String date;
  final List<String> acceptedEmotions;
  final String? contextSocial;
  final String? contextEnergy;
  final String? contextSleep;

  factory PulseSessionHistoryEntry.fromFirestoreData({
    required Map<String, dynamic> data,
    required String fallbackDate,
  }) {
    return PulseSessionHistoryEntry(
      date: _trimToNull(data['date']) ?? fallbackDate,
      acceptedEmotions: _readStringList(data['acceptedEmotions']),
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

  bool get hasAnyContextTag {
    return <String?>[
      contextSocial,
      contextEnergy,
      contextSleep,
    ].any((value) => value?.trim().isNotEmpty ?? false);
  }

  bool get hasFullContextTags {
    return <String?>[
      contextSocial,
      contextEnergy,
      contextSleep,
    ].every((value) => value?.trim().isNotEmpty ?? false);
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

  static List<String> _readStringList(Object? value) {
    if (value is! List) {
      return const <String>[];
    }

    return value
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(growable: false);
  }
}
