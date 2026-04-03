import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color Tokens
  static const Color cfNavy = Color(0xFF0F1729);
  static const Color cfRed = Color(0xFFE24B4A);
  static const Color cfAmber = Color(0xFFEF9F27);
  static const Color cfGreen = Color(0xFF1D9E75);
  static const Color cfBlue = Color(0xFF3B82F6);
  static const Color cfSurface = Color(0xFFF5F6FA);
  static const Color cfCard = Color(0xFFFFFFFF);
  static const Color cfBorder = Color(0xFFEBEBEB);
  static const Color cfMuted = Color(0xFF888888);
  static const Color cfDim = Color(0xFFBBBBBB);

  // Spacing Scale
  static const double s4 = 4.0;
  static const double s8 = 8.0;
  static const double s12 = 12.0;
  static const double s16 = 16.0;
  static const double s20 = 20.0;
  static const double s24 = 24.0;
  static const double s32 = 32.0;
  static const double s40 = 40.0;

  // Border Radius
  static const double r8 = 8.0;
  static const double r12 = 12.0;
  static const double r14 = 14.0;
  static const double r20 = 20.0;
  static const double r40 = 40.0;

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: cfNavy,
      scaffoldBackgroundColor: cfSurface,
      cardColor: cfCard,
      dividerColor: cfBorder,
      colorScheme: ColorScheme.light(
        primary: cfNavy,
        secondary: cfRed,
        surface: cfCard,
        error: cfRed,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: cfNavy,
        onError: Colors.white,
      ),
      textTheme: GoogleFonts.dmSansTextTheme().copyWith(
        displayLarge: GoogleFonts.dmSans(fontWeight: FontWeight.w600, color: cfNavy),
        displayMedium: GoogleFonts.dmSans(fontWeight: FontWeight.w600, color: cfNavy),
        displaySmall: GoogleFonts.dmSans(fontWeight: FontWeight.w600, color: cfNavy),
        headlineLarge: GoogleFonts.dmSans(fontWeight: FontWeight.w600, color: cfNavy),
        headlineMedium: GoogleFonts.dmSans(fontWeight: FontWeight.w600, color: cfNavy),
        headlineSmall: GoogleFonts.dmSans(fontWeight: FontWeight.w600, color: cfNavy),
        titleLarge: GoogleFonts.dmSans(fontWeight: FontWeight.w600, color: cfNavy),
        titleMedium: GoogleFonts.dmSans(fontWeight: FontWeight.w500, color: cfNavy), // labels
        titleSmall: GoogleFonts.dmSans(fontWeight: FontWeight.w500, color: cfNavy),
        bodyLarge: GoogleFonts.dmSans(fontWeight: FontWeight.w400, color: cfNavy), // body
        bodyMedium: GoogleFonts.dmSans(fontWeight: FontWeight.w400, color: cfNavy),
        bodySmall: GoogleFonts.dmSans(fontWeight: FontWeight.w400, color: cfMuted),
        labelLarge: GoogleFonts.dmSans(fontWeight: FontWeight.w500, color: cfNavy),
        labelMedium: GoogleFonts.dmSans(fontWeight: FontWeight.w500, color: cfMuted),
        labelSmall: GoogleFonts.dmSans(fontWeight: FontWeight.w500, color: cfDim),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: cfNavy,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        color: cfCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(r14),
          side: const BorderSide(color: cfBorder, width: 0.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: cfRed,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(r14),
          ),
          textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w600, fontSize: 15),
          padding: const EdgeInsets.symmetric(horizontal: s24, vertical: s16),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: cfNavy,
          textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: cfNavy,
          side: const BorderSide(color: cfBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(r12),
          ),
          textStyle: GoogleFonts.dmSans(fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cfCard,
        contentPadding: const EdgeInsets.symmetric(horizontal: s16, vertical: s12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r12),
          borderSide: const BorderSide(color: cfBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r12),
          borderSide: const BorderSide(color: cfBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r12),
          borderSide: const BorderSide(color: cfRed),
        ),
        hintStyle: GoogleFonts.dmSans(color: cfMuted, fontWeight: FontWeight.w400),
      ),
    );
  }
}
