// ============================================================
// 🇧🇩 NETPHONE APP UPDATE MODEL
//
// কাজ:
// - Backend থেকে পাওয়া latest app update information parse করা
// - Version / Build Number
// - Force Update
// - Play Store URL
// - Update Title / Message
// ============================================================

class AppUpdateInfo {
  final int id;

  final String platform;

  final String versionName;
  final int buildNumber;

  final String? minimumSupportedVersionName;
  final int? minimumSupportedBuildNumber;

  final String title;
  final String message;

  final String? playStoreUrl;

  final bool forceUpdate;
  final bool isActive;

  final DateTime? publishedAt;

  const AppUpdateInfo({
    required this.id,
    required this.platform,
    required this.versionName,
    required this.buildNumber,
    required this.minimumSupportedVersionName,
    required this.minimumSupportedBuildNumber,
    required this.title,
    required this.message,
    required this.playStoreUrl,
    required this.forceUpdate,
    required this.isActive,
    required this.publishedAt,
  });

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic value) {
      if (value is int) {
        return value;
      }

      return int.tryParse(value?.toString() ?? '') ?? 0;
    }

    int? asNullableInt(dynamic value) {
      if (value == null) {
        return null;
      }

      final parsed = int.tryParse(value.toString());

      return parsed;
    }

    String asString(dynamic value) {
      return value?.toString().trim() ?? '';
    }

    String? asNullableString(dynamic value) {
      final text = value?.toString().trim() ?? '';

      return text.isEmpty ? null : text;
    }

    bool asBool(dynamic value) {
      if (value is bool) {
        return value;
      }

      final text = value?.toString().trim().toLowerCase();

      return text == 'true' || text == '1';
    }

    DateTime? asDateTime(dynamic value) {
      final text = value?.toString().trim() ?? '';

      if (text.isEmpty) {
        return null;
      }

      return DateTime.tryParse(text);
    }

    return AppUpdateInfo(
      id: asInt(json['id']),

      platform: asString(json['platform']),

      versionName: asString(json['version_name']),

      buildNumber: asInt(json['build_number']),

      minimumSupportedVersionName: asNullableString(
        json['minimum_supported_version_name'],
      ),

      minimumSupportedBuildNumber: asNullableInt(
        json['minimum_supported_build_number'],
      ),

      title: asString(json['title']),

      message: asString(json['message']),

      playStoreUrl: asNullableString(json['play_store_url']),

      forceUpdate: asBool(json['force_update']),

      isActive: asBool(json['is_active']),

      publishedAt: asDateTime(json['published_at']),
    );
  }
}

// ============================================================
// 🇧🇩 APP UPDATE API RESPONSE
// ============================================================

class AppUpdateResponse {
  final bool ok;

  final AppUpdateInfo? update;

  const AppUpdateResponse({required this.ok, required this.update});

  factory AppUpdateResponse.fromJson(Map<String, dynamic> json) {
    final updateJson = json['update'];

    return AppUpdateResponse(
      ok: json['ok'] == true,

      update: updateJson is Map<String, dynamic>
          ? AppUpdateInfo.fromJson(updateJson)
          : null,
    );
  }
}
