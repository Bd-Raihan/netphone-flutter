import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import 'otp_screen.dart';
import 'review/review_login_screen.dart';
import 'package:intl_phone_field/intl_phone_field.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController phoneController = TextEditingController();

  String phoneE164 = '';
  bool isLoading = false;

  @override
  void dispose() {
    phoneController.dispose();
    super.dispose();
  }

  Future<void> requestOtp() async {
    final phone = phoneE164.trim();

    if (phone.isEmpty || !phone.startsWith('+') || phone.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Enter valid mobile number")),
      );
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      final phone = phoneE164.trim();

      final url = Uri.parse("${AppConfig.baseUrl}/api/auth/request-otp");

      final response = await http
          .post(
            url,
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({"phone_e164": phone}),
          )
          .timeout(const Duration(seconds: 22));

      Map<String, dynamic> data;

      try {
        final decoded = jsonDecode(response.body);

        if (decoded is! Map) {
          throw const FormatException('Invalid server response');
        }

        data = Map<String, dynamic>.from(decoded);
      } on FormatException {
        debugPrint(
          'Non-JSON OTP response: '
          '${response.statusCode} '
          '${response.body}',
        );

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Server is temporarily unavailable. Please try again.',
            ),
          ),
        );

        return;
      }

      if (response.statusCode == 200 && data["ok"] == true) {
        if (!mounted) return;

        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => OtpScreen(phone: phone)),
        );
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"] ?? "OTP Failed")),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Network Error: $e")));
    } finally {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(Icons.call, size: 90, color: AppColors.primary),

                  const SizedBox(height: 30),
                  Text(
                    "Welcome to NetPhone",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),

                  const SizedBox(height: 10),
                  Text(
                    "Enter your mobile number to continue",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 40),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Mobile Number",
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 10),
                  IntlPhoneField(
                    controller: phoneController,
                    initialCountryCode: 'KW',
                    keyboardType: TextInputType.phone,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      hintText: "Enter mobile number",
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (phone) {
                      phoneE164 = phone.completeNumber;
                    },
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: 220,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : requestOtp,
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "Continue",
                              style: TextStyle(fontSize: 16),
                            ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ReviewLoginScreen(),
                        ),
                      );
                    },
                    child: const Text("Google Play Review Access"),
                  ),

                  const SizedBox(height: 100),

                  Text(
                    "Secure International Calling",
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
