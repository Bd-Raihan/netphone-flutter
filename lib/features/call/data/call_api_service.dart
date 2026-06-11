import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/app_config.dart';

class CallApiService {
  static Future<Map<String, dynamic>?> startCall({
    required String token,
    required String phoneNumber,
    required String baseUrl,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/calls/start'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'to_phone_e164': phoneNumber}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    }

    return null;
  }

  static Future<bool> endCall({
    required String token,
    required int sessionId,
    required String baseUrl,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/calls/$sessionId/end'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    return response.statusCode == 200;
  }
}
