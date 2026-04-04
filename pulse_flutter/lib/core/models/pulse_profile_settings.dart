import 'package:flutter/material.dart';

enum PulseAppearanceMode { system, dark, light }

String? _readTrimmedString(Object? value) {
  if (value is! String) {
    return null;
  }

  final String trimmed = value.trim();
  if (trimmed.isEmpty) {
    return null;
  }

  return trimmed;
}

extension PulseAppearanceModeX on PulseAppearanceMode {
  static PulseAppearanceMode fromStorageValue(Object? value) {
    final String normalized = _readTrimmedString(value)?.toLowerCase() ?? '';

    switch (normalized) {
      case 'system':
        return PulseAppearanceMode.system;
      case 'light':
        return PulseAppearanceMode.light;
      case 'dark':
      default:
        return PulseAppearanceMode.dark;
    }
  }

  String get storageValue {
    switch (this) {
      case PulseAppearanceMode.system:
        return 'system';
      case PulseAppearanceMode.light:
        return 'light';
      case PulseAppearanceMode.dark:
        return 'dark';
    }
  }

  String get label {
    switch (this) {
      case PulseAppearanceMode.system:
        return 'System';
      case PulseAppearanceMode.light:
        return 'Light';
      case PulseAppearanceMode.dark:
        return 'Dark';
    }
  }

  ThemeMode get themeMode {
    switch (this) {
      case PulseAppearanceMode.system:
        return ThemeMode.system;
      case PulseAppearanceMode.light:
        return ThemeMode.light;
      case PulseAppearanceMode.dark:
        return ThemeMode.dark;
    }
  }
}

class PulseProfileSettings {
  static const String defaultPreferredReminderTime = '20:00';
  static const bool defaultDailyRemindersEnabled = true;
  static const bool defaultStreakRemindersEnabled = true;
  static const bool defaultWeeklySummaryEnabled = false;
  static const PulseAppearanceMode defaultAppearanceMode =
      PulseAppearanceMode.dark;
  static final RegExp _timePattern = RegExp(r'^(\d{1,2}):(\d{2})$');

  const PulseProfileSettings({
    this.preferredReminderTime = defaultPreferredReminderTime,
    this.dailyRemindersEnabled = defaultDailyRemindersEnabled,
    this.streakRemindersEnabled = defaultStreakRemindersEnabled,
    this.weeklySummaryEnabled = defaultWeeklySummaryEnabled,
    this.appearanceMode = defaultAppearanceMode,
  });

  final String preferredReminderTime;
  final bool dailyRemindersEnabled;
  final bool streakRemindersEnabled;
  final bool weeklySummaryEnabled;
  final PulseAppearanceMode appearanceMode;

  factory PulseProfileSettings.fromFirestoreData(Object? value) {
    return PulseProfileSettings(
      preferredReminderTime: normalizeReminderTime(
        _readMapValue(value, 'preferredReminderTime'),
      ),
      dailyRemindersEnabled: _readBool(
        _readMapValue(value, 'dailyRemindersEnabled'),
        defaultValue: defaultDailyRemindersEnabled,
      ),
      streakRemindersEnabled: _readBool(
        _readMapValue(value, 'streakRemindersEnabled'),
        defaultValue: defaultStreakRemindersEnabled,
      ),
      weeklySummaryEnabled: _readBool(
        _readMapValue(value, 'weeklySummaryEnabled'),
        defaultValue: defaultWeeklySummaryEnabled,
      ),
      appearanceMode: PulseAppearanceModeX.fromStorageValue(
        _readMapValue(value, 'appearanceMode'),
      ),
    );
  }

  Map<String, Object> toFirestore() {
    return <String, Object>{
      'preferredReminderTime': preferredReminderTime,
      'dailyRemindersEnabled': dailyRemindersEnabled,
      'streakRemindersEnabled': streakRemindersEnabled,
      'weeklySummaryEnabled': weeklySummaryEnabled,
      'appearanceMode': appearanceMode.storageValue,
    };
  }

