import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_flutter/core/models/pulse_badge.dart';
import 'package:pulse_flutter/core/providers/badge_providers.dart';

class BadgesScreen extends ConsumerWidget {
  const BadgesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<PulseBadgeStatus>> badgesAsync = ref.watch(
      currentUserBadgeStatusesProvider,
    );
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Badges')),
      body: SafeArea(
        child: badgesAsync.when(
          data: (statuses) {
            final List<PulseBadgeStatus> unlocked = statuses
                .where((status) => status.isUnlocked)
                .toList(growable: false);
            final List<PulseBadgeStatus> locked = statuses
                .where((status) => !status.isUnlocked)
                .toList(growable: false);

            return Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _BadgeSummaryCard(
                        unlockedCount: unlocked.length,
                        totalCount: statuses.length,
                        lockedCount: locked.length,
                      ),
                      const SizedBox(height: 24),
                      Text('Unlocked badges', style: textTheme.titleLarge),
                      const SizedBox(height: 12),
                      if (unlocked.isEmpty)
                        _EmptyBadgeState(
                          message:
                              'Your first badge unlocks after your first completed Pulse session.',
                        )
                      else
                        ...unlocked.map((status) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _BadgeCard(status: status),
                          );
                        }),
                      const SizedBox(height: 24),
                      Text('Locked badges', style: textTheme.titleLarge),
                      const SizedBox(height: 12),
                      ...locked.map((status) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _BadgeCard(status: status),
                        );
                      }),
                    ],
                  ),
                ),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) {
            return Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Unable to load badges',
                        style: textTheme.headlineLarge,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Please try again in a moment.',
                        style: textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BadgeSummaryCard extends StatelessWidget {
  const _BadgeSummaryCard({
    required this.unlockedCount,
    required this.totalCount,
    required this.lockedCount,
  });

  final int unlockedCount;
  final int totalCount;
  final int lockedCount;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Pulse badges', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              '$unlockedCount of $totalCount unlocked',
              style: textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '$lockedCount more badges are waiting on the session, streak, growth, emotion, and context data you already build in Pulse.',
              style: textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBadgeState extends StatelessWidget {
  const _EmptyBadgeState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Text(
          message,
          style: Theme.of(context).textTheme.bodyMedium,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.status});

  final PulseBadgeStatus status;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;
    final Color accentColor = status.isUnlocked
        ? theme.colorScheme.primary
        : theme.colorScheme.outline;
    final Color categoryChipColor = status.isUnlocked
        ? theme.colorScheme.primary
        : theme.colorScheme.secondary;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Icon(status.definition.icon, color: accentColor),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _BadgeCategoryChip(
                    label: status.categoryLabel,
                    color: categoryChipColor,
                  ),
                  const SizedBox(height: 10),
                  Text(status.definition.title, style: textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    status.definition.description,
                    style: textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  if (!status.isUnlocked) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        minHeight: 8,
                        value: status.progressRatio,
                        backgroundColor: theme.colorScheme.surfaceContainer,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  Text(
                    status.progressText,
                    style: textTheme.bodySmall?.copyWith(color: accentColor),
                  ),
                  const SizedBox(height: 4),
                  Text(status.hintText, style: textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeCategoryChip extends StatelessWidget {
  const _BadgeCategoryChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: color),
        ),
      ),
    );
  }
}
