import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:pulse_flutter/app/router.dart';

class AppShell extends StatelessWidget {
  const AppShell({
    super.key,
    required this.child,
    required this.currentLocation,
  });

  final Widget child;
  final String currentLocation;

  static const List<_AppShellDestination> _destinations =
      <_AppShellDestination>[
        _AppShellDestination(
          routeName: AppRoutes.homeName,
          routePath: AppRoutes.homePath,
          label: 'Home',
          icon: Icons.home_outlined,
          selectedIcon: Icons.home_rounded,
        ),
        _AppShellDestination(
          routeName: AppRoutes.historyName,
          routePath: AppRoutes.historyPath,
          label: 'History',
          icon: Icons.history_outlined,
          selectedIcon: Icons.history_rounded,
        ),
        _AppShellDestination(
          routeName: AppRoutes.insightsName,
          routePath: AppRoutes.insightsPath,
          label: 'Insights',
          icon: Icons.insights_outlined,
          selectedIcon: Icons.insights_rounded,
        ),
        _AppShellDestination(
          routeName: AppRoutes.badgesName,
          routePath: AppRoutes.badgesPath,
          label: 'Badges',
          icon: Icons.workspace_premium_outlined,
          selectedIcon: Icons.workspace_premium_rounded,
        ),
        _AppShellDestination(
          routeName: AppRoutes.profileName,
          routePath: AppRoutes.profilePath,
          label: 'Profile',
          icon: Icons.person_outline_rounded,
          selectedIcon: Icons.person_rounded,
        ),
      ];

  int get _selectedIndex {
    for (int index = 0; index < _destinations.length; index++) {
      final _AppShellDestination destination = _destinations[index];
      if (_matchesLocation(destination.routePath)) {
        return index;
      }
    }

    return 0;
  }

  bool _matchesLocation(String routePath) {
    return currentLocation == routePath ||
        currentLocation.startsWith('$routePath/');
  }

  void _onDestinationSelected(BuildContext context, int index) {
    if (index == _selectedIndex) {
      return;
    }

    GoRouter.of(context).goNamed(_destinations[index].routeName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        key: const Key('pulse-bottom-nav'),
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          _onDestinationSelected(context, index);
        },
        destinations: _destinations
            .map((destination) {
              return NavigationDestination(
                icon: Icon(destination.icon),
                selectedIcon: Icon(destination.selectedIcon),
                label: destination.label,
              );
            })
            .toList(growable: false),
      ),
    );
  }
}

class _AppShellDestination {
  const _AppShellDestination({
    required this.routeName,
    required this.routePath,
    required this.label,
    required this.icon,
    required this.selectedIcon,
  });

  final String routeName;
  final String routePath;
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}
