import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/app_config.dart';
import 'wallet_data.dart';

/// ===============================
/// GET TOKEN
/// ===============================
Future<String?> getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString("access_token");
}

/// ===============================
/// FETCH BALANCE
/// ===============================
Future<double> fetchWalletBalance() async {
  try {
    final token = await getToken();

    final response = await http.get(
      Uri.parse("${AppConfig.baseUrl}/api/wallet/me"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    print("BALANCE STATUS: ${response.statusCode}");
    print("BALANCE BODY: ${response.body}");

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final balanceCents = int.parse(
        data["wallet"]["balance_cents"].toString(),
      );

      return balanceCents / 1000;
    }

    return 0.000;
  } catch (e) {
    print("BALANCE ERROR:");
    print(e);
    return 0.000;
  }
}

/// ===============================
/// FETCH TRANSACTIONS
/// ===============================
Future<List<WalletTransaction>> fetchWalletTransactions() async {
  try {
    final token = await getToken();

    final response = await http.get(
      Uri.parse("${AppConfig.baseUrl}/api/wallet/tx"),
      headers: {"Authorization": "Bearer $token"},
    );

    print("TX STATUS:");
    print(response.statusCode);

    print("TX BODY:");
    print(response.body);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      final List txList = data["items"];

      return txList.map((e) => WalletTransaction.fromJson(e)).toList();
    }

    return [];
  } catch (e) {
    print("TX ERROR:");
    print(e);
    return [];
  }
}

/// ===============================
/// CREDIT WALLET (RECHARGE)
/// ===============================
Future<bool> creditWalletBalance(double amount) async {
  try {
    final amountCents = (amount * 1000).toInt();

    final response = await http.post(
      Uri.parse("${AppConfig.baseUrl}/api/wallet/credit"),

      headers: {
        "Authorization": "Bearer ${await getToken()}",
        "Content-Type": "application/json",
      },

      body: jsonEncode({
        "amount_cents": amountCents,
        "currency": "KWD",
        "meta": {"type": "mobile_recharge"},
      }),
    );

    print("CREDIT STATUS:");
    print(response.statusCode);

    print("CREDIT BODY:");
    print(response.body);

    if (response.statusCode == 200) {
      return true;
    }

    return false;
  } catch (e) {
    print("CREDIT ERROR:");
    print(e);
    return false;
  }
}

/// ===============================
/// DEDUCT BALANCE
/// ===============================
Future<void> deductWalletBalance(double amount) async {
  try {
    final amountCents = (amount * 1000).toInt();

    final response = await http.post(
      Uri.parse("${AppConfig.baseUrl}/api/wallet/debit"),

      headers: {
        "Authorization": "Bearer ${await getToken()}",
        "Content-Type": "application/json",
      },

      body: jsonEncode({"amount_cents": amountCents, "currency": "KWD"}),
    );

    print("DEBIT STATUS:");
    print(response.statusCode);

    print("DEBIT BODY:");
    print(response.body);
  } catch (e) {
    print("DEBIT ERROR:");
    print(e);
  }
}
