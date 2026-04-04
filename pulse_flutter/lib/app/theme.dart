import 'package:flutter/material.dart';

const Color _pulseBackground = Color(0xFF05070B);
const Color _pulseSurface = Color(0xFF11151B);
const Color _pulsePrimary = Color(0xFF2ED3E6);
const Color _pulseSecondary = Color(0xFF67F5D7);
const Color _pulseText = Color(0xFFF4F7FA);
const Color _pulseLightBackground = Color(0xFFF5F8FC);
const Color _pulseLightSurface = Color(0xFFFFFFFF);
const Color _pulseLightText = Color(0xFF0B1320);

ThemeData _buildPulseTheme({
  required Brightness brightness,
  required Color backgroundColor,
  required Color surfaceColor,
  required Color textColor,
}) {
  final ColorScheme colorScheme =
      ColorScheme.fromSeed(
        seedColor: _pulsePrimary,
        brightness: brightness,
      ).copyWith(
        primary: _pulsePrimary,
        secondary: _pulseSecondary,
        surface: surfaceColor,
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: backgroundColor,
    canvasColor: backgroundColor,
    appBarTheme: AppBarTheme(
      backgroundColor: backgroundColor,
      foregroundColor: textColor,
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
      brightness: brightness,
      useMaterial3: true,
    ).textTheme.apply(bodyColor: textColor, displayColor: textColor),
  );
}

final ThemeData pulseLightTheme = _buildPulseTheme(
  brightness: Brightness.light,
  backgroundColor: _pulseLightBackground,
  surfaceColor: _pulseLightSurface,
  textColor: _pulseLightText,
);

final ThemeData pulseDarkTheme = _buildPulseTheme(
  brightness: Brightness.dark,
  backgroundColor: _pulseBackground,
  surfaceColor: _pulseSurface,
  textColor: _pulseText,
);

final ThemeData pulseTheme = pulseDarkTheme;
