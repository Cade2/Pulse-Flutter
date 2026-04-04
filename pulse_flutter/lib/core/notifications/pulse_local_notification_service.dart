import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:pulse_flutter/core/models/pulse_profile_settings.dart';
import 'package:pulse_flutter/core/notifications/pulse_push_message.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

abstract class PulseForegroundNotificationPresenter {
  Future<void> showForegroundPushMessage(PulsePushMessage message);
}

abstract class PulseReminderService {
  Future<void> initialize();
  Future<void> syncReminders({
    required PulseProfileSettings settings,
    required bool hasCompletedToday,
  });
  Future<void> cancelUserReminders();
}

class PulseReminderSyncState {
  const PulseReminderSyncState({
    required this.uid,
    required this.settings,
    required this.hasCompletedToday,
  });

  const PulseReminderSyncState.signedOut()
    : uid = null,
      settings = null,
      hasCompletedToday = false;

  final String? uid;
  final PulseProfileSettings? settings;
  final bool hasCompletedToday;

  bool get isSignedIn => uid != null && uid!.isNotEmpty && settings != null;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }

    return other is PulseReminderSyncState &&
        other.uid == uid &&
        other.hasCompletedToday == hasCompletedToday &&
        other.settings?.preferredReminderTime ==
            settings?.preferredReminderTime &&
        other.settings?.dailyRemindersEnabled ==
            settings?.dailyRemindersEnabled &&
        other.settings?.streakRemindersEnabled ==
            settings?.streakRemindersEnabled &&
        other.settings?.weeklySummaryEnabled == settings?.weeklySummaryEnabled;
  }

  @override
  int get hashCode => Object.hash(
    uid,
    hasCompletedToday,
    settings?.preferredReminderTime,
    settings?.dailyRemindersEnabled,
    settings?.streakRemindersEnabled,
    settings?.weeklySummaryEnabled,
  );
}

class NoopPulseReminderService
    implements PulseReminderService, PulseForegroundNotificationPresenter {
  const NoopPulseReminderService();

  @override
  Future<void> cancelUserReminders() async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<void> syncReminders({
    required PulseProfileSettings settings,
    required bool hasCompletedToday,
  }) async {}

  @override
  Future<void> showForegroundPushMessage(PulsePushMessage message) async {}
}

class PulseReminderSyncController {
  const PulseReminderSyncController(this._service);

  final PulseReminderService _service;

  Future<void> syncState(PulseReminderSyncState state) async {
    if (!state.isSignedIn || state.settings == null) {
      await _service.cancelUserReminders();
      return;
    }

    await _service.syncReminders(
      settings: state.settings!,
      hasCompletedToday: state.hasCompletedToday,
    );
  }
}

