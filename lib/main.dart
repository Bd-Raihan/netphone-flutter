/**
 * ==========================================================
 * main.dart
 *
 * কাজ:
 * - App Start করা
 * - Responsive System চালু করা
 * - Theme Apply করা
 * - Auth Wrapper Screen Load করা
 * ==========================================================
 */

import 'package:flutter/material.dart';

import 'package:flutter_screenutil/flutter_screenutil.dart';

///import 'features/navigation/screens/main_navigation_screen.dart';
import 'features/auth/screens/auth_wrapper_screen.dart';
import 'features/recents/data/recent_calls_data.dart';

///import 'features/wallet/data/wallet_data.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await loadRecentCalls();

  runApp(const NetPhoneApp());
}

class NetPhoneApp extends StatelessWidget {
  const NetPhoneApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      /// ✅ Design Size
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

          /// ✅ First Screen
          home: const AuthWrapperScreen(),
        );
      },
    );
  }
}
