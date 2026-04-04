import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_flutter/app/app.dart';
import 'package:pulse_flutter/app/router.dart';
import 'package:pulse_flutter/core/firestore/swipe_session_repository.dart';
import 'package:pulse_flutter/core/models/pulse_insights.dart';
import 'package:pulse_flutter/core/models/pulse_level_progress.dart';
import 'package:pulse_flutter/core/models/pulse_streak.dart';
import 'package:pulse_flutter/core/models/user_profile.dart';
import 'package:pulse_flutter/core/providers/auth_providers.dart';
import 'package:pulse_flutter/core/providers/swipe_session_providers.dart';
import 'package:pulse_flutter/core/providers/user_profile_providers.dart';
import 'package:pulse_flutter/features/swipe_session/models/emotion_card.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_record.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_save_result.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_summary.dart';

void main() {
  testWidgets('signed-out users can reach login but not remain on home', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => null),
          isAuthenticatedProvider.overrideWith((ref) => false),
        ],
        child: const PulseApp(),
      ),
    );

    expect(find.text('Splash'), findsOneWidget);
    expect(find.text('Start onboarding'), findsOneWidget);

    await tester.tap(find.text('Start onboarding'));
    await tester.pumpAndSettle();
    expect(find.text('Onboarding'), findsOneWidget);

    await tester.tap(find.text('Continue to login'));
    await tester.pumpAndSettle();

    expect(find.text('Login'), findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(_bottomNavFinder, findsNothing);

    final BuildContext context = tester.element(find.text('Login'));
    GoRouter.of(context).go(AppRoutes.homePath);
    await tester.pumpAndSettle();

    expect(find.text('Splash'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
  });

  testWidgets('signed-in users are routed to home', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => null),
          isAuthenticatedProvider.overrideWith((ref) => true),
          currentUserProfileProvider.overrideWith(
            (ref) => Stream.value(
              _buildProfile(
                displayName: 'Maya',
                email: 'maya@example.com',
                avatarColour: '#10B981',
              ),
            ),
          ),
          currentUserStreakProvider.overrideWith((ref) => const PulseStreak()),
          currentUserLevelProgressProvider.overrideWith(
            (ref) => const PulseLevelProgress(),
          ),
        ],
        child: const PulseApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(_bottomNavFinder, findsOneWidget);
    expect(_selectedBottomNavIndex(tester), 0);
    expect(find.text('Splash'), findsNothing);
    expect(find.text('Welcome back, Maya'), findsOneWidget);
    expect(find.text('maya@example.com'), findsOneWidget);
    expect(find.text('Pulse progress'), findsOneWidget);
    expect(find.text('Current streak'), findsOneWidget);
    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('0 XP total'), findsOneWidget);
    expect(find.text('0 days'), findsOneWidget);
  });

  testWidgets('profile screen is reachable from home', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => null),
          currentUserIdProvider.overrideWith((ref) => 'test-user'),
          isAuthenticatedProvider.overrideWith((ref) => true),
          currentUserProfileProvider.overrideWith(
            (ref) => Stream.value(
              _buildProfile(
                displayName: 'Ava',
                email: 'ava@example.com',
                avatarColour: '#EC4899',
              ),
            ),
          ),
          currentUserStreakProvider.overrideWith((ref) => const PulseStreak()),
          currentUserLevelProgressProvider.overrideWith(
            (ref) => const PulseLevelProgress(),
          ),
        ],
        child: const PulseApp(),
      ),
    );

    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Profile'));
    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();

    expect(_selectedBottomNavIndex(tester), 4);
    expect(find.text('Profile'), findsWidgets);
    expect(find.text('ava@example.com'), findsOneWidget);
    expect(find.text('Save profile'), findsOneWidget);
    expect(find.text('Ava'), findsWidgets);
  });

  testWidgets('badge screen is reachable from profile and shows progress', (
    WidgetTester tester,
  ) async {
    final _FakeSwipeSessionRepository fakeRepository =
        _FakeSwipeSessionRepository(
          sessions: [
            _buildSessionRecord(
              date: '2026-04-04',
              acceptedEmotions: const ['Calm'],
            ),
          ],
        );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => null),
          currentUserIdProvider.overrideWith((ref) => 'test-user'),
          isAuthenticatedProvider.overrideWith((ref) => true),
          currentUserProfileProvider.overrideWith(
            (ref) => Stream.value(
              _buildProfile(
                displayName: 'Ava',
                email: 'ava@example.com',
                avatarColour: '#EC4899',
              ),
            ),
          ),
          currentUserStreakProvider.overrideWith(
            (ref) => const PulseStreak(
              currentStreak: 0,
              longestStreak: 3,
              lastSessionDate: '2026-04-02',
            ),
          ),
          currentUserLevelProgressProvider.overrideWith(
            (ref) => const PulseLevelProgress(totalXp: 50, currentLevel: 1),
          ),
          swipeSessionRepositoryProvider.overrideWith((ref) => fakeRepository),
        ],
        child: const PulseApp(),
      ),
    );

    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Profile'));
    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('View badges'));
    await tester.tap(find.text('View badges'));
    await tester.pumpAndSettle();

    expect(_selectedBottomNavIndex(tester), 3);
    expect(find.text('Badges'), findsWidgets);
    expect(find.text('Unlocked badges'), findsOneWidget);
    expect(find.text('Locked badges'), findsOneWidget);
    expect(find.text('First Pulse'), findsOneWidget);
    expect(find.text('On A Roll'), findsOneWidget);
    expect(find.text('Level Up'), findsOneWidget);
    expect(find.text('Seven Check-Ins'), findsOneWidget);
    expect(find.text('1 / 7 sessions'), findsOneWidget);
    expect(find.text('Level 1 / 2'), findsOneWidget);
    expect(find.text('Unlocked'), findsNWidgets(2));
  });

  testWidgets('insights screen shows locked progress before five sessions', (
    WidgetTester tester,
  ) async {
    final _FakeSwipeSessionRepository fakeRepository =
        _FakeSwipeSessionRepository(
          sessions: [
            _buildSessionRecord(
              date: '2026-04-01',
              acceptedEmotions: const ['Calm'],
            ),
            _buildSessionRecord(
              date: '2026-04-02',
              acceptedEmotions: const ['Calm', 'Joy'],
            ),
            _buildSessionRecord(
              date: '2026-04-03',
              acceptedEmotions: const ['Hope'],
            ),
          ],
        );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => null),
          currentUserIdProvider.overrideWith((ref) => 'test-user'),
          isAuthenticatedProvider.overrideWith((ref) => true),
          currentUserProfileProvider.overrideWith(
            (ref) => Stream.value(
              _buildProfile(
                displayName: 'Ava',
                email: 'ava@example.com',
                avatarColour: '#EC4899',
              ),
            ),
          ),
          currentUserStreakProvider.overrideWith((ref) => const PulseStreak()),
          currentUserLevelProgressProvider.overrideWith(
            (ref) => const PulseLevelProgress(),
          ),
          swipeSessionRepositoryProvider.overrideWith((ref) => fakeRepository),
        ],
        child: const PulseApp(),
      ),
    );

    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Insights'));
    await tester.tap(find.text('Insights').last);
    await tester.pumpAndSettle();

    expect(_selectedBottomNavIndex(tester), 2);
    expect(find.text('Insights are locked'), findsOneWidget);
    expect(find.text('3 / 5 sessions'), findsOneWidget);
    expect(
      find.text('Save 2 more sessions to unlock your first Pulse insights.'),
      findsOneWidget,
    );
  });

  testWidgets('insights screen shows expanded patterns from saved history', (
    WidgetTester tester,
  ) async {
    final List<SwipeSessionRecord> sessions = <SwipeSessionRecord>[
      for (int index = 1; index <= 9; index++)
        _buildSessionRecord(
          date: '2026-04-${index.toString().padLeft(2, '0')}',
          acceptedEmotions: const ['Calm', 'Joy'],
          contextSocial: 'Friends',
          contextEnergy: 'Steady',
          contextSleep: 'Good',
        ),
      for (int index = 10; index <= 14; index++)
        _buildSessionRecord(
          date: '2026-04-${index.toString().padLeft(2, '0')}',
          acceptedEmotions: const ['Calm'],
          contextSocial: 'Solo',
          contextEnergy: 'High',
          contextSleep: 'Late',
        ),
    ];
    final _FakeSwipeSessionRepository fakeRepository =
        _FakeSwipeSessionRepository(sessions: sessions);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => null),
          currentUserIdProvider.overrideWith((ref) => 'test-user'),
          isAuthenticatedProvider.overrideWith((ref) => true),
          currentUserProfileProvider.overrideWith(
            (ref) => Stream.value(
              _buildProfile(
                displayName: 'Ava',
                email: 'ava@example.com',
                avatarColour: '#EC4899',
              ),
            ),
          ),
          currentUserStreakProvider.overrideWith(
            (ref) => const PulseStreak(
              currentStreak: 5,
              longestStreak: 9,
              lastSessionDate: '2026-04-14',
            ),
          ),
          currentUserLevelProgressProvider.overrideWith(
            (ref) => const PulseLevelProgress(totalXp: 200, currentLevel: 3),
          ),
          swipeSessionRepositoryProvider.overrideWith((ref) => fakeRepository),
        ],
        child: const PulseApp(),
      ),
    );

    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Insights'));
    await tester.tap(find.text('Insights').last);
    await tester.pumpAndSettle();

    expect(_selectedBottomNavIndex(tester), 2);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Top accepted emotions'), findsOneWidget);
    expect(find.text('Most common context tags'), findsOneWidget);
    expect(find.text('Pattern signals'), findsOneWidget);
    expect(find.text('14 sessions saved'), findsOneWidget);
    expect(find.text('Calm'), findsWidgets);
    expect(find.text('Social: Friends'), findsOneWidget);
    expect(find.text('Most common social context'), findsOneWidget);
    expect(find.text('Friends'), findsOneWidget);
    expect(find.text('Steady'), findsOneWidget);
    expect(find.text('Good'), findsOneWidget);
    expect(
      find.text(
        _formatInsightAverage(
          23 / PulseInsightsReport.expandedUnlockSessionCount,
        ),
      ),
      findsOneWidget,
    );
  });

  testWidgets('home shows done-for-today state when today already exists', (
    WidgetTester tester,
  ) async {
    final _FakeSwipeSessionRepository fakeRepository =
        _FakeSwipeSessionRepository(
          sessions: [
            _buildSessionRecord(
              date: '2026-04-04',
              acceptedEmotions: const ['Calm', 'Joy'],
              contextEnergy: 'Steady',
            ),
          ],
        );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => null),
          currentUserIdProvider.overrideWith((ref) => 'test-user'),
          isAuthenticatedProvider.overrideWith((ref) => true),
          currentUserProfileProvider.overrideWith(
            (ref) => Stream.value(
              _buildProfile(
                displayName: 'Caleb',
                email: 'caleb@example.com',
                avatarColour: '#2ED3E6',
              ),
            ),
          ),
          currentUserStreakProvider.overrideWith(
            (ref) => const PulseStreak(
              currentStreak: 4,
              longestStreak: 6,
              lastSessionDate: '2026-04-04',
            ),
          ),
          currentUserLevelProgressProvider.overrideWith(
            (ref) => const PulseLevelProgress(totalXp: 135, currentLevel: 2),
          ),
          currentSessionDateProvider.overrideWith(
            (ref) => DateTime(2026, 4, 4),
          ),
          swipeSessionRepositoryProvider.overrideWith((ref) => fakeRepository),
        ],
        child: const PulseApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(_selectedBottomNavIndex(tester), 0);
    expect(find.text('Done for today'), findsOneWidget);
    expect(find.text('Today\'s session is complete'), findsOneWidget);
    expect(find.text('Level 2'), findsOneWidget);
    expect(find.text('135 XP total'), findsOneWidget);
    expect(find.text('4 days'), findsOneWidget);
    expect(find.text('Accepted emotions'), findsOneWidget);
    expect(find.text('Calm'), findsOneWidget);
    expect(find.text('Joy'), findsOneWidget);
  });

  testWidgets('users cannot open another session after finishing today', (
    WidgetTester tester,
  ) async {
    final _FakeSwipeSessionRepository fakeRepository =
        _FakeSwipeSessionRepository(
          sessions: [
            _buildSessionRecord(
              date: '2026-04-04',
              acceptedEmotions: const ['Focus', 'Hope'],
            ),
          ],
        );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => null),
          currentUserIdProvider.overrideWith((ref) => 'test-user'),
          isAuthenticatedProvider.overrideWith((ref) => true),
          currentUserProfileProvider.overrideWith(
            (ref) => Stream.value(
              _buildProfile(
                displayName: 'Caleb',
                email: 'caleb@example.com',
                avatarColour: '#2ED3E6',
              ),
            ),
          ),
          currentUserStreakProvider.overrideWith(
            (ref) => const PulseStreak(
              currentStreak: 2,
              longestStreak: 3,
              lastSessionDate: '2026-04-04',
            ),
          ),
          currentUserLevelProgressProvider.overrideWith(
            (ref) => const PulseLevelProgress(totalXp: 90, currentLevel: 1),
          ),
          currentSessionDateProvider.overrideWith(
            (ref) => DateTime(2026, 4, 4),
          ),
          swipeSessionRepositoryProvider.overrideWith((ref) => fakeRepository),
        ],
        child: const PulseApp(),
      ),
    );

    await tester.pumpAndSettle();

    final BuildContext context = tester.element(find.text('Done for today'));
    GoRouter.of(context).go(AppRoutes.swipeSessionPath);
    await tester.pumpAndSettle();

    expect(_selectedBottomNavIndex(tester), 0);
    expect(find.text('Done for today'), findsOneWidget);
    expect(find.text('Card 1 of 8'), findsNothing);
  });

  testWidgets('swiping right accepts and swiping left rejects a card', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => null),
          isAuthenticatedProvider.overrideWith((ref) => true),
          currentUserProfileProvider.overrideWith(
            (ref) => Stream.value(
              _buildProfile(
                displayName: 'Maya',
                email: 'maya@example.com',
                avatarColour: '#10B981',
              ),
            ),
          ),
          currentUserStreakProvider.overrideWith((ref) => const PulseStreak()),
          currentUserLevelProgressProvider.overrideWith(
            (ref) => const PulseLevelProgress(),
          ),
        ],
        child: const PulseApp(),
      ),
    );

    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Start swipe session'));
    await tester.tap(find.text('Start swipe session'));
    await tester.pumpAndSettle();

    expect(_bottomNavFinder, findsNothing);
    final Finder swipeCard = find.byKey(const Key('swipe-session-card'));
    await tester.ensureVisible(swipeCard);

    await tester.drag(swipeCard, const Offset(400, 0));
    await tester.pumpAndSettle();

    expect(find.text('Card 2 of 8'), findsOneWidget);
    expect(find.text('Accepted 1 | Rejected 0'), findsOneWidget);

    await tester.drag(swipeCard, const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(find.text('Card 3 of 8'), findsOneWidget);
    expect(find.text('Accepted 1 | Rejected 1'), findsOneWidget);
  });

  testWidgets('signed-in users can save an eight-card swipe session', (
    WidgetTester tester,
  ) async {
    final _FakeSwipeSessionRepository fakeRepository =
        _FakeSwipeSessionRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => null),
          currentUserIdProvider.overrideWith((ref) => 'test-user'),
          isAuthenticatedProvider.overrideWith((ref) => true),
          currentUserProfileProvider.overrideWith(
            (ref) => Stream.value(
              _buildProfile(
                displayName: 'Maya',
                email: 'maya@example.com',
                avatarColour: '#10B981',
              ),
            ),
          ),
          currentUserStreakProvider.overrideWith((ref) => const PulseStreak()),
          currentUserLevelProgressProvider.overrideWith(
            (ref) => const PulseLevelProgress(),
          ),
          swipeSessionRepositoryProvider.overrideWith((ref) => fakeRepository),
        ],
        child: const PulseApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Start swipe session'), findsOneWidget);

    await tester.ensureVisible(find.text('Start swipe session'));
    await tester.tap(find.text('Start swipe session'));
    await tester.pumpAndSettle();

    expect(_bottomNavFinder, findsNothing);
    expect(find.text('Card 1 of 8'), findsOneWidget);
    expect(find.text('Accept'), findsOneWidget);
    expect(find.text('Reject'), findsOneWidget);

    for (var i = 0; i < 8; i++) {
      final Finder actionButton = find.text(i.isEven ? 'Accept' : 'Reject');
      await tester.ensureVisible(actionButton);
      await tester.tap(actionButton);
      await tester.pumpAndSettle();
    }

    expect(find.text('Add optional context'), findsOneWidget);
    expect(find.text('Social context'), findsOneWidget);
    expect(find.text('Energy'), findsOneWidget);
    expect(find.text('Sleep'), findsOneWidget);

    await tester.tap(find.text('Friends'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Steady'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Good'));
    await tester.tap(find.text('Good'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Save session'));
    await tester.tap(find.text('Save session'));
    await tester.pumpAndSettle();

    expect(_bottomNavFinder, findsNothing);
    expect(find.text('Session complete'), findsOneWidget);
    expect(find.text('Cards reviewed: 8'), findsOneWidget);
    expect(find.text('Accepted: 4'), findsOneWidget);
    expect(find.text('Rejected: 4'), findsOneWidget);
    expect(find.text('XP earned: +65 XP'), findsOneWidget);
    expect(find.text('65 XP total'), findsOneWidget);
    expect(find.textContaining('saved to your history'), findsOneWidget);
    expect(find.textContaining('Social: Friends'), findsOneWidget);
    expect(fakeRepository.lastUid, 'test-user');
    expect(fakeRepository.lastSavedSession, isNotNull);
    expect(fakeRepository.lastSavedSession!.contextEnergy, 'Steady');
    expect(fakeRepository.lastSavedSession!.contextSleep, 'Good');
    expect(fakeRepository.lastSaveResult?.xpEarned, 65);
  });

  testWidgets('history shows saved sessions in reverse chronological order', (
    WidgetTester tester,
  ) async {
    final _FakeSwipeSessionRepository fakeRepository =
        _FakeSwipeSessionRepository(
          sessions: [
            _buildSessionRecord(
              date: '2026-04-02',
              acceptedEmotions: const ['Calm', 'Joy'],
              contextSocial: 'Friends',
            ),
            _buildSessionRecord(
              date: '2026-04-04',
              acceptedEmotions: const ['Focus', 'Hope', 'Confidence'],
              contextEnergy: 'High',
              contextSleep: 'Good',
            ),
          ],
        );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => null),
          currentUserIdProvider.overrideWith((ref) => 'test-user'),
          isAuthenticatedProvider.overrideWith((ref) => true),
          currentUserProfileProvider.overrideWith(
            (ref) => Stream.value(
              _buildProfile(
                displayName: 'Maya',
                email: 'maya@example.com',
                avatarColour: '#10B981',
              ),
            ),
          ),
          currentUserStreakProvider.overrideWith(
            (ref) => const PulseStreak(
              currentStreak: 3,
              longestStreak: 5,
              lastSessionDate: '2026-04-04',
            ),
          ),
          currentUserLevelProgressProvider.overrideWith(
            (ref) => const PulseLevelProgress(totalXp: 180, currentLevel: 2),
          ),
          swipeSessionRepositoryProvider.overrideWith((ref) => fakeRepository),
        ],
        child: const PulseApp(),
      ),
    );

    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('History'));
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    expect(_selectedBottomNavIndex(tester), 1);
    expect(find.text('2026-04-04'), findsOneWidget);
    expect(find.text('2026-04-02'), findsOneWidget);
    expect(find.text('Accepted 3 of 8 emotions'), findsOneWidget);
    expect(find.textContaining('Energy: High | Sleep: Good'), findsOneWidget);

    final Finder latest = find.text('2026-04-04');
    final Finder older = find.text('2026-04-02');
    expect(tester.getTopLeft(latest).dy, lessThan(tester.getTopLeft(older).dy));
  });

  testWidgets('history item opens a session detail view', (
    WidgetTester tester,
  ) async {
    final _FakeSwipeSessionRepository fakeRepository =
        _FakeSwipeSessionRepository(
          sessions: [
            _buildSessionRecord(
              date: '2026-04-04',
              acceptedEmotions: const ['Focus', 'Hope', 'Confidence'],
              contextSocial: 'Friends',
              contextEnergy: 'High',
              contextSleep: 'Good',
            ),
          ],
        );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => null),
          currentUserIdProvider.overrideWith((ref) => 'test-user'),
          isAuthenticatedProvider.overrideWith((ref) => true),
          currentUserProfileProvider.overrideWith(
            (ref) => Stream.value(
              _buildProfile(
                displayName: 'Maya',
                email: 'maya@example.com',
                avatarColour: '#10B981',
              ),
            ),
          ),
          currentUserStreakProvider.overrideWith(
            (ref) => const PulseStreak(
              currentStreak: 3,
              longestStreak: 5,
              lastSessionDate: '2026-04-04',
            ),
          ),
          currentUserLevelProgressProvider.overrideWith(
            (ref) => const PulseLevelProgress(totalXp: 180, currentLevel: 2),
          ),
          swipeSessionRepositoryProvider.overrideWith((ref) => fakeRepository),
        ],
        child: const PulseApp(),
      ),
    );

    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('History'));
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    expect(_selectedBottomNavIndex(tester), 1);
    await tester.tap(find.text('2026-04-04'));
    await tester.pumpAndSettle();

    expect(find.text('Session details'), findsOneWidget);
    expect(find.text('Accepted'), findsOneWidget);
    expect(find.text('Rejected'), findsOneWidget);
    expect(find.text('Accepted emotions'), findsOneWidget);
    expect(find.text('Focus'), findsOneWidget);
    expect(find.text('Hope'), findsOneWidget);
    expect(find.text('Confidence'), findsOneWidget);
    expect(find.text('Social: Friends'), findsOneWidget);
    expect(find.text('Energy: High'), findsOneWidget);
    expect(find.text('Sleep: Good'), findsOneWidget);
  });

  testWidgets('history shows an empty state when no sessions exist', (
    WidgetTester tester,
  ) async {
    final _FakeSwipeSessionRepository fakeRepository =
        _FakeSwipeSessionRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => null),
          currentUserIdProvider.overrideWith((ref) => 'test-user'),
          isAuthenticatedProvider.overrideWith((ref) => true),
          currentUserProfileProvider.overrideWith(
            (ref) => Stream.value(
              _buildProfile(
                displayName: 'Maya',
                email: 'maya@example.com',
                avatarColour: '#10B981',
              ),
            ),
          ),
          currentUserStreakProvider.overrideWith((ref) => const PulseStreak()),
          currentUserLevelProgressProvider.overrideWith(
            (ref) => const PulseLevelProgress(),
          ),
          swipeSessionRepositoryProvider.overrideWith((ref) => fakeRepository),
        ],
        child: const PulseApp(),
      ),
    );

    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('History'));
    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();

    expect(_selectedBottomNavIndex(tester), 1);
    expect(find.text('No sessions yet'), findsOneWidget);
    expect(
      find.textContaining('Complete your first swipe session'),
      findsOneWidget,
    );
  });

  testWidgets('bottom navigation stays in sync across main screens', (
    WidgetTester tester,
  ) async {
    final _FakeSwipeSessionRepository fakeRepository =
        _FakeSwipeSessionRepository(
          sessions: [
            _buildSessionRecord(
              date: '2026-04-04',
              acceptedEmotions: const ['Calm', 'Joy'],
            ),
          ],
        );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => null),
          currentUserIdProvider.overrideWith((ref) => 'test-user'),
          isAuthenticatedProvider.overrideWith((ref) => true),
          currentUserProfileProvider.overrideWith(
            (ref) => Stream.value(
              _buildProfile(
                displayName: 'Maya',
                email: 'maya@example.com',
                avatarColour: '#10B981',
              ),
            ),
          ),
          currentUserStreakProvider.overrideWith(
            (ref) => const PulseStreak(
              currentStreak: 2,
              longestStreak: 3,
              lastSessionDate: '2026-04-04',
            ),
          ),
          currentUserLevelProgressProvider.overrideWith(
            (ref) => const PulseLevelProgress(totalXp: 90, currentLevel: 1),
          ),
          swipeSessionRepositoryProvider.overrideWith((ref) => fakeRepository),
        ],
        child: const PulseApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(_selectedBottomNavIndex(tester), 0);

    await tester.tap(find.text('History'));
    await tester.pumpAndSettle();
    expect(_selectedBottomNavIndex(tester), 1);

    await tester.tap(find.text('Insights'));
    await tester.pumpAndSettle();
    expect(_selectedBottomNavIndex(tester), 2);

    await tester.tap(find.text('Badges'));
    await tester.pumpAndSettle();
    expect(_selectedBottomNavIndex(tester), 3);

    await tester.tap(find.text('Profile'));
    await tester.pumpAndSettle();
    expect(_selectedBottomNavIndex(tester), 4);
  });
}

