import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xFFF5F7FB);
  static const card = Colors.white;
  static const heading = Color(0xFF0F172A);
  static const text = Color(0xFF475569);
  static const border = Color(0xFFE2E8F0);
  static const accent = Color(0xFF12A56B);
  static const accentSoft = Color(0xFFE7FBF2);
  static const parking = Color(0xFFD97706);
  static const parkingSoft = Color(0xFFFFFBEB);
  static const warningSoft = Color(0xFFFFF7ED);
  static const warningText = Color(0xFF9A3412);
  static const errorSoft = Color(0xFFFFF1F2);
  static const errorText = Color(0xFFB91C1C);
  static const successSoft = Color(0xFFF0FDF4);
  static const successText = Color(0xFF166534);
  /// Web NavBar `bg-blue-500`
  static const navBarBlue = Color(0xFF3B82F6);
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
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.heading,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.card,
        indicatorColor: AppColors.accentSoft,
        height: 64,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.accent,
            );
          }
          return const TextStyle(fontSize: 11, color: AppColors.text);
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.accent,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.accent, width: 1.4),
        ),
      ),
    );
  }
}

ButtonStyle appPrimaryButtonStyle({Color? color}) {
  return ElevatedButton.styleFrom(
    backgroundColor: color ?? AppColors.accent,
    foregroundColor: Colors.white,
    disabledBackgroundColor: (color ?? AppColors.accent).withValues(alpha: 0.5),
    disabledForegroundColor: Colors.white70,
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    padding: const EdgeInsets.symmetric(vertical: 14),
  );
}
