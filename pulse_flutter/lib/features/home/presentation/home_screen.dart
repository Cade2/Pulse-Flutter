import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_flutter/app/router.dart';
import 'package:pulse_flutter/components/pulse_avatar.dart';
import 'package:pulse_flutter/core/models/pulse_level_progress.dart';
import 'package:pulse_flutter/core/models/pulse_streak_engagement.dart';
import 'package:pulse_flutter/core/models/user_profile.dart';
import 'package:pulse_flutter/core/providers/auth_providers.dart';
import 'package:pulse_flutter/core/providers/streak_engagement_providers.dart';
import 'package:pulse_flutter/core/providers/swipe_session_providers.dart';
import 'package:pulse_flutter/core/providers/user_profile_providers.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_record.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _isSigningOut = false;
  String? _errorMessage;

  Future<void> _handleSignOut() async {
    setState(() {
      _isSigningOut = true;
      _errorMessage = null;
    });

    try {
      await ref.read(firebaseAuthServiceProvider).signOut();

      if (!mounted) {
        return;
      }

      context.goNamed(AppRoutes.splashName);
    } on FirebaseAuthException catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.message ?? 'Unable to sign out right now.';
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'Unable to sign out right now.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isSigningOut = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final User? currentUser = ref.watch(currentUserProvider);
    final bool isAuthenticated = ref.watch(isAuthenticatedProvider);
    final AsyncValue<PulseUserProfile?> profileAsync = ref.watch(
      currentUserProfileProvider,
    );
    final PulseUserProfile? profile = profileAsync.asData?.value;
    final PulseLevelProgress levelProgress = ref.watch(
      currentUserLevelProgressProvider,
    );
    final int currentStreak = ref
        .watch(currentUserStreakProvider)
        .currentStreak;
    final PulseStreakEngagement streakEngagement = ref.watch(
      currentUserStreakEngagementProvider,
    );
    final AsyncValue<SwipeSessionRecord?> todaySessionAsync = ref.watch(
      todaySwipeSessionProvider,
    );
    final SwipeSessionRecord? todaySession = todaySessionAsync.asData?.value;
    final String? email = currentUser?.email?.trim().isNotEmpty == true
        ? currentUser!.email!.trim()
        : profile?.email.trim();
    final bool isCheckingToday =
        isAuthenticated &&
        todaySessionAsync.isLoading &&
        !todaySessionAsync.hasValue;
    final bool hasTodaySession = todaySession != null;
    final bool hasTodaySessionError =
        isAuthenticated &&
        todaySessionAsync.hasError &&
        !todaySessionAsync.hasValue;
    final bool canStartSession =
        isAuthenticated &&
        !isCheckingToday &&
        !hasTodaySession &&
        !hasTodaySessionError;
    final String greetingName =
        profile?.greetingName ??
        PulseUserProfile.friendlyNameFromEmail(email) ??
        'there';
    final String avatarInitial =
        profile?.avatarInitial ??
        (PulseUserProfile.friendlyNameFromEmail(
              email,
            )?.substring(0, 1).toUpperCase() ??
            'P');
    final String avatarColour =
        profile?.avatarColour ?? PulseUserProfile.defaultAvatarColour;

    final String authMessage;
    if (!isAuthenticated) {
      authMessage = 'No authenticated user is currently available.';
    } else if (email != null && email.isNotEmpty) {
      authMessage = email;
    } else {
      authMessage = 'You are signed in to Pulse.';
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Pulse')),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HomeHeader(
                    greetingName: greetingName,
                    subtitle: authMessage,
                    avatarInitial: avatarInitial,
                    avatarColour: avatarColour,
                    onProfilePressed: isAuthenticated
                        ? () => context.goNamed(AppRoutes.profileName)
                        : null,
                  ),
                  if (isAuthenticated) ...[
                    const SizedBox(height: 24),
                    _LevelProgressCard(levelProgress: levelProgress),
                    const SizedBox(height: 16),
                    _StreakSummaryCard(currentStreak: currentStreak),
                    if (streakEngagement.shouldSurface) ...[
                      const SizedBox(height: 16),
                      _StreakEngagementCard(engagement: streakEngagement),
                    ],
                    const SizedBox(height: 16),
                    _TodaySessionStatusCard(
                      todaySessionAsync: todaySessionAsync,
                    ),
                  ],
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          _errorMessage!,
                          style: textTheme.bodyMedium?.copyWith(
                            color: Theme.of(
                              context,
                            ).colorScheme.onErrorContainer,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                  FilledButton(
                    onPressed: canStartSession
                        ? () => context.goNamed(AppRoutes.swipeSessionName)
                        : null,
                    child: Text(
                      hasTodaySession
                          ? 'Today\'s session is complete'
                          : isCheckingToday
                          ? 'Checking today...'
                          : hasTodaySessionError
                          ? 'Session unavailable'
                          : 'Start swipe session',
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _isSigningOut || !isAuthenticated
                        ? null
                        : _handleSignOut,
                    child: _isSigningOut
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Sign out'),
                  ),
                  if (!isAuthenticated) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.goNamed(AppRoutes.loginName),
                      child: const Text('Back to login'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.greetingName,
    required this.subtitle,
    required this.avatarInitial,
    required this.avatarColour,
    required this.onProfilePressed,
  });

  final String greetingName;
  final String subtitle;
  final String avatarInitial;
  final String avatarColour;
  final VoidCallback? onProfilePressed;

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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PulseAvatar(
              initial: avatarInitial,
              avatarColour: avatarColour,
              radius: 28,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Home', style: textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text(
                    'Welcome back, $greetingName',
                    style: textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(subtitle, style: textTheme.bodyMedium),
                ],
              ),
            ),
            TextButton(onPressed: onProfilePressed, child: const Text('Edit')),
          ],
        ),
      ),
    );
  }
}

