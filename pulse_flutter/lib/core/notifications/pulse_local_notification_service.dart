import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:pulse_flutter/core/models/pulse_profile_settings.dart';
import 'package:pulse_flutter/core/models/user_profile.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

abstract class PulseDailyReminderService {
  Future<void> initialize();
  Future<void> scheduleDailyReminder(PulseProfileSettings settings);
  Future<void> cancelDailyReminder();
}

class NoopPulseDailyReminderService implements PulseDailyReminderService {
  const NoopPulseDailyReminderService();

  @override
  Future<void> cancelDailyReminder() async {}

  @override
  Future<void> initialize() async {}

  @override
  Future<void> scheduleDailyReminder(PulseProfileSettings settings) async {}
}

class PulseReminderSyncController {
  const PulseReminderSyncController(this._service);

  final PulseDailyReminderService _service;

  Future<void> syncProfile(PulseUserProfile? profile) async {
    if (profile == null || !profile.settings.dailyRemindersEnabled) {
      await _service.cancelDailyReminder();
      return;
    }

    await _service.scheduleDailyReminder(profile.settings);
  }
}

class PulseLocalNotificationService implements PulseDailyReminderService {
  PulseLocalNotificationService({
    FlutterLocalNotificationsPlugin? notificationsPlugin,
  }) : _notificationsPlugin =
           notificationsPlugin ?? FlutterLocalNotificationsPlugin();

  static const int dailyReminderNotificationId = 41001;
  static const String dailyReminderChannelId = 'pulse_daily_reminders';
  static const String _dailyReminderChannelName = 'Daily reminders';
  static const String _dailyReminderChannelDescription =
      'Daily Pulse check-in reminders.';

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

  @override
  Future<void> initialize() {
    return _initialization ??= _initializeInternal();
  }

  @override
  Future<void> scheduleDailyReminder(PulseProfileSettings settings) async {
    await initialize();

    if (!_supportsNotifications) {
      return;
    }

    final bool hasPermission = await _requestPermissionIfNeeded();
    if (!hasPermission) {
      await cancelDailyReminder();
      return;
    }

    await _notificationsPlugin.cancel(id: dailyReminderNotificationId);

    final TimeOfDay reminderTime = settings.reminderTimeOfDay;
    final DateTime nextReminder = nextReminderDate(reminderTime: reminderTime);

    await _notificationsPlugin.zonedSchedule(
      id: dailyReminderNotificationId,
      title: 'Pulse reminder',
      body: 'Take a minute to check in with Pulse today.',
      scheduledDate: tz.TZDateTime.from(nextReminder, tz.local),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          dailyReminderChannelId,
          _dailyReminderChannelName,
          channelDescription: _dailyReminderChannelDescription,
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(
          threadIdentifier: dailyReminderChannelId,
        ),
        macOS: DarwinNotificationDetails(
          threadIdentifier: dailyReminderChannelId,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  @override
  Future<void> cancelDailyReminder() async {
    await initialize();

    if (!_supportsNotifications) {
      return;
    }

    await _notificationsPlugin.cancel(id: dailyReminderNotificationId);
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

    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(
          const AndroidNotificationChannel(
            dailyReminderChannelId,
            _dailyReminderChannelName,
            description: _dailyReminderChannelDescription,
            importance: Importance.defaultImportance,
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
}