PulseUserProfile _buildProfile({
  required String email,
  String? displayName,
  String avatarColour = PulseUserProfile.defaultAvatarColour,
}) {
  return PulseUserProfile(
    uid: 'test-user',
    email: email,
    displayName: displayName,
    avatarColour: avatarColour,
  );
}

SwipeSessionRecord _buildSessionRecord({
  required String date,
  required List<String> acceptedEmotions,
  String? contextSocial,
  String? contextEnergy,
  String? contextSleep,
}) {
  return SwipeSessionRecord.fromSummary(
    summary: SwipeSessionSummary(
      responses: List<EmotionCardResponse>.generate(8, (index) {
        final bool accepted = index < acceptedEmotions.length;
        final String title = accepted
            ? acceptedEmotions[index]
            : 'Emotion $index';

        return EmotionCardResponse(
          card: EmotionCard(
            id: 'emotion-$index',
            title: title,
            headline: title,
            description: '',
            reflectionPrompt: '',
            accentColor: const Color(0xFF2ED3E6),
          ),
          decision: accepted
              ? EmotionCardDecision.accept
              : EmotionCardDecision.reject,
        );
      }),
    ),
    contextSocial: contextSocial,
    contextEnergy: contextEnergy,
    contextSleep: contextSleep,
    completedAt: DateTime.parse('$date 12:00:00'),
  );
}

