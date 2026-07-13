import 'package:flutter/material.dart';

class AppTheme {
  // Light Theme Colors
  static const Color ivory = Color(0xFFFFFFF0);
  static const Color lightBlue = Color(0xFFADD8E6);
  static const Color lightPink = Color(0xFFFFB6C1);
  static const Color darkText = Color(0xFF1E1E1E);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkBlue = Color(0xFF5C93AA);
  static const Color darkPink = Color(0xFFB56D84);
  static const Color lightText = Color(0xFFE0E0E0);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: lightBlue,
        secondary: lightPink,
        surface: ivory,
        onSurface: darkText,
      ),
      scaffoldBackgroundColor: ivory,
      appBarTheme: const AppBarTheme(
        backgroundColor: ivory,
        foregroundColor: darkText,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: darkText),
        bodyMedium: TextStyle(color: darkText),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: const ColorScheme.dark(
        primary: darkBlue,
        secondary: darkPink,
        surface: darkBackground,
        onSurface: lightText,
      ),
      scaffoldBackgroundColor: darkBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBackground,
        foregroundColor: lightText,
        elevation: 0,
        centerTitle: true,
      ),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: lightText),
        bodyMedium: TextStyle(color: lightText),
      ),
    );
  }
}
