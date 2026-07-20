import 'package:flutter/material.dart';

/// The visual language is deliberately quiet: an off-white canvas with lilac,
/// blush, and sky-blue accents that remain legible in both device themes.
class AppTheme {
  AppTheme._();

  static const offWhite = Color(0xFFFBF9F5);
  static const lilac = Color(0xFF9D88D8);
  static const lightPink = Color(0xFFF2C6D4);
  static const lightBlue = Color(0xFFB9DCF4);
  static const ink = Color(0xFF2D2937);

  static const night = Color(0xFF17151E);
  static const nightSurface = Color(0xFF211E29);
  static const darkLilac = Color(0xFFD1BEFF);
  static const darkPink = Color(0xFFF0B5C8);
  static const darkBlue = Color(0xFFB7DBF5);
  static const mist = Color(0xFFE9E3F0);

  static const lightScheme = ColorScheme.light(
    primary: lilac,
    onPrimary: Color(0xFF211534),
    primaryContainer: Color(0xFFEAE2FF),
    onPrimaryContainer: Color(0xFF372651),
    secondary: lightBlue,
    onSecondary: Color(0xFF15384C),
    secondaryContainer: Color(0xFFE2F2FF),
    onSecondaryContainer: Color(0xFF173A4D),
    tertiary: lightPink,
    onTertiary: Color(0xFF502838),
    tertiaryContainer: Color(0xFFFFE5EC),
    onTertiaryContainer: Color(0xFF5B2D3F),
    error: Color(0xFFB53A4A),
    onError: Colors.white,
    surface: offWhite,
    onSurface: ink,
    surfaceContainerLowest: Color(0xFFFFFFFF),
    surfaceContainerLow: Color(0xFFF6F2F8),
    surfaceContainer: Color(0xFFF1EDF4),
    surfaceContainerHigh: Color(0xFFEAE5EE),
    outline: Color(0xFFD8D0DC),
    outlineVariant: Color(0xFFE7E0E8),
  );

  static const darkScheme = ColorScheme.dark(
    primary: darkLilac,
    onPrimary: Color(0xFF33264A),
    primaryContainer: Color(0xFF4B3B68),
    onPrimaryContainer: Color(0xFFE9E0FF),
    secondary: darkBlue,
    onSecondary: Color(0xFF19384C),
    secondaryContainer: Color(0xFF294C61),
    onSecondaryContainer: Color(0xFFD8F0FF),
    tertiary: darkPink,
    onTertiary: Color(0xFF542C3D),
    tertiaryContainer: Color(0xFF663D4E),
    onTertiaryContainer: Color(0xFFFFD9E4),
    error: Color(0xFFFFB3B9),
    onError: Color(0xFF680019),
    surface: night,
    onSurface: mist,
    surfaceContainerLowest: Color(0xFF121017),
    surfaceContainerLow: Color(0xFF1D1A24),
    surfaceContainer: nightSurface,
    surfaceContainerHigh: Color(0xFF2A2633),
    outline: Color(0xFF978FA1),
    outlineVariant: Color(0xFF48424F),
  );

  static ThemeData get lightTheme => _build(lightScheme);
  static ThemeData get darkTheme => _build(darkScheme);

  static ThemeData _build(ColorScheme scheme) {
    final isDark = scheme.brightness == Brightness.dark;
    final baseText = ThemeData(brightness: scheme.brightness).textTheme;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
        titleTextStyle: baseText.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
      ),
      textTheme: baseText.copyWith(
        headlineSmall: baseText.headlineSmall?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.7,
        ),
        titleLarge: baseText.titleLarge?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleMedium: baseText.titleMedium?.copyWith(
          color: scheme.onSurface,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: baseText.bodyLarge?.copyWith(
          color: scheme.onSurface,
          height: 1.45,
        ),
        bodyMedium: baseText.bodyMedium?.copyWith(
          color: scheme.onSurface.withValues(alpha: 0.72),
          height: 1.42,
        ),
        labelLarge: baseText.labelLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        labelStyle: TextStyle(color: scheme.onSurface.withValues(alpha: 0.65)),
        hintStyle: TextStyle(color: scheme.onSurface.withValues(alpha: 0.42)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.primary, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: scheme.error),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 17),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: scheme.onSurface,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? scheme.surfaceContainerHigh : ink,
        contentTextStyle: TextStyle(
          color: isDark ? scheme.onSurface : Colors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}
