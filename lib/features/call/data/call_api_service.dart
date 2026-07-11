import 'dart:convert';
import 'package:http/http.dart' as http;

class CallApiService {
  // In a real application, the baseUrl would be configured in a more flexible way, such as through environment variables or a configuration file. For this example, we will pass it as a parameter to each method.
  static Future<Map<String, dynamic>> getVoiceToken({
    required String token,
    required String baseUrl,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/calls/token'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['ok'] != true) {
      throw Exception(data['message'] ?? 'Voice token failed');
    }

    return data;
  }

  // For testing purposes, we can use a mock API endpoint that simulates the call functionality. In a real application, this would be replaced with the actual backend API.
  static Future<Map<String, dynamic>> startCall({
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

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['ok'] != true) {
      throw Exception(data['reason'] ?? data['message'] ?? 'Call start failed');
    }

    return data;
  }

  // Similarly, we can use a mock API endpoint for ending the call. In a real application, this would also be replaced with the actual backend API.
  static Future<Map<String, dynamic>> endCall({
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

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['ok'] != true) {
      throw Exception(data['reason'] ?? data['message'] ?? 'Call end failed');
    }

    return data;
  }

  // For testing purposes, we can use a mock API endpoint that simulates the call status functionality. In a real application, this would be replaced with the actual backend API.
  static Future<Map<String, dynamic>> getCallStatus({
    required String token,
    required int sessionId,
    required String baseUrl,
  }) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/calls/$sessionId/status'),
      headers: {'Authorization': 'Bearer $token'},
    );

    final data = jsonDecode(response.body);
    if (response.statusCode != 200 || data['ok'] != true) {
      throw Exception(data['message'] ?? 'Call status failed');
    }
    return data;
  }
}
