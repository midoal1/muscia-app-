import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Gazelle Red / الأحمر الغزالي Palette
  static const Color gazelleRedDark = Color(0xFF670018);
  static const Color gazelleRed = Color(0xFF8B0021); // Primary Red
  static const Color gazelleRedBright = Color(0xFFB31336);
  static const Color gazelleRedVibrant = Color(0xFFD61840);
  static const Color gazelleRedGlow = Color(0xFFFF2E54);

  // Obsidian & Deep Blacks
  static const Color background = Color(0xFF0A0A0D);
  static const Color surface = Color(0xFF131317);
  static const Color surfaceLight = Color(0xFF1C1C22);
  static const Color surfaceHighlight = Color(0xFF262630);

  // Accents & Borders
  static const Color borderSubtle = Color(0x22FFFFFF);
  static const Color borderHighlight = Color(0x33B31336);

  // Whites & Silvers
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB3B3BE);
  static const Color textTertiary = Color(0xFF757582);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [gazelleRedBright, gazelleRed],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient emotionalPlayerGradient = LinearGradient(
    colors: [
      Color(0xFF4A0010),
      Color(0xFF1B0509),
      Color(0xFF0A0A0D),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient miniPlayerGradient = LinearGradient(
    colors: [
      Color(0xEE1E080C),
      Color(0xEE141418),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}

class AppTheme {
  static ThemeData get darkTheme {
    final baseTextTheme = GoogleFonts.cairoTextTheme(ThemeData.dark().textTheme);

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      primaryColor: AppColors.gazelleRed,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.gazelleRedBright,
        secondary: AppColors.gazelleRedVibrant,
        surface: AppColors.surface,
        onPrimary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      textTheme: baseTextTheme.apply(
        bodyColor: AppColors.textPrimary,
        displayColor: AppColors.textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.gazelleRedGlow,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 10,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.gazelleRedVibrant,
        inactiveTrackColor: Colors.white12,
        thumbColor: Colors.white,
        trackHeight: 3.5,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
        overlayColor: AppColors.gazelleRedGlow.withValues(alpha: 0.2),
      ),
    );
  }
}
