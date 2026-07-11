import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import '../models/rate_model.dart';

class RatesService {
  static Future<List<RateModel>> getRates() async {
    final uri = Uri.parse('${AppConfig.baseUrl}/api/rates');

    final response = await http.get(uri).timeout(const Duration(seconds: 12));
    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['ok'] != true) {
      throw Exception(data['message'] ?? 'Failed to load rates');
    }

    final items = data['items'] as List;

    return items
        .map((e) => RateModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }
}
