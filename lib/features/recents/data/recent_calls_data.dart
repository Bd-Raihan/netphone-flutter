import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

List<Map<String, dynamic>> recentCalls = [];

/// ===============================
/// Save Recent Calls
/// ===============================
Future<void> saveRecentCalls() async {
  final prefs = await SharedPreferences.getInstance();

  final String encodedData = jsonEncode(recentCalls);

  await prefs.setString("recent_calls", encodedData);
}

/// ===============================
/// Load Recent Calls
/// ===============================
Future<void> loadRecentCalls() async {
  final prefs = await SharedPreferences.getInstance();

  final String? data = prefs.getString("recent_calls");

  if (data != null) {
    final List decoded = jsonDecode(data);

    recentCalls = decoded
        .map((item) => Map<String, dynamic>.from(item))
        .toList();
  }
}
