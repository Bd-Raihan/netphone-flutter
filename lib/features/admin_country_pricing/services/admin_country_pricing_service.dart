/// ==========================================================
/// admin_country_pricing_service.dart
///
/// কাজ:
/// - Admin Country Pricing Backend API call করা
/// - JWT Bearer token পাঠানো
/// - Country pricing list/details load করা
/// - Auto Markup বা Manual Rate save করা
/// - Manual override disable করা
/// ==========================================================

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../shared/services/storage_service.dart';
import '../models/admin_country_pricing_model.dart';

class AdminCountryPricingApiException implements Exception {
  final String message;
  final int? statusCode;
  final String? code;

  final double? providerCostUsdPerMin;
  final double? minimumAllowedRate;

  const AdminCountryPricingApiException({
    required this.message,
    this.statusCode,
    this.code,
    this.providerCostUsdPerMin,
    this.minimumAllowedRate,
  });

  @override
  String toString() => message;
}

class AdminCountryPricingService {
  static const Duration _timeout = Duration(seconds: 45);

  static Future<Map<String, String>> _authorizedHeaders() async {
    final token = await StorageService.getToken();

    if (token == null || token.trim().isEmpty) {
      throw const AdminCountryPricingApiException(
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

  static String _normalizePrefix(String prefix) {
    return prefix.replaceAll(RegExp(r'[^0-9]'), '');
  }

  /// সব Country Pricing list।
  static Future<AdminCountryPricingListResult> listPricing({
    String search = '',
  }) async {
    final headers = await _authorizedHeaders();

    final queryParameters = <String, String>{};

    if (search.trim().isNotEmpty) {
      queryParameters['search'] = search.trim();
    }

    final baseUri = Uri.parse(
      '${AppConfig.baseUrl}'
      '/api/admin/country-pricing',
    );

    final uri = queryParameters.isEmpty
        ? baseUri
        : baseUri.replace(queryParameters: queryParameters);

    final response = await http.get(uri, headers: headers).timeout(_timeout);

    final payload = _decodeResponse(response);

    final data = payload['data'];

    if (data is! Map) {
      throw const AdminCountryPricingApiException(
        message: 'Invalid country pricing list response from server.',
      );
    }

    return AdminCountryPricingListResult.fromJson(
      Map<String, dynamic>.from(data),
    );
  }

  /// একটি prefix-এর pricing details।
  static Future<AdminCountryPricingItem> getPricing({
    required String prefix,
  }) async {
    final headers = await _authorizedHeaders();

    final normalizedPrefix = _normalizePrefix(prefix);

    if (normalizedPrefix.isEmpty) {
      throw const AdminCountryPricingApiException(
        message: 'A valid country prefix is required.',
      );
    }

    final uri = Uri.parse(
      '${AppConfig.baseUrl}'
      '/api/admin/country-pricing/'
      '$normalizedPrefix',
    );

    final response = await http.get(uri, headers: headers).timeout(_timeout);

    final payload = _decodeResponse(response);

    final data = payload['data'];

    if (data is! Map) {
      throw const AdminCountryPricingApiException(
        message: 'Invalid country pricing details response.',
      );
    }

    return AdminCountryPricingItem.fromJson(Map<String, dynamic>.from(data));
  }

  /// Auto Markup অথবা Manual Rate save।
  static Future<AdminCountryPricingItem> updatePricing({
    required String prefix,
    required CountryPricingUpdateRequest request,
  }) async {
    final headers = await _authorizedHeaders();

    final normalizedPrefix = _normalizePrefix(prefix);

    if (normalizedPrefix.isEmpty) {
      throw const AdminCountryPricingApiException(
        message: 'A valid country prefix is required.',
      );
    }

    final uri = Uri.parse(
      '${AppConfig.baseUrl}'
      '/api/admin/country-pricing/'
      '$normalizedPrefix',
    );

    final response = await http
        .put(uri, headers: headers, body: jsonEncode(request.toJson()))
        .timeout(_timeout);

    final payload = _decodeResponse(response);

    final data = payload['data'];

    if (data is! Map) {
      throw const AdminCountryPricingApiException(
        message: 'Invalid country pricing update response.',
      );
    }

    return AdminCountryPricingItem.fromJson(Map<String, dynamic>.from(data));
  }

  /// Manual override বন্ধ করে Auto Pricing-এ ফেরত যাবে।
  static Future<AdminCountryPricingItem> disableManualOverride({
    required String prefix,
  }) async {
    final headers = await _authorizedHeaders();

    final normalizedPrefix = _normalizePrefix(prefix);

    if (normalizedPrefix.isEmpty) {
      throw const AdminCountryPricingApiException(
        message: 'A valid country prefix is required.',
      );
    }

    final uri = Uri.parse(
      '${AppConfig.baseUrl}'
      '/api/admin/country-pricing/'
      '$normalizedPrefix/override',
    );

    final response = await http.delete(uri, headers: headers).timeout(_timeout);

    final payload = _decodeResponse(response);

    final data = payload['data'];

    if (data is! Map) {
      throw const AdminCountryPricingApiException(
        message: 'Invalid manual override response.',
      );
    }

    return AdminCountryPricingItem.fromJson(Map<String, dynamic>.from(data));
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
      throw AdminCountryPricingApiException(
        message: 'Server returned an invalid response.',
        statusCode: response.statusCode,
      );
    }

    final successfulStatus =
        response.statusCode >= 200 && response.statusCode < 300;

    if (!successfulStatus || payload['ok'] != true) {
      throw AdminCountryPricingApiException(
        message:
            payload['message']?.toString() ??
            'Country Pricing API request failed.',

        statusCode: response.statusCode,

        code: payload['code']?.toString(),

        providerCostUsdPerMin: double.tryParse(
          payload['provider_cost_usd_per_min']?.toString() ?? '',
        ),

        minimumAllowedRate: double.tryParse(
          payload['minimum_allowed_rate']?.toString() ?? '',
        ),
      );
    }

    return payload;
  }
}
