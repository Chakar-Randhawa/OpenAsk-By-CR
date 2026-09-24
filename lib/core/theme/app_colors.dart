import 'package:flutter/material.dart';

/// Calm, professional color palette for OpenAsk.
class AppColors {
  AppColors._();

  // Primary Brand Colors - Deep Indigo / Slate Blue
  static const Color primary = Color(0xFF1E3A8A); // Deep Slate Navy
  static const Color primaryLight = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF172554);

  // Secondary Accents
  static const Color secondary = Color(0xFF0F766E); // Deep Teal
  static const Color secondaryLight = Color(0xFF14B8A6);

  // Status & Semantic
  static const Color success = Color(0xFF16A34A); // Forest Green
  static const Color successBg = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFD97706); // Amber
  static const Color warningBg = Color(0xFFFEF3C7);
  static const Color error = Color(0xFFDC2626); // Crimson
  static const Color errorBg = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF2563EB); // Royal Blue

  // Light Mode Neutrals
  static const Color lightBackground = Color(0xFFF8FAFC); // Slate 50
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF1F5F9); // Slate 100
  static const Color lightBorder = Color(0xFFE2E8F0); // Slate 200
  static const Color lightTextPrimary = Color(0xFF0F172A); // Slate 900
  static const Color lightTextSecondary = Color(0xFF475569); // Slate 600
  static const Color lightTextTertiary = Color(0xFF94A3B8); // Slate 400

  // Dark Mode Neutrals
  static const Color darkBackground = Color(0xFF0F172A); // Slate 900
  static const Color darkSurface = Color(0xFF1E293B); // Slate 800
  static const Color darkSurfaceVariant = Color(0xFF334155); // Slate 700
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFFCBD5E1);
  static const Color darkTextTertiary = Color(0xFF64748B);
}
