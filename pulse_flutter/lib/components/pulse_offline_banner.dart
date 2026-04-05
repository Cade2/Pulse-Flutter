import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_flutter/core/connectivity/pulse_connectivity_service.dart';
import 'package:pulse_flutter/core/providers/connectivity_providers.dart';

class PulseOfflineBanner extends ConsumerWidget {
  const PulseOfflineBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<PulseConnectivityState> connectivityAsync = ref.watch(
      pulseConnectivityStateProvider,
    );
    final PulseConnectivityState? state = connectivityAsync.asData?.value;
    final bool isOffline = state?.isOffline ?? false;

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: !isOffline
          ? const SizedBox.shrink()
          : Container(
              key: const Key('pulse-offline-banner'),
              width: double.infinity,
              color: Theme.of(context).colorScheme.errorContainer,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    Icon(
                      Icons.cloud_off_rounded,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'You\'re offline. Pulse will keep local progress on this device until you reconnect.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .colorScheme
                              .onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
