import 'package:flutter/material.dart';

class AppTheme {
  // Deep atmospheric colors
  static const Color primaryDark = Color(0xFF050B14); 
  static const Color secondaryDark = Color(0xFF0D1B2A);
  // Default fallback accent color
  static const Color defaultAccentColor = Color(0xFF0EA5E9); 
  static const Color warningColor = Color(0xFFFFB300);
  static const Color criticalColor = Color(0xFFFF1744);
  static const Color textLight = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF8A9BB3);

  // Glassmorphism styling
  static BoxDecoration get glassDecoration {
    return BoxDecoration(
      color: Colors.white.withOpacity(0.08), // Slightly more opaque for better contrast
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: Colors.white.withOpacity(0.15), width: 1.5),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          blurRadius: 10,
          spreadRadius: -2,
        ),
      ],
    );
  }

  static ThemeData getDarkTheme(Color accentColor) {
    return ThemeData(
      brightness: Brightness.dark,
      primaryColor: primaryDark,
      scaffoldBackgroundColor: primaryDark,
      colorScheme: ColorScheme.dark(
        primary: accentColor,
        secondary: accentColor,
        surface: secondaryDark,
        error: criticalColor,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textLight,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
      cardTheme: CardThemeData(
        color: secondaryDark.withOpacity(0.5),
        elevation: 0, // Elevation handled by glassDecoration if needed
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
        ),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: secondaryDark.withOpacity(0.8),
        selectedItemColor: accentColor,
        unselectedItemColor: textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: primaryDark,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.1),
          elevation: 8,
          shadowColor: accentColor.withOpacity(0.5),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: accentColor,
        inactiveTrackColor: secondaryDark,
        thumbColor: Colors.white,
        overlayColor: accentColor.withOpacity(0.2),
        trackHeight: 8,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return Colors.white;
          return textMuted;
        }),
        trackColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) return accentColor;
          return secondaryDark;
        }),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(color: textLight, fontSize: 36, fontWeight: FontWeight.w800),
        titleLarge: TextStyle(color: textLight, fontSize: 20, fontWeight: FontWeight.w700),
        bodyLarge: TextStyle(color: textLight, fontSize: 16),
        bodyMedium: TextStyle(color: textMuted, fontSize: 14),
      ),
    );
  }
}
