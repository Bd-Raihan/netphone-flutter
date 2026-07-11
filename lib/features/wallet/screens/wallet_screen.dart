import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/wallet_data.dart';
import '../../../shared/services/storage_service.dart';
import '../data/wallet_api_service.dart';
import '../data/transaction_history_screen.dart';
import 'transfer_balance_screen.dart';
import 'recharge_crypto_screen.dart';
import 'admin_recharge_screen.dart';

import '../services/exchange_rate_service.dart';
import '../services/country_currency_service.dart';
import '../services/currency_formatter.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  bool showPayments = false;
  String userRole = 'user';
  String displayCurrencyCode = 'USD';
  String userPhoneE164 = '';

  @override
  void initState() {
    super.initState();
    loadWallet();
    loadUserRole();
  }

  Future<void> loadUserRole() async {
    final prefs = await SharedPreferences.getInstance();

    final savedRole =
        prefs.getString("user_role") ??
        prefs.getString("role") ??
        prefs.getString("userRole") ??
        "user";

    if (!mounted) return;

    setState(() {
      userRole = savedRole.toLowerCase();
    });
  }

  Future<void> loadWallet() async {
    // Backend balance is always USD.
    // UI converts USD -> local display currency by phone country code.
    await ExchangeRateService.instance.loadRates();

    currentBalance = await fetchWalletBalance();

    final phone = await StorageService.getPhone();
    userPhoneE164 = phone ?? '';
    displayCurrencyCode = CountryCurrencyService.currencyFromPhone(
      userPhoneE164,
    );

    if (!mounted) return;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("WALLET BALANCE => $currentBalance");
    debugPrint("WALLET USER ROLE => $userRole");
    debugPrint("WALLET PHONE => $userPhoneE164");
    debugPrint("WALLET DISPLAY CURRENCY => $displayCurrencyCode");

    final balanceUsd = currentBalance;
    final displayAmount = ExchangeRateService.instance.convertUsdTo(
      balanceUsd,
      displayCurrencyCode,
    );
    final displayText = CurrencyFormatter.formatDisplayAmount(
      displayAmount,
      displayCurrencyCode,
    );
    final usdText = CurrencyFormatter.formatUsd(balanceUsd);

    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: const Color(0xFF1145F5),
        elevation: 0,
        centerTitle: true,
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            /// =========================
            /// Balance Card
            /// =========================
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(20.w),

              decoration: BoxDecoration(
                color: const Color(0xFF1B1B1B),
                borderRadius: BorderRadius.circular(20.r),
              ),

              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  /// LEFT SIDE
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Text(
                        "Current Balance",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 20.sp,
                        ),
                      ),

                      SizedBox(height: 12.h),

                      Text(
                        displayText,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 8.h),

                      Text(
                        "≈ \$${currentBalance.toStringAsFixed(2)}",
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 15.sp,
                        ),
                      ),
                    ],
                  ),

                  /// RIGHT SIDE
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,

                    children: [
                      Text(
                        "${getRemainingMinutes()} Min",
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 8.h),

                      Text(
                        "Remaining",
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 15.sp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 25.h),

            /// =========================
            /// Recharge Buttons
            /// =========================
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      setState(() {
                        showPayments = !showPayments;
                      });
                    },

                    child: Container(
                      height: 55.h,

                      decoration: BoxDecoration(
                        color: Colors.green,
                        borderRadius: BorderRadius.circular(14.r),
                      ),

                      child: Center(
                        child: Text(
                          "Add Balance",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                SizedBox(width: 14.w),

                Expanded(
                  /// =====================================
                  /// Transfer Balance Button
                  /// =====================================
                  child: GestureDetector(
                    onTap: () async {
                      /// =================================
                      /// Transfer Screen open হবে
                      /// =================================
                      final result = await Navigator.push(
                        context,

                        MaterialPageRoute(
                          builder: (_) => const TransferBalanceScreen(),
                        ),
                      );

                      /// =================================
                      /// Transfer success হলে
                      /// wallet auto refresh হবে
                      /// =================================
                      if (result == true) {
                        await loadWallet();

                        setState(() {});
                      }
                    },

                    child: Container(
                      height: 55.h,

                      decoration: BoxDecoration(
                        color: Colors.orange,

                        borderRadius: BorderRadius.circular(14.r),
                      ),

                      child: Center(
                        child: Text(
                          "Transfer Balance",

                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 30.h),

            /// =========================
            /// Payment Methods
            /// =========================
            if (showPayments) ...[
              Text(
                "Payment Methods",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),

              SizedBox(height: 16.h),

              Wrap(
                spacing: 12.w,
                runSpacing: 12.h,

                children: [
                  paymentMethod("Visa Card"),
                  paymentMethod("KNET"),
                  paymentMethod("Crypto Pay"),

                  /// Normal user যেন Admin Recharge দেখতে না পায়
                  if (userRole == "admin") paymentMethod("Admin Recharge"),
                ],
              ),

              SizedBox(height: 30.h),
            ],

            /// =========================
            /// Transaction Title + History Button
            /// =========================
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Recent Transactions",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const TransactionHistoryScreen(),
                      ),
                    );
                  },
                  child: Text(
                    "View All",
                    style: TextStyle(color: Colors.blue, fontSize: 14.sp),
                  ),
                ),
              ],
            ),

            SizedBox(height: 18.h),

            /// Example Recent Transactions
            buildTransactionTile(
              title: "See full history",
              date: "Tap View All",
              amount: "",
              amountColor: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  /// =========================
  /// Transaction Tile
  /// =========================

  Widget buildTransactionTile({
    required String title,
    required String date,
    required String amount,
    required Color amountColor,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 14.h),
      padding: EdgeInsets.all(16.w),

      decoration: BoxDecoration(
        color: const Color(0xFF1B1B1B),
        borderRadius: BorderRadius.circular(18.r),
      ),

      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,

        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),

              SizedBox(height: 5.h),

              Text(
                date,
                style: TextStyle(color: Colors.white54, fontSize: 12.sp),
              ),
            ],
          ),

          Text(
            amount,
            style: TextStyle(
              color: amountColor,
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// =========================
  /// Payment Method Widget
  /// =========================

  Widget paymentMethod(String title) {
    return GestureDetector(
      onTap: () async {
        setState(() {
          showPayments = false;
        });

        if (title == "Crypto Pay") {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RechargeCryptoScreen()),
          );

          await loadWallet();
          return;
        }

        if (title == "Admin Recharge") {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AdminRechargeScreen()),
          );

          await loadWallet();
          return;
        }

        if (title == "Visa Card") {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Visa Payment Gateway Coming Soon"),
              backgroundColor: Colors.blue,
            ),
          );
          return;
        }

        if (title == "KNET") {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("KNET Payment Gateway Coming Soon"),
              backgroundColor: Colors.green,
            ),
          );
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Payment Method Not Available"),
            backgroundColor: Colors.red,
          ),
        );
      },

      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: const Color(0xFF1B1B1B),
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: Colors.white,
            fontSize: 13.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
