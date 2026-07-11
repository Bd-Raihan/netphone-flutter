import 'dart:convert';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../shared/services/storage_service.dart';
import '../models/recharge_request_model.dart';

class AdminCryptoService {
  static Future<List<RechargeRequestModel>> fetchPendingRequests() async {
    final token = await StorageService.getToken();

    final response = await http.get(
      Uri.parse("${AppConfig.baseUrl}/api/admin/crypto/pending"),
      headers: {"Authorization": "Bearer $token"},
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data["ok"] == true) {
      final List list = data["data"];
      return list.map((e) => RechargeRequestModel.fromJson(e)).toList();
    }

    throw Exception(data["message"] ?? "Failed to load requests");
  }

  static Future<void> approveRequest(int id) async {
    final token = await StorageService.getToken();

    final response = await http.post(
      Uri.parse("${AppConfig.baseUrl}/api/admin/crypto/$id/approve"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    final data = jsonDecode(response.body);

    if (!(response.statusCode == 200 && data["ok"] == true)) {
      throw Exception(data["message"] ?? "Approve failed");
    }
  }

  static Future<void> rejectRequest(int id, String note) async {
    final token = await StorageService.getToken();

    final response = await http.post(
      Uri.parse("${AppConfig.baseUrl}/api/admin/crypto/$id/reject"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
      body: jsonEncode({"admin_note": note}),
    );

    final data = jsonDecode(response.body);

    if (!(response.statusCode == 200 && data["ok"] == true)) {
      throw Exception(data["message"] ?? "Reject failed");
    }
  }
}
