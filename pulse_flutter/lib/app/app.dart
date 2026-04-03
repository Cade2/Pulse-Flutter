import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pulse_flutter/app/router.dart';
import 'package:pulse_flutter/app/theme.dart';

class PulseApp extends ConsumerWidget {
  const PulseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'Pulse',
      debugShowCheckedModeBanner: false,
      theme: pulseTheme,
      darkTheme: pulseTheme,
      themeMode: ThemeMode.dark,
      routerConfig: router,
    );
  }
}
