import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_flutter/app/app.dart';
import 'package:pulse_flutter/app/router.dart';
import 'package:pulse_flutter/core/firebase/firebase_auth_service.dart';
import 'package:pulse_flutter/core/firebase/social_auth_clients.dart';
import 'package:pulse_flutter/core/firestore/pulse_account_repository.dart';
import 'package:pulse_flutter/core/firestore/swipe_session_repository.dart';
import 'package:pulse_flutter/core/firestore/user_profile_repository.dart';
import 'package:pulse_flutter/core/models/pulse_badge.dart';
import 'package:pulse_flutter/core/models/pulse_insights.dart';
import 'package:pulse_flutter/core/models/pulse_level_progress.dart';
import 'package:pulse_flutter/core/models/pulse_profile_settings.dart';
import 'package:pulse_flutter/core/models/pulse_referral.dart';
import 'package:pulse_flutter/core/models/pulse_session_history_entry.dart';
import 'package:pulse_flutter/core/models/pulse_streak.dart';
import 'package:pulse_flutter/core/models/user_profile.dart';
import 'package:pulse_flutter/core/notifications/pulse_firebase_messaging_service.dart';
import 'package:pulse_flutter/core/notifications/pulse_local_notification_service.dart';
import 'package:pulse_flutter/core/notifications/pulse_push_message.dart';
import 'package:pulse_flutter/core/providers/auth_providers.dart';
import 'package:pulse_flutter/core/providers/account_providers.dart';
import 'package:pulse_flutter/core/providers/messaging_providers.dart';
import 'package:pulse_flutter/core/providers/swipe_session_providers.dart';
import 'package:pulse_flutter/core/providers/user_profile_providers.dart';
import 'package:pulse_flutter/features/swipe_session/models/emotion_card.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_record.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_reward_details.dart';
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
    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);
    expect(_bottomNavFinder, findsNothing);

    final BuildContext context = tester.element(find.text('Login'));
    GoRouter.of(context).go(AppRoutes.homePath);
    await tester.pumpAndSettle();

    expect(find.text('Splash'), findsOneWidget);
    expect(find.text('Home'), findsNothing);
  });

  testWidgets(
    'login screen shows social sign-in actions and handles unavailable providers gracefully',
    (WidgetTester tester) async {
      final StreamController<PulseUserProfile?> profileController =
          StreamController<PulseUserProfile?>.broadcast();
      addTearDown(profileController.close);
      final _FakeFirebaseAuthService
      fakeAuthService = _FakeFirebaseAuthService()
        ..googleSignInException = PulseSocialAuthException.unavailable('Google')
        ..appleSignInException = PulseSocialAuthException.unavailable('Apple');
      final _FakeUserProfileRepository fakeUserProfileRepository =
          _FakeUserProfileRepository(
            initialProfile: _buildProfile(email: 'tester@example.com'),
            profileController: profileController,
          );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentUserProvider.overrideWith((ref) => null),
            currentUserIdProvider.overrideWith((ref) => null),
            isAuthenticatedProvider.overrideWith((ref) => false),
            firebaseAuthServiceProvider.overrideWithValue(fakeAuthService),
            userProfileRepositoryProvider.overrideWithValue(
              fakeUserProfileRepository,
            ),
          ],
          child: const PulseApp(),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Start onboarding'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue to login'));
      await tester.pumpAndSettle();

      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Continue with Apple'), findsOneWidget);

      final Finder googleButton = find.widgetWithText(
        OutlinedButton,
        'Continue with Google',
      );
      final Finder appleButton = find.widgetWithText(
        OutlinedButton,
        'Continue with Apple',
      );

      await tester.ensureVisible(googleButton);
      await tester.tap(googleButton);
      await tester.pumpAndSettle();

      expect(fakeAuthService.googleSignInCalled, isTrue);
      expect(
        find.text('Google sign-in is not available on this device yet.'),
        findsOneWidget,
      );

      await tester.ensureVisible(appleButton);
      await tester.tap(appleButton);
      await tester.pumpAndSettle();

      expect(fakeAuthService.appleSignInCalled, isTrue);
      expect(
        find.text('Apple sign-in is not available on this device yet.'),
        findsOneWidget,
      );
    },
  );

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

  testWidgets(
    'launching from a notification routes into the targeted history detail',
    (WidgetTester tester) async {
      final _FakeWidgetMessagingService messagingService =
          _FakeWidgetMessagingService(
            initialMessage: const PulsePushMessage(
              messageId: 'history-launch',
              data: <String, String>{
                'route': 'history',
                'sessionId': '2026-04-04',
              },
            ),
          );
      final _FakeWidgetNotificationTapSource notificationTapSource =
          _FakeWidgetNotificationTapSource();
      addTearDown(() async {
        await messagingService.dispose();
        await notificationTapSource.dispose();
      });
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
            swipeSessionRepositoryProvider.overrideWith(
              (ref) => fakeRepository,
            ),
            pulseMessagingServiceProvider.overrideWithValue(messagingService),
            pulsePushNotificationTapSourceProvider.overrideWithValue(
              notificationTapSource,
            ),
          ],
          child: const PulseApp(),
        ),
      );

      await tester.pumpAndSettle();

      expect(_selectedBottomNavIndex(tester), 1);
      expect(find.text('History'), findsWidgets);
      expect(find.text('Session details'), findsOneWidget);
      expect(find.text('2026-04-04'), findsWidgets);
      expect(find.text('Focus'), findsOneWidget);
      expect(find.text('Energy: High'), findsOneWidget);
    },
  );

  testWidgets('opened-app notification taps route to the intended screen', (
    WidgetTester tester,
  ) async {
    final _FakeWidgetMessagingService messagingService =
        _FakeWidgetMessagingService();
    final _FakeWidgetNotificationTapSource notificationTapSource =
        _FakeWidgetNotificationTapSource();
    final _FakeSwipeSessionRepository fakeRepository =
        _FakeSwipeSessionRepository();
    addTearDown(() async {
      await messagingService.dispose();
      await notificationTapSource.dispose();
    });

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
          pulseMessagingServiceProvider.overrideWithValue(messagingService),
          pulsePushNotificationTapSourceProvider.overrideWithValue(
            notificationTapSource,
          ),
        ],
        child: const PulseApp(),
      ),
    );

    await tester.pumpAndSettle();
    expect(_selectedBottomNavIndex(tester), 0);

    messagingService.openedController.add(
      const PulsePushMessage(
        messageId: 'opened-insights',
        data: <String, String>{'route': 'insights'},
      ),
    );
    await tester.pumpAndSettle();

    expect(_selectedBottomNavIndex(tester), 2);
    expect(find.text('Insights'), findsWidgets);
  });

  testWidgets(
    'foreground notification taps route through the local notification bridge',
    (WidgetTester tester) async {
      final _FakeWidgetMessagingService messagingService =
          _FakeWidgetMessagingService();
      final _FakeWidgetNotificationTapSource notificationTapSource =
          _FakeWidgetNotificationTapSource();
      addTearDown(() async {
        await messagingService.dispose();
        await notificationTapSource.dispose();
      });

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
              (ref) => const PulseStreak(),
            ),
            currentUserLevelProgressProvider.overrideWith(
              (ref) => const PulseLevelProgress(),
            ),
            pulseMessagingServiceProvider.overrideWithValue(messagingService),
            pulsePushNotificationTapSourceProvider.overrideWithValue(
              notificationTapSource,
            ),
          ],
          child: const PulseApp(),
        ),
      );

      await tester.pumpAndSettle();

      notificationTapSource.tapController.add(
        const PulsePushMessage(
          messageId: 'local-profile',
          data: <String, String>{'route': 'profile'},
        ),
      );
      await tester.pumpAndSettle();

      expect(_selectedBottomNavIndex(tester), 4);
      expect(find.text('Profile'), findsWidgets);
      expect(find.text('Profile basics'), findsOneWidget);
    },
  );

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
    expect(find.text('Profile basics'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Reminder time'), findsOneWidget);
    expect(find.text('Daily reminders'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Referral code'), findsOneWidget);
    expect(find.text('Copy code'), findsOneWidget);
    expect(find.text('Share invite'), findsOneWidget);
    expect(find.text('View friends'), findsOneWidget);
    expect(find.text('Save changes'), findsOneWidget);
    expect(find.text('Ava'), findsWidgets);
  });

  testWidgets('profile referral section shows code and opens invite share', (
    WidgetTester tester,
  ) async {
    final String referralCode = PulseReferral.generateReferralCode('test-user');

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
                referralCode: referralCode,
                referralCount: 2,
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

    expect(find.text('Referral code'), findsOneWidget);
    expect(find.text(referralCode), findsOneWidget);
    expect(find.text('2 referrals so far'), findsOneWidget);
    expect(
      find.byKey(const Key('profile-copy-referral-button')),
      findsOneWidget,
    );

    await tester.ensureVisible(
      find.byKey(const Key('profile-share-referral-button')),
    );
    await tester.tap(find.byKey(const Key('profile-share-referral-button')));
    await tester.pumpAndSettle();

    expect(find.text('Share your referral'), findsOneWidget);
    expect(find.text('Copy invite text'), findsOneWidget);
    expect(find.textContaining('Referral code: $referralCode'), findsOneWidget);
  });

  testWidgets(
    'friends leaderboard screen is reachable from profile and shows empty state',
    (WidgetTester tester) async {
      final String referralCode = PulseReferral.generateReferralCode(
        'test-user',
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
                  referralCode: referralCode,
                  referralCount: 0,
                ),
              ),
            ),
            currentUserStreakProvider.overrideWith(
              (ref) => const PulseStreak(
                currentStreak: 4,
                longestStreak: 7,
                lastSessionDate: '2026-04-05',
              ),
            ),
            currentUserLevelProgressProvider.overrideWith(
              (ref) => const PulseLevelProgress(totalXp: 180, currentLevel: 2),
            ),
          ],
          child: const PulseApp(),
        ),
      );

      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Profile'));
      await tester.tap(find.text('Profile').last);
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const Key('profile-view-friends-button')),
      );
      await tester.tap(find.byKey(const Key('profile-view-friends-button')));
      await tester.pumpAndSettle();

      expect(_selectedBottomNavIndex(tester), 4);
      expect(find.text('Friends'), findsWidgets);
      expect(find.text('Your Pulse circle'), findsOneWidget);
      expect(find.textContaining(referralCode), findsWidgets);
      expect(find.text('Your row'), findsOneWidget);
      expect(find.text('No friends yet'), findsOneWidget);
      expect(find.text('Ava'), findsOneWidget);
      expect(find.text('4 day streak'), findsOneWidget);
      expect(find.text('Level 2'), findsOneWidget);
    },
  );

  testWidgets('profile settings save and reload correctly', (
    WidgetTester tester,
  ) async {
    final StreamController<PulseUserProfile?> profileController =
        StreamController<PulseUserProfile?>.broadcast();
    addTearDown(profileController.close);

    final PulseUserProfile initialProfile = _buildProfile(
      displayName: 'Ava',
      email: 'ava@example.com',
      avatarColour: '#EC4899',
    );
    final _FakeUserProfileRepository fakeRepository =
        _FakeUserProfileRepository(
          initialProfile: initialProfile,
          profileController: profileController,
        );
    Stream<PulseUserProfile?> profileStream() async* {
      yield initialProfile;
      yield* profileController.stream;
    }

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentUserProvider.overrideWith((ref) => null),
          currentUserIdProvider.overrideWith((ref) => 'test-user'),
          isAuthenticatedProvider.overrideWith((ref) => true),
          currentUserProfileProvider.overrideWith((ref) => profileStream()),
          userProfileRepositoryProvider.overrideWith((ref) => fakeRepository),
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

    expect(find.text('8:00 PM'), findsOneWidget);
    expect(find.text('Dark'), findsWidgets);

    await tester.ensureVisible(find.text('Weekly summary'));
    await tester.tap(find.text('Weekly summary'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Light').last);
    await tester.tap(find.text('Light').last);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'Ava Stone');
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Save changes'));
    await tester.tap(find.text('Save changes'));
    await tester.pumpAndSettle();

    expect(fakeRepository.lastUpdatedUid, 'test-user');
    expect(fakeRepository.lastDisplayName, 'Ava Stone');
    expect(fakeRepository.lastAvatarColour, '#EC4899');
    expect(fakeRepository.lastSettings, isNotNull);
    expect(fakeRepository.lastSettings!.preferredReminderTime, '20:00');
    expect(fakeRepository.lastSettings!.dailyRemindersEnabled, isTrue);
    expect(fakeRepository.lastSettings!.streakRemindersEnabled, isTrue);
    expect(fakeRepository.lastSettings!.weeklySummaryEnabled, isTrue);
    expect(
      fakeRepository.lastSettings!.appearanceMode,
      PulseAppearanceMode.light,
    );
    expect(find.text('Profile settings updated.'), findsOneWidget);
    expect(find.text('Ava Stone'), findsWidgets);
  });

  testWidgets('profile export opens a JSON data sheet', (
    WidgetTester tester,
  ) async {
    final _FakeSwipeSessionRepository fakeRepository =
        _FakeSwipeSessionRepository(
          sessions: [
            _buildSessionRecord(
              date: '2026-04-21',
              acceptedEmotions: const ['Calm', 'Joy'],
              contextSocial: 'Friends',
              contextEnergy: 'Steady',
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

    await tester.ensureVisible(find.text('Profile'));
    await tester.tap(find.text('Profile').last);
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Export my data'));
    await tester.tap(find.text('Export my data'));
    await tester.pumpAndSettle();

    expect(find.text('Export your data'), findsOneWidget);
    expect(find.text('Copy JSON'), findsOneWidget);
    expect(find.textContaining('"profile"'), findsOneWidget);
    expect(find.textContaining('"settings"'), findsOneWidget);
    expect(find.textContaining('"sessions"'), findsOneWidget);
    expect(find.textContaining('"uid": "test-user"'), findsOneWidget);
    expect(find.textContaining('"sessionId": "2026-04-21"'), findsOneWidget);
  });

  testWidgets(
    'delete account requires DELETE and removes Pulse data before sign out',
    (WidgetTester tester) async {
      final _FakePulseAccountRepository fakeAccountRepository =
          _FakePulseAccountRepository();
      final _FakeFirebaseAuthService fakeAuthService =
          _FakeFirebaseAuthService();

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
              (ref) => const PulseStreak(),
            ),
            currentUserLevelProgressProvider.overrideWith(
              (ref) => const PulseLevelProgress(),
            ),
            pulseAccountRepositoryProvider.overrideWithValue(
              fakeAccountRepository,
            ),
            firebaseAuthServiceProvider.overrideWithValue(fakeAuthService),
          ],
          child: const PulseApp(),
        ),
      );

      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Profile'));
      await tester.tap(find.text('Profile').last);
      await tester.pumpAndSettle();

      await tester.ensureVisible(
        find.byKey(const Key('profile-delete-account-button')),
      );
      await tester.tap(find.byKey(const Key('profile-delete-account-button')));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('delete-account-confirm-button')),
            )
            .onPressed,
        isNull,
      );

      await tester.enterText(
        find.byKey(const Key('delete-account-confirmation-input')),
        'DELETE',
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const Key('delete-account-confirm-button')),
            )
            .onPressed,
        isNotNull,
      );

      await tester.tap(find.byKey(const Key('delete-account-confirm-button')));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(fakeAccountRepository.deletedUid, 'test-user');
      expect(fakeAuthService.signOutCalled, isTrue);
    },
  );

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
    expect(find.text('Fortnight Reflections'), findsOneWidget);
    expect(find.text('Emotion Cartographer'), findsOneWidget);
    expect(find.text('Context Curious'), findsOneWidget);
    expect(find.text('1 / 7 sessions'), findsOneWidget);
    expect(find.text('Level 1 / 2'), findsOneWidget);
    expect(find.text('0 / 5 sessions with context'), findsOneWidget);
    expect(find.text('1 / 7 unique emotions'), findsOneWidget);
    expect(find.text('Add context tags in 5 more sessions.'), findsOneWidget);
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
          currentSessionDateProvider.overrideWith(
            (ref) => DateTime(2026, 4, 4),
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
    expect(find.text('Current streak'), findsOneWidget);
    expect(find.text('Weekly Pulse Score'), findsOneWidget);
    expect(find.text('3 / 7 days checked in this week'), findsOneWidget);
    expect(find.text('86'), findsOneWidget);
    expect(find.text('Insights are locked'), findsOneWidget);
    expect(find.text('3 / 5 sessions'), findsOneWidget);
    expect(
      find.text('Save 2 more sessions to unlock your first Pulse insights.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'insights screen shows richer basic insights after five sessions',
    (WidgetTester tester) async {
      final _FakeSwipeSessionRepository fakeRepository =
          _FakeSwipeSessionRepository(
            sessions: [
              _buildSessionRecord(
                date: '2026-04-01',
                acceptedEmotions: const ['Calm', 'Joy'],
                contextSocial: 'Friends',
                contextEnergy: 'Steady',
              ),
              _buildSessionRecord(
                date: '2026-04-03',
                acceptedEmotions: const ['Calm'],
                contextSocial: 'Friends',
                contextSleep: 'Good',
              ),
              _buildSessionRecord(
                date: '2026-04-08',
                acceptedEmotions: const ['Focus'],
                contextEnergy: 'High',
              ),
              _buildSessionRecord(
                date: '2026-04-10',
                acceptedEmotions: const ['Calm', 'Hope'],
                contextSocial: 'Friends',
                contextSleep: 'Good',
              ),
              _buildSessionRecord(
                date: '2026-04-15',
                acceptedEmotions: const ['Joy'],
                contextSocial: 'Friends',
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
                  displayName: 'Ava',
                  email: 'ava@example.com',
                  avatarColour: '#EC4899',
                ),
              ),
            ),
            currentUserStreakProvider.overrideWith(
              (ref) => const PulseStreak(),
            ),
            currentUserLevelProgressProvider.overrideWith(
              (ref) => const PulseLevelProgress(),
            ),
            currentSessionDateProvider.overrideWith(
              (ref) => DateTime(2026, 4, 15),
            ),
            swipeSessionRepositoryProvider.overrideWith(
              (ref) => fakeRepository,
            ),
          ],
          child: const PulseApp(),
        ),
      );

      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Insights'));
      await tester.tap(find.text('Insights').last);
      await tester.pumpAndSettle();

      expect(_selectedBottomNavIndex(tester), 2);
      expect(find.text('Current streak'), findsOneWidget);
      expect(find.text('Weekly Pulse Score'), findsOneWidget);
      expect(find.text('1 / 7 days checked in this week'), findsOneWidget);
      expect(find.text('92'), findsOneWidget);
      expect(find.text('+13 vs last week'), findsOneWidget);
      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Most common mood'), findsOneWidget);
      expect(find.text('Context breakdown'), findsOneWidget);
      expect(find.text('Emotion mix'), findsOneWidget);
      expect(find.text('5 / 5 sessions with context'), findsOneWidget);
      expect(find.text('Top accepted emotions'), findsOneWidget);
      expect(find.text('Most common context tags'), findsOneWidget);
      expect(find.text('Most active weekday'), findsOneWidget);
      expect(find.text('Wednesday'), findsOneWidget);
      expect(find.text('Friends'), findsWidgets);
      expect(find.text('Steady'), findsOneWidget);
      expect(find.text('Good'), findsOneWidget);
      expect(find.text('More patterns unlock at 14 sessions'), findsOneWidget);
      expect(find.text('Session rhythm'), findsNothing);
    },
  );

  testWidgets('insights screen opens the Pulse share card preview', (
    WidgetTester tester,
  ) async {
    final _FakeSwipeSessionRepository fakeRepository =
        _FakeSwipeSessionRepository(
          sessions: [
            _buildSessionRecord(
              date: '2026-04-01',
              acceptedEmotions: const ['Calm', 'Joy'],
              contextSocial: 'Friends',
              contextEnergy: 'Steady',
            ),
            _buildSessionRecord(
              date: '2026-04-03',
              acceptedEmotions: const ['Calm'],
              contextSocial: 'Friends',
              contextSleep: 'Good',
            ),
            _buildSessionRecord(
              date: '2026-04-08',
              acceptedEmotions: const ['Focus'],
              contextEnergy: 'High',
            ),
            _buildSessionRecord(
              date: '2026-04-10',
              acceptedEmotions: const ['Calm', 'Hope'],
              contextSocial: 'Friends',
              contextSleep: 'Good',
            ),
            _buildSessionRecord(
              date: '2026-04-15',
              acceptedEmotions: const ['Joy'],
              contextSocial: 'Friends',
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
                displayName: 'Ava',
                email: 'ava@example.com',
                avatarColour: '#EC4899',
              ),
            ),
          ),
          currentUserStreakProvider.overrideWith(
            (ref) => const PulseStreak(
              currentStreak: 4,
              longestStreak: 6,
              lastSessionDate: '2026-04-15',
            ),
          ),
          currentUserLevelProgressProvider.overrideWith(
            (ref) => const PulseLevelProgress(),
          ),
          currentSessionDateProvider.overrideWith(
            (ref) => DateTime(2026, 4, 15),
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

    expect(find.byKey(const Key('open-share-card-button')), findsOneWidget);

    await tester.tap(find.byKey(const Key('open-share-card-button')));
    await tester.pumpAndSettle();

    expect(find.text('Share your Pulse snapshot'), findsOneWidget);
    expect(find.text('My Pulse snapshot'), findsOneWidget);
    expect(find.text('Weekly Pulse Score'), findsWidgets);
    expect(find.text('Current streak'), findsWidgets);
    expect(find.text('Top emotions'), findsWidgets);
    expect(find.text('Copy share text'), findsOneWidget);
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
          currentSessionDateProvider.overrideWith(
            (ref) => DateTime(2026, 4, 12),
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
    expect(find.text('Current streak'), findsOneWidget);
    expect(find.text('Weekly Pulse Score'), findsOneWidget);
    expect(find.text('7 / 7 days checked in this week'), findsOneWidget);
    expect(find.text('89'), findsOneWidget);
    expect(find.text('-1 vs last week'), findsOneWidget);
    expect(find.text('Overview'), findsOneWidget);
    expect(find.text('Context breakdown'), findsOneWidget);
    expect(find.text('Top accepted emotions'), findsOneWidget);
    expect(find.text('Most common context tags'), findsOneWidget);
    expect(find.text('Pattern signals'), findsOneWidget);
    expect(find.text('Session rhythm'), findsOneWidget);
    expect(find.text('Weekday pattern'), findsOneWidget);
    expect(find.text('Recurring signal'), findsOneWidget);
    expect(find.text('Context anchors'), findsOneWidget);
    expect(find.text('Emotion range'), findsWidgets);
    expect(find.text('Repeated emotion + context signals'), findsOneWidget);
    expect(find.text('14 sessions saved overall'), findsOneWidget);
    expect(find.text('Calm'), findsWidgets);
    expect(find.text('Social: Friends'), findsWidgets);
    expect(find.textContaining('Friends / Steady / Good'), findsOneWidget);
    expect(find.text('Most active weekday'), findsWidgets);
    expect(find.text('Friends'), findsWidgets);
    expect(find.text('Steady'), findsWidgets);
    expect(find.text('Good'), findsWidgets);
    expect(
      find.text(
        _formatInsightAverage(
          23 / PulseInsightsReport.expandedUnlockSessionCount,
        ),
      ),
      findsWidgets,
    );
  });

  testWidgets(
    'insights screen shows the emotional year layer after thirty sessions',
    (WidgetTester tester) async {
      final List<SwipeSessionRecord> sessions = <SwipeSessionRecord>[
        for (int index = 1; index <= 6; index++)
          _buildSessionRecord(
            date: '2026-01-${index.toString().padLeft(2, '0')}',
            acceptedEmotions: const ['Calm', 'Joy'],
            contextSocial: 'Friends',
          ),
        for (int index = 1; index <= 8; index++)
          _buildSessionRecord(
            date: '2026-02-${index.toString().padLeft(2, '0')}',
            acceptedEmotions: const ['Focus', 'Hope'],
            contextEnergy: 'Steady',
          ),
        for (int index = 1; index <= 10; index++)
          _buildSessionRecord(
            date: '2026-03-${index.toString().padLeft(2, '0')}',
            acceptedEmotions: const ['Calm', 'Confidence'],
            contextSleep: 'Good',
          ),
        for (int index = 1; index <= 6; index++)
          _buildSessionRecord(
            date: '2026-04-${index.toString().padLeft(2, '0')}',
            acceptedEmotions: <String>[
              'Calm',
              if (index <= 2) 'Vulnerability' else 'Curiosity',
            ],
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
                currentStreak: 6,
                longestStreak: 10,
                lastSessionDate: '2026-04-06',
              ),
            ),
            currentUserLevelProgressProvider.overrideWith(
              (ref) => const PulseLevelProgress(totalXp: 650, currentLevel: 7),
            ),
            currentSessionDateProvider.overrideWith(
              (ref) => DateTime(2026, 4, 6),
            ),
            swipeSessionRepositoryProvider.overrideWith(
              (ref) => fakeRepository,
            ),
          ],
          child: const PulseApp(),
        ),
      );

      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Insights'));
      await tester.tap(find.text('Insights').last);
      await tester.pumpAndSettle();

      expect(find.text('Emotional year'), findsOneWidget);
      expect(find.text('4 active months tracked'), findsOneWidget);
      expect(find.text('Rarest emotion'), findsOneWidget);
      expect(find.text('Vulnerability'), findsWidgets);
      expect(find.text('Recent month trend'), findsOneWidget);
      expect(find.text('-4 sessions vs Mar 2026'), findsOneWidget);
      expect(find.text('Monthly pulse trail'), findsOneWidget);
      expect(find.text('Jan 2026'), findsOneWidget);
      expect(find.text('Feb 2026'), findsOneWidget);
      expect(find.text('Mar 2026'), findsWidgets);
      expect(find.text('Apr 2026'), findsOneWidget);
    },
  );

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
    expect(find.byKey(const Key('level-up-celebration-dialog')), findsNothing);
    expect(
      find.byKey(const Key('badge-unlock-celebration-dialog')),
      findsOneWidget,
    );
    expect(find.text('Badge unlocked!'), findsOneWidget);
    await tester.tap(
      find.byKey(const Key('badge-unlock-celebration-continue')),
    );
    await tester.pumpAndSettle();

    expect(find.text('Session complete'), findsOneWidget);
    expect(find.text('Session reward'), findsOneWidget);
    expect(find.text('+65 XP'), findsOneWidget);
    expect(find.text('65 XP'), findsOneWidget);
    expect(find.text('Level 1'), findsOneWidget);
    expect(find.text('Session summary'), findsOneWidget);
    expect(find.text('8'), findsWidgets);
    expect(find.text('4'), findsWidgets);
    expect(find.textContaining('saved to your history'), findsOneWidget);
    expect(find.textContaining('Social: Friends'), findsOneWidget);
    expect(fakeRepository.lastUid, 'test-user');
    expect(fakeRepository.lastSavedSession, isNotNull);
    expect(fakeRepository.lastSavedSession!.contextEnergy, 'Steady');
    expect(fakeRepository.lastSavedSession!.contextSleep, 'Good');
    expect(fakeRepository.lastSaveResult?.xpEarned, 65);
  });

  testWidgets(
    'completion shows level-up and badge celebrations before the reward details',
    (WidgetTester tester) async {
      final _FakeSwipeSessionRepository fakeRepository =
          _FakeSwipeSessionRepository(
            sessions: [
              _buildSessionRecord(
                date: '2026-03-25',
                acceptedEmotions: const ['Calm'],
              ),
              _buildSessionRecord(
                date: '2026-03-27',
                acceptedEmotions: const ['Joy'],
                contextSocial: 'Solo',
                contextEnergy: 'High',
                contextSleep: 'Good',
              ),
              _buildSessionRecord(
                date: '2026-03-29',
                acceptedEmotions: const ['Focus'],
              ),
              _buildSessionRecord(
                date: '2026-03-31',
                acceptedEmotions: const ['Hope'],
              ),
              _buildSessionRecord(
                date: '2026-04-02',
                acceptedEmotions: const ['Calm'],
                contextSocial: 'Friends',
                contextEnergy: 'Steady',
                contextSleep: 'Good',
              ),
              _buildSessionRecord(
                date: '2026-04-03',
                acceptedEmotions: const ['Calm'],
                contextSocial: 'Friends',
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
                  displayName: 'Maya',
                  email: 'maya@example.com',
                  avatarColour: '#10B981',
                ),
              ),
            ),
            currentUserStreakProvider.overrideWith(
              (ref) => const PulseStreak(
                currentStreak: 2,
                longestStreak: 2,
                lastSessionDate: '2026-04-03',
              ),
            ),
            currentUserLevelProgressProvider.overrideWith(
              (ref) => const PulseLevelProgress(totalXp: 340, currentLevel: 4),
            ),
            swipeSessionRepositoryProvider.overrideWith(
              (ref) => fakeRepository,
            ),
          ],
          child: const PulseApp(),
        ),
      );

      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Start swipe session'));
      await tester.tap(find.text('Start swipe session'));
      await tester.pumpAndSettle();

      for (var i = 0; i < 8; i++) {
        final Finder actionButton = find.text(i.isEven ? 'Accept' : 'Reject');
        await tester.ensureVisible(actionButton);
        await tester.tap(actionButton);
        await tester.pumpAndSettle();
      }

      await tester.tap(find.text('Friends'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Steady'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Save session'));
      await tester.tap(find.text('Save session'));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('level-up-celebration-dialog')),
        findsOneWidget,
      );
      expect(find.text('Level up!'), findsOneWidget);
      expect(find.text('You reached Level 5.'), findsWidgets);
      await tester.tap(find.byKey(const Key('level-up-celebration-continue')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('badge-unlock-celebration-dialog')),
        findsOneWidget,
      );
      expect(find.text('Badges unlocked!'), findsOneWidget);
      expect(find.text('On A Roll'), findsWidgets);
      expect(find.text('Seven Check-Ins'), findsWidgets);
      await tester.tap(
        find.byKey(const Key('badge-unlock-celebration-continue')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const Key('level-up-celebration-dialog')),
        findsNothing,
      );
      expect(
        find.byKey(const Key('badge-unlock-celebration-dialog')),
        findsNothing,
      );
      expect(find.text('Session complete'), findsOneWidget);
      expect(find.text('Level up'), findsOneWidget);
      expect(find.text('You reached Level 5.'), findsOneWidget);
      expect(find.text('New badges'), findsOneWidget);
      expect(find.text('On A Roll'), findsOneWidget);
      expect(find.text('Seven Check-Ins'), findsOneWidget);
      expect(find.text('Streak milestone'), findsOneWidget);
      expect(
        find.text('Streak milestone reached: 3 days in a row.'),
        findsOneWidget,
      );
      expect(find.text('Current streak: 3 days'), findsOneWidget);
      expect(fakeRepository.lastSaveResult?.reward.didLevelUp, isTrue);
      expect(
        fakeRepository.lastSaveResult?.reward.newlyUnlockedBadgeIds,
        unorderedEquals(<String>['on-a-roll', 'seven-check-ins']),
      );
    },
  );

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
    expect(find.text('April 2026'), findsOneWidget);
    expect(find.text('Session journey'), findsOneWidget);
    expect(find.text('2026-04-04'), findsOneWidget);
    expect(find.text('2026-04-02'), findsOneWidget);
    expect(find.text('Accepted 3 of 8 emotions'), findsOneWidget);
    expect(find.textContaining('Energy: High | Sleep: Good'), findsOneWidget);

    final Finder latest = find.text('2026-04-04');
    final Finder older = find.text('2026-04-02');
    expect(tester.getTopLeft(latest).dy, lessThan(tester.getTopLeft(older).dy));
  });

  testWidgets('history supports month navigation across saved periods', (
    WidgetTester tester,
  ) async {
    final _FakeSwipeSessionRepository fakeRepository =
        _FakeSwipeSessionRepository(
          sessions: [
            _buildSessionRecord(
              date: '2026-03-15',
              acceptedEmotions: const ['Hope', 'Calm'],
            ),
            _buildSessionRecord(
              date: '2026-04-04',
              acceptedEmotions: const ['Focus', 'Confidence'],
              contextSocial: 'Friends',
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
          currentSessionDateProvider.overrideWith(
            (ref) => DateTime(2026, 4, 4),
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

    expect(find.text('April 2026'), findsOneWidget);
    expect(find.text('2026-04-04'), findsOneWidget);
    expect(find.text('2026-03-15'), findsNothing);

    await tester.tap(find.byKey(const Key('history-previous-month')));
    await tester.pumpAndSettle();

    expect(find.text('March 2026'), findsOneWidget);
    expect(find.text('2026-03-15'), findsOneWidget);
    expect(find.text('2026-04-04'), findsNothing);

    await tester.tap(find.byKey(const Key('history-next-month')));
    await tester.pumpAndSettle();

    expect(find.text('April 2026'), findsOneWidget);
    expect(find.text('2026-04-04'), findsOneWidget);
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
    await tester.tap(find.byKey(const Key('history-day-2026-04-04')));
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
  String? referralCode,
  int referralCount = PulseReferral.defaultReferralCount,
  PulseProfileSettings settings = const PulseProfileSettings(),
}) {
  return PulseUserProfile(
    uid: 'test-user',
    email: email,
    displayName: displayName,
    avatarColour: avatarColour,
    referralCode: referralCode,
    referralCount: referralCount,
    settings: settings,
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

class _FakeWidgetMessagingService implements PulseMessagingService {
  _FakeWidgetMessagingService({this.initialMessage});

  final StreamController<String> tokenRefreshController =
      StreamController<String>.broadcast();
  final StreamController<PulsePushMessage> foregroundController =
      StreamController<PulsePushMessage>.broadcast();
  final StreamController<PulsePushMessage> openedController =
      StreamController<PulsePushMessage>.broadcast();

  PulsePushMessage? initialMessage;
  @override
  Future<PulsePushMessage?> getInitialMessage() async {
    return initialMessage;
  }

  @override
  Future<String?> getToken() async {
    return null;
  }

  @override
  Future<void> initialize() async {}

  @override
  Stream<PulsePushMessage> get onForegroundMessage =>
      foregroundController.stream;

  @override
  Stream<PulsePushMessage> get onMessageOpenedApp => openedController.stream;

  @override
  Stream<String> get onTokenRefresh => tokenRefreshController.stream;

  @override
  Future<void> requestPermission() async {}

  Future<void> dispose() async {
    await tokenRefreshController.close();
    await foregroundController.close();
    await openedController.close();
  }
}

class _FakeWidgetNotificationTapSource
    implements PulsePushNotificationTapSource {
  _FakeWidgetNotificationTapSource();

  final StreamController<PulsePushMessage> tapController =
      StreamController<PulsePushMessage>.broadcast();

  @override
  Future<PulsePushMessage?> getInitialPushNotificationTap() async {
    return null;
  }

  @override
  Stream<PulsePushMessage> get onPushNotificationTap => tapController.stream;

  Future<void> dispose() async {
    await tapController.close();
  }
}

class _FakeFirebaseAuthService implements FirebaseAuthService {
  bool signOutCalled = false;
  bool googleSignInCalled = false;
  bool appleSignInCalled = false;
  Object? googleSignInException;
  Object? appleSignInException;

  @override
  User? get currentUser => null;

  @override
  Stream<User?> authStateChanges() {
    return const Stream<User?>.empty();
  }

  @override
  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  bool get isAuthenticated => false;

  @override
  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<UserCredential> signInWithGoogle() async {
    googleSignInCalled = true;
    if (googleSignInException != null) {
      throw googleSignInException!;
    }

    throw UnimplementedError();
  }

  @override
  Future<UserCredential> signInWithApple() async {
    appleSignInCalled = true;
    if (appleSignInException != null) {
      throw appleSignInException!;
    }

    throw UnimplementedError();
  }

  @override
  Future<void> signOut() async {
    signOutCalled = true;
  }
}

class _FakePulseAccountRepository implements PulseAccountRepository {
  String? deletedUid;

  @override
  Future<void> deleteUserData(String uid) async {
    deletedUid = uid;
  }
}

class _FakeUserProfileRepository implements UserProfileRepository {
  _FakeUserProfileRepository({
    required PulseUserProfile initialProfile,
    required StreamController<PulseUserProfile?> profileController,
  }) : _currentProfile = initialProfile,
       _profileController = profileController;

  PulseUserProfile _currentProfile;
  final StreamController<PulseUserProfile?> _profileController;
  String? lastUpdatedUid;
  String? lastDisplayName;
  String? lastAvatarColour;
  PulseProfileSettings? lastSettings;

  @override
  Future<PulseUserProfile?> fetchUserProfile(String uid) async {
    return _currentProfile;
  }

  @override
  Stream<PulseUserProfile?> watchUserProfile(String uid) {
    return _profileController.stream;
  }

  @override
  Future<void> ensureUserProfile(User user) async {}

  @override
  Future<void> updateProfile({
    required String uid,
    String? displayName,
    required String avatarColour,
    required PulseProfileSettings settings,
  }) async {
    lastUpdatedUid = uid;
    lastDisplayName = displayName?.trim();
    lastAvatarColour = avatarColour;
    lastSettings = settings;
    _currentProfile = PulseUserProfile(
      uid: _currentProfile.uid,
      email: _currentProfile.email,
      displayName: displayName?.trim(),
      avatarColour: avatarColour,
      currentStreak: _currentProfile.currentStreak,
      longestStreak: _currentProfile.longestStreak,
      lastSessionDate: _currentProfile.lastSessionDate,
      totalXp: _currentProfile.totalXp,
      currentLevel: _currentProfile.currentLevel,
      unlockedBadgeIds: _currentProfile.unlockedBadgeIds,
      referralCode: _currentProfile.referralCode,
      referralCount: _currentProfile.referralCount,
      settings: settings,
      createdAt: _currentProfile.createdAt,
      lastSeenAt: _currentProfile.lastSeenAt,
    );
    _profileController.add(_currentProfile);
  }

  @override
  DocumentReference<Map<String, dynamic>> userDocument(String uid) {
    throw UnimplementedError();
  }
}

class _FakeSwipeSessionRepository implements SwipeSessionRepository {
  _FakeSwipeSessionRepository({
    List<SwipeSessionRecord> sessions = const <SwipeSessionRecord>[],
  }) : _sessions = List<SwipeSessionRecord>.from(sessions);

  final List<SwipeSessionRecord> _sessions;
  final StreamController<void> _changesController =
      StreamController<void>.broadcast();
  String? lastUid;
  SwipeSessionRecord? lastSavedSession;
  SwipeSessionSaveResult? lastSaveResult;

  @override
  Future<SwipeSessionSaveResult> saveSession({
    required String uid,
    required SwipeSessionSummary summary,
    String? contextSocial,
    String? contextEnergy,
    String? contextSleep,
  }) async {
    lastUid = uid;
    final List<SwipeSessionRecord> previousSessions =
        List<SwipeSessionRecord>.from(_sessions);
    lastSavedSession = SwipeSessionRecord.fromSummary(
      summary: summary,
      contextSocial: contextSocial,
      contextEnergy: contextEnergy,
      contextSleep: contextSleep,
      completedAt: DateTime(2026, 4, 4, 12),
    );
    final PulseLevelProgress previousLevelProgress = _levelProgressFromSessions(
      previousSessions,
    );
    final PulseStreak previousStreak = _streakFromSessions(
      previousSessions,
      currentDate: lastSavedSession!.completedAt,
    );
    final List<String> previousUnlockedBadgeIds = _unlockedBadgeIdsFromSessions(
      previousSessions,
      previousStreak,
      previousLevelProgress,
    );
    _sessions.removeWhere(
      (session) => session.sessionId == lastSavedSession!.sessionId,
    );
    _sessions.add(lastSavedSession!);
    final PulseLevelProgress levelProgress = _levelProgressFromSessions(
      _sessions,
    );
    final PulseStreak currentStreak = _streakFromSessions(
      _sessions,
      currentDate: lastSavedSession!.completedAt,
    );
    final List<String> unlockedBadgeIds = _unlockedBadgeIdsFromSessions(
      _sessions,
      currentStreak,
      levelProgress,
    );
    final SwipeSessionRewardDetails reward =
        SwipeSessionRewardDetails.fromTransition(
          xpEarned: _sessionXpForRecord(lastSavedSession!),
          previousLevelProgress: previousLevelProgress,
          levelProgress: levelProgress,
          previousStreak: previousStreak,
          currentStreak: currentStreak,
          previousUnlockedBadgeIds: previousUnlockedBadgeIds,
          unlockedBadgeIds: unlockedBadgeIds,
        );
    lastSaveResult = SwipeSessionSaveResult(
      session: lastSavedSession!,
      reward: reward,
    );
    _changesController.add(null);
    return lastSaveResult!;
  }

  @override
  Stream<SwipeSessionRecord?> watchSession({
    required String uid,
    required String sessionId,
  }) async* {
    yield _matchingSession(sessionId);
    yield* _changesController.stream.map((_) => _matchingSession(sessionId));
  }

  @override
  Stream<List<SwipeSessionRecord>> watchSessions({required String uid}) async* {
    yield _sortedSessions();
    yield* _changesController.stream.map((_) => _sortedSessions());
  }

  PulseLevelProgress _levelProgressFromSessions(
    List<SwipeSessionRecord> sessions,
  ) {
    return PulseLevelProgress.fromSessionXpAwards(
      sessions.map(_sessionXpForRecord),
    );
  }

  PulseStreak _streakFromSessions(
    List<SwipeSessionRecord> sessions, {
    required DateTime currentDate,
  }) {
    if (sessions.isEmpty) {
      return const PulseStreak();
    }

    return PulseStreak.fromSessionDates(
      sessions.map((session) => session.sessionId),
      currentDate: currentDate,
    );
  }

  List<String> _unlockedBadgeIdsFromSessions(
    List<SwipeSessionRecord> sessions,
    PulseStreak streak,
    PulseLevelProgress levelProgress,
  ) {
    return PulseBadgeCatalog.unlockedBadgeIds(
      PulseBadgeProgressSnapshot.fromSessionHistory(
        sessionHistory: sessions.map((session) {
          return PulseSessionHistoryEntry(
            date: session.date,
            acceptedEmotions: session.acceptedEmotions,
            contextSocial: session.contextSocial,
            contextEnergy: session.contextEnergy,
            contextSleep: session.contextSleep,
          );
        }),
        longestStreak: streak.longestStreak,
        currentLevel: levelProgress.currentLevel,
      ),
    );
  }

  int _sessionXpForRecord(SwipeSessionRecord session) {
    return PulseLevelProgress.sessionXp(
      contextSocial: session.contextSocial,
      contextEnergy: session.contextEnergy,
      contextSleep: session.contextSleep,
    );
  }

  SwipeSessionRecord? _matchingSession(String sessionId) {
    for (final SwipeSessionRecord session in _sessions) {
      if (session.sessionId == sessionId) {
        return session;
      }
    }

    return null;
  }

  List<SwipeSessionRecord> _sortedSessions() {
    return List<SwipeSessionRecord>.from(_sessions)
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));
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
