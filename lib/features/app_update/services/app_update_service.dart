import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';

import '../../../core/config/app_config.dart';
import '../models/app_update_model.dart';

// ============================================================
// 🇧🇩 NETPHONE APP UPDATE SERVICE
//
// কাজ:
// - Backend থেকে latest Android update notice নেওয়া
// - Installed app build number পড়া
// - Update available কি না নির্ধারণ করা
// - Force update প্রয়োজন কি না নির্ধারণ করা
// ============================================================

class AppUpdateCheckResult {
  final AppUpdateInfo update;

  final int installedBuildNumber;
  final String installedVersionName;

  final bool updateAvailable;
  final bool forceUpdateRequired;

  const AppUpdateCheckResult({
    required this.update,
    required this.installedBuildNumber,
    required this.installedVersionName,
    required this.updateAvailable,
    required this.forceUpdateRequired,
  });
}

class AppUpdateService {
  static const String _platform = 'android';

  // ============================================================
  // 🇧🇩 BACKEND থেকে latest update notice নেওয়া
  // ============================================================

  static Future<AppUpdateInfo?> getLatestUpdate() async {
    final uri = Uri.parse(
      '${AppConfig.baseUrl}'
      '/api/app-update/latest'
      '?platform=$_platform',
    );

    final response = await http
        .get(uri, headers: const {'Accept': 'application/json'})
        .timeout(const Duration(seconds: 15));

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Unable to check for app updates.');
    }

    final decoded = jsonDecode(response.body);

    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid app update response.');
    }

    final result = AppUpdateResponse.fromJson(decoded);

    if (!result.ok) {
      throw Exception('App update check failed.');
    }

    return result.update;
  }

  // ============================================================
  // 🇧🇩 CURRENT INSTALLED APP VERSION + BUILD NUMBER
  // ============================================================

  static Future<PackageInfo> getInstalledPackageInfo() {
    return PackageInfo.fromPlatform();
  }

  // ============================================================
  // 🇧🇩 UPDATE DECISION
  // ============================================================

  static Future<AppUpdateCheckResult?> checkForUpdate() async {
    final latestUpdate = await getLatestUpdate();

    if (latestUpdate == null || !latestUpdate.isActive) {
      return null;
    }

    final packageInfo = await getInstalledPackageInfo();

    final installedBuildNumber = int.tryParse(packageInfo.buildNumber) ?? 0;

    final installedVersionName = packageInfo.version;

    final updateAvailable = latestUpdate.buildNumber > installedBuildNumber;

    if (!updateAvailable) {
      return null;
    }

    final minimumSupportedBuild = latestUpdate.minimumSupportedBuildNumber;

    final forceByMinimumBuild =
        minimumSupportedBuild != null &&
        installedBuildNumber < minimumSupportedBuild;

    final forceUpdateRequired = latestUpdate.forceUpdate || forceByMinimumBuild;

    return AppUpdateCheckResult(
      update: latestUpdate,
      installedBuildNumber: installedBuildNumber,
      installedVersionName: installedVersionName,
      updateAvailable: updateAvailable,
      forceUpdateRequired: forceUpdateRequired,
    );
  }
}
