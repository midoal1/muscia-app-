import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  // Gazelle Red / الأحمر الغزالي الملكي
  static const Color gazelleRedDark = Color(0xFF4D0012);
  static const Color gazelleRedDeep = Color(0xFF6B0019);
  static const Color gazelleRed = Color(0xFF8B0021); // Primary Red
  static const Color gazelleRedBright = Color(0xFFB31336);
  static const Color gazelleRedVibrant = Color(0xFFE51744);
  static const Color gazelleRedGlow = Color(0xFFFF2E54);
  static const Color gazelleRedNeon = Color(0xFFFF4D71);

  // Obsidian & Deep True-Black
  static const Color background = Color(0xFF070709); // Ultra-deep OLED
  static const Color surface = Color(0xFF101015);
  static const Color surfaceLight = Color(0xFF171720);
  static const Color surfaceCard = Color(0xFF1E1E2A);
  static const Color surfaceHighlight = Color(0xFF282838);

  // Accents & Glass Borders
  static const Color borderSubtle = Color(0x1AFFFFFF);
  static const Color borderHighlight = Color(0x40B31336);
  static const Color borderGlow = Color(0x80FF2E54);
  static const Color goldAccent = Color(0xFFFFD700);

  // Whites & Silvers
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFC4C4D0);
  static const Color textTertiary = Color(0xFF7E7E90);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [gazelleRedVibrant, gazelleRedDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient glowingRedGradient = LinearGradient(
    colors: [gazelleRedGlow, gazelleRedBright],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient glassCardGradient = LinearGradient(
    colors: [
      Color(0x33282838),
      Color(0x1A14141E),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroBannerGradient = LinearGradient(
    colors: [
      Color(0x00070709),
      Color(0x804D0012),
      Color(0xF0070709),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient emotionalPlayerGradient = LinearGradient(
    colors: [
      Color(0xFF5A0015),
      Color(0xFF22050B),
      Color(0xFF070709),
    ],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient miniPlayerGradient = LinearGradient(
    colors: [
      Color(0xF0200810),
      Color(0xF012121A),
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  // Shadow Presets
  static List<BoxShadow> get redGlowShadow => [
    BoxShadow(
      color: gazelleRedGlow.withValues(alpha: 0.4),
      blurRadius: 20,
      spreadRadius: 2,
    ),
  ];

  static List<BoxShadow> get cardElevationShadow => [
    const BoxShadow(
      color: Colors.black54,
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];
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
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
        overlayColor: AppColors.gazelleRedGlow.withValues(alpha: 0.25),
      ),
    );
  }
}
