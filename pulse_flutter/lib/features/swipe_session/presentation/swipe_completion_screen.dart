import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_flutter/app/router.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_summary.dart';

class SwipeCompletionScreen extends StatelessWidget {
  const SwipeCompletionScreen({super.key, this.summary});

  final SwipeSessionSummary? summary;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final int acceptedCount = summary?.acceptedCount ?? 0;
    final int rejectedCount = summary?.rejectedCount ?? 0;
    final int totalCards = summary?.totalCards ?? 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Pulse session')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Session complete',
                    style: textTheme.headlineLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    totalCards == 0
                        ? 'Your swipe session has ended.'
                        : 'You reviewed $totalCards emotion cards in this session.',
                    style: textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            'Accepted: $acceptedCount',
                            style: textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Rejected: $rejectedCount',
                            style: textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: () => context.goNamed(AppRoutes.homeName),
                    child: const Text('Return home'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () =>
                        context.goNamed(AppRoutes.swipeSessionName),
                    child: const Text('Start another session'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
