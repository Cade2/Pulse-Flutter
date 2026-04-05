import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:pulse_flutter/core/firestore/user_messaging_repository.dart';
import 'package:pulse_flutter/core/notifications/pulse_local_notification_service.dart';
import 'package:pulse_flutter/core/notifications/pulse_push_message.dart';

abstract class PulseMessagingService {
  Future<void> initialize();
  Future<void> requestPermission();
  Future<String?> getToken();
  Future<PulsePushMessage?> getInitialMessage();
  Stream<String> get onTokenRefresh;
  Stream<PulsePushMessage> get onForegroundMessage;
  Stream<PulsePushMessage> get onMessageOpenedApp;
}

class NoopPulseMessagingService implements PulseMessagingService {
  const NoopPulseMessagingService();

  @override
  Future<PulsePushMessage?> getInitialMessage() async {
    return null;
  }

  @override
  Future<String?> getToken() async {
    return null;
  }

  @override
  Future<void> initialize() async {}

  @override
  Stream<PulsePushMessage> get onForegroundMessage =>
      const Stream<PulsePushMessage>.empty();

  @override
  Stream<PulsePushMessage> get onMessageOpenedApp =>
      const Stream<PulsePushMessage>.empty();

  @override
  Stream<String> get onTokenRefresh => const Stream<String>.empty();

  @override
  Future<void> requestPermission() async {}
}

class PulseFirebaseMessagingService implements PulseMessagingService {
  PulseFirebaseMessagingService({FirebaseMessaging? firebaseMessaging})
    : _firebaseMessaging = firebaseMessaging ?? FirebaseMessaging.instance;

  final FirebaseMessaging _firebaseMessaging;

  @override
  Future<void> initialize() async {
    await _firebaseMessaging.setAutoInitEnabled(true);

    if (!kIsWeb) {
      await _firebaseMessaging.setForegroundNotificationPresentationOptions(
        alert: false,
        badge: false,
        sound: false,
      );
    }
  }

  @override
  Future<void> requestPermission() async {
    final NotificationSettings settings = await _firebaseMessaging
        .requestPermission(alert: true, badge: true, sound: true);

    debugPrint(
      'Pulse FCM permission status: ${settings.authorizationStatus.name}',
    );
  }

  @override
  Future<String?> getToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (error) {
      debugPrint('Pulse FCM token fetch failed: $error');
      return null;
    }
  }

  @override
  Future<PulsePushMessage?> getInitialMessage() async {
    final RemoteMessage? message = await _firebaseMessaging.getInitialMessage();
    if (message == null) {
      return null;
    }

    return _toPulsePushMessage(message);
  }

  @override
  Stream<PulsePushMessage> get onForegroundMessage {
    return FirebaseMessaging.onMessage.map(_toPulsePushMessage);
  }

  @override
  Stream<PulsePushMessage> get onMessageOpenedApp {
    return FirebaseMessaging.onMessageOpenedApp.map(_toPulsePushMessage);
  }

  @override
  Stream<String> get onTokenRefresh => _firebaseMessaging.onTokenRefresh;

  PulsePushMessage _toPulsePushMessage(RemoteMessage message) {
    return PulsePushMessage(
      messageId: message.messageId,
      title: message.notification?.title,
      body: message.notification?.body,
      sentTime: message.sentTime,
      data: Map<String, String>.from(message.data),
    );
  }
}

class PulseMessagingController {
  PulseMessagingController({
    required PulseMessagingService messagingService,
    required UserMessagingRepository userMessagingRepository,
    required PulseForegroundNotificationPresenter notificationPresenter,
    required PulsePushNotificationTapSource notificationTapSource,
  }) : _messagingService = messagingService,
       _userMessagingRepository = userMessagingRepository,
       _notificationPresenter = notificationPresenter,
       _notificationTapSource = notificationTapSource;

  final PulseMessagingService _messagingService;
  final UserMessagingRepository _userMessagingRepository;
  final PulseForegroundNotificationPresenter _notificationPresenter;
  final PulsePushNotificationTapSource _notificationTapSource;