class _LevelProgressCard extends StatelessWidget {
  const _LevelProgressCard({required this.levelProgress});

  final PulseLevelProgress levelProgress;

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
            Text('Pulse progress', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              'Level ${levelProgress.currentLevel}',
              style: textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${levelProgress.totalXp} XP total',
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: levelProgress.progressToNextLevel,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${levelProgress.xpToNextLevel} XP to Level ${levelProgress.nextLevel}',
              style: textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakSummaryCard extends StatelessWidget {
  const _StreakSummaryCard({required this.currentStreak});

  final int currentStreak;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;
    final String dayLabel = currentStreak == 1 ? 'day' : 'days';

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
            Text('Current streak', style: textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('$currentStreak $dayLabel', style: textTheme.headlineMedium),
            const SizedBox(height: 8),
            Text(
              currentStreak > 0
                  ? 'Keep showing up each day to grow your Pulse streak.'
                  : 'Complete a daily session to start your Pulse streak.',
              style: textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _TodaySessionStatusCard extends StatelessWidget {
  const _TodaySessionStatusCard({required this.todaySessionAsync});

  final AsyncValue<SwipeSessionRecord?> todaySessionAsync;

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
        child: todaySessionAsync.when(
          data: (session) {
            if (session == null) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Ready for today', style: textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(
                    'Your next Pulse session is available whenever you are.',
                    style: textTheme.bodyMedium,
                  ),
                ],
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Done for today', style: textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  'Today\'s Pulse session is complete. Come back tomorrow for your next check-in.',
                  style: textTheme.bodyMedium,
                ),
                if (session.acceptedEmotions.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Accepted emotions', style: textTheme.titleMedium),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: session.acceptedEmotions
                        .map((emotion) {
                          return Chip(label: Text(emotion));
                        })
                        .toList(growable: false),
                  ),
                ],
              ],
            );
          },
          loading: () {
            return Row(
              children: [
                const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Checking today\'s session availability...',
                    style: textTheme.bodyMedium,
                  ),
                ),
              ],
            );
          },
          error: (error, stackTrace) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Unable to check today', style: textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  'Please try again in a moment before starting a new session.',
                  style: textTheme.bodyMedium,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _StreakEngagementCard extends StatelessWidget {
  const _StreakEngagementCard({required this.engagement});

  final PulseStreakEngagement engagement;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;
    final Color accentColor =
        engagement.kind == PulseStreakEngagementKind.milestoneNearby
        ? theme.colorScheme.primary
        : theme.colorScheme.tertiary;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: accentColor.withValues(alpha: 0.45)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Icon(
                      engagement.kind ==
                              PulseStreakEngagementKind.milestoneNearby
                          ? Icons.flag_rounded
                          : Icons.refresh_rounded,
                      color: accentColor,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(engagement.title, style: textTheme.titleLarge),
                      const SizedBox(height: 8),
                      Text(engagement.message, style: textTheme.bodyMedium),
                      if (engagement.supportingText.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(
                          engagement.supportingText,
                          style: textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
