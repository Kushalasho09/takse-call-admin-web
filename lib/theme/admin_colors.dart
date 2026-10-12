import 'package:flutter/material.dart';
import '../services/admin_state_service.dart';

class AdminColors {
  static bool get isDark => AdminStateService.instance.isDarkMode;

  // Backgrounds:
  // Light Mode (Customer Web): 0xFFF4F6F9
  // Dark Mode (Mobile App): 0xFF111318
  static Color get background => isDark ? const Color(0xFF111318) : const Color(0xFFF4F6F9);

  // Surface / Cards:
  // Light Mode (Customer Web): Pure White 0xFFFFFFFF
  // Dark Mode (Mobile App): Premium Card Slate 0xFF1B1D26
  static Color get surface => isDark ? const Color(0xFF1B1D26) : const Color(0xFFFFFFFF);

  // Elevated Surfaces / Hovers:
  // Light Mode: 0xFFF8FAFC
  // Dark Mode: 0xFF232634
  static Color get surfaceElevated => isDark ? const Color(0xFF232634) : const Color(0xFFF8FAFC);

  // Subtle Container / Input Fill:
  // Light Mode: 0xFFF1F5F9
  // Dark Mode: 0xFF1E202B
  static Color get surfaceSubtle => isDark ? const Color(0xFF1E202B) : const Color(0xFFF1F5F9);

  // Borders:
  // Light Mode (Customer Web): 0xFFE2E8F0
  // Dark Mode (Mobile App): 0xFF282B3C
  static Color get border => isDark ? const Color(0xFF282B3C) : const Color(0xFFE2E8F0);
  static Color get borderBright => isDark ? const Color(0xFF3F445E) : const Color(0xFFCBD5E1);

  // Brand Accents (Vibrant Royal Blue & Cyan from app and web):
  static const Color primary = Color(0xFF2563EB); // Royal Blue
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryGlow = Color(0x332563EB);
  static const Color accentCyan = Color(0xFF0D9488); // Teal
  static const Color accentPurple = Color(0xFF8B5CF6);

  // Status Colors:
  static const Color success = Color(0xFF10B981); // Emerald Green
  static Color get successSubtle => isDark ? const Color(0x2210B981) : const Color(0xFFECFDF5);
  static const Color warning = Color(0xFFF59E0B); // Amber
  static Color get warningSubtle => isDark ? const Color(0x22F59E0B) : const Color(0xFFFFFBEB);
  static const Color error = Color(0xFFEF4444); // Crimson
  static Color get errorSubtle => isDark ? const Color(0x22EF4444) : const Color(0xFFFEF2F2);
  static const Color info = Color(0xFF38BDF8);

  // Typography:
  // Light Mode (Customer Web): 0xFF0F172A
  // Dark Mode (Mobile App): 0xFFFFFFFF
  static Color get textPrimary => isDark ? const Color(0xFFFFFFFF) : const Color(0xFF0F172A);

  // Secondary text:
  // Light Mode (Customer Web): 0xFF64748B
  // Dark Mode (Mobile App): 0xFFCBD5E1
  static Color get textSecondary => isDark ? const Color(0xFFCBD5E1) : const Color(0xFF64748B);

  // Tertiary / Muted:
  // Light Mode: 0xFF94A3B8
  // Dark Mode: 0xFF828FA3
  static Color get textTertiary => isDark ? const Color(0xFF828FA3) : const Color(0xFF94A3B8);
  static Color get textMuted => isDark ? const Color(0xFF5A6679) : const Color(0xFF94A3B8);

  // Decorative Badges (Connect Code):
  // Light Mode (Customer Web): 0xFFFEF3C7 bg, 0xFFD97706 text
  // Dark Mode (Mobile App): 0xFF1E293B bg, 0xFFFBBF24 text
  static Color get codePillBg => isDark ? const Color(0xFF1E293B) : const Color(0xFFFEF3C7);
  static Color get codePillText => isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706);
}
