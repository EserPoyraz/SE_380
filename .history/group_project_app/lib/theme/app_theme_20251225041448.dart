import 'package:flutter/material.dart';

class AppTheme {
  // ================= COLORS =================
  static const Color background = Color(0xFF0B0B14);
  static const Color surface = Color(0xFF1A1A2E);

  static const Color neonPurple = Color(0xFF7B4DFF);
  static const Color neonBlue = Color(0xFF00D2FF);
  static const Color neonOrange = Color(0xFFFF8C42);
  static const Color neonGreen = Color(0xFF2DFFB3);

  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Colors.white70;

  // ================= GRADIENTS =================
  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0B0B14),
      Color(0xFF141428),
    ],
  );

  static const LinearGradient purpleGlow = LinearGradient(
    colors: [
      Color(0xFF7B4DFF),
      Color(0xFF9D50FF),
    ],
  );

  // ================= THEME =================
  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: background,
    fontFamily: 'Roboto',

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      foregroundColor: Colors.white,
    ),

    textTheme: const TextTheme(
      titleLarge: TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
      titleMedium: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textPrimary,
      ),
      bodyMedium: TextStyle(
        fontSize: 14,
        color: textSecondary,
      ),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: neonPurple,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.bold),
      ),
    ),

    cardTheme: CardThemeData(
  color: surface,
  elevation: 0,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(24),
  ),
),

  );
}
