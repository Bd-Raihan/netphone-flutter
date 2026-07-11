import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import '../../../shared/services/storage_service.dart';

class AdminProfitService {
  static Future<Map<String, dynamic>> getDashboard() async {
    final token = await StorageService.getToken();

    final res = await http.get(
      Uri.parse('${AppConfig.baseUrl}/api/admin/profit/dashboard'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(res.body);

    if (res.statusCode != 200 || data['ok'] != true) {
      throw Exception(data['message'] ?? 'Failed to load profit dashboard');
    }

    return data;
  }
}
