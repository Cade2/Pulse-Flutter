import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class PulseConnectivityState {
  const PulseConnectivityState._(this.results);

  const PulseConnectivityState.online()
    : results = const <ConnectivityResult>[ConnectivityResult.wifi];

  const PulseConnectivityState.offline()
    : results = const <ConnectivityResult>[ConnectivityResult.none];

  factory PulseConnectivityState.fromResults(
    Iterable<ConnectivityResult> values,
  ) {
    final List<ConnectivityResult> normalized = values
        .toSet()
        .toList(growable: false);

    if (normalized.isEmpty ||
        normalized.every((value) => value == ConnectivityResult.none)) {
      return const PulseConnectivityState.offline();
    }

    return PulseConnectivityState._(normalized);
  }

  final List<ConnectivityResult> results;

  bool get isOffline {
    return results.isEmpty ||
        results.every((value) => value == ConnectivityResult.none);
  }

  bool get isOnline => !isOffline;

  String get description {
    return isOffline ? 'Offline' : 'Back online';
  }

  @override
  bool operator ==(Object other) {
    return other is PulseConnectivityState &&
        listEquals(other.results, results);
  }

  @override
  int get hashCode => Object.hashAll(results);
}

abstract class PulseConnectivityService {
  Future<PulseConnectivityState> currentState();

  Stream<PulseConnectivityState> watchConnectivity();
}

class NoopPulseConnectivityService implements PulseConnectivityService {
  const NoopPulseConnectivityService({
    this.state = const PulseConnectivityState.online(),
  });

  final PulseConnectivityState state;

  @override
  Future<PulseConnectivityState> currentState() async => state;

  @override
  Stream<PulseConnectivityState> watchConnectivity() {
    return Stream<PulseConnectivityState>.value(state);
  }
}

class PulseConnectivityPlusService implements PulseConnectivityService {
  PulseConnectivityPlusService({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<PulseConnectivityState> currentState() async {
    final Object results = await _connectivity.checkConnectivity();
    return PulseConnectivityState.fromResults(_readResults(results));
  }

  @override
  Stream<PulseConnectivityState> watchConnectivity() {
    return _connectivity.onConnectivityChanged
        .map<PulseConnectivityState>(
          (event) => PulseConnectivityState.fromResults(_readResults(event)),
        )
        .distinct();
  }

  Iterable<ConnectivityResult> _readResults(Object value) {
    if (value is ConnectivityResult) {
      return <ConnectivityResult>[value];
    }

    if (value is Iterable) {
      return value.whereType<ConnectivityResult>();
    }

    return const <ConnectivityResult>[ConnectivityResult.none];
  }
}
