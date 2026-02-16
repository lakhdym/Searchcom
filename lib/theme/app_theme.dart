import 'package:flutter/material.dart';

/// Thème de l'application inspiré du design existant
/// Couleurs principales : Violet (#7C3AED) avec variantes
class AppTheme {
  // Couleurs principales (inspirées du thème CSS)
  static const Color primaryViolet = Color(0xFF7C3AED); // violet-600
  static const Color primaryVioletLight = Color(0xFFEDE9FE); // violet-50
  static const Color primaryVioletLighter = Color(0xFFDDD6FE); // violet-100
  static const Color primaryVioletDark = Color(0xFF6D28D9); // violet-700
  static const Color primaryVioletMedium = Color(0xFFA78BFA); // violet-400
  
  // Couleurs de fond
  static const Color backgroundWhite = Color(0xFFFFFFFF);
  static const Color backgroundGray = Color(0xFFF9FAFB); // gray-50
  
  // Couleurs de texte
  static const Color textPrimary = Color(0xFF030213); // presque noir
  static const Color textSecondary = Color(0xFF717182); // gray-500
  static const Color textMuted = Color(0xFF9CA3AF); // gray-400
  
  // Couleurs de bordure
  static const Color borderLight = Color(0xFFE5E7EB); // gray-200
  static const Color borderMedium = Color(0xFFD1D5DB); // gray-300
  
  // Couleurs d'input
  static const Color inputBackground = Color(0xFFF3F3F5);
  
  // Couleurs d'état
  static const Color successGreen = Color(0xFF10B981); // green-500
  static const Color errorRed = Color(0xFFEF4444); // red-500
  
  /// Retourne le thème Material 3 configuré
  static ThemeData getTheme() {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryViolet,
        brightness: Brightness.light,
        primary: primaryViolet,
        onPrimary: Colors.white,
        secondary: primaryVioletLight,
        onSecondary: textPrimary,
        surface: backgroundWhite,
        onSurface: textPrimary,
        background: backgroundGray,
        onBackground: textPrimary,
        error: errorRed,
        onError: Colors.white,
      ),
      
      // Configuration de l'AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: backgroundWhite,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      
      // Configuration des cartes
      cardTheme: CardTheme(
        color: backgroundWhite,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: borderLight, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      
      // Configuration des boutons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryViolet,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Configuration des champs de texte
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputBackground,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: borderLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryViolet, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      
      // Configuration des icônes
      iconTheme: const IconThemeData(
        color: textSecondary,
        size: 24,
      ),
      
      // Typographie
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimary,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textPrimary,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textSecondary,
        ),
      ),
      
      // Configuration des ombres
      shadowColor: Colors.black.withOpacity(0.1),
    );
  }
  
  // Constantes de design
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusXLarge = 24.0;
  
  static const double spacingXS = 4.0;
  static const double spacingSM = 8.0;
  static const double spacingMD = 16.0;
  static const double spacingLG = 24.0;
  static const double spacingXL = 32.0;
}
