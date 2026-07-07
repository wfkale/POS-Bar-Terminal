import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const background = Color(0xFF0f1419);
  static const surface = Color(0xFF1a2332);
  static const surfaceLight = Color(0xFF243044);
  static const accent = Color(0xFFf59e0b);
  static const accentMuted = Color(0xFFd97706);
  static const textPrimary = Color(0xFFf8fafc);
  static const textSecondary = Color(0xFF94a3b8);
  static const success = Color(0xFF22c55e);
  static const danger = Color(0xFFef4444);

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true);
    return base.copyWith(
      scaffoldBackgroundColor: background,
      colorScheme: base.colorScheme.copyWith(
        primary: accent,
        secondary: accentMuted,
        surface: surface,
      ),
      textTheme: GoogleFonts.dmSansTextTheme(base.textTheme).apply(
        bodyColor: textPrimary,
        displayColor: textPrimary,
      ),
      cardTheme: CardTheme(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: background,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  static Color parseHex(String hex) {
    final value = hex.replaceFirst('#', '');
    return Color(int.parse('FF$value', radix: 16));
  }
}
