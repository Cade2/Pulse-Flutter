import 'package:go_router/go_router.dart';
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

final GoRouter appRouter = GoRouter(
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
);
