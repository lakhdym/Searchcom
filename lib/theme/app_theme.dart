import 'package:flutter/material.dart';

import '../services/theme_service.dart';

class AppTheme {
  static const Color primaryViolet = Color(0xFF7C3AED);
  static const Color successGreen = Color(0xFF10B981);
  static const Color errorRed = Color(0xFFEF4444);

  static const Color _lightPrimaryVioletLight = Color(0xFFEDE9FE);
  static const Color _lightPrimaryVioletLighter = Color(0xFFDDD6FE);
  static const Color _lightPrimaryVioletMedium = Color(0xFFA78BFA);
  static const Color _lightPrimaryVioletDark = Color(0xFF6D28D9);
  static const Color _lightBackgroundWhite = Color(0xFFFFFFFF);
  static const Color _lightBackgroundGray = Color(0xFFF9FAFB);
  static const Color _lightTextPrimary = Color(0xFF030213);
  static const Color _lightTextSecondary = Color(0xFF717182);
  static const Color _lightTextMuted = Color(0xFF9CA3AF);
  static const Color _lightBorderLight = Color(0xFFE5E7EB);
  static const Color _lightBorderMedium = Color(0xFFD1D5DB);
  static const Color _lightInputBackground = Color(0xFFF3F3F5);

  static const Color _darkPrimaryVioletLight = Color(0xFF24153F);
  static const Color _darkPrimaryVioletLighter = Color(0xFF312055);
  static const Color _darkPrimaryVioletMedium = Color(0xFFC4B5FD);
  static const Color _darkPrimaryVioletDark = Color(0xFFE9DDFF);
  static const Color _darkBackgroundWhite = Color(0xFF111827);
  static const Color _darkBackgroundGray = Color(0xFF0B1120);
  static const Color _darkTextPrimary = Color(0xFFF8FAFC);
  static const Color _darkTextSecondary = Color(0xFFCBD5E1);
  static const Color _darkTextMuted = Color(0xFF94A3B8);
  static const Color _darkBorderLight = Color(0xFF273449);
  static const Color _darkBorderMedium = Color(0xFF364152);
  static const Color _darkInputBackground = Color(0xFF0F172A);

  static bool get _isDark => ThemeService.instance.isDark;

  static Color get primaryVioletLight =>
      _isDark ? _darkPrimaryVioletLight : _lightPrimaryVioletLight;
  static Color get primaryVioletLighter =>
      _isDark ? _darkPrimaryVioletLighter : _lightPrimaryVioletLighter;
  static Color get primaryVioletMedium =>
      _isDark ? _darkPrimaryVioletMedium : _lightPrimaryVioletMedium;
  static Color get primaryVioletDark =>
      _isDark ? _darkPrimaryVioletDark : _lightPrimaryVioletDark;

  static Color get backgroundWhite =>
      _isDark ? _darkBackgroundWhite : _lightBackgroundWhite;
  static Color get backgroundGray =>
      _isDark ? _darkBackgroundGray : _lightBackgroundGray;
  static Color get textPrimary =>
      _isDark ? _darkTextPrimary : _lightTextPrimary;
  static Color get textSecondary =>
      _isDark ? _darkTextSecondary : _lightTextSecondary;
  static Color get textMuted => _isDark ? _darkTextMuted : _lightTextMuted;
  static Color get borderLight =>
      _isDark ? _darkBorderLight : _lightBorderLight;
  static Color get borderMedium =>
      _isDark ? _darkBorderMedium : _lightBorderMedium;
  static Color get inputBackground =>
      _isDark ? _darkInputBackground : _lightInputBackground;

  static ThemeData get lightTheme => _buildTheme(brightness: Brightness.light);
  static ThemeData get darkTheme => _buildTheme(brightness: Brightness.dark);

  static ThemeData getTheme() {
    return lightTheme;
  }

  static ThemeData _buildTheme({required Brightness brightness}) {
    final isDark = brightness == Brightness.dark;
    final surface = isDark ? _darkBackgroundWhite : _lightBackgroundWhite;
    final scaffold = isDark ? _darkBackgroundGray : _lightBackgroundGray;
    final textPrimaryColor = isDark ? _darkTextPrimary : _lightTextPrimary;
    final textSecondaryColor = isDark
        ? _darkTextSecondary
        : _lightTextSecondary;
    final textMutedColor = isDark ? _darkTextMuted : _lightTextMuted;
    final borderLightColor = isDark ? _darkBorderLight : _lightBorderLight;
    final borderMediumColor = isDark ? _darkBorderMedium : _lightBorderMedium;
    final inputFill = isDark ? _darkInputBackground : _lightInputBackground;
    final secondary = isDark
        ? _darkPrimaryVioletLight
        : _lightPrimaryVioletLight;

    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: primaryViolet,
          brightness: brightness,
        ).copyWith(
          primary: primaryViolet,
          onPrimary: Colors.white,
          secondary: secondary,
          onSecondary: textPrimaryColor,
          surface: surface,
          onSurface: textPrimaryColor,
          onSurfaceVariant: textSecondaryColor,
          outline: borderMediumColor,
          outlineVariant: borderLightColor,
          shadow: Colors.black,
          error: errorRed,
          onError: Colors.white,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffold,
      canvasColor: surface,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: textPrimaryColor,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: textPrimaryColor,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        modalBackgroundColor: surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0.35 : 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderLightColor, width: 1),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryViolet,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: textPrimaryColor,
          side: BorderSide(color: borderMediumColor),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputFill,
        hintStyle: TextStyle(color: textMutedColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderLightColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderLightColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryViolet, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      iconTheme: IconThemeData(color: textSecondaryColor, size: 24),
      listTileTheme: ListTileThemeData(
        iconColor: textSecondaryColor,
        textColor: textPrimaryColor,
      ),
      dividerColor: borderLightColor,
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryViolet;
          }
          return isDark ? _darkTextSecondary : Colors.white;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryViolet.withValues(alpha: 0.45);
          }
          return borderMediumColor;
        }),
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textPrimaryColor,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textPrimaryColor,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: textPrimaryColor,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: textSecondaryColor,
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: textMutedColor,
        ),
      ),
      shadowColor: Colors.black.withValues(alpha: isDark ? 0.35 : 0.1),
    );
  }

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
