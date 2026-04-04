import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_flutter/core/providers/auth_providers.dart';
import 'package:pulse_flutter/features/auth/presentation/login_screen.dart';
import 'package:pulse_flutter/features/home/presentation/home_screen.dart';
import 'package:pulse_flutter/features/onboarding/presentation/onboarding_screen.dart';
import 'package:pulse_flutter/features/splash/presentation/splash_screen.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_record.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_summary.dart';
import 'package:pulse_flutter/features/swipe_session/presentation/context_tag_screen.dart';
import 'package:pulse_flutter/features/swipe_session/presentation/swipe_completion_screen.dart';
import 'package:pulse_flutter/features/swipe_session/presentation/swipe_screen.dart';

abstract final class AppRoutes {
  static const String splashName = 'splash';
  static const String splashPath = '/';

  static const String onboardingName = 'onboarding';
  static const String onboardingPath = '/onboarding';

  static const String loginName = 'login';
  static const String loginPath = '/login';

  static const String homeName = 'home';
  static const String homePath = '/home';

  static const String swipeSessionName = 'swipe-session';
  static const String swipeSessionPath = '/session';

  static const String contextTagsName = 'context-tags';
  static const String contextTagsPath = '/session/context';

  static const String swipeSessionCompleteName = 'swipe-session-complete';
  static const String swipeSessionCompletePath = '/session/complete';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final bool isAuthenticated = ref.watch(isAuthenticatedProvider);
  const Set<String> publicPaths = <String>{
    AppRoutes.splashPath,
    AppRoutes.onboardingPath,
    AppRoutes.loginPath,
  };

  final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splashPath,
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splashPath,
        name: AppRoutes.splashName,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.onboardingPath,
        name: AppRoutes.onboardingName,
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: AppRoutes.loginPath,
        name: AppRoutes.loginName,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.homePath,
        name: AppRoutes.homeName,
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.swipeSessionPath,
        name: AppRoutes.swipeSessionName,
        builder: (context, state) => const SwipeScreen(),
      ),
      GoRoute(
        path: AppRoutes.contextTagsPath,
        name: AppRoutes.contextTagsName,
        builder: (context, state) {
          final SwipeSessionSummary? summary =
              state.extra as SwipeSessionSummary?;
          return ContextTagScreen(summary: summary);
        },
      ),
      GoRoute(
        path: AppRoutes.swipeSessionCompletePath,
        name: AppRoutes.swipeSessionCompleteName,
        builder: (context, state) {
          final SwipeSessionRecord? session =
              state.extra as SwipeSessionRecord?;
          return SwipeCompletionScreen(session: session);
        },
      ),
    ],
    redirect: (context, state) {
      final String location = state.matchedLocation;

      if (!isAuthenticated && !publicPaths.contains(location)) {
        return AppRoutes.splashPath;
      }

      if (isAuthenticated && publicPaths.contains(location)) {
        return AppRoutes.homePath;
      }

      return null;
    },
  );

  ref.onDispose(router.dispose);
  return router;
});
