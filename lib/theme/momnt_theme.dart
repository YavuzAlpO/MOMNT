import 'package:flutter/material.dart';

abstract final class MomntColors {
  static const ink = Color(0xFF14304B);
  static const accent = Color(0xFF116293);
  static const background = Color(0xFFEEF6FA);
  static const surface = Color(0xFFFCFEFF);
  static const soft = Color(0xFFE0F0F8);
  static const outline = Color(0xFFC8DCE9);
  static const muted = Color(0xFF4B6176);
  static const success = Color(0xFF16A34A);
  static const successSoft = Color(0xFFDCFCE7);
  static const mapFill = Color(0xFFD8E9F2);
  static const mapPark = Color(0xFFC5DDC8);
  static const mapRoad = surface;
}

ThemeData buildMomntTheme() {
  const fieldBorder = OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(14)),
    borderSide: BorderSide(color: MomntColors.outline),
  );

  return ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    textTheme: const TextTheme(
      headlineSmall: TextStyle(
        color: MomntColors.ink,
        fontSize: 26,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.65,
        height: 1.2,
      ),
      titleLarge: TextStyle(
        color: MomntColors.ink,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.4,
        height: 1.25,
      ),
      titleMedium: TextStyle(
        color: MomntColors.ink,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.15,
        height: 1.3,
      ),
      bodyLarge: TextStyle(fontSize: 16, letterSpacing: 0, height: 1.45),
      bodyMedium: TextStyle(fontSize: 14, letterSpacing: 0, height: 1.4),
      bodySmall: TextStyle(fontSize: 12, letterSpacing: 0, height: 1.35),
      labelLarge: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0),
      labelMedium: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0,
        height: 1.3,
      ),
      labelSmall: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
        height: 1.25,
      ),
    ),
    colorScheme: ColorScheme.fromSeed(
      seedColor: MomntColors.accent,
      primary: MomntColors.accent,
      onPrimary: Colors.white,
      primaryContainer: MomntColors.soft,
      onPrimaryContainer: MomntColors.ink,
      surface: MomntColors.surface,
      onSurface: MomntColors.ink,
      surfaceContainerLow: MomntColors.surface,
      surfaceContainer: MomntColors.soft,
      surfaceContainerHigh: MomntColors.soft,
      onSurfaceVariant: MomntColors.muted,
      outlineVariant: MomntColors.outline,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: MomntColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: MomntColors.background,
      foregroundColor: MomntColors.ink,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
    ),
    bottomAppBarTheme: const BottomAppBarThemeData(
      color: MomntColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: MomntColors.surface,
      selectedItemColor: MomntColors.accent,
      unselectedItemColor: MomntColors.muted,
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
      selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      unselectedLabelStyle: TextStyle(fontSize: 11),
    ),
    cardTheme: const CardThemeData(
      color: MomntColors.surface,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        side: BorderSide(color: MomntColors.outline),
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: MomntColors.surface,
      modalBackgroundColor: MomntColors.surface,
      surfaceTintColor: Colors.transparent,
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: MomntColors.surface,
      border: fieldBorder,
      enabledBorder: fieldBorder,
      focusedBorder: fieldBorder.copyWith(
        borderSide: const BorderSide(color: MomntColors.accent, width: 1.5),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: MomntColors.accent,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}
