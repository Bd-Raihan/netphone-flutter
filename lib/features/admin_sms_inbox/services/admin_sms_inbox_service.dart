import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import '../../../shared/services/storage_service.dart';

class AdminSmsInboxService {
  static Future<List<Map<String, dynamic>>> fetchMessages() async {
    final token = await StorageService.getToken();

    if (token == null || token.trim().isEmpty) {
      throw Exception('Admin login required');
    }

    final response = await http
        .get(
          Uri.parse('${AppConfig.baseUrl}/api/admin/sms-inbox'),
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
        )
        .timeout(const Duration(seconds: 20));

    final decoded = jsonDecode(response.body);

    if (decoded is! Map) {
      throw Exception('Invalid server response');
    }

    if (response.statusCode != 200 || decoded['ok'] != true) {
      throw Exception(
        decoded['message']?.toString() ?? 'Unable to load SMS inbox',
      );
    }

    final items = decoded['messages'];

    if (items is! List) {
      throw Exception('Invalid SMS list');
    }

    return items.map((item) => Map<String, dynamic>.from(item as Map)).toList();
  }
}
