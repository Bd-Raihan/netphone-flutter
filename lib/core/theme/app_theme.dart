/// ==========================================================
/// app_theme.dart
/// কাজ:
/// - পুরো App এর Theme control করা
/// - Font, Color, AppBar style ইত্যাদি
/// ==========================================================

import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    // ✅ App এর main color
    primaryColor: AppColors.primary,

    // ✅ Scaffold background color
    scaffoldBackgroundColor: AppColors.background,

    // ✅ AppBar Design
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      centerTitle: true,
      elevation: 0,
    ),

    // ✅ Text Theme
    textTheme: const TextTheme(
      headlineMedium: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: AppColors.textPrimary,
      ),

      bodyLarge: TextStyle(fontSize: 16, color: AppColors.textPrimary),

      bodyMedium: TextStyle(fontSize: 14, color: AppColors.textSecondary),
    ),

    // ✅ Button Theme
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        minimumSize: const Size(double.infinity, 55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    ),
  );
}
