/**
 * screen_utils.dart
 *
 * কাজ:
 * - Responsive Size manage করা
 * - সব মোবাইলে UI ঠিক রাখা
 */

import 'package:flutter_screenutil/flutter_screenutil.dart';

class Responsive {
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
}