class _FakeSwipeSessionRepository implements SwipeSessionRepository {
  _FakeSwipeSessionRepository({
    List<SwipeSessionRecord> sessions = const <SwipeSessionRecord>[],
  }) : _sessions = List<SwipeSessionRecord>.from(sessions);

  final List<SwipeSessionRecord> _sessions;
  String? lastUid;
  SwipeSessionRecord? lastSavedSession;
  SwipeSessionSaveResult? lastSaveResult;
  PulseLevelProgress _currentLevelProgress = const PulseLevelProgress();

  @override
  Future<SwipeSessionSaveResult> saveSession({
    required String uid,
    required SwipeSessionSummary summary,
    String? contextSocial,
    String? contextEnergy,
    String? contextSleep,
  }) async {
    lastUid = uid;
    lastSavedSession = SwipeSessionRecord.fromSummary(
      summary: summary,
      contextSocial: contextSocial,
      contextEnergy: contextEnergy,
      contextSleep: contextSleep,
      completedAt: DateTime(2026, 4, 4, 12),
    );
    _sessions.removeWhere(
      (session) => session.sessionId == lastSavedSession!.sessionId,
    );
    _sessions.add(lastSavedSession!);
    final int xpEarned = PulseLevelProgress.sessionXp(
      contextSocial: contextSocial,
      contextEnergy: contextEnergy,
      contextSleep: contextSleep,
    );
    _currentLevelProgress = _currentLevelProgress.addXp(xpEarned);
    lastSaveResult = SwipeSessionSaveResult(
      session: lastSavedSession!,
      xpEarned: xpEarned,
      levelProgress: _currentLevelProgress,
    );
    return lastSaveResult!;
  }

  @override
  Stream<SwipeSessionRecord?> watchSession({
    required String uid,
    required String sessionId,
  }) {
    SwipeSessionRecord? matchingSession;

    for (final SwipeSessionRecord session in _sessions) {
      if (session.sessionId == sessionId) {
        matchingSession = session;
        break;
      }
    }

    return Stream<SwipeSessionRecord?>.value(matchingSession);
  }

  @override
  Stream<List<SwipeSessionRecord>> watchSessions({required String uid}) {
    final List<SwipeSessionRecord> sorted = List<SwipeSessionRecord>.from(
      _sessions,
    )..sort((a, b) => b.completedAt.compareTo(a.completedAt));

    return Stream<List<SwipeSessionRecord>>.value(sorted);
  }
}

String _formatInsightAverage(double value) {
  final bool isWholeNumber = value == value.roundToDouble();
  return isWholeNumber ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
}

final Finder _bottomNavFinder = find.byKey(const Key('pulse-bottom-nav'));

int _selectedBottomNavIndex(WidgetTester tester) {
  return tester.widget<NavigationBar>(_bottomNavFinder).selectedIndex;
}
