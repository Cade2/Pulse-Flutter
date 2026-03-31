import 'package:flutter/material.dart';
import 'package:pulse_flutter/app/router.dart';
import 'package:pulse_flutter/app/theme.dart';

class PulseApp extends StatelessWidget {
  const PulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Pulse',
      debugShowCheckedModeBanner: false,
      theme: pulseTheme,
      darkTheme: pulseTheme,
      themeMode: ThemeMode.dark,
      routerConfig: appRouter,
    );
  }
}
