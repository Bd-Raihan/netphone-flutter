// =======================================================
// main_navigation_screen.dart
//
// কাজ:
// - Main Bottom Navigation
// - Dial Pad
// - Recents
// - Wallet
// - Settings
// - Dynamic Drawer App Pages
// =======================================================
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:share_plus/share_plus.dart';

import '../../call/screens/dial_pad_screen.dart';
import '../../contacts/screens/contacts_screen.dart';
import 'package:netphone/features/recents/screens/recents_screen.dart';
import '../../wallet/screens/wallet_screen.dart';
import '../../wallet/data/wallet_data.dart';
import '../../wallet/data/wallet_api_service.dart';
import '../../../shared/services/storage_service.dart';
import '../../admin/screens/admin_crypto_recharge_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../admin_profit/screens/admin_profit_dashboard_screen.dart';
import '../../app_pages/screens/app_page_screen.dart';
import '../../rates/screens/rates_screen.dart';
import '../../fax/screens/fax_home_screen.dart';
import '../../admin_sms_inbox/screens/admin_sms_inbox_screen.dart';
import '../../admin_rate_management/screens/admin_rate_management_screen.dart';
import '../../admin_call_activity/screens/admin_call_activity_screen.dart';
import '../../app_update/services/app_update_service.dart';
import '../../app_update/dialogs/app_update_dialog.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with WidgetsBindingObserver {
  int currentIndex = 0;
  bool _isCheckingAppUpdate = false;
  bool _isUpdateDialogOpen = false;
  String userPhone = "";
  String userRole = "user";

  final List<Widget> screens = [
    const DialPadScreen(),
    const ContactsScreen(),
    const RecentsScreen(),
    const WalletScreen(),
  ];

  String getTitle() {
    switch (currentIndex) {
      case 0:
        return "Dial Pad";
      case 1:
        return "Contacts";
      case 2:
        return "Recents";
      case 3:
        return "Wallet";
      default:
        return "NetPhone";
    }
  }

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    loadWallet();
    loadUserInfo();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      checkAppUpdate();
    });
  }

  // ============================================================
  // 🇧🇩 APP RESUME UPDATE CHECK
  //
  // User যতক্ষণ নতুন version install না করবে,
  // app আবার foreground/open হলে update check হবে.
  // ============================================================

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        checkAppUpdate();
      });
    }
  }

  Future<void> loadWallet() async {
    currentBalance = await fetchWalletBalance();
    if (mounted) setState(() {});
  }

  Future<void> loadUserInfo() async {
    final phone = await StorageService.getPhone();
    final role = await StorageService.getRole();

    if (!mounted) return;

    setState(() {
      userPhone = phone ?? "";
      userRole = (role ?? "user").toLowerCase();
    });
  }

  // ============================================================
  // 🇧🇩 NETPHONE APP UPDATE CHECK
  //
  // কাজ:
  // - Backend থেকে latest version check করা
  // - Update থাকলে dialog দেখানো
  // ============================================================

  Future<void> checkAppUpdate() async {
    if (_isCheckingAppUpdate || _isUpdateDialogOpen) {
      return;
    }

    _isCheckingAppUpdate = true;

    try {
      final result = await AppUpdateService.checkForUpdate();

      if (!mounted || result == null) {
        return;
      }

      _isUpdateDialogOpen = true;

      await showNetPhoneUpdateDialog(context, result);
    } catch (e) {
      debugPrint('App update check failed: $e');
    } finally {
      _isCheckingAppUpdate = false;
      _isUpdateDialogOpen = false;
    }
  }

  void openAppPage({
    required BuildContext context,
    required String slug,
    required String title,
  }) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AppPageScreen(slug: slug, fallbackTitle: title),
      ),
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = userRole.toLowerCase() == "admin";

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1145F5),
        elevation: 0,
        title: Text(
          getTitle(),
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
                size: 20.sp,
              ),
              SizedBox(width: 6.w),
              Text(
                "\$${currentBalance.toStringAsFixed(2)} USD",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(width: 14.w),
              IconButton(
                onPressed: () {
                  Share.share(
                    "Download NetPhone App\n\n"
                    "Cheap Rates International Calls 🌍\n"
                    "https://play.google.com/store/apps/details?id=com.netphoneapp.call",
                  );
                },
                icon: Icon(Icons.share, color: Colors.white, size: 22.sp),
              ),
            ],
          ),
        ],
      ),

      body: screens[currentIndex],

      drawer: Drawer(
        backgroundColor: Colors.black,
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(20.w, 28.h, 20.w, 24.h),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1145F5), Color(0xFF0B2A9E)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "NetPhoneApp",
                      style: TextStyle(
                        color: const Color.fromARGB(255, 154, 255, 253),
                        fontSize: 28.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      userPhone,
                      style: TextStyle(
                        color: const Color.fromARGB(
                          255,
                          222,
                          138,
                          248,
                        ).withValues(alpha: 0.95),
                        fontSize: 15.sp,
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 10.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color.fromARGB(
                          255,
                          222,
                          138,
                          248,
                        ).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: Text(
                        userRole.toUpperCase(),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    buildDrawerItem(
                      context: context,
                      icon: Icons.settings,
                      title: "Settings",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),

                    if (isAdmin)
                      buildDrawerItem(
                        context: context,
                        icon: Icons.bar_chart,
                        title: "Profit Dashboard",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  const AdminProfitDashboardScreen(),
                            ),
                          );
                        },
                      ),

                    if (isAdmin)
                      buildDrawerItem(
                        context: context,
                        icon: Icons.manage_history,
                        title: "Call Activity / CDR",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminCallActivityScreen(),
                            ),
                          );
                        },
                      ),

                    buildDrawerItem(
                      context: context,
                      icon: Icons.rate_review,
                      title: "Rates",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RatesScreen(),
                          ),
                        );
                      },
                    ),

                    buildDrawerItem(
                      context: context,
                      icon: Icons.fax,
                      title: "Fax",
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const FaxHomeScreen(),
                          ),
                        );
                      },
                    ),

                    if (isAdmin)
                      buildDrawerItem(
                        context: context,
                        icon: Icons.sms_outlined,
                        title: "SMS Inbox",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminSmsInboxScreen(),
                            ),
                          );
                        },
                      ),

                    if (isAdmin)
                      buildDrawerItem(
                        context: context,
                        icon: Icons.account_balance_wallet,
                        title: "Admin Recharge",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminCryptoRechargeScreen(),
                            ),
                          );
                        },
                      ),

                    if (isAdmin)
                      buildDrawerItem(
                        context: context,
                        icon: Icons.route,
                        title: "Rate Management",
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const AdminRateManagementScreen(),
                            ),
                          );
                        },
                      ),

                    buildDrawerItem(
                      context: context,
                      icon: Icons.info,
                      title: "About App",
                      onTap: () {
                        openAppPage(
                          context: context,
                          slug: "about_app",
                          title: "About App",
                        );
                      },
                    ),

                    buildDrawerItem(
                      context: context,
                      icon: Icons.lock,
                      title: "Privacy Policy",
                      onTap: () {
                        openAppPage(
                          context: context,
                          slug: "privacy_policy",
                          title: "Privacy Policy",
                        );
                      },
                    ),

                    buildDrawerItem(
                      context: context,
                      icon: Icons.description,
                      title: "Terms & Conditions",
                      onTap: () {
                        openAppPage(
                          context: context,
                          slug: "terms_conditions",
                          title: "Terms & Conditions",
                        );
                      },
                    ),

                    buildDrawerItem(
                      context: context,
                      icon: Icons.assignment_return,
                      title: "Refund & Return",
                      onTap: () {
                        openAppPage(
                          context: context,
                          slug: "refund_return",
                          title: "Refund & Return",
                        );
                      },
                    ),

                    buildDrawerItem(
                      context: context,
                      icon: Icons.support_agent,
                      title: "Customer Support",
                      onTap: () {
                        openAppPage(
                          context: context,
                          slug: "customer_support",
                          title: "Customer Support",
                        );
                      },
                    ),

                    buildDrawerItem(
                      context: context,
                      icon: Icons.share,
                      title: "Share App",
                      onTap: () {
                        Share.share(
                          "Download NetPhone App\n\n"
                          "Cheap Rates International Calls 🌍\n"
                          "https://play.google.com/store/apps/details?id=com.netphoneapp.call",
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),

      bottomNavigationBar: Container(
        height: 78.h,
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10.r)],
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex >= 3 ? currentIndex + 1 : currentIndex,
          onTap: (index) {
            if (index == 3) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const FaxHomeScreen()),
              );
              return;
            }
            final screenIndex = index > 3 ? index - 1 : index;
            if (screenIndex == currentIndex) {
              return;
            }

            setState(() {
              currentIndex = screenIndex;
            });
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          selectedFontSize: 13.sp,
          unselectedFontSize: 11.sp,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dialpad),
              label: "Dial Pad",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.contacts),
              label: "Contacts",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.history),
              label: "Recents",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.fax),
              label: "Fax",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.account_balance_wallet),
              label: "Wallet",
            ),
          ],
        ),
      ),
    );
  }
}

Widget buildDrawerItem({
  required BuildContext context,
  required IconData icon,
  required String title,
  required VoidCallback onTap,
  bool isLogout = false,
}) {
  return ListTile(
    leading: Icon(icon, color: isLogout ? Colors.red : Colors.white),
    title: Text(
      title,
      style: TextStyle(
        color: isLogout ? Colors.red : Colors.white,
        fontSize: 15.sp,
      ),
    ),
    trailing: Icon(Icons.arrow_forward_ios, color: Colors.white38, size: 16.sp),
    onTap: () {
      Navigator.pop(context);
      onTap();
    },
  );
}
