import 'package:flutter/material.dart';

/// The visual foundation for the worker-facing screening app.
///
/// Colors deliberately stay soft and low contrast in large areas so that the
/// important states (recording, quality, and risk) remain easy to notice.
class AppTheme {
  AppTheme._();

  static const offWhite = Color(0xFFFFFCF8);
  static const ink = Color(0xFF27222E);
  static const lilac = Color(0xFF8367C7);
  static const lightLilac = Color(0xFFECE6FF);
  static const lightPink = Color(0xFFF8C7D7);
  static const lightBlue = Color(0xFFC7E9F5);
  static const line = Color(0xFFE8E1ED);

  static const night = Color(0xFF17141E);
  static const nightSurface = Color(0xFF211D29);
  static const nightSurfaceHigh = Color(0xFF2A2534);
  static const nightText = Color(0xFFF2EDF8);
  static const nightMuted = Color(0xFFCAC1D4);
  static const darkLilac = Color(0xFFCBB9FF);
  static const darkPink = Color(0xFFF2A8C3);
  static const darkBlue = Color(0xFFA9DCEE);

  static ThemeData get lightTheme => _buildTheme(
    scheme: const ColorScheme.light(
      primary: lilac,
      onPrimary: Colors.white,
      primaryContainer: lightLilac,
      onPrimaryContainer: Color(0xFF352457),
      secondary: Color(0xFFD57A9D),
      onSecondary: Colors.white,
      secondaryContainer: lightPink,
      onSecondaryContainer: Color(0xFF542134),
      tertiary: Color(0xFF5C99B3),
      onTertiary: Colors.white,
      tertiaryContainer: lightBlue,
      onTertiaryContainer: Color(0xFF143D4E),
      error: Color(0xFFB3261E),
      onError: Colors.white,
      surface: Colors.white,
      onSurface: ink,
      surfaceContainerHighest: Color(0xFFF3EDF5),
      outline: Color(0xFFCCC2D1),
      outlineVariant: line,
    ),
    scaffold: offWhite,
    card: Colors.white,
    mutedText: const Color(0xFF726B7A),
  );

  static ThemeData get darkTheme => _buildTheme(
    scheme: const ColorScheme.dark(
      primary: darkLilac,
      onPrimary: Color(0xFF352457),
      primaryContainer: Color(0xFF4B3972),
      onPrimaryContainer: Color(0xFFECE4FF),
      secondary: darkPink,
      onSecondary: Color(0xFF5A2339),
      secondaryContainer: Color(0xFF71354D),
      onSecondaryContainer: Color(0xFFFFD9E5),
      tertiary: darkBlue,
      onTertiary: Color(0xFF153D4E),
      tertiaryContainer: Color(0xFF315D70),
      onTertiaryContainer: Color(0xFFD0F0FF),
      error: Color(0xFFFFB4AB),
      onError: Color(0xFF690005),
      surface: nightSurface,
      onSurface: nightText,
      surfaceContainerHighest: nightSurfaceHigh,
      outline: Color(0xFF978EA2),
      outlineVariant: Color(0xFF49434F),
    ),
    scaffold: night,
    card: nightSurface,
    mutedText: nightMuted,
  );

  static ThemeData _buildTheme({
    required ColorScheme scheme,
    required Color scaffold,
    required Color card,
    required Color mutedText,
  }) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: scheme.brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffold,
      fontFamily: 'sans-serif',
    );

    final textTheme = base.textTheme.copyWith(
      displaySmall: base.textTheme.displaySmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.8,
      ),
      headlineSmall: base.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
      ),
      titleLarge: base.textTheme.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
      ),
      titleMedium: base.textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.w700,
      ),
      bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.4),
      bodySmall: base.textTheme.bodySmall?.copyWith(
        color: mutedText,
        height: 1.35,
      ),
    );

    final rounded = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: scaffold,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        shape: rounded,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      dividerTheme: DividerThemeData(color: scheme.outlineVariant, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 17,
        ),
        labelStyle: TextStyle(color: mutedText),
        hintStyle: TextStyle(color: mutedText),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.primary, width: 1.7),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: scheme.error),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
          textStyle: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(50),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(17),
          ),
          textStyle: textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        elevation: 0,
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: BorderSide(color: scheme.outlineVariant),
        backgroundColor: scheme.surface,
        labelStyle: textTheme.labelMedium,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: scheme.primaryContainer,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.onSurface,
        contentTextStyle: TextStyle(color: scheme.surface),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surface,
        modalBackgroundColor: scheme.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
      ),
    );
  }
}
