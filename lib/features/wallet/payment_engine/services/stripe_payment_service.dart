import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../shared/services/storage_service.dart';

class StripePaymentService {
  StripePaymentService._();

  static final instance = StripePaymentService._();

  static String get _baseUrl =>
      '${AppConfig.baseUrl}/api/payment-engine/stripe';

  Future<Map<String, String>> _headers() async {
    final token = await StorageService.getToken();

    if (token == null || token.trim().isEmpty) {
      throw Exception('Please log in again.');
    }

    return {
      'Authorization': 'Bearer ${token.trim()}',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
  }

  Map<String, dynamic> _decode(http.Response response) {
    final dynamic decoded;

    try {
      decoded = jsonDecode(response.body);
    } catch (_) {
      throw Exception('Invalid payment server response.');
    }

    if (decoded is! Map) {
      throw Exception('Invalid payment response.');
    }

    final data = Map<String, dynamic>.from(decoded);

    if (response.statusCode < 200 ||
        response.statusCode >= 300 ||
        data['ok'] != true) {
      throw Exception(data['error']?.toString() ?? 'Payment request failed.');
    }

    return data;
  }

  Future<Map<String, dynamic>> createPayment({
    required double amountUsd,
    required String clientRequestId,
  }) async {
    if (!amountUsd.isFinite ||
        amountUsd < 5 ||
        amountUsd > 500 ||
        (amountUsd * 100 - (amountUsd * 100).round()).abs() > 0.000001) {
      throw Exception(
        'Enter an amount between \$5 and \$500 (maximum 2 decimals).',
      );
    }

    final requestId = clientRequestId.trim();

    final uuidV4Pattern = RegExp(
      r'^[a-f0-9]{8}-[a-f0-9]{4}-4[a-f0-9]{3}-[89ab][a-f0-9]{3}-[a-f0-9]{12}$',
      caseSensitive: false,
    );

    if (!uuidV4Pattern.hasMatch(requestId)) {
      throw Exception('Invalid recharge request ID.');
    }

    final response = await http
        .post(
          Uri.parse('$_baseUrl/create'),
          headers: await _headers(),
          body: jsonEncode({
            'amountUsd': amountUsd,
            'clientRequestId': requestId,
          }),
        )
        .timeout(const Duration(seconds: 30));

    return _decode(response);
  }

  Future<Map<String, dynamic>> getPaymentStatus({required int orderId}) async {
    if (orderId <= 0) {
      throw Exception('Invalid Stripe order ID.');
    }

    final response = await http
        .get(Uri.parse('$_baseUrl/orders/$orderId'), headers: await _headers())
        .timeout(const Duration(seconds: 30));

    return _decode(response);
  }
}
