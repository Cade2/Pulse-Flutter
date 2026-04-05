import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_flutter/app/app_shell.dart';
import 'package:pulse_flutter/core/providers/auth_providers.dart';
import 'package:pulse_flutter/core/providers/swipe_session_providers.dart';
import 'package:pulse_flutter/features/auth/presentation/login_screen.dart';
import 'package:pulse_flutter/features/badges/presentation/badges_screen.dart';
import 'package:pulse_flutter/features/home/presentation/home_screen.dart';
import 'package:pulse_flutter/features/history/presentation/history_screen.dart';
import 'package:pulse_flutter/features/insights/presentation/insights_screen.dart';
import 'package:pulse_flutter/features/onboarding/presentation/onboarding_screen.dart';
import 'package:pulse_flutter/features/profile/presentation/profile_screen.dart';
import 'package:pulse_flutter/features/splash/presentation/splash_screen.dart';
import 'package:pulse_flutter/features/swipe_session/models/swipe_session_save_result.dart';
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

  static const String historyName = 'history';
  static const String historyPath = '/history';

  static const String profileName = 'profile';
  static const String profilePath = '/profile';

  static const String badgesName = 'badges';
  static const String badgesPath = '/badges';

  static const String insightsName = 'insights';
  static const String insightsPath = '/insights';

  static const String swipeSessionName = 'swipe-session';
  static const String swipeSessionPath = '/session';

  static const String contextTagsName = 'context-tags';
  static const String contextTagsPath = '/session/context';

  static const String swipeSessionCompleteName = 'swipe-session-complete';
  static const String swipeSessionCompletePath = '/session/complete';

  static String historyLocation({String? sessionId}) {
    final String? trimmedSessionId = sessionId?.trim();
    if (trimmedSessionId == null || trimmedSessionId.isEmpty) {
      return historyPath;
    }

    final Uri uri = Uri(
      path: historyPath,
      queryParameters: <String, String>{'sessionId': trimmedSessionId},
    );
    return uri.toString();
  }
}

class _AppRouterNotifier extends ChangeNotifier {
  _AppRouterNotifier(this._ref)
    : _isAuthenticated = _ref.read(isAuthenticatedProvider),
      _hasCompletedToday = _ref.read(hasCompletedTodayProvider) {
    _ref.listen<bool>(isAuthenticatedProvider, (previous, next) {
      if (_isAuthenticated == next) {
        return;
      }

      _isAuthenticated = next;
      notifyListeners();
    });

    _ref.listen<bool>(hasCompletedTodayProvider, (previous, next) {
      if (_hasCompletedToday == next) {
        return;
      }

      _hasCompletedToday = next;
      notifyListeners();
    });
  }

  final Ref _ref;
  bool _isAuthenticated;
  bool _hasCompletedToday;

  static const Set<String> publicPaths = <String>{
    AppRoutes.splashPath,
    AppRoutes.onboardingPath,
    AppRoutes.loginPath,
  };

  String? redirect(GoRouterState state) {
    final String location = state.matchedLocation;

    if (!_isAuthenticated && !publicPaths.contains(location)) {
      return AppRoutes.splashPath;
    }

    if (_isAuthenticated && publicPaths.contains(location)) {
      return AppRoutes.homePath;
    }

    if (_isAuthenticated &&
        _hasCompletedToday &&
        location == AppRoutes.swipeSessionPath) {
      return AppRoutes.homePath;
    }

    return null;
  }
}

final _appRouterNotifierProvider = Provider<_AppRouterNotifier>((ref) {
  final _AppRouterNotifier notifier = _AppRouterNotifier(ref);
  ref.onDispose(notifier.dispose);
  return notifier;
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final _AppRouterNotifier notifier = ref.watch(_appRouterNotifierProvider);
  final GoRouter router = GoRouter(
    initialLocation: AppRoutes.splashPath,
    refreshListenable: notifier,
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
      ShellRoute(
        builder: (context, state, child) {
          return AppShell(currentLocation: state.matchedLocation, child: child);
        },
        routes: <RouteBase>[
          GoRoute(
            path: AppRoutes.homePath,
            name: AppRoutes.homeName,
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: AppRoutes.historyPath,
            name: AppRoutes.historyName,
            builder: (context, state) => HistoryScreen(
              initialSessionId: state.uri.queryParameters['sessionId'],
            ),
          ),
          GoRoute(
            path: AppRoutes.insightsPath,
            name: AppRoutes.insightsName,
            builder: (context, state) => const InsightsScreen(),
          ),
          GoRoute(
            path: AppRoutes.badgesPath,
            name: AppRoutes.badgesName,
            builder: (context, state) => const BadgesScreen(),
          ),
          GoRoute(
            path: AppRoutes.profilePath,
            name: AppRoutes.profileName,
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
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
          final SwipeSessionSaveResult? result =
              state.extra as SwipeSessionSaveResult?;
          return SwipeCompletionScreen(result: result);
        },
      ),
    ],
    redirect: (context, state) => notifier.redirect(state),
  );

  ref.onDispose(router.dispose);
  return router;
});
