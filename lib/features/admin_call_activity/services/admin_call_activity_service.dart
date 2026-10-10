import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../shared/services/storage_service.dart';
import '../models/admin_call_activity_model.dart';

// ============================================================
// 🇧🇩 ADMIN CALL ACTIVITY / CDR API SERVICE
//
// কাজ:
// - Admin JWT token দিয়ে Call Activity report load করা
// - Backend-এর read-only Admin CDR API ব্যবহার করা
// - Calling Engine / Billing / Wallet modify করে না
// ============================================================

class AdminCallActivityService {
  static const int defaultLimit = 50;

  static Future<AdminCallActivityResponse> getCallActivity({
    String? search,
    String? registeredNumber,
    String? destinationNumber,
    String? originCountry,
    String? destinationCountry,
    String? status,
    String? provider,
    DateTime? fromDate,
    DateTime? toDate,
    int limit = defaultLimit,
    int offset = 0,
  }) async {
    final token = await StorageService.getToken();

    if (token == null || token.trim().isEmpty) {
      throw Exception('Admin login token not found');
    }

    final query = <String, String>{
      'limit': limit.toString(),
      'offset': offset.toString(),
    };

    void addText(String key, String? value) {
      final normalized = value?.trim();

      if (normalized != null && normalized.isNotEmpty) {
        query[key] = normalized;
      }
    }

    addText('search', search);
    addText('registered_number', registeredNumber);
    addText('destination_number', destinationNumber);
    addText('origin_country', originCountry);
    addText('destination_country', destinationCountry);
    addText('status', status);
    addText('provider', provider);

    if (fromDate != null) {
      query['from_date'] = fromDate.toUtc().toIso8601String();
    }

    if (toDate != null) {
      query['to_date'] = toDate.toUtc().toIso8601String();
    }

    final uri = Uri.parse(
      '${AppConfig.baseUrl}/api/admin/call-activity',
    ).replace(queryParameters: query);

    final response = await http.get(
      uri,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw Exception('Invalid server response');
    }

    if (decoded is! Map) {
      throw Exception('Invalid Call Activity response');
    }

    final data = Map<String, dynamic>.from(decoded);

    if (response.statusCode != 200 || data['ok'] != true) {
      throw Exception(
        data['message']?.toString() ?? 'Failed to load Call Activity report',
      );
    }

    return AdminCallActivityResponse.fromJson(data);
  }
}
