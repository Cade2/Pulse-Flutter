import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_flutter/app/app_shell.dart';
import 'package:pulse_flutter/app/router.dart';
import 'package:pulse_flutter/core/connectivity/pulse_connectivity_service.dart';
import 'package:pulse_flutter/core/providers/connectivity_providers.dart';
import 'package:pulse_flutter/core/providers/swipe_session_providers.dart';
import 'package:pulse_flutter/features/swipe_session/models/pending_swipe_session.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_record.dart';

void main() {
  testWidgets('shows the offline banner when connectivity is lost', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pulseConnectivityServiceProvider.overrideWithValue(
            const NoopPulseConnectivityService(
              state: PulseConnectivityState.offline(),
            ),
          ),
        ],
        child: const MaterialApp(
          home: AppShell(
            currentLocation: AppRoutes.homePath,
            child: SizedBox.expand(),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.byKey(const Key('pulse-offline-banner')), findsOneWidget);
    expect(find.textContaining('You\'re offline'), findsOneWidget);
  });

  testWidgets('shows queued session context while offline', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          pulseConnectivityServiceProvider.overrideWithValue(
            const NoopPulseConnectivityService(
              state: PulseConnectivityState.offline(),
            ),
          ),
          pendingSwipeSessionsProvider.overrideWith(
            (ref) => Stream.value(<PendingSwipeSession>[
              PendingSwipeSession(
                uid: 'test-user',
                session: SwipeSessionRecord(
                  sessionId: '2026-04-09',
                  date: '2026-04-09',
                  completedAt: DateTime(2026, 4, 9, 18),
                  responses: const [],
                  acceptedEmotions: const <String>[],
                ),
                status: PendingSwipeSessionStatus.pending,
                createdAt: DateTime(2026, 4, 9, 18),
                updatedAt: DateTime(2026, 4, 9, 18),
              ),
            ]),
          ),
        ],
        child: const MaterialApp(
          home: AppShell(
            currentLocation: AppRoutes.homePath,
            child: SizedBox.expand(),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.byKey(const Key('pulse-offline-banner')), findsOneWidget);
    expect(find.textContaining('queued on this device'), findsOneWidget);
  });
}
