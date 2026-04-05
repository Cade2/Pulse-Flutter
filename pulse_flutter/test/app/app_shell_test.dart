import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_flutter/app/app_shell.dart';
import 'package:pulse_flutter/app/router.dart';
import 'package:pulse_flutter/core/connectivity/pulse_connectivity_service.dart';
import 'package:pulse_flutter/core/providers/connectivity_providers.dart';

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
}
