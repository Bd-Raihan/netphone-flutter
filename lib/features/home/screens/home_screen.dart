/// ==========================================================
/// home_screen.dart
/// কাজ:
/// - Login হওয়ার পর Main Screen
/// - Future এ Dial Pad / Wallet / Call History আসবে
/// ==========================================================

import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(title: const Text("NetPhone"), centerTitle: true),

      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            // ✅ Call Icon
            const Icon(Icons.call, size: 90, color: AppColors.primary),

            const SizedBox(height: 20),

            // ✅ Title
            Text(
              "Welcome to NetPhone",

              style: Theme.of(context).textTheme.headlineMedium,
            ),

            const SizedBox(height: 10),

            // ✅ Subtitle
            Text(
              "International Calling App",

              style: Theme.of(context).textTheme.bodyMedium,
            ),

            const SizedBox(height: 40),

            // ✅ Future Feature Note
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),

              padding: const EdgeInsets.all(20),

              decoration: BoxDecoration(
                color: Colors.white,

                borderRadius: BorderRadius.circular(20),
              ),

              child: const Column(
                children: [
                  Text(
                    "Next Features",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),

                  SizedBox(height: 15),

                  Row(
                    children: [
                      Icon(Icons.dialpad),
                      SizedBox(width: 10),
                      Text("Dial Pad"),
                    ],
                  ),

                  SizedBox(height: 10),

                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet),
                      SizedBox(width: 10),
                      Text("Wallet"),
                    ],
                  ),

                  SizedBox(height: 10),

                  Row(
                    children: [
                      Icon(Icons.history),
                      SizedBox(width: 10),
                      Text("Call History"),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
