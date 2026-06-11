import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../shared/services/storage_service.dart';

/// =======================================================
/// Admin Recharge Screen
///
/// কাজ:
/// - শুধু admin use করবে
/// - phone number দিয়ে user recharge করবে
/// - amount লিখে balance add করবে
/// =======================================================
class AdminRechargeScreen extends StatefulWidget {
  const AdminRechargeScreen({super.key});

  @override
  State<AdminRechargeScreen> createState() => _AdminRechargeScreenState();
}

class _AdminRechargeScreenState extends State<AdminRechargeScreen> {
  /// =====================================
  /// Phone number input controller
  /// =====================================
  final TextEditingController phoneController = TextEditingController();

  /// =====================================
  /// Amount input controller
  /// =====================================
  final TextEditingController amountController = TextEditingController();

  /// =====================================
  /// Loading state
  /// button click হলে loading হবে
  /// =====================================
  bool isLoading = false;

  /// =====================================
  /// Recharge function
  /// backend API call করবে
  /// =====================================
  Future<void> rechargeUser() async {
    try {
      /// -----------------------------
      /// input নেওয়া
      /// -----------------------------
      final phone = phoneController.text.trim();
      final amountText = amountController.text.trim();

      /// phone empty
      if (phone.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Phone number required")));
        return;
      }

      /// amount empty
      if (amountText.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Amount required")));
        return;
      }

      /// string amount → double
      final amount = double.tryParse(amountText);

      if (amount == null || amount <= 0) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text("Invalid amount")));
        return;
      }

      /// USD → cents convert
      final amountCents = (amount * 100).toInt();

      /// loading start
      setState(() {
        isLoading = true;
      });

      /// token read
      final token = await StorageService.getToken();

      /// backend API URL
      final url = Uri.parse("${AppConfig.baseUrl}/api/wallet/credit");

      /// =====================================
      /// API request
      /// =====================================
      final response = await http.post(
        url,

        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },

        body: jsonEncode({
          "phone_e164": phone,
          "amount_cents": amountCents,
          "currency": "USD",
          "meta": {"type": "admin_recharge"},
        }),
      );

      final data = jsonDecode(response.body);

      debugPrint("RECHARGE RESPONSE => $data");

      /// =====================================
      /// Success
      /// =====================================
      if (response.statusCode == 200 && data["ok"] == true) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "\$${amount.toStringAsFixed(4)} USD recharge successful",
            ),
            backgroundColor: Colors.green,
          ),
        );

        /// input clear
        phoneController.clear();
        amountController.clear();
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["message"] ?? "Recharge failed"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Recharge Error: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (!mounted) return;

      /// loading stop
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    phoneController.dispose();
    amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),

      appBar: AppBar(
        backgroundColor: const Color(0xFF1145F5),

        title: Text(
          "Admin Recharge",
          style: TextStyle(
            color: Colors.white,
            fontSize: 18.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.w),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            SizedBox(height: 20.h),

            /// ===========================
            /// Phone Number
            /// ===========================
            Text(
              "User Phone Number",
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 10.h),

            TextField(
              controller: phoneController,

              keyboardType: TextInputType.phone,

              decoration: InputDecoration(
                hintText: "+965xxxxxxxx",

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),

            SizedBox(height: 25.h),

            /// ===========================
            /// Amount
            /// ===========================
            Text(
              "Recharge Amount (USD)",
              style: TextStyle(fontSize: 15.sp, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 10.h),

            TextField(
              controller: amountController,

              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),

              decoration: InputDecoration(
                hintText: "5.000",

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
            ),

            SizedBox(height: 35.h),

            /// ===========================
            /// Recharge Button
            /// ===========================
            SizedBox(
              width: double.infinity,
              height: 55.h,

              child: ElevatedButton(
                onPressed: isLoading ? null : rechargeUser,

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1145F5),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                ),

                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "Recharge Now",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
