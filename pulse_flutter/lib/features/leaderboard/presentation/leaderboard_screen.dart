import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_flutter/components/pulse_avatar.dart';
import 'package:pulse_flutter/core/models/pulse_leaderboard.dart';
import 'package:pulse_flutter/core/providers/leaderboard_providers.dart';

class LeaderboardScreen extends ConsumerWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<PulseLeaderboardState?> leaderboardAsync = ref.watch(
      currentUserLeaderboardStateProvider,
    );
    final TextTheme textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Friends')),
      body: SafeArea(
        child: leaderboardAsync.when(
          data: (leaderboard) {
            if (leaderboard == null) {
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
                          'Friends unavailable',
                          style: textTheme.headlineLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Please try again after your Pulse profile loads.',
                          style: textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            return Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _LeaderboardSummaryCard(leaderboard: leaderboard),
                      const SizedBox(height: 24),
                      Text('Your row', style: textTheme.titleLarge),
                      const SizedBox(height: 12),
                      _LeaderboardRow(entry: leaderboard.currentUserEntry),
                      const SizedBox(height: 24),
                      Text('Friends leaderboard', style: textTheme.titleLarge),
                      const SizedBox(height: 12),
                      if (!leaderboard.hasFriends)
                        _LeaderboardEmptyState(
                          referralCode: leaderboard.referralCode,
                        )
                      else
                        ...leaderboard.friendEntries.map((entry) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _LeaderboardRow(entry: entry),
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
                        'Unable to load friends',
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

class _LeaderboardSummaryCard extends StatelessWidget {
  const _LeaderboardSummaryCard({required this.leaderboard});

  final PulseLeaderboardState leaderboard;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;
    final String referralLabel = leaderboard.referralCount == 1
        ? '1 friend join ready'
        : '${leaderboard.referralCount} friend joins ready';

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
            Text('Your Pulse circle', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              referralLabel,
              style: textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Referral code ${leaderboard.referralCode}',
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'This scaffold keeps your spot ready for future friends, rankings, and shared streak challenges.',
              style: textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardRow extends StatelessWidget {
  const _LeaderboardRow({required this.entry});

  final PulseLeaderboardEntry entry;

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
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 42,
              child: Text(
                '#${entry.rank}',
                style: textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 12),
            PulseAvatar(
              initial: entry.avatarInitial,
              avatarColour: entry.avatarColour,
              radius: 22,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(entry.name, style: textTheme.titleMedium),
                  if (entry.subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(entry.subtitle!, style: textTheme.bodySmall),
                  ],
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _LeaderboardStatChip(
                        label: '${entry.currentStreak} day streak',
                      ),
                      _LeaderboardStatChip(
                        label: 'Level ${entry.currentLevel}',
                      ),
                      _LeaderboardStatChip(
                        label: '${entry.referralCount} referrals',
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardEmptyState extends StatelessWidget {
  const _LeaderboardEmptyState({required this.referralCode});

  final String referralCode;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'No friends yet',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Invite friends with referral code $referralCode and their rows will appear here once Pulse friend joins are live.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _LeaderboardStatChip extends StatelessWidget {
  const _LeaderboardStatChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(label, style: Theme.of(context).textTheme.bodySmall),
      ),
    );
  }
}
