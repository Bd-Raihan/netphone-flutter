/**
 * ==========================================================
 * screen_utils.dart
 *
 * কাজ:
 * - Responsive Size manage করা
 * - সব মোবাইলে UI ঠিক রাখা
 * - iPhone / Android Phone responsive রাখা
 * - iPad / Tablet screen detect করা
 * - বড় screen-এ content অতিরিক্ত stretch হওয়া বন্ধ করা
 * ==========================================================
 */

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Responsive {
  // ==========================================================
  // Existing Responsive System
  //
  // গুরুত্বপূর্ণ:
  // এই ৩টি পুরোনো method পরিবর্তন করা হয়নি।
  // Existing Android / Flutter UI আগের মতোই কাজ করবে।
  // ==========================================================

  /// Width
  static double w(double width) {
    return width.w;
  }

  /// Height
  static double h(double height) {
    return height.h;
  }

  /// Font Size
  static double sp(double size) {
    return size.sp;
  }

  // ==========================================================
  // Phone / Tablet Responsive Breakpoints
  // ==========================================================

  /// বর্তমান screen-এর logical width
  static double screenWidth(BuildContext context) {
    return MediaQuery.sizeOf(context).width;
  }

  /// বর্তমান screen-এর logical height
  static double screenHeight(BuildContext context) {
    return MediaQuery.sizeOf(context).height;
  }

  /// Android Phone / iPhone
  ///
  /// 600 logical pixel-এর নিচে হলে Phone হিসেবে ধরা হবে।
  static bool isPhone(BuildContext context) {
    return screenWidth(context) < 600;
  }

  /// Standard Tablet / iPad
  ///
  /// 600 থেকে 899 logical pixel পর্যন্ত।
  static bool isTablet(BuildContext context) {
    final width = screenWidth(context);

    return width >= 600 && width < 900;
  }

  /// Large iPad / Large Tablet
  ///
  /// 900 logical pixel বা তার বেশি।
  static bool isLargeTablet(BuildContext context) {
    return screenWidth(context) >= 900;
  }

  /// Tablet অথবা Large Tablet কিনা
  static bool isAnyTablet(BuildContext context) {
    return screenWidth(context) >= 600;
  }

  // ==========================================================
  // Orientation Helpers
  // ==========================================================

  /// Portrait mode কিনা
  static bool isPortrait(BuildContext context) {
    return MediaQuery.orientationOf(context) == Orientation.portrait;
  }

  /// Landscape mode কিনা
  static bool isLandscape(BuildContext context) {
    return MediaQuery.orientationOf(context) == Orientation.landscape;
  }

  // ==========================================================
  // Content Width
  //
  // বড় iPad screen-এ Button/Card/Text পুরো screen জুড়ে
  // অস্বাভাবিকভাবে stretch হওয়া বন্ধ করবে।
  // ==========================================================

  static double contentMaxWidth(BuildContext context) {
    final width = screenWidth(context);

    // Large iPad / Large Tablet
    if (width >= 1000) {
      return 900;
    }

    // Standard iPad / Tablet
    if (width >= 700) {
      return 720;
    }

    // Small Tablet
    if (width >= 600) {
      return 560;
    }

    // Phone
    return width;
  }

  // ==========================================================
  // Form / Dial Pad Width
  //
  // Login, OTP, Dial Pad-এর মতো screen-এর content
  // iPad-এ অতিরিক্ত বড় হবে না।
  // ==========================================================

  static double formMaxWidth(BuildContext context) {
    final width = screenWidth(context);

    if (width >= 900) {
      return 560;
    }

    if (width >= 600) {
      return 520;
    }

    return width;
  }

  // ==========================================================
  // Horizontal Page Padding
  // ==========================================================

  static double horizontalPadding(BuildContext context) {
    final width = screenWidth(context);

    if (width >= 900) {
      return 32;
    }

    if (width >= 600) {
      return 24;
    }

    return 16;
  }
}
