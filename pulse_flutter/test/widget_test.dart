import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_flutter/app/app.dart';
import 'package:pulse_flutter/app/router.dart';
import 'package:pulse_flutter/core/firestore/swipe_session_repository.dart';
import 'package:pulse_flutter/core/providers/auth_providers.dart';
import 'package:pulse_flutter/core/providers/swipe_session_providers.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_record.dart';
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
        ],
        child: const PulseApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Splash'), findsNothing);
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
          swipeSessionRepositoryProvider.overrideWith((ref) => fakeRepository),
        ],
        child: const PulseApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Start swipe session'), findsOneWidget);

    await tester.tap(find.text('Start swipe session'));
    await tester.pumpAndSettle();

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

    expect(find.text('Session complete'), findsOneWidget);
    expect(find.text('Cards reviewed: 8'), findsOneWidget);
    expect(find.text('Accepted: 4'), findsOneWidget);
    expect(find.text('Rejected: 4'), findsOneWidget);
    expect(find.textContaining('saved to your history'), findsOneWidget);
    expect(find.textContaining('Social: Friends'), findsOneWidget);
    expect(fakeRepository.lastUid, 'test-user');
    expect(fakeRepository.lastSavedSession, isNotNull);
    expect(fakeRepository.lastSavedSession!.contextEnergy, 'Steady');
    expect(fakeRepository.lastSavedSession!.contextSleep, 'Good');
  });
}

class _FakeSwipeSessionRepository implements SwipeSessionRepository {
  String? lastUid;
  SwipeSessionRecord? lastSavedSession;

  @override
  Future<SwipeSessionRecord> saveSession({
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
    return lastSavedSession!;
  }
}
