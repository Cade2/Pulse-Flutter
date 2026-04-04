import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_flutter/app/router.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_record.dart';

class SwipeCompletionScreen extends StatelessWidget {
  const SwipeCompletionScreen({super.key, this.session});

  final SwipeSessionRecord? session;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final int acceptedCount = session?.acceptedCount ?? 0;
    final int rejectedCount = session?.rejectedCount ?? 0;
    final int totalCards = session?.totalCards ?? 0;
    final String contextSummary = _buildContextSummary();

    return Scaffold(
      appBar: AppBar(title: const Text('Pulse session')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: SingleChildScrollView(
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
                    session == null
                        ? 'Your swipe session has ended.'
                        : 'Session ${session!.sessionId} was saved to your history.',
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
                            'Cards reviewed: $totalCards',
                            style: textTheme.titleMedium,
                          ),
                          const SizedBox(height: 12),
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
                  if (session != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Accepted emotions: ${session!.acceptedEmotions.join(', ')}',
                      style: textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      contextSummary,
                      style: textTheme.bodyMedium,
                      textAlign: TextAlign.center,
                    ),
                  ],
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

  String _buildContextSummary() {
    if (session == null) {
      return 'No context tags were saved.';
    }

    final List<String> parts = <String>[
      if (session!.contextSocial != null) 'Social: ${session!.contextSocial}',
      if (session!.contextEnergy != null) 'Energy: ${session!.contextEnergy}',
      if (session!.contextSleep != null) 'Sleep: ${session!.contextSleep}',
    ];

    if (parts.isEmpty) {
      return 'No context tags were selected for this session.';
    }

    return parts.join(' | ');
  }
}
