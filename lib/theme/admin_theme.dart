import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'admin_colors.dart';

class AdminTheme {
  static ThemeData get lightTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.light().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF4F6F9), // Customer web background
      primaryColor: AdminColors.primary,
      colorScheme: const ColorScheme.light(
        primary: AdminColors.primary,
        secondary: AdminColors.accentCyan,
        surface: Color(0xFFFFFFFF), // Customer web card surface
        error: AdminColors.error,
      ),
      textTheme: baseTextTheme.copyWith(
        headlineLarge: GoogleFonts.outfit(
          color: const Color(0xFF0F172A),
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.outfit(
          color: const Color(0xFF0F172A),
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleLarge: GoogleFonts.outfit(
          color: const Color(0xFF0F172A),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: GoogleFonts.inter(
          color: const Color(0xFF0F172A),
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.inter(
          color: const Color(0xFF0F172A),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: GoogleFonts.inter(
          color: const Color(0xFF64748B),
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: GoogleFonts.inter(
          color: const Color(0xFF94A3B8),
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.inter(
          color: const Color(0xFF94A3B8),
          fontSize: 13,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AdminColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AdminColors.error, width: 1),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFFFFFFFF),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE2E8F0),
        thickness: 1,
      ),
    );
  }

  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.interTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF111318), // Mobile app background
      primaryColor: AdminColors.primary,
      colorScheme: const ColorScheme.dark(
        primary: AdminColors.primary,
        secondary: AdminColors.accentCyan,
        surface: Color(0xFF1B1D26), // Mobile app card surface
        error: AdminColors.error,
      ),
      textTheme: baseTextTheme.copyWith(
        headlineLarge: GoogleFonts.outfit(
          color: const Color(0xFFFFFFFF),
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
        headlineMedium: GoogleFonts.outfit(
          color: const Color(0xFFFFFFFF),
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
        ),
        titleLarge: GoogleFonts.outfit(
          color: const Color(0xFFFFFFFF),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        titleMedium: GoogleFonts.inter(
          color: const Color(0xFFFFFFFF),
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: GoogleFonts.inter(
          color: const Color(0xFFFFFFFF),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        bodyMedium: GoogleFonts.inter(
          color: const Color(0xFFCBD5E1),
          fontSize: 13,
          fontWeight: FontWeight.w400,
        ),
        bodySmall: GoogleFonts.inter(
          color: const Color(0xFF828FA3),
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E202B),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.inter(
          color: const Color(0xFF828FA3),
          fontSize: 13,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF282B3C), width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AdminColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AdminColors.error, width: 1),
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1B1D26),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF282B3C), width: 1),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF282B3C),
        thickness: 1,
      ),
    );
  }
}
