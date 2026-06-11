/// ==========================================================
/// splash_screen.dart
/// কাজ:
/// - App চালু হলে প্রথম এই screen দেখাবে
/// - Logo / App Name / Loading
/// - Future এ এখান থেকে Login/Home এ যাবে
/// ==========================================================

import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    // ✅ Future এ এখানে:
    // - Token check
    // - Auto login
    // - Navigation
    // করা হবে
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ✅ App Logo/Icon
            Icon(Icons.call, size: 90, color: AppColors.primary),

            const SizedBox(height: 20),

            // ✅ App Name
            Text("NetPhone", style: Theme.of(context).textTheme.headlineMedium),

            const SizedBox(height: 12),

            // ✅ Subtitle
            Text(
              "Smart International Calling",
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            const SizedBox(height: 40),

            // ✅ Loading Indicator
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
