import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pulse_flutter/core/connectivity/pulse_connectivity_service.dart';

void main() {
  test('connectivity state treats none-only results as offline', () {
    const PulseConnectivityState expected = PulseConnectivityState.offline();

    final PulseConnectivityState actual = PulseConnectivityState.fromResults(
      const <ConnectivityResult>[ConnectivityResult.none],
    );

    expect(actual, expected);
    expect(actual.isOffline, isTrue);
  });

  test('connectivity state treats active transports as online', () {
    final PulseConnectivityState actual = PulseConnectivityState.fromResults(
      const <ConnectivityResult>[
        ConnectivityResult.wifi,
        ConnectivityResult.wifi,
        ConnectivityResult.mobile,
      ],
    );

    expect(actual.isOnline, isTrue);
    expect(
      actual.results,
      containsAll(<ConnectivityResult>[
        ConnectivityResult.wifi,
        ConnectivityResult.mobile,
      ]),
    );
  });
}
