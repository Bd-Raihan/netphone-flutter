import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../shared/services/storage_service.dart';

class CryptoService {
  static Future<Map<String, dynamic>> submitRechargeRequest({
    required double amountUsd,
    required String txHash,
    String cryptoCurrency = "USDT",
    String network = "TRC20",
    required String walletAddress,
  }) async {
    final token = await StorageService.getToken();

    if (token == null || token.isEmpty) {
      throw Exception("Login token missing. Please login again.");
    }

    final url = Uri.parse("${AppConfig.baseUrl}/api/crypto/recharge-request");

    final response = await http
        .post(
          url,
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer $token",
          },
          body: jsonEncode({
            "amount_usd": amountUsd,
            "crypto_currency": cryptoCurrency,
            "network": network,
            "tx_hash": txHash,
          }),
        )
        .timeout(const Duration(seconds: 20));

    final Map<String, dynamic> data = response.body.isNotEmpty
        ? jsonDecode(response.body)
        : <String, dynamic>{};

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (data["ok"] == true) {
        return data;
      }
    }

    throw Exception(
      data["message"] ?? data["error"] ?? "Recharge request failed",
    );
  }
}
