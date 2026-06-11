import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../shared/services/storage_service.dart';

/// =======================================================
/// TransferBalanceScreen
///
/// কাজ:
/// - User অন্য user কে balance transfer করবে
/// - phone number দিবে
/// - amount দিবে
/// - backend API call করবে
/// =======================================================
class TransferBalanceScreen extends StatefulWidget {
  const TransferBalanceScreen({super.key});

  @override
  State<TransferBalanceScreen> createState() => _TransferBalanceScreenState();
}

class _TransferBalanceScreenState extends State<TransferBalanceScreen> {
  /// =========================================
  /// Phone Controller
  /// =========================================
  final phoneController = TextEditingController();

  /// =========================================
  /// Amount Controller
  /// =========================================
  final amountController = TextEditingController();

  /// =========================================
  /// Loading state
  /// =========================================
  bool isLoading = false;

  /// ===================================================
  /// Transfer Balance Function
  /// ===================================================
  Future<void> transferBalance() async {
    /// phone
    final phone = phoneController.text.trim();

    /// amount
    final amount = double.tryParse(amountController.text.trim());

    /// =======================================
    /// Validation
    /// =======================================
    if (phone.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter phone number")));

      return;
    }

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter valid amount")));

      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      /// =====================================
      /// JWT token read
      /// =====================================
      final token = await StorageService.getToken();

      /// =====================================
      /// API call
      /// =====================================
      final response = await http.post(
        Uri.parse("${AppConfig.baseUrl}/api/wallet/transfer"),

        headers: {
          "Authorization": "Bearer $token",

          "Content-Type": "application/json",
        },

        body: jsonEncode({
          /// receiver phone
          "phone_e164": phone,

          /// amount convert
          "amount_cents": (amount * 100).toInt(),

          "currency": "USD",
        }),
      );

      /// debug log
      debugPrint("TRANSFER STATUS => ${response.statusCode}");

      debugPrint("TRANSFER BODY => ${response.body}");

      final data = jsonDecode(response.body);

      /// =====================================
      /// Success
      /// =====================================
      if (response.statusCode == 200 && data["ok"] == true) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Balance transferred successfully"),

            backgroundColor: Colors.green,
          ),
        );

        /// screen close
        Navigator.pop(context, true);
      } else {
        /// ===================================
        /// API Error
        /// ===================================
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data["message"] ?? "Transfer failed"),

            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      debugPrint("TRANSFER ERROR => $e");

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
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
      backgroundColor: const Color(0xFFF5F5F5),

      appBar: AppBar(
        backgroundColor: const Color(0xFF1145F5),

        title: const Text("Transfer Balance"),
      ),

      body: Padding(
        padding: EdgeInsets.all(20.w),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            /// ===========================
            /// Receiver Phone
            /// ===========================
            Text(
              "Receiver Phone Number",

              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 14.h),

            TextField(
              controller: phoneController,

              decoration: InputDecoration(
                hintText: "+965xxxxxxxx",

                filled: true,

                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18.r),
                ),
              ),
            ),

            SizedBox(height: 28.h),

            /// ===========================
            /// Amount
            /// ===========================
            Text(
              "Amount (USD)",

              style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
            ),

            SizedBox(height: 14.h),

            TextField(
              controller: amountController,

              keyboardType: TextInputType.number,

              decoration: InputDecoration(
                hintText: "5.000",

                filled: true,

                fillColor: Colors.white,

                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18.r),
                ),
              ),
            ),

            SizedBox(height: 40.h),

            /// ===========================
            /// Transfer Button
            /// ===========================
            SizedBox(
              width: double.infinity,

              height: 60.h,

              child: ElevatedButton(
                onPressed: isLoading ? null : transferBalance,

                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1145F5),

                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18.r),
                  ),
                ),

                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        "Transfer Now",

                        style: TextStyle(
                          fontSize: 22.sp,
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
