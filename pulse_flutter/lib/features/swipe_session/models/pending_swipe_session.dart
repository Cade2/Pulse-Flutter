import 'dart:convert';

import 'package:pulse_flutter/core/database/pulse_app_database.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_record.dart';

enum PendingSwipeSessionStatus {
  pending,
  syncing,
  failed;

  String get storageValue => name;

  static PendingSwipeSessionStatus fromStorageValue(Object? value) {
    final String normalized = value is String ? value.trim().toLowerCase() : '';

    switch (normalized) {
      case 'syncing':
        return PendingSwipeSessionStatus.syncing;
      case 'failed':
        return PendingSwipeSessionStatus.failed;
      case 'pending':
      default:
        return PendingSwipeSessionStatus.pending;
    }
  }
}

class PendingSwipeSession {
  const PendingSwipeSession({
    required this.uid,
    required this.session,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.errorMessage,
  });

  factory PendingSwipeSession.fromDatabaseRow(PendingSession row) {
    final Object? decoded = jsonDecode(row.payloadJson);
    final Map<String, dynamic> payload = decoded is Map<String, dynamic>
        ? decoded
        : <String, dynamic>{};

    return PendingSwipeSession(
      uid: row.uid,
      session: SwipeSessionRecord.fromLocalJson(payload),
      status: PendingSwipeSessionStatus.fromStorageValue(row.status),
      errorMessage: row.errorMessage,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }

  final String uid;
  final SwipeSessionRecord session;
  final PendingSwipeSessionStatus status;
  final String? errorMessage;
  final DateTime createdAt;
  final DateTime updatedAt;

  String get payloadJson => jsonEncode(session.toLocalJson());
}
