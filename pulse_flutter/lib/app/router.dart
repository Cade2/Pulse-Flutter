import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_flutter/core/providers/auth_providers.dart';
import 'package:pulse_flutter/features/auth/presentation/login_screen.dart';
import 'package:pulse_flutter/features/home/presentation/home_screen.dart';
import 'package:pulse_flutter/features/onboarding/presentation/onboarding_screen.dart';
import 'package:pulse_flutter/features/splash/presentation/splash_screen.dart';

abstract final class AppRoutes {
  static const String splashName = 'splash';
  static const String splashPath = '/';

  static const String onboardingName = 'onboarding';
  static const String onboardingPath = '/onboarding';

  static const String loginName = 'login';
  static const String loginPath = '/login';

  static const String homeName = 'home';
  static const String homePath = '/home';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final bool isAuthenticated = ref.watch(isAuthenticatedProvider);

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
    ],
    redirect: (context, state) {
      final String location = state.matchedLocation;
      final bool isHomeRoute = location == AppRoutes.homePath;

      if (!isAuthenticated && isHomeRoute) {
        return AppRoutes.splashPath;
      }

      if (isAuthenticated && !isHomeRoute) {
        return AppRoutes.homePath;
      }

      return null;
    },
  );

  ref.onDispose(router.dispose);
  return router;
});
