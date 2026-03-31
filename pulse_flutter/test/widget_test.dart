import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_flutter/app/app.dart';

void main() {
  testWidgets('Pulse starter flow navigates from splash to home', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const ProviderScope(child: PulseApp()));

    expect(find.text('Splash'), findsOneWidget);
    expect(find.text('Start onboarding'), findsOneWidget);

    await tester.tap(find.text('Start onboarding'));
    await tester.pumpAndSettle();
    expect(find.text('Onboarding'), findsOneWidget);

    await tester.tap(find.text('Continue to login'));
    await tester.pumpAndSettle();
    expect(find.text('Login'), findsOneWidget);

    await tester.tap(find.text('Enter Pulse'));
    await tester.pumpAndSettle();
    expect(find.text('Home'), findsOneWidget);

    await tester.tap(find.text('Restart setup flow'));
    await tester.pumpAndSettle();
    expect(find.text('Splash'), findsOneWidget);
  });
}
