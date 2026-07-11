import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../shared/services/storage_service.dart';
import '../models/admin_content_page_model.dart';

class AdminContentService {
  static const Duration _timeout = Duration(seconds: 20);

  static Future<Map<String, String>> _headers({
    bool includeJsonContentType = false,
  }) async {
    final token = await StorageService.getToken();

    if (token == null || token.trim().isEmpty) {
      throw Exception('Invalid token. Please logout and login again.');
    }

    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      if (includeJsonContentType) 'Content-Type': 'application/json',
    };
  }

  static Future<List<AdminContentPageModel>> getAllPages() async {
    final uri = Uri.parse('${AppConfig.baseUrl}/api/admin/content/pages');

    final response = await http
        .get(uri, headers: await _headers())
        .timeout(_timeout);

    final data = _decodeResponse(response);

    if (response.statusCode != 200 || data['ok'] != true) {
      throw Exception(
        data['message']?.toString() ?? 'Failed to load content pages',
      );
    }

    final rawItems = data['items'];

    if (rawItems is! List) {
      return [];
    }

    return rawItems
        .whereType<Map>()
        .map(
          (item) =>
              AdminContentPageModel.fromJson(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  static Future<AdminContentPageModel> getPageById(int id) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/api/admin/content/pages/$id');

    final response = await http
        .get(uri, headers: await _headers())
        .timeout(_timeout);

    final data = _decodeResponse(response);

    if (response.statusCode != 200 || data['ok'] != true) {
      throw Exception(data['message']?.toString() ?? 'Failed to load page');
    }

    final page = data['page'];

    if (page is! Map) {
      throw Exception('Invalid page response');
    }

    return AdminContentPageModel.fromJson(Map<String, dynamic>.from(page));
  }

  static Future<AdminContentPageModel> createPage({
    required String slug,
    required String title,
    required String content,
    required String language,
    required bool isActive,
  }) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/api/admin/content/pages');

    final response = await http
        .post(
          uri,
          headers: await _headers(includeJsonContentType: true),
          body: jsonEncode({
            'slug': slug.trim(),
            'title': title.trim(),
            'content': content.trim(),
            'language': language.trim().toLowerCase(),
            'is_active': isActive,
          }),
        )
        .timeout(_timeout);

    final data = _decodeResponse(response);

    if (response.statusCode != 201 || data['ok'] != true) {
      throw Exception(data['message']?.toString() ?? 'Failed to create page');
    }

    final page = data['page'];

    if (page is! Map) {
      throw Exception('Invalid create response');
    }

    return AdminContentPageModel.fromJson(Map<String, dynamic>.from(page));
  }

  static Future<AdminContentPageModel> updatePage({
    required int id,
    required String slug,
    required String title,
    required String content,
    required String language,
    required bool isActive,
  }) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/api/admin/content/pages/$id');

    final response = await http
        .put(
          uri,
          headers: await _headers(includeJsonContentType: true),
          body: jsonEncode({
            'slug': slug.trim(),
            'title': title.trim(),
            'content': content.trim(),
            'language': language.trim().toLowerCase(),
            'is_active': isActive,
          }),
        )
        .timeout(_timeout);

    final data = _decodeResponse(response);

    if (response.statusCode != 200 || data['ok'] != true) {
      throw Exception(data['message']?.toString() ?? 'Failed to update page');
    }

    final page = data['page'];

    if (page is! Map) {
      throw Exception('Invalid update response');
    }

    return AdminContentPageModel.fromJson(Map<String, dynamic>.from(page));
  }

  static Future<void> deletePage(int id) async {
    final uri = Uri.parse('${AppConfig.baseUrl}/api/admin/content/pages/$id');

    final response = await http
        .delete(uri, headers: await _headers())
        .timeout(_timeout);

    final data = _decodeResponse(response);

    if (response.statusCode != 200 || data['ok'] != true) {
      throw Exception(data['message']?.toString() ?? 'Failed to delete page');
    }
  }

  static Map<String, dynamic> _decodeResponse(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }

      return {'ok': false, 'message': 'Invalid server response'};
    } on FormatException {
      return {
        'ok': false,
        'message':
            'Server returned invalid data. Status: ${response.statusCode}',
      };
    }
  }
}
