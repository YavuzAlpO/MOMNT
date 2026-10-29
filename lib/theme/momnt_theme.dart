import 'package:flutter/material.dart';

abstract final class MomntColors {
  static const navy = Color(0xFF0B192C);
  static const navyDeep = Color(0xFF0F2167);
  static const background = Color(0xFFF8FAFC);
  static const surface = Colors.white;
  static const muted = Color(0xFF64748B);
  static const success = Color(0xFF16A34A);
  static const successSoft = Color(0xFFDCFCE7);
  static const mapFill = Color(0xFFD9E4F0);
  static const mapPark = Color(0xFFC5DDC8);
  static const mapRoad = Color(0xFFF8FAFC);
}

ThemeData buildMomntTheme() {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: MomntColors.navyDeep,
      primary: MomntColors.navy,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: MomntColors.background,
    appBarTheme: const AppBarTheme(
      backgroundColor: MomntColors.background,
      foregroundColor: MomntColors.navy,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: MomntColors.navy,
        fontSize: 22,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,
      selectedItemColor: MomntColors.navy,
      unselectedItemColor: Color(0xFF94A3B8),
      type: BottomNavigationBarType.fixed,
      showUnselectedLabels: true,
      selectedLabelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      unselectedLabelStyle: TextStyle(fontSize: 11),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: MomntColors.navy,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}
