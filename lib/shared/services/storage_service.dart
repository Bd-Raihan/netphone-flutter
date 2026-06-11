import 'package:shared_preferences/shared_preferences.dart';

/// =======================================================
/// StorageService
///
/// কাজ:
/// - Login token save করবে
/// - User role save করবে
/// - Phone save করবে
/// - App এর যেকোনো জায়গা থেকে read করা যাবে
/// - Logout হলে clear করবে
/// =======================================================
class StorageService {
  /// =====================================
  /// Access Token save
  /// JWT token এখানে save হবে
  /// =====================================
  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString("access_token", token);
  }

  /// =====================================
  /// User Role save
  /// admin / user
  /// =====================================
  static Future<void> saveRole(String role) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString("user_role", role);
  }

  /// =====================================
  /// Phone save
  /// =====================================
  static Future<void> savePhone(String phone) async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.setString("user_phone", phone);
  }

  /// =====================================
  /// Access Token read
  /// =====================================
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString("access_token");
  }

  /// =====================================
  /// User Role read
  /// =====================================
  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString("user_role");
  }

  /// =====================================
  /// Phone read
  /// =====================================
  static Future<String?> getPhone() async {
    final prefs = await SharedPreferences.getInstance();

    return prefs.getString("user_phone");
  }

  /// =====================================
  /// Check Login
  /// Token আছে কিনা check করবে
  /// =====================================
  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString("access_token");

    return token != null && token.isNotEmpty;
  }

  /// =====================================
  /// শুধু token clear করবে
  /// (logout button এ use হবে)
  /// =====================================
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove("access_token");
    await prefs.remove("user_role");
    await prefs.remove("user_phone");
  }

  /// =====================================
  /// সব clear করবে
  /// =====================================
  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.clear();
  }
}
