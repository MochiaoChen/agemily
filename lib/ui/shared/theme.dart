import 'package:flutter/material.dart';

class AppTheme {
  // memo-ios sage green palette
  static const _accent = Color(0xFF5A7863);
  static const _accentSoft = Color(0xFFEBF4DD);

  static ThemeData light() {
    const bg = Color(0xFFFAF9F5);
    const surface = Color(0xFFFFFFFF);
    const textPrimary = Color(0xFF1A1A1A);
    const textSecondary = Color(0xFF8E8E93); // iOS secondaryLabel

    const fontFamily = 'serif';

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.light(
        primary: _accent,
        onPrimary: Colors.white,
        secondary: _accent,
        surface: surface,
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
        outline: const Color(0xFFD1D1D6), // iOS separator
        outlineVariant: const Color(0xFFE5E5EA), // iOS opaqueSeparator
        surfaceContainerHighest: const Color(0xFFEDEDEB),
        surfaceContainerHigh: const Color(0xFFF2F2F0),
        surfaceContainerLow: const Color(0xFFF7F7F5),
        error: const Color(0xFFFF3B30), // iOS red
        errorContainer: const Color(0xFFFEE2E2),
        onErrorContainer: const Color(0xFF991B1B),
        primaryContainer: _accentSoft,
        onPrimaryContainer: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: bg,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: surface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: const Color(0xFFF2F2F0),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      dividerColor: const Color(0xFFE5E5EA),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textPrimary, fontSize: 18, height: 1.5),
        bodyMedium: TextStyle(color: textPrimary, fontSize: 17, height: 1.5),
        bodySmall: TextStyle(color: textSecondary, fontSize: 13, height: 1.4),
        titleLarge: TextStyle(
            color: textPrimary, fontSize: 22, fontWeight: FontWeight.w600, height: 1.3),
        titleMedium: TextStyle(
            color: textPrimary, fontSize: 17, fontWeight: FontWeight.w600, height: 1.4),
        labelSmall: TextStyle(
            color: textSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        labelMedium: TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  static ThemeData dark() {
    const bg = Color(0xFF1C1C1E); // iOS dark background
    const surface = Color(0xFF2C2C2E); // iOS dark elevated
    const textPrimary = Color(0xFFE5E5E7);
    const textSecondary = Color(0xFF8E8E93);

    const fontFamily = 'serif';

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.dark(
        primary: const Color(0xFF7A9B83), // lighter sage for dark mode
        onPrimary: Colors.white,
        secondary: const Color(0xFF7A9B83),
        surface: surface,
        onSurface: textPrimary,
        onSurfaceVariant: textSecondary,
        outline: const Color(0xFF38383A), // iOS dark separator
        outlineVariant: const Color(0xFF2C2C2E),
        surfaceContainerHighest: const Color(0xFF3A3A3C),
        surfaceContainerHigh: const Color(0xFF323234),
        surfaceContainerLow: const Color(0xFF242426),
        error: const Color(0xFFFF453A), // iOS dark red
        errorContainer: const Color(0xFF7F1D1D),
        onErrorContainer: const Color(0xFFFECACA),
        primaryContainer: const Color(0xFF2A3A2E),
        onPrimaryContainer: textPrimary,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        backgroundColor: bg,
        foregroundColor: textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      drawerTheme: const DrawerThemeData(
        backgroundColor: surface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(24),
          borderSide: BorderSide.none,
        ),
        filled: true,
        fillColor: const Color(0xFF3A3A3C),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      dividerColor: const Color(0xFF38383A),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: textPrimary, fontSize: 18, height: 1.5),
        bodyMedium: TextStyle(color: textPrimary, fontSize: 17, height: 1.5),
        bodySmall: TextStyle(color: textSecondary, fontSize: 13, height: 1.4),
        titleLarge: TextStyle(
            color: textPrimary, fontSize: 22, fontWeight: FontWeight.w600, height: 1.3),
        titleMedium: TextStyle(
            color: textPrimary, fontSize: 17, fontWeight: FontWeight.w600, height: 1.4),
        labelSmall: TextStyle(
            color: textSecondary, fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5),
        labelMedium: TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }
}
