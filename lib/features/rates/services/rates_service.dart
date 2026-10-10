import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../models/rate_model.dart';

class RatesService {
  static Future<List<RateModel>> getRates() async {
    final uri = Uri.parse('${AppConfig.baseUrl}/api/rates');

    try {
      final response = await http
          .get(uri, headers: const {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 45));

      final decoded = jsonDecode(response.body);

      if (decoded is! Map<String, dynamic>) {
        throw Exception('Invalid rates response from server.');
      }

      if (response.statusCode != 200 || decoded['ok'] != true) {
        throw Exception(
          decoded['message']?.toString() ?? 'Failed to load rates.',
        );
      }

      final rawItems = decoded['items'];

      if (rawItems is! List) {
        throw Exception('Invalid rates list from server.');
      }

      return rawItems
          .whereType<Map>()
          .map((item) => RateModel.fromJson(Map<String, dynamic>.from(item)))
          .toList();
    } on TimeoutException {
      throw Exception(
        'Rates are taking longer than expected. Please tap Refresh and try again.',
      );
    } on FormatException {
      throw Exception('Invalid response received from the server.');
    }
  }
}
