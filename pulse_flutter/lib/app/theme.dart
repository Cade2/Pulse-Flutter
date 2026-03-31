import 'package:flutter/material.dart';

const Color _pulseBackground = Color(0xFF05070B);
const Color _pulseSurface = Color(0xFF11151B);
const Color _pulsePrimary = Color(0xFF2ED3E6);
const Color _pulseSecondary = Color(0xFF67F5D7);
const Color _pulseText = Color(0xFFF4F7FA);

final ColorScheme _pulseColorScheme =
    ColorScheme.fromSeed(
      seedColor: _pulsePrimary,
      brightness: Brightness.dark,
    ).copyWith(
      primary: _pulsePrimary,
      secondary: _pulseSecondary,
      surface: _pulseSurface,
    );

final ThemeData pulseTheme = ThemeData(
  useMaterial3: true,
  colorScheme: _pulseColorScheme,
  scaffoldBackgroundColor: _pulseBackground,
  canvasColor: _pulseBackground,
  appBarTheme: const AppBarTheme(
    backgroundColor: _pulseBackground,
    foregroundColor: _pulseText,
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      minimumSize: const Size(double.infinity, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
    ),
  ),
  textTheme: ThemeData(
    brightness: Brightness.dark,
    useMaterial3: true,
  ).textTheme.apply(bodyColor: _pulseText, displayColor: _pulseText),
);
