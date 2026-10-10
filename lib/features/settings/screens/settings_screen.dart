import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../shared/services/storage_service.dart';
import '../../admin_content/screens/admin_content_list_screen.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../auth/screens/login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isDarkMode = true;
  String selectedLanguage = 'English';
  String userRole = 'user';
  bool isLoadingRole = true;
  String appVersion = '';

  bool get isAdmin => userRole.toLowerCase() == 'admin';

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadAppVersion();
  }

  Future<void> _loadUserRole() async {
    final role = await StorageService.getRole();

    if (!mounted) return;

    setState(() {
      userRole = (role ?? 'user').toLowerCase();
      isLoadingRole = false;
    });
  }

  Future<void> _loadAppVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();

    if (!mounted) return;

    setState(() {
      appVersion = packageInfo.version;
    });
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout from NetPhone?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (shouldLogout != true) return;

    await StorageService.clearAll();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  void _showLanguageDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Language'),
              contentPadding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _languageOption(
                    dialogContext: dialogContext,
                    language: 'English',
                    setDialogState: setDialogState,
                  ),
                  _languageOption(
                    dialogContext: dialogContext,
                    language: 'বাংলা',
                    setDialogState: setDialogState,
                  ),
                  _languageOption(
                    dialogContext: dialogContext,
                    language: 'العربية',
                    setDialogState: setDialogState,
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _languageOption({
    required BuildContext dialogContext,
    required String language,
    required StateSetter setDialogState,
  }) {
    final selected = selectedLanguage == language;

    return ListTile(
      title: Text(language),
      leading: Icon(
        Icons.language,
        color: selected ? const Color(0xFF1145F5) : Colors.grey,
      ),
      trailing: selected
          ? const Icon(Icons.check_circle, color: Color(0xFF1145F5))
          : null,
      onTap: () {
        setDialogState(() {
          selectedLanguage = language;
        });

        setState(() {
          selectedLanguage = language;
        });

        Navigator.pop(dialogContext);
      },
    );
  }

  void _showDeleteAccountDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete Account & Balance'),
          content: const Text(
            'Account deletion permanently removes your account information '
            'and remaining balance after verification.\n\n'
            'This feature will be connected to the secure backend deletion '
            'request system before public production release.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.pop(dialogContext);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Account deletion request system is not enabled yet.',
                    ),
                  ),
                );
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      appBar: AppBar(
        backgroundColor: const Color(0xFF1145F5),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),

      body: isLoadingRole
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.w),
              child: Column(
                children: [
                  if (isAdmin) ...[
                    _sectionLabel('Administration'),

                    _settingTile(
                      icon: Icons.edit_document,
                      title: 'Content Management',
                      subtitle:
                          'Create and edit About, Privacy, Terms and Support pages',
                      accentColor: const Color(0xFF5FA8FF),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AdminContentListScreen(),
                          ),
                        );
                      },
                    ),

                    SizedBox(height: 8.h),
                  ],

                  _sectionLabel('Application'),

                  _switchTile(
                    icon: Icons.dark_mode,
                    title: 'Dark Mode',
                    subtitle: isDarkMode
                        ? 'Dark appearance enabled'
                        : 'Light appearance enabled',
                    value: isDarkMode,
                    onChanged: (value) {
                      setState(() {
                        isDarkMode = value;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            value
                                ? 'Dark Mode selected'
                                : 'Light Mode selected',
                          ),
                        ),
                      );
                    },
                  ),

                  _settingTile(
                    icon: Icons.language,
                    title: 'Language',
                    subtitle: selectedLanguage,
                    onTap: _showLanguageDialog,
                  ),

                  _sectionLabel('Account'),

                  _settingTile(
                    icon: Icons.delete_forever,
                    title: 'Delete Account & Balance',
                    subtitle: 'Permanently request account deletion',
                    isDanger: true,
                    onTap: _showDeleteAccountDialog,
                  ),

                  _settingTile(
                    icon: Icons.logout,
                    title: 'Logout',
                    isLogout: true,
                    onTap: _logout,
                  ),

                  SizedBox(height: 28.h),

                  Text(
                    'NetPhone',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  SizedBox(height: 4.h),

                  Text(
                    appVersion.isEmpty ? 'Version' : 'Version $appVersion',
                    style: TextStyle(color: Colors.white38, fontSize: 12.sp),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _sectionLabel(String title) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(top: 8.h, bottom: 10.h),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.white54,
          fontSize: 11.sp,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    String? subtitle,
    bool isLogout = false,
    bool isDanger = false,
    Color? accentColor,
  }) {
    final color = isLogout || isDanger
        ? Colors.red
        : accentColor ?? Colors.white;

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B1B),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(
          color: accentColor != null
              ? accentColor.withValues(alpha: 0.20)
              : Colors.white.withValues(alpha: 0.04),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(18.r),
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 15.h),
            child: Row(
              children: [
                Container(
                  width: 42.w,
                  height: 42.w,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.11),
                    borderRadius: BorderRadius.circular(13.r),
                  ),
                  child: Icon(icon, color: color, size: 23.sp),
                ),

                SizedBox(width: 14.w),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: color,
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (subtitle != null) ...[
                        SizedBox(height: 4.h),
                        Text(
                          subtitle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11.5.sp,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white38,
                  size: 15.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _switchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B1B),
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: Colors.white.withValues(alpha: 0.04)),
      ),
      child: Row(
        children: [
          Container(
            width: 42.w,
            height: 42.w,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(13.r),
            ),
            child: Icon(icon, color: Colors.white, size: 23.sp),
          ),

          SizedBox(width: 14.w),

          Expanded(
            child: Column(
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
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: TextStyle(color: Colors.white54, fontSize: 11.5.sp),
                ),
              ],
            ),
          ),

          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}
