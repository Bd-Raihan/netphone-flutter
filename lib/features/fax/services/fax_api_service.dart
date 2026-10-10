import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/app_config.dart';
import '../models/fax_model.dart';
import '../models/fax_notification_model.dart';

class FaxApiException implements Exception {
  final String message;
  final int? statusCode;

  const FaxApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class FaxApiService {
  static const String _faxPath = '/api/fax';

  // =========================================================
  // Authentication
  // =========================================================

  static Future<String> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');

    if (token == null || token.trim().isEmpty) {
      throw const FaxApiException(
        'Your login session was not found. Please login again.',
        statusCode: 401,
      );
    }

    return token.trim();
  }

  static Future<Map<String, String>> _headers() async {
    final token = await _getAccessToken();

    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  static Uri _uri(String path) {
    return Uri.parse('${AppConfig.baseUrl}$_faxPath$path');
  }

  // =========================================================
  // Upload Fax Document
  // PDF / JPG / JPEG / PNG
  // =========================================================

  static Future<int> uploadDocument(File file) async {
    final token = await _getAccessToken();

    final request = http.MultipartRequest('POST', _uri('/upload'));

    request.headers.addAll({
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
    });

    request.files.add(await http.MultipartFile.fromPath('document', file.path));

    final streamedResponse = await request.send();

    final response = await http.Response.fromStream(streamedResponse);

    final data = _decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FaxApiException(
        _messageFromData(data, 'Unable to upload fax document.'),
        statusCode: response.statusCode,
      );
    }

    final upload = data['upload'];

    if (upload is! Map) {
      throw const FaxApiException('Invalid upload response from server.');
    }

    final uploadId = _toInt(upload['upload_id']);

    if (uploadId == null || uploadId <= 0) {
      throw const FaxApiException('Upload ID was not returned by the server.');
    }

    return uploadId;
  }

  // =========================================================
  // Send Fax
  // =========================================================

  static Future<FaxModel> sendFax({
    required int uploadId,
    required String toNumber,
    String? senderName,
    String? userEmail,
    String? countryCode,
  }) async {
    final response = await http.post(
      _uri('/send'),
      headers: await _headers(),
      body: jsonEncode({
        'upload_id': uploadId,
        'to_number': toNumber.trim(),
        if (senderName != null && senderName.trim().isNotEmpty)
          'sender_name': senderName.trim(),
        if (userEmail != null && userEmail.trim().isNotEmpty)
          'user_email': userEmail.trim(),
        if (countryCode != null && countryCode.trim().isNotEmpty)
          'country_code': countryCode.trim(),
      }),
    );

    final data = _decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FaxApiException(
        _messageFromData(data, 'Unable to send fax.'),
        statusCode: response.statusCode,
      );
    }

    final faxData = data['fax'];

    if (faxData is! Map) {
      throw const FaxApiException('Invalid fax response from server.');
    }

    return FaxModel.fromJson(Map<String, dynamic>.from(faxData));
  }

  // =========================================================
  // Fax History
  // =========================================================

  static Future<List<FaxModel>> getHistory() async {
    final response = await http.get(
      _uri('/history'),
      headers: await _headers(),
    );

    final data = _decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FaxApiException(
        _messageFromData(data, 'Unable to load fax history.'),
        statusCode: response.statusCode,
      );
    }

    final dynamic rawList = data['faxes'] ?? data['history'] ?? data['data'];

    if (rawList == null) {
      return [];
    }

    if (rawList is! List) {
      throw const FaxApiException('Invalid fax history response from server.');
    }

    return rawList
        .whereType<Map>()
        .map((item) => FaxModel.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  // =========================================================
  // Fax Notifications
  // =========================================================

  static Future<List<FaxNotificationModel>> getNotifications() async {
    final response = await http.get(
      _uri('/notifications'),
      headers: await _headers(),
    );

    final data = _decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FaxApiException(
        _messageFromData(data, 'Unable to load fax notifications.'),
        statusCode: response.statusCode,
      );
    }

    final dynamic rawList = data['notifications'] ?? data['data'];

    if (rawList == null) {
      return [];
    }

    if (rawList is! List) {
      throw const FaxApiException('Invalid notification response from server.');
    }

    return rawList
        .whereType<Map>()
        .map(
          (item) =>
              FaxNotificationModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  static Future<void> markNotificationAsRead(int notificationId) async {
    final response = await http.patch(
      _uri('/notifications/$notificationId/read'),
      headers: await _headers(),
    );

    final data = _decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw FaxApiException(
        _messageFromData(data, 'Unable to update notification.'),
        statusCode: response.statusCode,
      );
    }
  }

  // =========================================================
  // Secure Fax Document
  // =========================================================

  static Future<File> downloadDocument({
    required int faxId,
    bool forceDownload = false,
  }) async {
    final token = await _getAccessToken();

    final endpoint = forceDownload ? 'download' : 'view';

    final response = await http.get(
      _uri('/documents/$faxId/$endpoint'),
      headers: {'Authorization': 'Bearer $token', 'Accept': '*/*'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      String message = 'Unable to download fax document.';

      try {
        final decoded = jsonDecode(utf8.decode(response.bodyBytes));

        if (decoded is Map && decoded['message'] != null) {
          message = decoded['message'].toString();
        }
      } catch (_) {}

      throw FaxApiException(message, statusCode: response.statusCode);
    }

    final directory = await getTemporaryDirectory();

    final contentType = response.headers['content-type']?.toLowerCase() ?? '';

    String extension = '.pdf';

    if (contentType.contains('image/jpeg')) {
      extension = '.jpg';
    } else if (contentType.contains('image/png')) {
      extension = '.png';
    }

    final file = File('${directory.path}/netphone_fax_$faxId$extension');

    await file.writeAsBytes(response.bodyBytes, flush: true);

    return file;
  }

  // =========================================================
  // Response Helpers
  // =========================================================

  static Map<String, dynamic> _decodeResponse(http.Response response) {
    if (response.bodyBytes.isEmpty) {
      return <String, dynamic>{};
    }

    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }

      return <String, dynamic>{};
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  static String _messageFromData(Map<String, dynamic> data, String fallback) {
    final message = data['message'];

    if (message != null && message.toString().trim().isNotEmpty) {
      return message.toString();
    }

    return fallback;
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
