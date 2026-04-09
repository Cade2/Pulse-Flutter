import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_flutter/core/connectivity/pulse_connectivity_service.dart';
import 'package:pulse_flutter/core/providers/connectivity_providers.dart';
import 'package:pulse_flutter/core/providers/swipe_session_providers.dart';
import 'package:pulse_flutter/features/swipe_session/models/pending_swipe_session.dart';

class PulseOfflineBanner extends ConsumerWidget {
  const PulseOfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<PulseConnectivityState> connectivityAsync = ref.watch(
      pulseConnectivityStateProvider,
    );
    final AsyncValue<List<PendingSwipeSession>> pendingSessionsAsync = ref
        .watch(pendingSwipeSessionsProvider);
    final PulseConnectivityState? state = connectivityAsync.asData?.value;
    final List<PendingSwipeSession> pendingSessions =
        pendingSessionsAsync.asData?.value ?? const <PendingSwipeSession>[];
    final bool isOffline = state?.isOffline ?? false;
    final int pendingCount = pendingSessions.length;
    final bool hasPendingSessions = pendingCount > 0;
    final bool hasFailedPendingSessions = pendingSessions.any(
      (session) => session.status == PendingSwipeSessionStatus.failed,
    );
    final bool isSyncingPendingSessions = pendingSessions.any(
      (session) => session.status == PendingSwipeSessionStatus.syncing,
    );

    if (!isOffline && !hasPendingSessions) {
      return const SizedBox.shrink();
    }

    final bool showOfflineBanner = isOffline;
    final Color backgroundColor = showOfflineBanner
        ? Theme.of(context).colorScheme.errorContainer
        : Theme.of(context).colorScheme.tertiaryContainer;
    final Color foregroundColor = showOfflineBanner
        ? Theme.of(context).colorScheme.onErrorContainer
        : Theme.of(context).colorScheme.onTertiaryContainer;
    final IconData icon = showOfflineBanner
        ? Icons.cloud_off_rounded
        : isSyncingPendingSessions
        ? Icons.sync_rounded
        : Icons.cloud_upload_rounded;

    final String message;
    if (showOfflineBanner && hasPendingSessions) {
      final String noun = pendingCount == 1 ? 'session is' : 'sessions are';
      message =
          'You\'re offline. $pendingCount Pulse $noun queued on this device and will sync when you reconnect.';
    } else if (showOfflineBanner) {
      message =
          'You\'re offline. Pulse will keep local progress on this device until you reconnect.';
    } else if (isSyncingPendingSessions) {
      message = pendingCount == 1
          ? 'Pulse is syncing 1 queued session back into your history.'
          : 'Pulse is syncing $pendingCount queued sessions back into your history.';
    } else if (hasFailedPendingSessions) {
      message = pendingCount == 1
          ? '1 queued Pulse session is still stored locally until sync can finish.'
          : '$pendingCount queued Pulse sessions are still stored locally until sync can finish.';
    } else {
      message = pendingCount == 1
          ? '1 queued Pulse session is ready to sync now that you\'re back online.'
          : '$pendingCount queued Pulse sessions are ready to sync now that you\'re back online.';
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: Container(
        key: Key(
          showOfflineBanner ? 'pulse-offline-banner' : 'pulse-sync-banner',
        ),
        width: double.infinity,
        color: backgroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: SafeArea(
          bottom: false,
          child: Row(
            children: [
              Icon(icon, color: foregroundColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: foregroundColor),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
