import 'package:flutter/material.dart';

/// Centralized clinical typography and visual theme for Drugph.
///
/// Uses IBM Plex Sans Thai (bundled offline with weights 400–700) for crisp
/// Thai/Latin harmony, generous line heights for Thai diacritics, and
/// IBM Plex Mono with tabular figures for copy-ready clinical notes.
class AppTheme {
  const AppTheme._();

  static const String primaryFontFamily = 'IBMPlexSansThai';
  static const String monoFontFamily = 'IBMPlexMono';
  static const List<String> fallbackFonts = [
    'IBMPlexSansThai',
    'ThaiFont',
    'Sarabun',
    'sans-serif',
  ];

  static const Color _inkPrimary = Color(0xFF0F172A);
  static const Color _inkSecondary = Color(0xFF475569);
  static const Color _seedTeal = Color(0xFF0F766E);

  /// Monospaced text style for HIS orders, pharmacist notes, and numeric tables.
  static TextStyle monoStyle({
    double fontSize = 13,
    Color color = _inkPrimary,
    FontWeight fontWeight = FontWeight.w400,
    double height = 1.5,
  }) {
    return TextStyle(
      fontFamily: monoFontFamily,
      fontFamilyFallback: fallbackFonts,
      fontSize: fontSize,
      fontWeight: fontWeight,
      height: height,
      color: color,
      fontFeatures: const [FontFeature.tabularFigures()],
    );
  }

  static TextTheme _buildTextTheme() {
    return const TextTheme(
      displaySmall: TextStyle(
        fontFamily: primaryFontFamily,
        fontFamilyFallback: fallbackFonts,
        fontSize: 30,
        fontWeight: FontWeight.w700,
        height: 1.25,
        letterSpacing: -0.3,
        color: _inkPrimary,
      ),
      headlineMedium: TextStyle(
        fontFamily: primaryFontFamily,
        fontFamilyFallback: fallbackFonts,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.3,
        letterSpacing: -0.2,
        color: _inkPrimary,
      ),
      headlineSmall: TextStyle(
        fontFamily: primaryFontFamily,
        fontFamilyFallback: fallbackFonts,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: _inkPrimary,
      ),
      titleLarge: TextStyle(
        fontFamily: primaryFontFamily,
        fontFamilyFallback: fallbackFonts,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.38,
        color: _inkPrimary,
      ),
      titleMedium: TextStyle(
        fontFamily: primaryFontFamily,
        fontFamilyFallback: fallbackFonts,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: _inkPrimary,
      ),
      titleSmall: TextStyle(
        fontFamily: primaryFontFamily,
        fontFamilyFallback: fallbackFonts,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.42,
        color: _inkPrimary,
      ),
      bodyLarge: TextStyle(
        fontFamily: primaryFontFamily,
        fontFamilyFallback: fallbackFonts,
        fontSize: 15.5,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: _inkPrimary,
      ),
      bodyMedium: TextStyle(
        fontFamily: primaryFontFamily,
        fontFamilyFallback: fallbackFonts,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.48,
        color: _inkPrimary,
      ),
      bodySmall: TextStyle(
        fontFamily: primaryFontFamily,
        fontFamilyFallback: fallbackFonts,
        fontSize: 12.5,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: _inkSecondary,
      ),
      labelLarge: TextStyle(
        fontFamily: primaryFontFamily,
        fontFamilyFallback: fallbackFonts,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: _inkPrimary,
      ),
      labelMedium: TextStyle(
        fontFamily: primaryFontFamily,
        fontFamilyFallback: fallbackFonts,
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
        height: 1.35,
        color: _inkSecondary,
      ),
      labelSmall: TextStyle(
        fontFamily: primaryFontFamily,
        fontFamilyFallback: fallbackFonts,
        fontSize: 11.5,
        fontWeight: FontWeight.w500,
        height: 1.35,
        color: _inkSecondary,
      ),
    );
  }

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: _seedTeal,
      brightness: Brightness.light,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      fontFamily: primaryFontFamily,
      fontFamilyFallback: fallbackFonts,
      textTheme: _buildTextTheme(),
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 1,
        titleTextStyle: TextStyle(
          fontFamily: primaryFontFamily,
          fontFamilyFallback: fallbackFonts,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          height: 1.35,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
