import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_flutter/app/router.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_reward_details.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_save_result.dart';
import 'package:pulse_flutter/features/swipe_session/presentation/swipe_completion_celebrations.dart';

class SwipeCompletionScreen extends StatefulWidget {
  const SwipeCompletionScreen({super.key, this.result});

  final SwipeSessionSaveResult? result;

  @override
  State<SwipeCompletionScreen> createState() => _SwipeCompletionScreenState();
}

class _SwipeCompletionScreenState extends State<SwipeCompletionScreen> {
  bool _hasShownCelebrations = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showCelebrationsIfNeeded();
    });
  }

  Future<void> _showCelebrationsIfNeeded() async {
    if (_hasShownCelebrations || !mounted) {
      return;
    }

    _hasShownCelebrations = true;
    final SwipeSessionRewardDetails? reward = widget.result?.reward;
    if (reward == null) {
      return;
    }

    await showSwipeCompletionCelebrations(context, reward);
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.result?.session;
    final SwipeSessionRewardDetails? reward = widget.result?.reward;
    final TextTheme textTheme = Theme.of(context).textTheme;
    final int acceptedCount = session?.acceptedCount ?? 0;
    final int rejectedCount = session?.rejectedCount ?? 0;
    final int totalCards = session?.totalCards ?? 0;
    final int xpEarned = reward?.xpEarned ?? 0;
    final int currentLevel = reward?.levelProgress.currentLevel ?? 1;
    final int totalXp = reward?.levelProgress.totalXp ?? 0;
    final String contextSummary = _buildContextSummary();
    final bool isPendingSync = widget.result?.isPendingSync ?? false;

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
                        : isPendingSync
                        ? 'Session ${session.sessionId} was saved on this device and will sync when you reconnect.'
                        : 'Session ${session.sessionId} was saved to your history.',
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
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Session reward', style: textTheme.titleLarge),
                          const SizedBox(height: 12),
                          _RewardRow(
                            label: 'Session XP',
                            value: '+$xpEarned XP',
                          ),
                          const SizedBox(height: 12),
                          _RewardRow(label: 'Total XP', value: '$totalXp XP'),
                          const SizedBox(height: 12),
                          _RewardRow(
                            label: 'Current level',
                            value: 'Level $currentLevel',
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (reward?.didLevelUp ?? false) ...[
                    const SizedBox(height: 24),
                    _CompletionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Level up', style: textTheme.titleLarge),
                          const SizedBox(height: 12),
                          Text(
                            reward!.levelsGained == 1
                                ? 'You reached Level ${reward.levelProgress.currentLevel}.'
                                : 'You climbed ${reward.levelsGained} levels to Level ${reward.levelProgress.currentLevel}.',
                            style: textTheme.bodyLarge,
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (reward?.hasNewBadgeUnlocks ?? false) ...[
                    const SizedBox(height: 24),
                    _CompletionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('New badges', style: textTheme.titleLarge),
                          const SizedBox(height: 16),
                          ...reward!.newlyUnlockedBadges.map((badge) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _BadgeUnlockTile(
                                title: badge.title,
                                description: badge.description,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ],
                  if (reward?.streakMilestoneMessage != null) ...[
                    const SizedBox(height: 24),
                    _CompletionCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text('Streak milestone', style: textTheme.titleLarge),
                          const SizedBox(height: 12),
                          Text(
                            reward!.streakMilestoneMessage!,
                            style: textTheme.bodyLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Current streak: ${reward.currentStreak.currentStreak} ${reward.currentStreak.currentStreak == 1 ? 'day' : 'days'}',
                            style: textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  _CompletionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Session summary', style: textTheme.titleLarge),
                        const SizedBox(height: 12),
                        _RewardRow(
                          label: 'Cards reviewed',
                          value: '$totalCards',
                        ),
                        const SizedBox(height: 12),
                        _RewardRow(label: 'Accepted', value: '$acceptedCount'),
                        const SizedBox(height: 12),
                        _RewardRow(label: 'Rejected', value: '$rejectedCount'),
                      ],
                    ),
                  ),
                  if (session != null) ...[
                    const SizedBox(height: 24),
                    Text(
                      'Accepted emotions: ${session.acceptedEmotions.join(', ')}',
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
                    onPressed: () => context.goNamed(AppRoutes.historyName),
                    child: const Text('View history'),
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
    final session = widget.result?.session;
    if (session == null) {
      return 'No context tags were saved.';
    }

    final List<String> parts = <String>[
      if (session.contextSocial != null) 'Social: ${session.contextSocial}',
      if (session.contextEnergy != null) 'Energy: ${session.contextEnergy}',
      if (session.contextSleep != null) 'Sleep: ${session.contextSleep}',
    ];

    if (parts.isEmpty) {
      return 'No context tags were selected for this session.';
    }

    return parts.join(' | ');
  }
}

class _CompletionCard extends StatelessWidget {
  const _CompletionCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(padding: const EdgeInsets.all(20), child: child),
    );
  }
}

class _RewardRow extends StatelessWidget {
  const _RewardRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(child: Text(label, style: textTheme.bodyLarge)),
        Text(value, style: textTheme.titleMedium),
      ],
    );
  }
}

class _BadgeUnlockTile extends StatelessWidget {
  const _BadgeUnlockTile({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(description, style: textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
