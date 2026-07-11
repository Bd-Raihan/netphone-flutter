import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import '../models/app_page.dart';

class AppPageService {
  static Future<AppPage> getPage({
    required String slug,
    String language = 'en',
  }) async {
    final uri = Uri.parse(
      '${AppConfig.baseUrl}/api/app-pages/$slug?language=$language',
    );

    final response = await http.get(uri).timeout(const Duration(seconds: 12));

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['ok'] != true) {
      throw Exception(data['message'] ?? 'Page not found');
    }

    return AppPage.fromJson(Map<String, dynamic>.from(data['page']));
  }
}