class PulseLocalNotificationService
    implements PulseReminderService, PulseForegroundNotificationPresenter {
  PulseLocalNotificationService({
    FlutterLocalNotificationsPlugin? notificationsPlugin,
  }) : _notificationsPlugin =
           notificationsPlugin ?? FlutterLocalNotificationsPlugin();

  static const int dailyReminderNotificationId = 41001;
  static const int streakRiskWarningNotificationId = 41002;
  static const int streakRiskFinalWarningNotificationId = 41003;
  static const int weeklySummaryNotificationId = 41004;

  static const String dailyReminderChannelId = 'pulse_daily_reminders';
  static const String streakReminderChannelId = 'pulse_streak_risk_reminders';
  static const String weeklySummaryChannelId = 'pulse_weekly_summary';
  static const String foregroundMessageChannelId = 'pulse_foreground_messages';

  static const String _dailyReminderChannelName = 'Daily reminders';
  static const String _dailyReminderChannelDescription =
      'Daily Pulse check-in reminders.';
  static const String _streakReminderChannelName = 'Streak reminders';
  static const String _streakReminderChannelDescription =
      'Pulse streak-risk reminders for unfinished days.';
  static const String _weeklySummaryChannelName = 'Weekly summary reminders';
  static const String _weeklySummaryChannelDescription =
      'Pulse weekly summary reminder prompts.';
  static const String _foregroundMessageChannelName = 'Foreground messages';
  static const String _foregroundMessageChannelDescription =
      'Foreground Firebase Cloud Messaging notifications.';

  static const TimeOfDay streakRiskWarningTime = TimeOfDay(hour: 18, minute: 0);
  static const TimeOfDay streakRiskFinalWarningTime = TimeOfDay(
    hour: 21,
    minute: 0,
  );
  static const TimeOfDay weeklySummaryReminderTime = TimeOfDay(
    hour: 19,
    minute: 0,
  );

  final FlutterLocalNotificationsPlugin _notificationsPlugin;

  Future<void>? _initialization;

  static DateTime nextReminderDate({
    required TimeOfDay reminderTime,
    DateTime? now,
  }) {
    final DateTime current = now ?? DateTime.now();
    DateTime scheduled = DateTime(
      current.year,
      current.month,
      current.day,
      reminderTime.hour,
      reminderTime.minute,
    );

    if (!scheduled.isAfter(current)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    return scheduled;
  }

  static List<DateTime> upcomingStreakRiskReminderDates({DateTime? now}) {
    final DateTime current = now ?? DateTime.now();
    final List<TimeOfDay> reminderTimes = <TimeOfDay>[
      streakRiskWarningTime,
      streakRiskFinalWarningTime,
    ];

    return reminderTimes
        .map(
          (time) => DateTime(
            current.year,
            current.month,
            current.day,
            time.hour,
            time.minute,
          ),
        )
        .where((scheduled) => scheduled.isAfter(current))
        .toList(growable: false);
  }

  static DateTime nextWeeklySummaryReminderDate({DateTime? now}) {
    final DateTime current = now ?? DateTime.now();
    DateTime scheduled = DateTime(
      current.year,
      current.month,
      current.day,
      weeklySummaryReminderTime.hour,
      weeklySummaryReminderTime.minute,
    );

    final int daysUntilSunday =
        (DateTime.sunday - scheduled.weekday + DateTime.daysPerWeek) %
        DateTime.daysPerWeek;
    scheduled = scheduled.add(Duration(days: daysUntilSunday));

    if (!scheduled.isAfter(current)) {
      scheduled = scheduled.add(const Duration(days: DateTime.daysPerWeek));
    }

    return scheduled;
  }

  @override
  Future<void> initialize() {
    return _initialization ??= _initializeInternal();
  }

  @override
  Future<void> syncReminders({
    required PulseProfileSettings settings,
    required bool hasCompletedToday,
  }) async {
    await initialize();

    if (!_supportsNotifications) {
      return;
    }

    await _cancelTrackedReminders();

    final bool shouldScheduleDailyReminder = settings.dailyRemindersEnabled;
    final bool shouldScheduleStreakRiskReminders =
        settings.streakRemindersEnabled && !hasCompletedToday;
    final bool shouldScheduleWeeklySummaryReminder =
        settings.weeklySummaryEnabled;

    if (!shouldScheduleDailyReminder &&
        !shouldScheduleStreakRiskReminders &&
        !shouldScheduleWeeklySummaryReminder) {
      return;
    }

    final bool hasPermission = await _requestPermissionIfNeeded();
    if (!hasPermission) {
      return;
    }

    if (shouldScheduleDailyReminder) {
      await _scheduleDailyReminder(settings);
    }

    if (shouldScheduleStreakRiskReminders) {
      await _scheduleStreakRiskReminders();
    }

    if (shouldScheduleWeeklySummaryReminder) {
      await _scheduleWeeklySummaryReminder();
    }
  }

  @override
  Future<void> cancelUserReminders() async {
    await initialize();

    if (!_supportsNotifications) {
      return;
    }

    await _cancelTrackedReminders();
  }

  @override
  Future<void> showForegroundPushMessage(PulsePushMessage message) async {
    await initialize();

    if (!_supportsNotifications || !message.hasDisplayContent) {
      return;
    }

    final String payload = jsonEncode(message.toJson());

    await _notificationsPlugin.show(
      id: _foregroundNotificationIdFor(message),
      title: message.title ?? 'Pulse',
      body: message.body,
      payload: payload,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          foregroundMessageChannelId,
          _foregroundMessageChannelName,
          channelDescription: _foregroundMessageChannelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(
          threadIdentifier: foregroundMessageChannelId,
        ),
        macOS: DarwinNotificationDetails(
          threadIdentifier: foregroundMessageChannelId,
        ),
      ),
    );
  }

  Future<void> _scheduleDailyReminder(PulseProfileSettings settings) async {
    final DateTime nextReminder = nextReminderDate(
      reminderTime: settings.reminderTimeOfDay,
    );

    await _notificationsPlugin.zonedSchedule(
      id: dailyReminderNotificationId,
      title: 'Pulse reminder',
      body: 'Take a minute to check in with Pulse today.',
      scheduledDate: tz.TZDateTime.from(nextReminder, tz.local),
      notificationDetails: _dailyReminderNotificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _scheduleStreakRiskReminders() async {
    final DateTime now = DateTime.now();
    final List<({int id, TimeOfDay time, String body})>
    reminders = <({int id, TimeOfDay time, String body})>[
      (
        id: streakRiskWarningNotificationId,
        time: streakRiskWarningTime,
        body:
            'Your Pulse streak is still open today. Check in before the evening gets away from you.',
      ),
      (
        id: streakRiskFinalWarningNotificationId,
        time: streakRiskFinalWarningTime,
        body:
            'Last call for today: save your Pulse streak with a quick check-in tonight.',
      ),
    ];

    for (final reminder in reminders) {
      final DateTime scheduledDate = DateTime(
        now.year,
        now.month,
        now.day,
        reminder.time.hour,
        reminder.time.minute,
      );

      if (!scheduledDate.isAfter(now)) {
        continue;
      }

      await _notificationsPlugin.zonedSchedule(
        id: reminder.id,
        title: 'Protect your Pulse streak',
        body: reminder.body,
        scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails: _streakRiskNotificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<void> _scheduleWeeklySummaryReminder() async {
    final DateTime nextReminder = nextWeeklySummaryReminderDate();

    await _notificationsPlugin.zonedSchedule(
      id: weeklySummaryNotificationId,
      title: 'Your weekly Pulse summary is ready',
      body: 'Take a look back at this week in Pulse.',
      scheduledDate: tz.TZDateTime.from(nextReminder, tz.local),
      notificationDetails: _weeklySummaryNotificationDetails,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
    );
  }

  NotificationDetails get _dailyReminderNotificationDetails {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        dailyReminderChannelId,
        _dailyReminderChannelName,
        channelDescription: _dailyReminderChannelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(threadIdentifier: dailyReminderChannelId),
      macOS: DarwinNotificationDetails(
        threadIdentifier: dailyReminderChannelId,
      ),
    );
  }

  NotificationDetails get _streakRiskNotificationDetails {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        streakReminderChannelId,
        _streakReminderChannelName,
        channelDescription: _streakReminderChannelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(threadIdentifier: streakReminderChannelId),
      macOS: DarwinNotificationDetails(
        threadIdentifier: streakReminderChannelId,
      ),
    );
  }

  NotificationDetails get _weeklySummaryNotificationDetails {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        weeklySummaryChannelId,
        _weeklySummaryChannelName,
        channelDescription: _weeklySummaryChannelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
      iOS: DarwinNotificationDetails(threadIdentifier: weeklySummaryChannelId),
      macOS: DarwinNotificationDetails(
        threadIdentifier: weeklySummaryChannelId,
      ),
    );
  }

  Future<void> _cancelTrackedReminders() async {
    await _notificationsPlugin.cancel(id: dailyReminderNotificationId);
    await _notificationsPlugin.cancel(id: streakRiskWarningNotificationId);
    await _notificationsPlugin.cancel(id: streakRiskFinalWarningNotificationId);
    await _notificationsPlugin.cancel(id: weeklySummaryNotificationId);
  }

  Future<void> _initializeInternal() async {
    if (!_supportsNotifications) {
      return;
    }

    tz.initializeTimeZones();
    await _configureTimeZone();

    const DarwinInitializationSettings darwinInitializationSettings =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: darwinInitializationSettings,
          macOS: darwinInitializationSettings,
        );

    await _notificationsPlugin.initialize(settings: initializationSettings);

    final AndroidFlutterLocalNotificationsPlugin? androidPlugin =
        _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        dailyReminderChannelId,
        _dailyReminderChannelName,
        description: _dailyReminderChannelDescription,
        importance: Importance.defaultImportance,
      ),
    );
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        streakReminderChannelId,
        _streakReminderChannelName,
        description: _streakReminderChannelDescription,
        importance: Importance.defaultImportance,
      ),
    );
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        weeklySummaryChannelId,
        _weeklySummaryChannelName,
        description: _weeklySummaryChannelDescription,
        importance: Importance.defaultImportance,
      ),
    );
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        foregroundMessageChannelId,
        _foregroundMessageChannelName,
        description: _foregroundMessageChannelDescription,
        importance: Importance.high,
      ),
    );
  }

  Future<void> _configureTimeZone() async {
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      final tz.Location location = tz.getLocation(timezone.identifier);
      tz.setLocalLocation(location);
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
  }

  Future<bool> _requestPermissionIfNeeded() async {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return await _notificationsPlugin
                .resolvePlatformSpecificImplementation<
                  AndroidFlutterLocalNotificationsPlugin
                >()
                ?.requestNotificationsPermission() ??
            true;
      case TargetPlatform.iOS:
        return await _notificationsPlugin
                .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin
                >()
                ?.requestPermissions(alert: true, badge: true, sound: true) ??
            true;
      case TargetPlatform.macOS:
        return await _notificationsPlugin
                .resolvePlatformSpecificImplementation<
                  MacOSFlutterLocalNotificationsPlugin
                >()
                ?.requestPermissions(alert: true, badge: true, sound: true) ??
            true;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return true;
    }
  }

  bool get _supportsNotifications {
    if (kIsWeb) {
      return false;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        return true;
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.windows:
        return false;
    }
  }

  int _foregroundNotificationIdFor(PulsePushMessage message) {
    final int candidate =
        message.messageId?.hashCode ??
        Object.hash(
          message.title,
          message.body,
          message.data,
          message.sentTime,
        );
    return candidate.abs() % 2147483647;
  }
}
