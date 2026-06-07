import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFFF5F7FB);
  static const card = Colors.white;
  static const heading = Color(0xFF0F172A);
  static const text = Color(0xFF475569);
  static const border = Color(0xFFE2E8F0);
  static const accent = Color(0xFF12A56B);
  static const accentSoft = Color(0xFFE7FBF2);
  static const warningSoft = Color(0xFFFFF7ED);
  static const warningText = Color(0xFF9A3412);
  static const errorSoft = Color(0xFFFFF1F2);
  static const errorText = Color(0xFFB91C1C);
  static const successSoft = Color(0xFFF0FDF4);
  static const successText = Color(0xFF166534);
}

class AppTheme {
  static ThemeData light() {
    return ThemeData(
      colorSchemeSeed: AppColors.accent,
      scaffoldBackgroundColor: AppColors.background,
      useMaterial3: true,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.card,
        foregroundColor: AppColors.heading,
        elevation: 0,
        centerTitle: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.card,
        indicatorColor: AppColors.accentSoft,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AppColors.accent,
            );
          }
          return const TextStyle(fontSize: 12, color: AppColors.text);
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
      ),
    );
  }
}
