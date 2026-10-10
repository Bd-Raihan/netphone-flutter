/**
 * ==========================================================
 * main.dart
 *
 * কাজ:
 * - App Start করা
 * - Responsive System চালু করা
 * - Theme Apply করা
 * - Auth Wrapper Screen Load করা
 * - Android/iPhone Portrait এবং iPad Portrait + Landscape Support
 * ==========================================================
 */

import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_stripe/flutter_stripe.dart';

import 'features/auth/screens/auth_wrapper_screen.dart';
import 'features/recents/data/recent_calls_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const stripePublishableKey = String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');
  if (stripePublishableKey.startsWith('pk_test_') ||
      stripePublishableKey.startsWith('pk_live_')) {
    Stripe.publishableKey = stripePublishableKey;
    await Stripe.instance.applySettings();
  }

  await loadRecentCalls();

  runApp(const NetPhoneApp());
}

class NetPhoneApp extends StatefulWidget {
  const NetPhoneApp({super.key});

  @override
  State<NetPhoneApp> createState() => _NetPhoneAppState();
}

class _NetPhoneAppState extends State<NetPhoneApp> with WidgetsBindingObserver {
  ui.FlutterView? _view;

  // ==========================================================
  // Tablet / iPad breakpoint
  // 600 logical pixels বা তার বেশি হলে large-screen হিসেবে ধরা হবে।
  // ==========================================================
  static const double _tabletBreakpoint = 600;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    _view = View.maybeOf(context);

    _updateOrientation();
  }

  @override
  void didChangeMetrics() {
    _updateOrientation();
  }

  Future<void> _updateOrientation() async {
    final display = _view?.display;

    if (display == null) {
      return;
    }

    final logicalWidth = display.size.width / display.devicePixelRatio;

    // ========================================================
    // Android Phone + iPhone
    // Portrait Only
    // ========================================================
    if (logicalWidth < _tabletBreakpoint) {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);

      return;
    }

    // ========================================================
    // iPad / Large Tablet
    // Portrait + Landscape
    //
    // Empty list = Native OS supported orientations ব্যবহার করবে।
    // iPad-এর orientations Info.plist থেকে নেওয়া হবে।
    // ========================================================
    await SystemChrome.setPreferredOrientations([]);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _view = null;

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      // ========================================================
      // Existing NetPhone mobile design size
      // এটা পরিবর্তন করছি না যাতে Android UI নষ্ট না হয়।
      // ========================================================
      designSize: const Size(390, 844),

      minTextAdapt: true,

      splitScreenMode: true,

      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,

          title: 'NetPhone',

          theme: ThemeData(
            primarySwatch: Colors.blue,

            scaffoldBackgroundColor: const Color(0xFFF4F6FA),
          ),

          home: const AuthWrapperScreen(),
        );
      },
    );
  }
}
