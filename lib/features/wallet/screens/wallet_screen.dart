import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/wallet_data.dart';
import '../../../shared/services/storage_service.dart';
import '../data/wallet_api_service.dart';
import '../data/transaction_history_screen.dart';
import 'transfer_balance_screen.dart';

import '../services/exchange_rate_service.dart';
import '../services/country_currency_service.dart';
import '../services/currency_formatter.dart';
import '../payment_engine/screens/automatic_crypto_recharge_screen.dart';
import '../payment_engine/screens/stripe_recharge_screen.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  static const bool enableStripeTest = bool.fromEnvironment(
    'ENABLE_STRIPE_TEST',
    defaultValue: false,
  );
  bool showPayments = false;
  String userRole = 'user';
  String displayCurrencyCode = 'USD';
  String userPhoneE164 = '';
  double currentEstimatedRateUsdPerMinute = 0.0;

  bool _isRefreshingWallet = false;

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
    // একই সময়ে একাধিক wallet refresh বন্ধ করবে
    if (_isRefreshingWallet) {
      return;
    }

    _isRefreshingWallet = true;

    try {
      // Exchange rate এবং wallet overview
      // একই সময়ে load হবে
      final walletFuture = fetchWalletOverview();

      final exchangeRateFuture = ExchangeRateService.instance.loadRates();

      final walletOverview = await walletFuture;

      // Exchange rate-ও complete হতে দিন
      await exchangeRateFuture;

      final phone = await StorageService.getPhone();

      if (!mounted) {
        return;
      }

      setState(() {
        currentBalance = walletOverview.balanceUsd;

        currentEstimatedRateUsdPerMinute =
            walletOverview.estimatedRateUsdPerMinute;

        userPhoneE164 = phone ?? '';

        displayCurrencyCode = CountryCurrencyService.currencyFromPhone(
          userPhoneE164,
        );
      });
    } catch (e) {
      debugPrint('Wallet refresh failed: $e');
    } finally {
      _isRefreshingWallet = false;
    }
  }

  int getRemainingMinutes() {
    if (currentBalance <= 0) {
      return 0;
    }

    if (currentEstimatedRateUsdPerMinute <= 0) {
      return 0;
    }

    return (currentBalance / currentEstimatedRateUsdPerMinute).floor();
  }

  String formatEstimatedRate(double rate) {
    if (!rate.isFinite || rate <= 0) {
      return '0.0000';
    }

    /// Wallet card compact রাখার জন্য 4 decimal।
    /// Example:
    /// 0.02513 => 0.0251
    /// 0.00700 => 0.0070
    return rate.toStringAsFixed(4);
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
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: const Color(0xFF1145F5),
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Refresh Wallet',
            onPressed: _isRefreshingWallet ? null : loadWallet,
            icon: _isRefreshingWallet
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
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
                  Expanded(
                    child: Column(
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
                          "≈ \$${currentBalance.toStringAsFixed(2)} USD",
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 15.sp,
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: 12.w),

                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currentEstimatedRateUsdPerMinute > 0
                            ? "${getRemainingMinutes()} Min"
                            : "-- Min",
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 20.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      SizedBox(height: 8.h),

                      Text(
                        "Estimated",
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 15.sp,
                        ),
                      ),

                      if (currentEstimatedRateUsdPerMinute > 0) ...[
                        SizedBox(height: 4.h),

                        Text(
                          "@ \$${formatEstimatedRate(currentEstimatedRateUsdPerMinute)}/min",
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 11.sp,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 25.h),

            /// ==========================================================
            /// Wallet Actions
            /// Add Balance + Transfer Balance
            /// ==========================================================
            Row(
              children: [
                Expanded(
                  child: _buildWalletActionCard(
                    title: 'Add Balance',
                    subtitle: showPayments
                        ? 'Hide payment methods'
                        : 'Choose a payment method',
                    icon: showPayments
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.add_card_rounded,
                    accentColor: const Color(0xFF20C67A),
                    onTap: () {
                      setState(() {
                        showPayments = !showPayments;
                      });
                    },
                  ),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: _buildWalletActionCard(
                    title: 'Transfer',
                    subtitle: 'Send wallet balance',
                    icon: Icons.swap_horiz_rounded,
                    accentColor: const Color(0xFFFFA726),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TransferBalanceScreen(),
                        ),
                      );

                      if (result == true) {
                        await loadWallet();
                      }
                    },
                  ),
                ),
              ],
            ),

            SizedBox(height: 22.h),

            /// ==========================================================
            /// Payment Methods Panel
            /// ==========================================================
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: !showPayments
                  ? const SizedBox.shrink()
                  : Container(
                      key: const ValueKey<String>('payment_methods_panel'),
                      width: double.infinity,
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFF15171C),
                        borderRadius: BorderRadius.circular(22.r),
                        border: Border.all(color: const Color(0xFF292D36)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x33000000),
                            blurRadius: 20,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 42.w,
                                height: 42.w,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1D315F),
                                  borderRadius: BorderRadius.circular(13.r),
                                ),
                                child: Icon(
                                  Icons.account_balance_wallet_rounded,
                                  color: const Color(0xFF6EA1FF),
                                  size: 22.sp,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Payment Methods',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18.sp,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    SizedBox(height: 3.h),
                                    Text(
                                      'Select how you want to add balance',
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: 12.sp,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    showPayments = false;
                                  });
                                },
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: Colors.white54,
                                  size: 21.sp,
                                ),
                              ),
                            ],
                          ),

                          SizedBox(height: 18.h),

                          _buildPaymentMethodCard(
                            title: 'USDT Crypto Recharge',
                            subtitle: 'Automatic verification • TRON / TRC20',
                            icon: Icons.currency_bitcoin_rounded,
                            accentColor: const Color(0xFF20C67A),
                            badgeText: 'Recommended',
                            badgeColor: const Color(0xFF145C3C),
                            onTap: () => _handlePaymentMethodTap('Crypto Pay'),
                          ),

                          SizedBox(height: 12.h),

                          _buildPaymentMethodCard(
                            title: 'Visa / Mastercard',
                            subtitle: 'International debit and credit cards',
                            icon: Icons.credit_card_rounded,
                            accentColor: const Color(0xFF4D7CFE),
                            badgeText: enableStripeTest
                                ? 'Test Mode'
                                : 'Coming Soon',
                            badgeColor: enableStripeTest
                                ? const Color(0xFF176B46)
                                : const Color(0xFF30364A),
                            isAvailable: enableStripeTest,
                            onTap: () => _handlePaymentMethodTap('Visa Card'),
                          ),

                          SizedBox(height: 12.h),

                          _buildPaymentMethodCard(
                            title: 'Binance Pay',
                            subtitle: 'Fast Binance-to-Binance USDT transfer',
                            icon: Icons.bolt_rounded,
                            accentColor: const Color(0xFFF3BA2F),
                            badgeText: 'Available',
                            badgeColor: const Color(0xFF176B46),
                            isAvailable: true,
                            onTap: () => _handlePaymentMethodTap('Binance Pay'),
                          ),

                          SizedBox(height: 14.h),

                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.shield_outlined,
                                color: Colors.white38,
                                size: 17.sp,
                              ),
                              SizedBox(width: 8.w),
                              Expanded(
                                child: Text(
                                  'Crypto payments are verified securely '
                                  'by the NetPhone payment engine before '
                                  'your wallet is credited.',
                                  style: TextStyle(
                                    color: Colors.white38,
                                    fontSize: 11.sp,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
            ),

            SizedBox(height: showPayments ? 28.h : 8.h),

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

  Widget _buildWalletActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18.r),
        child: Ink(
          height: 82.h,
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
          decoration: BoxDecoration(
            color: const Color(0xFF191C22),
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: const Color(0xFF2B303A)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x24000000),
                blurRadius: 14,
                offset: Offset(0, 7),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 45.w,
                height: 45.w,
                decoration: BoxDecoration(
                  color: accentColor,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(icon, color: Colors.white, size: 23.sp),
              ),
              SizedBox(width: 11.w),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white54,
                        fontSize: 9.5.sp,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accentColor,
    required VoidCallback onTap,
    String? badgeText,
    Color badgeColor = const Color(0xFF30364A),
    bool isAvailable = true,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(17.r),
        child: Ink(
          padding: EdgeInsets.all(14.w),
          decoration: BoxDecoration(
            color: isAvailable
                ? const Color(0xFF1B1F27)
                : const Color(0xFF181A20),
            borderRadius: BorderRadius.circular(17.r),
            border: Border.all(
              color: isAvailable
                  ? const Color(0xFF303641)
                  : const Color(0xFF252932),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48.w,
                height: 48.w,
                decoration: BoxDecoration(
                  color: isAvailable ? accentColor : const Color(0xFF343842),
                  borderRadius: BorderRadius.circular(15.r),
                ),
                child: Icon(
                  icon,
                  color: isAvailable ? Colors.white : Colors.white38,
                  size: 24.sp,
                ),
              ),

              SizedBox(width: 13.w),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isAvailable
                                  ? Colors.white
                                  : Colors.white54,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (badgeText != null) ...[
                          SizedBox(width: 8.w),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 8.w,
                              vertical: 4.h,
                            ),
                            decoration: BoxDecoration(
                              color: badgeColor,
                              borderRadius: BorderRadius.circular(20.r),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                color: isAvailable
                                    ? Colors.white
                                    : Colors.white54,
                                fontSize: 8.5.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: 5.h),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: isAvailable ? Colors.white54 : Colors.white30,
                        fontSize: 10.5.sp,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(width: 8.w),

              Icon(
                isAvailable
                    ? Icons.arrow_forward_ios_rounded
                    : Icons.lock_outline_rounded,
                color: isAvailable ? Colors.white38 : Colors.white24,
                size: 16.sp,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handlePaymentMethodTap(String method) async {
    if (!mounted) {
      return;
    }

    if (method == 'Crypto Pay') {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AutomaticCryptoRechargeScreen(),
        ),
      );

      if (result == true) {
        await loadWallet();
      }

      return;
    }

    if (method == 'Visa Card') {
      if (!enableStripeTest) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Visa / Mastercard payment is coming soon.'),
          ),
        );
        return;
      }

      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const StripeRechargeScreen()),
      );

      if (mounted) {
        await loadWallet();
      }
      return;
    }

    if (method == 'Binance Pay') {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const AutomaticCryptoRechargeScreen(),
        ),
      );

      if (result == true) {
        await loadWallet();
      }

      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('This payment method is not available.'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
