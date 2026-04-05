import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:pulse_flutter/core/connectivity/pulse_connectivity_service.dart';
import 'package:pulse_flutter/core/database/pulse_app_database.dart';
import 'package:pulse_flutter/core/firestore/swipe_session_repository.dart';
import 'package:pulse_flutter/features/swipe_session/models/pending_swipe_session.dart';

class PendingSessionSyncController {
  PendingSessionSyncController({
    required PulseAppDatabase database,
    required RemoteSwipeSessionRepository remoteRepository,
    required PulseConnectivityService connectivityService,
  }) : _database = database,
       _remoteRepository = remoteRepository,
       _connectivityService = connectivityService;

  final PulseAppDatabase _database;
  final RemoteSwipeSessionRepository _remoteRepository;
  final PulseConnectivityService _connectivityService;
  bool _isSyncing = false;

  Future<void> syncQueuedSessions(String uid) async {
    if (_isSyncing || uid.trim().isEmpty) {
      return;
    }

    _isSyncing = true;

    try {
      final List<PendingSession> rows = await _database.readPendingSessions(uid);
      for (final PendingSession row in rows) {
        final PendingSwipeSession pending = PendingSwipeSession.fromDatabaseRow(
          row,
        );

        await _database.updatePendingSessionStatus(
          uid: uid,
          sessionId: pending.session.sessionId,
          status: PendingSwipeSessionStatus.syncing.storageValue,
        );

        try {
          await _remoteRepository.saveRecord(uid: uid, record: pending.session);
          await _database.removePendingSession(
            uid: uid,
            sessionId: pending.session.sessionId,
          );
        } on FirebaseException catch (error) {
          if (_isOfflineFailure(error)) {
            await _database.updatePendingSessionStatus(
              uid: uid,
              sessionId: pending.session.sessionId,
              status: PendingSwipeSessionStatus.pending.storageValue,
              errorMessage: error.message,
            );
            break;
          }

          if (!(await _connectivityService.currentState()).isOnline) {
            await _database.updatePendingSessionStatus(
              uid: uid,
              sessionId: pending.session.sessionId,
              status: PendingSwipeSessionStatus.pending.storageValue,
              errorMessage: error.message ?? 'Waiting for a connection.',
            );
            break;
          }

          await _database.updatePendingSessionStatus(
            uid: uid,
            sessionId: pending.session.sessionId,
            status: PendingSwipeSessionStatus.failed.storageValue,
            errorMessage: error.message ?? 'Sync failed.',
          );
        } catch (_) {
          if (!(await _connectivityService.currentState()).isOnline) {
            await _database.updatePendingSessionStatus(
              uid: uid,
              sessionId: pending.session.sessionId,
              status: PendingSwipeSessionStatus.pending.storageValue,
              errorMessage: 'Waiting for a connection.',
            );
            break;
          }

          await _database.updatePendingSessionStatus(
            uid: uid,
            sessionId: pending.session.sessionId,
            status: PendingSwipeSessionStatus.failed.storageValue,
            errorMessage: 'Sync failed.',
          );
        }
      }
    } finally {
      _isSyncing = false;
    }
  }

  bool _isOfflineFailure(FirebaseException error) {
    return error.code == 'network-request-failed' ||
        error.code == 'unavailable';
  }
}
