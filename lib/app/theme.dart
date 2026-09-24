import 'package:flutter/material.dart';

class OpenAskTheme {
  static const primaryColor = Color(0xFF4F46E5); // Indigo 600
  static const secondaryColor = Color(0xFF7C3AED); // Violet 600
  static const successColor = Color(0xFF059669); // Emerald 600
  static const dangerColor = Color(0xFFE11D48); // Rose 600

  static final lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.light,
      primary: primaryColor,
      secondary: secondaryColor,
      surface: Colors.white,
      background: const Color(0xFFF9FAFB),
    ),
    scaffoldBackgroundColor: const Color(0xFFF9FAFB),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: Color(0xFF111827),
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
    ),
  );

  static final darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      brightness: Brightness.dark,
      primary: const Color(0xFF6366F1),
      secondary: const Color(0xFF8B5CF6),
      surface: const Color(0xFF18181B),
      background: const Color(0xFF09090B),
    ),
    scaffoldBackgroundColor: const Color(0xFF09090B),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF18181B),
      foregroundColor: Color(0xFFF4F4F5),
      elevation: 0,
      centerTitle: false,
    ),
    cardTheme: CardTheme(
      color: const Color(0xFF18181B),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF27272A)),
      ),
    ),
  );
}
