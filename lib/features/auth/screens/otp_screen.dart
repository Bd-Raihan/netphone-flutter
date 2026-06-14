/// ==========================================================
/// otp_screen.dart
/// কাজ:
/// - OTP input নিবে
/// - Backend verify করবে
/// - Token save করবে
/// - User role save করবে (admin / user)
/// - Login success হলে MainNavigationScreen এ যাবে
/// ==========================================================

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../navigation/screens/main_navigation_screen.dart';
import '../../../core/config/app_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/services/storage_service.dart';

class OtpScreen extends StatefulWidget {
  final String phone;
  final String devOtp;

  const OtpScreen({super.key, required this.phone, required this.devOtp});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final TextEditingController otpController = TextEditingController();

  bool isLoading = false;

  /// ==========================================================
  /// OTP Verify Function
  /// কাজ:
  /// - OTP backend এ পাঠাবে
  /// - Backend token দিবে
  /// - Token + role + phone save করবে
  /// ==========================================================
  Future<void> verifyOtp() async {
    /// =====================================
    /// User যে OTP লিখেছে সেটা নেওয়া
    /// =====================================
    final otp = otpController.text.trim();

    /// OTP empty হলে error
    if (otp.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter OTP code")));
      return;
    }

    try {
      /// Loading start
      setState(() {
        isLoading = true;
      });

      /// =====================================
      /// Backend OTP verify API
      /// =====================================
      final url = Uri.parse("${AppConfig.baseUrl}/api/auth/verify-otp");

      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},

            body: jsonEncode({"phone_e164": widget.phone, "code": otp}),
          )
          .timeout(const Duration(seconds: 15));

      final data = jsonDecode(response.body);

      debugPrint("OTP RESPONSE => $data");

      /// =====================================
      /// OTP verify success
      /// =====================================
      if (response.statusCode == 200 && data["ok"] == true) {
        final accessToken = data["accessToken"];

        /// Backend token না পাঠালে error
        if (accessToken == null || accessToken.toString().isEmpty) {
          throw Exception("Token missing from backend");
        }

        /// =====================================
        /// Token save
        /// =====================================
        await StorageService.saveToken(accessToken);

        /// =====================================
        /// User Role save
        /// admin / user
        /// =====================================
        if (data["user"] != null && data["user"]["role"] != null) {
          await StorageService.saveRole(data["user"]["role"].toString());
        }

        /// =====================================
        /// User Phone save
        /// =====================================
        if (data["user"] != null && data["user"]["phone"] != null) {
          await StorageService.savePhone(data["user"]["phone"].toString());
        }

        debugPrint("TOKEN SAVED => $accessToken");
        debugPrint("ROLE SAVED => ${data["user"]["role"]}");
        debugPrint("PHONE SAVED => ${data["user"]["phone"]}");

        if (!mounted) return;

        /// =====================================
        /// Login success → Main Screen
        /// =====================================
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          (route) => false,
        );
      } else {
        if (!mounted) return;

        /// OTP failed
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["message"] ?? data["reason"] ?? "OTP Failed"),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      /// Network / backend error
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Verification Error: $e")));
    } finally {
      if (!mounted) return;

      /// Loading stop
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: AppBar(title: const Text("OTP Verification")),

      body: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const SizedBox(height: 30),

            /// Title
            Text(
              "Enter OTP Code",
              style: Theme.of(context).textTheme.headlineMedium,
            ),

            const SizedBox(height: 10),

            /// Phone
            Text(
              "Code sent to ${widget.phone}",
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            const SizedBox(height: 20),

            /// DEV OTP show

            /*
            Container(
              padding: const EdgeInsets.all(14),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),

              child: Row(
                children: [
                  const Icon(Icons.info),
                  const SizedBox(width: 10),
                  Text("DEV OTP: ${widget.devOtp}"),
                ],
              ),
            ),
            */
            const SizedBox(height: 30),

            /// OTP Input
            TextField(
              controller: otpController,
              keyboardType: TextInputType.number,

              decoration: InputDecoration(
                hintText: "Enter OTP",
                filled: true,
                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 30),

            /// Verify Button
            ElevatedButton(
              onPressed: isLoading ? null : verifyOtp,

              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("Verify OTP"),
            ),
          ],
        ),
      ),
    );
  }
}