  final StreamController<PulsePushMessage> _openedMessagesController =
      StreamController<PulsePushMessage>.broadcast();

  StreamSubscription<String>? _tokenRefreshSubscription;
  StreamSubscription<PulsePushMessage>? _foregroundMessageSubscription;
  StreamSubscription<PulsePushMessage>? _openedMessageSubscription;
  StreamSubscription<PulsePushMessage>? _notificationTapSubscription;
  Future<void>? _initialization;

  String? _currentUid;
  String? _lastKnownToken;
  PulsePushMessage? _lastOpenedMessage;

  Stream<PulsePushMessage> get openedMessages =>
      _openedMessagesController.stream;
  PulsePushMessage? get lastOpenedMessage => _lastOpenedMessage;

  Future<void> initialize() {
    return _initialization ??= _initializeInternal();
  }

  Future<void> syncCurrentUser(String? uid) async {
    await initialize();

    if (_currentUid == uid) {
      if (uid != null && uid.isNotEmpty && _lastKnownToken == null) {
        await _syncCurrentToken(uid);
      }
      return;
    }

    final String? previousUid = _currentUid;
    _currentUid = uid;

    if (previousUid != null &&
        previousUid.isNotEmpty &&
        _lastKnownToken != null &&
        _lastKnownToken!.isNotEmpty) {
      await _userMessagingRepository.clearFcmToken(
        uid: previousUid,
        token: _lastKnownToken!,
      );
    }

    if (uid == null || uid.isEmpty) {
      return;
    }

    await _syncCurrentToken(uid);
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    await _foregroundMessageSubscription?.cancel();
    await _openedMessageSubscription?.cancel();
    await _notificationTapSubscription?.cancel();
    await _openedMessagesController.close();
  }

  Future<void> _initializeInternal() async {
    await _messagingService.initialize();
    await _messagingService.requestPermission();

    final PulsePushMessage? initialMessage = await _messagingService
        .getInitialMessage();
    if (initialMessage != null) {
      _handleOpenedMessage(initialMessage);
    }

    final PulsePushMessage? initialNotificationTap = await _notificationTapSource
        .getInitialPushNotificationTap();
    if (initialNotificationTap != null) {
      _handleOpenedMessage(initialNotificationTap);
    }

    _foregroundMessageSubscription = _messagingService.onForegroundMessage
        .listen(_handleForegroundMessage);
    _openedMessageSubscription = _messagingService.onMessageOpenedApp.listen(
      _handleOpenedMessage,
    );
    _notificationTapSubscription = _notificationTapSource.onPushNotificationTap
        .listen(_handleOpenedMessage);
    _tokenRefreshSubscription = _messagingService.onTokenRefresh.listen((
      token,
    ) async {
      await _persistToken(token);
    });

    if (_currentUid != null && _currentUid!.isNotEmpty) {
      await _syncCurrentToken(_currentUid!);
    }
  }

  Future<void> _syncCurrentToken(String uid) async {
    final String? token = await _messagingService.getToken();
    if (token == null || token.isEmpty) {
      return;
    }

    await _persistToken(token);
  }

  Future<void> _persistToken(String token) async {
    _lastKnownToken = token;

    final String? uid = _currentUid;
    if (uid == null || uid.isEmpty) {
      return;
    }

    await _userMessagingRepository.saveFcmToken(uid: uid, token: token);
    debugPrint('Pulse FCM token saved for $uid');
  }

  Future<void> _handleForegroundMessage(PulsePushMessage message) async {
    debugPrint('Pulse FCM foreground message: ${message.toJson()}');

    if (!message.hasDisplayContent) {
      return;
    }

    await _notificationPresenter.showForegroundPushMessage(message);
  }

  void _handleOpenedMessage(PulsePushMessage message) {
    if (_lastOpenedMessage?.routingKey == message.routingKey) {
      return;
    }

    _lastOpenedMessage = message;
    debugPrint('Pulse FCM opened message: ${message.toJson()}');
    if (!_openedMessagesController.isClosed) {
      _openedMessagesController.add(message);
    }
  }
}
