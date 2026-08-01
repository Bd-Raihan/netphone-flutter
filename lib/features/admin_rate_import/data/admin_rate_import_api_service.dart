/// ==========================================================
/// admin_rate_import_api_service.dart
///
/// কাজ:
/// - Admin Rate Import Backend API call করা
/// - Saved JWT Bearer token পাঠানো
/// - Server CSV file list আনা
/// - CSV validation করা
/// - CSV import এবং activation করা
/// ==========================================================

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../shared/services/storage_service.dart';
import '../models/admin_rate_import_models.dart';

class AdminRateImportApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;

  const AdminRateImportApiException({
    required this.message,
    this.statusCode,
    this.code,
  });

  @override
  String toString() => message;
}

class AdminRateImportApiService {
  static const Duration _timeout = Duration(seconds: 90);

  static Future<Map<String, String>> _authorizedHeaders() async {
    final token = await StorageService.getToken();

    if (token == null || token.trim().isEmpty) {
      throw const AdminRateImportApiException(
        message: 'Admin login token was not found. Please login again.',
        statusCode: 401,
      );
    }

    return {
      'Authorization': 'Bearer ${token.trim()}',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  /// Server storage-এর নির্দিষ্ট provider CSV list।
  static Future<RateDeckFileListResult> listFiles({
    String provider = 'telnyx',
  }) async {
    final headers = await _authorizedHeaders();

    final uri = Uri.parse(
      '${AppConfig.baseUrl}/api/admin/rate-import/files',
    ).replace(queryParameters: {'provider': provider});

    final response = await http.get(uri, headers: headers).timeout(_timeout);

    final payload = _decodeResponse(response);

    final data = payload['data'];

    if (data is! Map) {
      throw const AdminRateImportApiException(
        message: 'Invalid file-list response from server.',
      );
    }

    return RateDeckFileListResult.fromJson(Map<String, dynamic>.from(data));
  }

  /// Database পরিবর্তন না করে CSV dry-run validation।
  static Future<RateDeckValidationResult> validateRateDeck({
    required String provider,
    required String file,
    int sampleLimit = 3,
  }) async {
    final headers = await _authorizedHeaders();

    final uri = Uri.parse(
      '${AppConfig.baseUrl}/api/admin/rate-import/validate',
    );

    final response = await http
        .post(
          uri,
          headers: headers,
          body: jsonEncode({
            'provider': provider,
            'file': file,
            'sample_limit': sampleLimit,
          }),
        )
        .timeout(_timeout);

    final payload = _decodeResponse(response);

    final data = payload['data'];

    if (data is! Map) {
      throw const AdminRateImportApiException(
        message: 'Invalid validation response from server.',
      );
    }

    return RateDeckValidationResult.fromJson(Map<String, dynamic>.from(data));
  }

  /// CSV import করে নতুন rate card activate করে।
  static Future<RateDeckImportResult> importRateDeck({
    required String provider,
    required String plan,
    required String file,
    int batchSize = 500,
    bool allowDuplicateChecksum = false,
  }) async {
    final headers = await _authorizedHeaders();

    final uri = Uri.parse('${AppConfig.baseUrl}/api/admin/rate-import/import');

    final response = await http
        .post(
          uri,
          headers: headers,
          body: jsonEncode({
            'provider': provider,
            'plan': plan,
            'file': file,
            'batch_size': batchSize,
            'allow_duplicate_checksum': allowDuplicateChecksum,
          }),
        )
        .timeout(const Duration(minutes: 10));

    final payload = _decodeResponse(response);

    final data = payload['data'];

    if (data is! Map) {
      throw const AdminRateImportApiException(
        message: 'Invalid import response from server.',
      );
    }

    return RateDeckImportResult.fromJson(Map<String, dynamic>.from(data));
  }

  static Map<String, dynamic> _decodeResponse(http.Response response) {
    Map<String, dynamic> payload;

    try {
      final decoded = jsonDecode(response.body);

      if (decoded is! Map) {
        throw const FormatException('Response is not a JSON object.');
      }

      payload = Map<String, dynamic>.from(decoded);
    } catch (_) {
      throw AdminRateImportApiException(
        message: 'Server returned an invalid response.',
        statusCode: response.statusCode,
      );
    }

    final successfulStatus =
        response.statusCode >= 200 && response.statusCode < 300;

    if (!successfulStatus || payload['ok'] != true) {
      throw AdminRateImportApiException(
        message:
            payload['message']?.toString() ?? 'Rate Import API request failed.',
        statusCode: response.statusCode,
        code: payload['code']?.toString(),
      );
    }

    return payload;
  }
}
