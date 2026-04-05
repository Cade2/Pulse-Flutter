import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_flutter/app/pulse_notification_routing.dart';
import 'package:pulse_flutter/app/router.dart';
import 'package:pulse_flutter/core/notifications/pulse_push_message.dart';

void main() {
  test('defaults to home when the notification payload is minimal', () {
    const PulsePushMessage message = PulsePushMessage(
      title: 'Pulse',
      body: 'Check in when you can.',
    );

    expect(
      PulseNotificationRouting.locationForMessage(message),
      AppRoutes.homePath,
    );
  });

  test('routes history notifications into the matching session detail state', () {
    const PulsePushMessage message = PulsePushMessage(
      data: <String, String>{
        'route': 'history',
        'sessionId': '2026-04-05',
      },
    );

    expect(
      PulseNotificationRouting.locationForMessage(message),
      AppRoutes.historyLocation(sessionId: '2026-04-05'),
    );
  });

  test('supports alias routes for richer notification types', () {
    const PulsePushMessage message = PulsePushMessage(
      data: <String, String>{'kind': 'reminder'},
    );

    expect(
      PulseNotificationRouting.locationForMessage(message),
      AppRoutes.swipeSessionPath,
    );
  });
}