  PulseProfileSettings copyWith({
    String? preferredReminderTime,
    bool? dailyRemindersEnabled,
    bool? streakRemindersEnabled,
    bool? weeklySummaryEnabled,
    PulseAppearanceMode? appearanceMode,
  }) {
    return PulseProfileSettings(
      preferredReminderTime:
          preferredReminderTime ?? this.preferredReminderTime,
      dailyRemindersEnabled:
          dailyRemindersEnabled ?? this.dailyRemindersEnabled,
      streakRemindersEnabled:
          streakRemindersEnabled ?? this.streakRemindersEnabled,
      weeklySummaryEnabled: weeklySummaryEnabled ?? this.weeklySummaryEnabled,
      appearanceMode: appearanceMode ?? this.appearanceMode,
    );
  }

  TimeOfDay get reminderTimeOfDay {
    return timeOfDayFromStorage(preferredReminderTime);
  }

  String get reminderTimeLabel {
    return formatDisplayTime(reminderTimeOfDay);
  }

  static String normalizeReminderTime(Object? value) {
    final String rawValue = _readTrimmedString(value) ?? '';
    final Match? match = _timePattern.firstMatch(rawValue);
    if (match == null) {
      return defaultPreferredReminderTime;
    }

    final int? hour = int.tryParse(match.group(1) ?? '');
    final int? minute = int.tryParse(match.group(2) ?? '');
    if (hour == null ||
        minute == null ||
        hour < 0 ||
        hour > 23 ||
        minute < 0 ||
        minute > 59) {
      return defaultPreferredReminderTime;
    }

    return formatStorageTime(TimeOfDay(hour: hour, minute: minute));
  }

  static TimeOfDay timeOfDayFromStorage(String value) {
    final String normalized = normalizeReminderTime(value);
    final Match match = _timePattern.firstMatch(normalized)!;
    final int hour = int.parse(match.group(1)!);
    final int minute = int.parse(match.group(2)!);
    return TimeOfDay(hour: hour, minute: minute);
  }

  static String formatStorageTime(TimeOfDay time) {
    final String hour = time.hour.toString().padLeft(2, '0');
    final String minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String formatDisplayTime(TimeOfDay time) {
    final int hourOfPeriod = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final String minute = time.minute.toString().padLeft(2, '0');
    final String period = time.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hourOfPeriod:$minute $period';
  }

  static bool needsRepair(Object? value) {
    if (value is! Map) {
      return true;
    }

    final PulseProfileSettings normalized =
        PulseProfileSettings.fromFirestoreData(value);

    final Object? reminderValue = _readMapValue(value, 'preferredReminderTime');
    final String? storedReminder = _readTrimmedString(reminderValue);
    if (storedReminder != normalized.preferredReminderTime) {
      return true;
    }

    final Object? dailyValue = _readMapValue(value, 'dailyRemindersEnabled');
    if (dailyValue is! bool || dailyValue != normalized.dailyRemindersEnabled) {
      return true;
    }

    final Object? streakValue = _readMapValue(value, 'streakRemindersEnabled');
    if (streakValue is! bool ||
        streakValue != normalized.streakRemindersEnabled) {
      return true;
    }

    final Object? weeklyValue = _readMapValue(value, 'weeklySummaryEnabled');
    if (weeklyValue is! bool ||
        weeklyValue != normalized.weeklySummaryEnabled) {
      return true;
    }

    final String? storedAppearance = _readTrimmedString(
      _readMapValue(value, 'appearanceMode'),
    )?.toLowerCase();
    if (storedAppearance != normalized.appearanceMode.storageValue) {
      return true;
    }

    return false;
  }

  static Object? _readMapValue(Object? value, String key) {
    if (value is Map<String, dynamic>) {
      return value[key];
    }

    if (value is Map) {
      return value[key];
    }

    return null;
  }

  static bool _readBool(Object? value, {required bool defaultValue}) {
    if (value is bool) {
      return value;
    }

    return defaultValue;
  }
}
