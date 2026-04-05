import 'package:flutter/material.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_reward_details.dart';

Future<void> showSwipeCompletionCelebrations(
  BuildContext context,
  SwipeSessionRewardDetails reward,
) async {
  if (reward.didLevelUp) {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return LevelUpCelebrationDialog(reward: reward);
      },
    );
  }

  if (!context.mounted || !reward.hasNewBadgeUnlocks) {
    return;
  }

  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      return BadgeUnlockCelebrationDialog(reward: reward);
    },
  );
}

class LevelUpCelebrationDialog extends StatelessWidget {
  const LevelUpCelebrationDialog({super.key, required this.reward});

  final SwipeSessionRewardDetails reward;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;

    return _CelebrationDialogShell(
      key: const Key('level-up-celebration-dialog'),
      icon: Icons.arrow_circle_up_rounded,
      title: 'Level up!',
      action: FilledButton(
        key: const Key('level-up-celebration-continue'),
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('Keep going'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            reward.levelsGained == 1
                ? 'You reached Level ${reward.levelProgress.currentLevel}.'
                : 'You climbed ${reward.levelsGained} levels to Level ${reward.levelProgress.currentLevel}.',
            style: textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Total XP: ${reward.levelProgress.totalXp}',
            style: textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class BadgeUnlockCelebrationDialog extends StatelessWidget {
  const BadgeUnlockCelebrationDialog({super.key, required this.reward});

  final SwipeSessionRewardDetails reward;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final String title = reward.newlyUnlockedBadges.length == 1
        ? 'Badge unlocked!'
        : 'Badges unlocked!';

    return _CelebrationDialogShell(
      key: const Key('badge-unlock-celebration-dialog'),
      icon: Icons.workspace_premium_rounded,
      title: title,
      action: FilledButton(
        key: const Key('badge-unlock-celebration-continue'),
        onPressed: () => Navigator.of(context).pop(),
        child: const Text('See results'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            reward.newlyUnlockedBadges.length == 1
                ? 'A new Pulse badge is ready.'
                : '${reward.newlyUnlockedBadges.length} new Pulse badges are ready.',
            style: textTheme.titleMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ...reward.newlyUnlockedBadges.map((badge) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        badge.icon,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(badge.title, style: textTheme.titleMedium),
                            const SizedBox(height: 4),
                            Text(
                              badge.description,
                              style: textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CelebrationDialogShell extends StatelessWidget {
  const _CelebrationDialogShell({
    super.key,
    required this.icon,
    required this.title,
    required this.child,
    required this.action,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Widget action;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      backgroundColor: theme.colorScheme.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(icon, size: 42, color: theme.colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                title,
                style: textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              child,
              const SizedBox(height: 20),
              action,
            ],
          ),
        ),
      ),
    );
  }
}
