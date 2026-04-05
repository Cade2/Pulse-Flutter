import 'package:pulse_flutter/app/router.dart';
import 'package:pulse_flutter/core/notifications/pulse_push_message.dart';

abstract final class PulseNotificationRouting {
  static const Map<String, String> _routeAliases = <String, String>{
    'home': AppRoutes.homePath,
    '/home': AppRoutes.homePath,
    'history': AppRoutes.historyPath,
    '/history': AppRoutes.historyPath,
    'summary': AppRoutes.insightsPath,
    'insights': AppRoutes.insightsPath,
    'insight': AppRoutes.insightsPath,
    '/insights': AppRoutes.insightsPath,
    'weekly_summary': AppRoutes.insightsPath,
    'badges': AppRoutes.badgesPath,
    'badge': AppRoutes.badgesPath,
    'achievement': AppRoutes.badgesPath,
    '/badges': AppRoutes.badgesPath,
    'profile': AppRoutes.profilePath,
    '/profile': AppRoutes.profilePath,
    'session': AppRoutes.swipeSessionPath,
    '/session': AppRoutes.swipeSessionPath,
    'swipe': AppRoutes.swipeSessionPath,
    'checkin': AppRoutes.swipeSessionPath,
    'reminder': AppRoutes.swipeSessionPath,
  };

  static String locationForMessage(PulsePushMessage message) {
    final String? sessionId = _normalizedValue(
      message.data['sessionId'] ?? message.data['session_id'],
    );
    final String? routeKey = _normalizedValue(
      message.data['route'] ??
          message.data['screen'] ??
          message.data['destination'] ??
          message.data['target'] ??
          message.data['kind'] ??
          message.data['type'],
    );

    final String? resolvedRoute = routeKey == null
        ? null
        : _routeAliases[routeKey];

    if (sessionId != null && sessionId.isNotEmpty) {
      return AppRoutes.historyLocation(sessionId: sessionId);
    }

    return resolvedRoute ?? AppRoutes.homePath;
  }

  static String? _normalizedValue(String? value) {
    final String? trimmedValue = value?.trim();
    if (trimmedValue == null || trimmedValue.isEmpty) {
      return null;
    }

    return trimmedValue.toLowerCase();
  }
}
