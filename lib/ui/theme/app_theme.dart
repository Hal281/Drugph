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

  // Core Brand & Surfaces (Clinical Precision — UpToDate / Lexicomp / MDCalc)
  static const Color primaryTeal = Color(0xFF0F766E);
  static const Color primaryTealDark = Color(0xFF115E59);
  static const Color primaryTealSoft = Color(0xFFF0FDFA);
  static const Color primaryTealBorder = Color(0xFF99F6E4);
  static const Color clinicalNavy = Color(0xFF0F172A);

  static const Color inkPrimary = Color(0xFF0F172A);
  static const Color inkSecondary = Color(0xFF475569);
  static const Color inkMuted = Color(0xFF64748B);

  static const Color surfaceBackground = Color(0xFFF8FAFC);
  static const Color surfaceCard = Colors.white;
  static const Color surfaceSubtle = Color(0xFFF1F5F9);
  static const Color borderDefault = Color(0xFFE2E8F0);
  static const Color borderStrong = Color(0xFFCBD5E1);

  // Semantic Clinical Status Tokens (Strictly Reserved for Safety / Dose State)
  static const Color statusSafe = Color(0xFF059669);
  static const Color statusSafeBg = Color(0xFFECFDF5);
  static const Color statusSafeBorder = Color(0xFFA7F3D0);

  static const Color statusInfo = Color(0xFF0284C7);
  static const Color statusInfoBg = Color(0xFFF0F9FF);
  static const Color statusInfoBorder = Color(0xFFBAE6FD);

  static const Color statusWarning = Color(0xFFD97706);
  static const Color statusWarningBg = Color(0xFFFFFBEB);
  static const Color statusWarningBorder = Color(0xFFFDE68A);

  static const Color statusCritical = Color(0xFFDC2626);
  static const Color statusCriticalBg = Color(0xFFFEF2F2);
  static const Color statusCriticalBorder = Color(0xFFFECACA);

  /// Monospaced text style for HIS orders, pharmacist notes, and numeric tables.
  static TextStyle monoStyle({
    double fontSize = 13,
    Color color = inkPrimary,
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
        color: inkPrimary,
      ),
      headlineMedium: TextStyle(
        fontFamily: primaryFontFamily,
        fontFamilyFallback: fallbackFonts,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.3,
        letterSpacing: -0.2,
        color: inkPrimary,
      ),
      headlineSmall: TextStyle(
        fontFamily: primaryFontFamily,
        fontFamilyFallback: fallbackFonts,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: inkPrimary,
      ),
      titleLarge: TextStyle(
        fontFamily: primaryFontFamily,
        fontFamilyFallback: fallbackFonts,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 1.38,
        color: inkPrimary,
      ),
      titleMedium: TextStyle(
        fontFamily: primaryFontFamily,
        fontFamilyFallback: fallbackFonts,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: inkPrimary,
      ),
      titleSmall: TextStyle(
        fontFamily: primaryFontFamily,
        fontFamilyFallback: fallbackFonts,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.42,
        color: inkPrimary,
      ),
      bodyLarge: TextStyle(
        fontFamily: primaryFontFamily,
        fontFamilyFallback: fallbackFonts,
        fontSize: 15.5,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: inkPrimary,
      ),
      bodyMedium: TextStyle(
        fontFamily: primaryFontFamily,
        fontFamilyFallback: fallbackFonts,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.48,
        color: inkPrimary,
      ),
      bodySmall: TextStyle(
        fontFamily: primaryFontFamily,
        fontFamilyFallback: fallbackFonts,
        fontSize: 12.5,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: inkSecondary,
      ),
      labelLarge: TextStyle(
        fontFamily: primaryFontFamily,
        fontFamilyFallback: fallbackFonts,
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.35,
        color: inkPrimary,
      ),
      labelMedium: TextStyle(
        fontFamily: primaryFontFamily,
        fontFamilyFallback: fallbackFonts,
        fontSize: 12.5,
        fontWeight: FontWeight.w500,
        height: 1.35,
        color: inkSecondary,
      ),
      labelSmall: TextStyle(
        fontFamily: primaryFontFamily,
        fontFamilyFallback: fallbackFonts,
        fontSize: 11.5,
        fontWeight: FontWeight.w500,
        height: 1.35,
        color: inkSecondary,
      ),
    );
  }

  static ThemeData get light {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primaryTeal,
      primary: primaryTeal,
      surface: surfaceCard,
      brightness: Brightness.light,
    );

    return ThemeData(
      colorScheme: colorScheme,
      useMaterial3: true,
      fontFamily: primaryFontFamily,
      fontFamilyFallback: fallbackFonts,
      textTheme: _buildTextTheme(),
      scaffoldBackgroundColor: surfaceBackground,
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryTeal,
        foregroundColor: Colors.white,
        centerTitle: false,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          fontFamily: primaryFontFamily,
          fontFamilyFallback: fallbackFonts,
          fontSize: 17,
          fontWeight: FontWeight.w600,
          height: 1.35,
          color: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: surfaceCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: borderDefault),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceCard,
        selectedColor: primaryTealSoft,
        side: const BorderSide(color: borderDefault),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        labelStyle: const TextStyle(
          fontFamily: primaryFontFamily,
          fontFamilyFallback: fallbackFonts,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: inkSecondary,
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          side: const WidgetStatePropertyAll(BorderSide(color: borderStrong)),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderStrong),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: borderStrong),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: primaryTeal, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: borderDefault,
        thickness: 1,
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: clinicalNavy,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}
