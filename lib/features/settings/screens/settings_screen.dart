import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../shared/services/storage_service.dart';
import '../../auth/screens/login_screen.dart';

/// =======================================================
/// Settings Screen

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: const Color(0xFF1145F5),
        elevation: 0,
        centerTitle: true,

        title: Text(
          "Settings",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: SingleChildScrollView(
        padding: EdgeInsets.all(16.w),

        child: Column(
          children: [
            buildSettingTile(
              context: context,
              icon: Icons.person,
              title: "Profile",
            ),

            buildSettingTile(
              context: context,
              icon: Icons.language,
              title: "Language",
            ),

            buildSettingTile(
              context: context,
              icon: Icons.record_voice_over,
              title: "Recording Calls",
            ),

            buildSettingTile(
              context: context,
              icon: Icons.dark_mode,
              title: "Dark Mode",
            ),

            buildSettingTile(
              context: context,
              icon: Icons.privacy_tip,
              title: "Privacy Policy",
            ),

            buildSettingTile(
              context: context,
              icon: Icons.contact_support,
              title: "Customer Support",
            ),

            buildSettingTile(
              context: context,
              icon: Icons.logout,
              title: "Logout",
              isLogout: true,
            ),

            SizedBox(height: 30.h),

            Text(
              "Version 1.0.0",
              style: TextStyle(color: Colors.white38, fontSize: 13.sp),
            ),
          ],
        ),
      ),
    );
  }

  /// =========================
  /// Setting Tile
  /// =========================

  Widget buildSettingTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    bool isLogout = false,
  }) {
    return GestureDetector(
      onTap: () async {
        if (isLogout) {
          await StorageService.clearAll();

          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const LoginScreen()),
            (route) => false,
          );
        }
      },

      child: Container(
        margin: EdgeInsets.only(bottom: 14.h),
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),

        decoration: BoxDecoration(
          color: const Color(0xFF1B1B1B),
          borderRadius: BorderRadius.circular(18.r),
        ),

        child: Row(
          children: [
            Icon(icon, color: isLogout ? Colors.red : Colors.white),

            SizedBox(width: 14.w),

            Expanded(
              child: Text(
                title,
                style: TextStyle(color: isLogout ? Colors.red : Colors.white),
              ),
            ),

            Icon(Icons.arrow_forward_ios, color: Colors.white38),
          ],
        ),
      ),
    );
  }
}
