import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_flutter/app/router.dart';
import 'package:pulse_flutter/app/theme.dart';
import 'package:pulse_flutter/core/providers/user_profile_providers.dart';

class PulseApp extends ConsumerWidget {
  const PulseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final ThemeMode themeMode = ref.watch(currentUserThemeModeProvider);

    return MaterialApp.router(
      title: 'Pulse',
      debugShowCheckedModeBanner: false,
      theme: pulseLightTheme,
      darkTheme: pulseDarkTheme,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
