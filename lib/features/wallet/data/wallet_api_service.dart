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

      return balanceCents / 100;
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
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    print("TX STATUS: ${response.statusCode}");
    print("TX BODY: ${response.body}");

    if (response.statusCode != 200) return [];

    final data = jsonDecode(response.body);

    final dynamic rawList =
        data["items"] ??
        data["transactions"] ??
        data["data"]?["items"] ??
        data["data"]?["transactions"];

    if (rawList is! List) {
      print("TX PARSE ERROR: transactions list not found");
      return [];
    }

    final result = <WalletTransaction>[];

    for (final item in rawList) {
      try {
        result.add(WalletTransaction.fromJson(item));
      } catch (e) {
        print("TX ITEM PARSE ERROR: $e");
        print("TX ITEM: $item");
      }
    }

    print("TX PARSED COUNT: ${result.length}");
    return result;
  } catch (e) {
    print("TX ERROR: $e");
    return [];
  }
}

/// ===============================
/// CREDIT WALLET (RECHARGE)
/// ===============================
Future<bool> creditWalletBalance(double amount) async {
  try {
    final amountCents = (amount * 100).round();

    final response = await http.post(
      Uri.parse("${AppConfig.baseUrl}/api/wallet/credit"),

      headers: {
        "Authorization": "Bearer ${await getToken()}",
        "Content-Type": "application/json",
      },

      body: jsonEncode({
        "amount_cents": amountCents,
        "currency": "USD",
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
    final amountCents = (amount * 100).round();

    final response = await http.post(
      Uri.parse("${AppConfig.baseUrl}/api/wallet/debit"),

      headers: {
        "Authorization": "Bearer ${await getToken()}",
        "Content-Type": "application/json",
      },

      body: jsonEncode({"amount_cents": amountCents, "currency": "USD"}),
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
