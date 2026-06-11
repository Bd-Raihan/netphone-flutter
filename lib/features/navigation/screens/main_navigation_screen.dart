/// =======================================================
/// main_navigation_screen.dart
///
/// কাজ:
/// - Main Bottom Navigation
/// - Dial Pad
/// - Recents
/// - Wallet
/// - Settings
/// =======================================================
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../call/screens/dial_pad_screen.dart';
import '../../contacts/screens/contacts_screen.dart';
import 'package:netphone/features/recents/screens/recents_screen.dart';
import '../../wallet/screens/wallet_screen.dart';
import '../../wallet/data/wallet_data.dart';
import 'package:share_plus/share_plus.dart';
import '../../wallet/data/wallet_api_service.dart';
import '../../../shared/services/storage_service.dart'; // ✅ role load করার জন্য
import '../../wallet/screens/admin_recharge_screen.dart'; //
import '../../auth/screens/login_screen.dart'; // Login screen এ navigate করার জন্য

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  /// ===============================
  /// বর্তমান bottom nav tab index
  /// ===============================
  int currentIndex = 0;

  /// ===============================
  /// user role save থাকবে এখানে
  /// default = user
  /// ===============================
  ///String userRole = "user";

  /// =====================================
  /// Login user phone
  /// drawer + appbar এ show হবে
  /// =====================================
  String userPhone = "";

  /// =====================================
  /// User role
  /// admin / user
  /// =====================================
  String userRole = "";

  /// ===============================
  /// সব screen list
  /// ===============================
  final List<Widget> screens = [
    const DialPadScreen(),
    const ContactsScreen(),
    const RecentsScreen(),
    const WalletScreen(),
  ];

  /// ===============================
  /// AppBar title change হবে tab অনুযায়ী
  /// ===============================
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

    /// wallet load
    loadWallet();
    loadUserInfo();

    /// user role load
    loadUserRole();
  }

  /// ===============================
  /// Wallet balance load
  /// ===============================
  Future<void> loadWallet() async {
    currentBalance = await fetchWalletBalance();

    if (mounted) {
      setState(() {});
    }
  }

  /// =====================================
  /// User info load
  /// SharedPreferences থেকে
  /// =====================================
  Future<void> loadUserInfo() async {
    /// saved phone
    final phone = await StorageService.getPhone();

    /// saved role
    final role = await StorageService.getRole();

    setState(() {
      userPhone = phone ?? "";
      userRole = role ?? "";
    });
  }

  /// ===============================
  /// Login এর পরে save করা role load হবে
  /// ===============================
  Future<void> loadUserRole() async {
    final role = await StorageService.getRole();

    if (mounted) {
      setState(() {
        userRole = role ?? "user";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      /// ===============================
      /// AppBar
      /// ===============================
      appBar: AppBar(
        backgroundColor: const Color(0xFF1145F5),
        elevation: 0,

        actions: [
          Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
                size: 20.sp,
              ),

              SizedBox(width: 6.w),

              /// Wallet KWD
              Text(
                "${currentBalance.toStringAsFixed(3)} KWD",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 2),

              /// USD balance
              Text(
                "≈ \$${(currentBalance * usdRate).toStringAsFixed(2)}",
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),

              SizedBox(width: 14.w),

              /// Share app button
              IconButton(
                onPressed: () {
                  Share.share(
                    "Download NetPhone App\n\n"
                    "Cheap Rates International Calls 🌍\n"
                    "https://play.google.com/store/apps/details?id=com.netphone.app",
                  );
                },
                icon: Icon(Icons.share, color: Colors.white, size: 22.sp),
              ),
            ],
          ),
        ],

        title: Text(
          getTitle(),
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      /// ===============================
      /// Body
      /// ===============================
      body: screens[currentIndex],

      /// ===============================
      /// Drawer Menu
      /// ===============================
      drawer: Drawer(
        /// Drawer background color
        backgroundColor: Colors.black,

        child: Column(
          children: [
            /// =========================================
            /// Drawer Top Header
            /// এখানে App name + phone + role show হবে
            /// =========================================
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF1145F5)),

              child: Column(
                /// left alignment
                crossAxisAlignment: CrossAxisAlignment.start,

                /// নিচের দিকে show হবে
                mainAxisAlignment: MainAxisAlignment.end,

                children: [
                  /// =============================
                  /// App Name
                  /// =============================
                  Text(
                    "NetPhone",

                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 8.h),

                  /// =============================
                  /// Login phone number
                  /// SharedPreferences থেকে আসবে
                  /// =============================
                  Text(
                    userPhone,

                    style: TextStyle(color: Colors.white70, fontSize: 14.sp),
                  ),

                  SizedBox(height: 4.h),

                  /// =============================
                  /// User Role
                  /// ADMIN / USER
                  /// =============================
                  Text(
                    userRole.toUpperCase(),

                    style: TextStyle(color: Colors.white54, fontSize: 12.sp),
                  ),
                ],
              ),
            ),

            /// =========================================
            /// Settings
            /// =========================================
            buildDrawerItem(
              context: context,
              icon: Icons.settings,
              title: "Settings",
            ),

            /// =========================================
            /// Rates
            /// =========================================
            buildDrawerItem(
              context: context,
              icon: Icons.rate_review,
              title: "Rates",
            ),

            /// =========================================
            /// Recording Calls
            /// =========================================
            buildDrawerItem(
              context: context,
              icon: Icons.record_voice_over,
              title: "Recording Calls",
            ),

            /// =========================================
            /// Admin Recharge
            /// শুধু admin হলে দেখাবে
            /// =========================================
            if (userRole == "admin")
              buildDrawerItem(
                context: context,
                icon: Icons.account_balance_wallet,
                title: "Admin Recharge",
              ),

            /// =========================================
            /// About App
            /// =========================================
            buildDrawerItem(
              context: context,
              icon: Icons.info,
              title: "About App",
            ),

            /// =========================================
            /// Privacy Policy
            /// =========================================
            buildDrawerItem(
              context: context,
              icon: Icons.lock,
              title: "Privacy Policy",
            ),

            /// =========================================
            /// Customer Support
            /// =========================================
            buildDrawerItem(
              context: context,
              icon: Icons.contact_support,
              title: "Customer Support",
            ),

            /// =========================================
            /// Share App
            /// =========================================
            buildDrawerItem(
              context: context,
              icon: Icons.share,
              title: "Share App",
            ),

            /// =========================================
            /// Logout Button
            /// =========================================
            buildDrawerItem(
              context: context,
              icon: Icons.logout,
              title: "Logout",
              isLogout: true,
            ),
          ],
        ),
      ),

      /// ===============================
      /// Bottom Navigation
      /// ===============================
      bottomNavigationBar: Container(
        height: 78.h,

        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10.r)],
        ),

        child: BottomNavigationBar(
          currentIndex: currentIndex,

          onTap: (index) async {
            await loadWallet();

            setState(() {
              currentIndex = index;
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
              icon: Icon(Icons.account_balance_wallet),
              label: "Wallet",
            ),
          ],
        ),
      ),
    );
  }
}

