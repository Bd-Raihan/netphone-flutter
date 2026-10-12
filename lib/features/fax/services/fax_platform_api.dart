import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/app_config.dart';
import 'fax_api_service.dart';

class FaxPlatformApi {
  static Future<Map<String, String>> _headers() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    if (token == null || token.isEmpty) {
      throw const FaxApiException('Please login again.', statusCode: 401);
    }
    return {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'};
  }

  static Uri _uri(String path) => Uri.parse('${AppConfig.baseUrl}/api/fax$path');

  static Future<Map<String, dynamic>> request(
    String path, {String method = 'GET', Map<String, dynamic>? body}
  ) async {
    final headers = await _headers();
    final request = http.Request(method, _uri(path));
    request.headers.addAll(headers);
    if (body != null) request.body = jsonEncode(body);
    final response = await http.Response.fromStream(
      await request.send().timeout(const Duration(seconds: 30)),
    ).timeout(const Duration(seconds: 30));
    Map<String, dynamic> data = {};
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map) data = Map<String, dynamic>.from(decoded);
    } catch (_) {}
    if (response.statusCode < 200 || response.statusCode >= 300 || data['success'] != true) {
      throw FaxApiException(data['message']?.toString() ?? 'Fax service unavailable.',
        statusCode: response.statusCode);
    }
    return data;
  }

  static Future<File> adminDocument(int id) async {
    final response = await http.get(_uri('/admin/inbox/$id/document'),
      headers: await _headers()).timeout(const Duration(seconds: 30));
    if (response.statusCode != 200) {
      throw const FaxApiException('Unable to open this incoming document.');
    }
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/netphone_admin_fax_$id.pdf');
    await file.writeAsBytes(response.bodyBytes, flush: true);
    return file;
  }

  static String usd(dynamic value) {
    final number = double.tryParse(value?.toString() ?? '') ?? 0;
    var text = number.toStringAsFixed(6);
    while (text.endsWith('0') && text.indexOf('.') < text.length - 3) {
      text = text.substring(0, text.length - 1);
    }
    return '\$$text';
  }
}
