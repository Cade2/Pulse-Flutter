import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_flutter/core/firestore/user_messaging_repository.dart';
import 'package:pulse_flutter/core/notifications/pulse_firebase_messaging_service.dart';
import 'package:pulse_flutter/core/notifications/pulse_local_notification_service.dart';
import 'package:pulse_flutter/core/notifications/pulse_push_message.dart';

void main() {
  test(
    'syncCurrentUser saves the current FCM token for the signed-in user',
    () async {
      final _FakePulseMessagingService messagingService =
          _FakePulseMessagingService(currentToken: 'token-1');
      final _FakeUserMessagingRepository repository =
          _FakeUserMessagingRepository();
      final _FakeForegroundNotificationPresenter presenter =
          _FakeForegroundNotificationPresenter();
      final _FakeNotificationTapSource notificationTapSource =
          _FakeNotificationTapSource();
      final PulseMessagingController controller = PulseMessagingController(
        messagingService: messagingService,
        userMessagingRepository: repository,
        notificationPresenter: presenter,
        notificationTapSource: notificationTapSource,
      );
      addTearDown(() async {
        await controller.dispose();
        await notificationTapSource.dispose();
      });

      await controller.initialize();
      await controller.syncCurrentUser('user-1');

      expect(repository.savedTokens, <({String uid, String token})>[
        (uid: 'user-1', token: 'token-1'),
      ]);
    },
  );

  test(
    'token refresh persists the updated token for the current user',
    () async {
      final _FakePulseMessagingService messagingService =
          _FakePulseMessagingService();
      final _FakeUserMessagingRepository repository =
          _FakeUserMessagingRepository();
      final _FakeNotificationTapSource notificationTapSource =
          _FakeNotificationTapSource();
      final PulseMessagingController controller = PulseMessagingController(
        messagingService: messagingService,
        userMessagingRepository: repository,
        notificationPresenter: _FakeForegroundNotificationPresenter(),
        notificationTapSource: notificationTapSource,
      );
      addTearDown(() async {
        await controller.dispose();
        await messagingService.dispose();
        await notificationTapSource.dispose();
      });

      await controller.initialize();
      await controller.syncCurrentUser('user-1');

      messagingService.tokenRefreshController.add('token-refresh');
      await Future<void>.delayed(Duration.zero);

      expect(repository.savedTokens.last, (
        uid: 'user-1',
        token: 'token-refresh',
      ));
    },
  );

  test(
    'signing out clears the previously synced token from the prior user',
    () async {
      final _FakePulseMessagingService messagingService =
          _FakePulseMessagingService(currentToken: 'token-1');
      final _FakeUserMessagingRepository repository =
          _FakeUserMessagingRepository();
      final _FakeNotificationTapSource notificationTapSource =
          _FakeNotificationTapSource();
      final PulseMessagingController controller = PulseMessagingController(
        messagingService: messagingService,
        userMessagingRepository: repository,
        notificationPresenter: _FakeForegroundNotificationPresenter(),
        notificationTapSource: notificationTapSource,
      );
      addTearDown(() async {
        await controller.dispose();
        await notificationTapSource.dispose();
      });

      await controller.initialize();
      await controller.syncCurrentUser('user-1');
      await controller.syncCurrentUser(null);

      expect(repository.clearedTokens, <({String uid, String token})>[
        (uid: 'user-1', token: 'token-1'),
      ]);
    },
  );

  test(
    'foreground messages with display content are shown via local notifications',
    () async {
      final _FakePulseMessagingService messagingService =
          _FakePulseMessagingService();
      final _FakeForegroundNotificationPresenter presenter =
          _FakeForegroundNotificationPresenter();
      final _FakeNotificationTapSource notificationTapSource =
          _FakeNotificationTapSource();
      final PulseMessagingController controller = PulseMessagingController(
        messagingService: messagingService,
        userMessagingRepository: _FakeUserMessagingRepository(),
        notificationPresenter: presenter,
        notificationTapSource: notificationTapSource,
      );
      addTearDown(() async {
        await controller.dispose();
        await messagingService.dispose();
        await notificationTapSource.dispose();
      });

      await controller.initialize();

      messagingService.foregroundController.add(
        const PulsePushMessage(title: 'Pulse', body: 'New reminder'),
      );
      messagingService.foregroundController.add(
        const PulsePushMessage(data: <String, String>{'kind': 'silent'}),
      );
      await Future<void>.delayed(Duration.zero);

      expect(presenter.shownMessages, hasLength(1));
      expect(presenter.shownMessages.single.title, 'Pulse');
    },
  );

  test(
    'initial and opened-app messages are captured for future handling',
    () async {
      final _FakePulseMessagingService messagingService =
          _FakePulseMessagingService(
            initialMessage: const PulsePushMessage(
              messageId: 'initial',
              title: 'Welcome back',
            ),
          );
      final _FakeNotificationTapSource notificationTapSource =
          _FakeNotificationTapSource();
      final PulseMessagingController controller = PulseMessagingController(
        messagingService: messagingService,
        userMessagingRepository: _FakeUserMessagingRepository(),
        notificationPresenter: _FakeForegroundNotificationPresenter(),
        notificationTapSource: notificationTapSource,
      );
      addTearDown(() async {
        await controller.dispose();
        await messagingService.dispose();
        await notificationTapSource.dispose();
      });

      final Future<PulsePushMessage> openedMessageFuture =
          controller.openedMessages.first;

      await controller.initialize();

      expect(controller.lastOpenedMessage?.messageId, 'initial');
      expect((await openedMessageFuture).messageId, 'initial');

      messagingService.openedController.add(
        const PulsePushMessage(messageId: 'opened', title: 'Tapped'),
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.lastOpenedMessage?.messageId, 'opened');
    },
  );

  test(
    'local notification taps are merged into opened-app handling',
    () async {
      final _FakePulseMessagingService messagingService =
          _FakePulseMessagingService();
      final _FakeNotificationTapSource notificationTapSource =
          _FakeNotificationTapSource();
      final PulseMessagingController controller = PulseMessagingController(
        messagingService: messagingService,
        userMessagingRepository: _FakeUserMessagingRepository(),
        notificationPresenter: _FakeForegroundNotificationPresenter(),
        notificationTapSource: notificationTapSource,
      );
      addTearDown(() async {
        await controller.dispose();
        await messagingService.dispose();
        await notificationTapSource.dispose();
      });

      await controller.initialize();

      notificationTapSource.tapController.add(
        const PulsePushMessage(
          messageId: 'local-opened',
          data: <String, String>{'route': 'history'},
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(controller.lastOpenedMessage?.messageId, 'local-opened');
    },
  );
}

class _FakePulseMessagingService implements PulseMessagingService {
  _FakePulseMessagingService({this.currentToken, this.initialMessage});

  final StreamController<String> tokenRefreshController =
      StreamController<String>.broadcast();
  final StreamController<PulsePushMessage> foregroundController =
      StreamController<PulsePushMessage>.broadcast();
  final StreamController<PulsePushMessage> openedController =
      StreamController<PulsePushMessage>.broadcast();

  String? currentToken;
  PulsePushMessage? initialMessage;

  @override
  Future<PulsePushMessage?> getInitialMessage() async {
    return initialMessage;
  }

  @override
  Future<String?> getToken() async {
    return currentToken;
  }

  @override
  Future<void> initialize() async {}

  @override
  Stream<PulsePushMessage> get onForegroundMessage =>
      foregroundController.stream;

  @override
  Stream<PulsePushMessage> get onMessageOpenedApp => openedController.stream;

  @override
  Stream<String> get onTokenRefresh => tokenRefreshController.stream;

  @override
  Future<void> requestPermission() async {}

  Future<void> dispose() async {
    await tokenRefreshController.close();
    await foregroundController.close();
    await openedController.close();
  }
}

class _FakeUserMessagingRepository implements UserMessagingRepository {
  final List<({String uid, String token})> savedTokens =
      <({String uid, String token})>[];
  final List<({String uid, String token})> clearedTokens =
      <({String uid, String token})>[];

  @override
  Future<void> clearFcmToken({
    required String uid,
    required String token,
  }) async {
    clearedTokens.add((uid: uid, token: token));
  }

  @override
  Future<void> saveFcmToken({
    required String uid,
    required String token,
  }) async {
    savedTokens.add((uid: uid, token: token));
  }

  @override
  DocumentReference<Map<String, dynamic>> userDocument(String uid) {
    throw UnimplementedError();
  }
}

class _FakeForegroundNotificationPresenter
    implements PulseForegroundNotificationPresenter {
  final List<PulsePushMessage> shownMessages = <PulsePushMessage>[];

  @override
  Future<void> showForegroundPushMessage(PulsePushMessage message) async {
    shownMessages.add(message);
  }
}

class _FakeNotificationTapSource implements PulsePushNotificationTapSource {
  final StreamController<PulsePushMessage> tapController =
      StreamController<PulsePushMessage>.broadcast();

  @override
  Future<PulsePushMessage?> getInitialPushNotificationTap() async {
    return null;
  }

  @override
  Stream<PulsePushMessage> get onPushNotificationTap => tapController.stream;

  Future<void> dispose() async {
    await tapController.close();
  }
}