/// ===============================
/// Drawer Item Widget
///
/// কাজ:
/// - Drawer menu button বানায়
/// - কোন title click হয়েছে check করে
/// - Admin Recharge click হলে screen open করে
/// ===============================
Widget buildDrawerItem({
  required BuildContext context, // screen navigation এর জন্য
  required IconData icon,
  required String title,
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

    onTap: () async {
      /// =====================================
      /// Admin Recharge button click
      /// =====================================
      if (title == "Admin Recharge") {
        Navigator.push(
          context,

          MaterialPageRoute(builder: (_) => const AdminRechargeScreen()),
        );
      }
      /// =====================================
      /// Share App button click
      /// =====================================
      else if (title == "Share App") {
        Share.share(
          "Download NetPhone App\n\n"
          "Cheap Rates International Calls 🌍\n"
          "https://play.google.com/store/apps/details?id=com.netphone.app",
        );
      }
      /// =====================================
      /// Logout button
      /// =====================================
      else if (isLogout) {
        /// সব saved data clear
        await StorageService.clearAll();

        /// Login screen এ পাঠাবে
        if (context.mounted) {
          Navigator.pushAndRemoveUntil(
            context,

            MaterialPageRoute(builder: (_) => const LoginScreen()),

            (route) => false,
          );
        }
      }

      /// =====================================
      /// অন্য button পরে add করবো
      /// =====================================
    },
  );
}
