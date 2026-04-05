import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_flutter/core/connectivity/pulse_connectivity_service.dart';

final pulseConnectivityServiceProvider = Provider<PulseConnectivityService>((
  ref,
) {
  return const NoopPulseConnectivityService();
});

final pulseConnectivityStateProvider =
    StreamProvider<PulseConnectivityState>((ref) async* {
      final PulseConnectivityService connectivityService = ref.watch(
        pulseConnectivityServiceProvider,
      );

      yield await connectivityService.currentState();
      yield* connectivityService.watchConnectivity();
    });

final isOfflineProvider = Provider<bool>((ref) {
  return ref.watch(pulseConnectivityStateProvider).maybeWhen(
    data: (PulseConnectivityState state) => state.isOffline,
    orElse: () => false,
  );
});
