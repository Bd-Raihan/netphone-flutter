/// ==========================================================
/// app_colors.dart
/// কাজ:
/// - App এর সব color এক জায়গা থেকে manage করা
/// - Future এ theme change সহজ হবে
/// ==========================================================

import 'package:flutter/material.dart';

class AppColors {
  // ✅ Primary Brand Color
  static const Color primary = Color(0xFF2563EB);

  // ✅ Background Color
  static const Color background = Color(0xFFF8FAFC);

  // ✅ Text Colors
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);

  // ✅ Button / Success / Error
  static const Color success = Color(0xFF10B981);
  static const Color error = Color(0xFFEF4444);

  // ✅ White / Black
  static const Color white = Colors.white;
  static const Color black = Colors.black;
}
