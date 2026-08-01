import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/app_config.dart';
import 'wallet_data.dart';

class WalletOverview {
  final double balanceUsd;
  final double estimatedRateUsdPerMinute;

  const WalletOverview({
    required this.balanceUsd,
    required this.estimatedRateUsdPerMinute,
  });
}

/// ===============================
/// GET TOKEN
/// ===============================
Future<String?> getToken() async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString("access_token");
}

Future<WalletOverview> fetchWalletOverview() async {
  try {
    final token = await getToken();

    if (token == null || token.trim().isEmpty) {
      return const WalletOverview(
        balanceUsd: 0.0,
        estimatedRateUsdPerMinute: 0.0,
      );
    }

    final response = await http.get(
      Uri.parse("${AppConfig.baseUrl}/api/wallet/me"),
      headers: {
        "Authorization": "Bearer $token",
        "Content-Type": "application/json",
      },
    );

    print(
      "WALLET OVERVIEW STATUS: "
      "${response.statusCode}",
    );

    print(
      "WALLET OVERVIEW BODY: "
      "${response.body}",
    );

    if (response.statusCode != 200) {
      return const WalletOverview(
        balanceUsd: 0.0,
        estimatedRateUsdPerMinute: 0.0,
      );
    }

    final dynamic decoded = jsonDecode(response.body);

    if (decoded is! Map) {
      return const WalletOverview(
        balanceUsd: 0.0,
        estimatedRateUsdPerMinute: 0.0,
      );
    }

    final data = Map<String, dynamic>.from(decoded);

    final walletRaw = data["wallet"];

    final wallet = walletRaw is Map
        ? Map<String, dynamic>.from(walletRaw)
        : <String, dynamic>{};

    final rateRaw = data["estimated_call_rate"];

    final estimatedRate = rateRaw is Map
        ? Map<String, dynamic>.from(rateRaw)
        : <String, dynamic>{};

    final balanceUsdDirect = double.tryParse(
      wallet["balance_usd"]?.toString() ?? "",
    );

    final balanceMicroUsd = int.tryParse(
      wallet["balance_microusd"]?.toString() ?? "",
    );

    final balanceCents =
        int.tryParse(wallet["balance_cents"]?.toString() ?? "0") ?? 0;

    /// Priority:
    /// 1. Exact balance_usd
    /// 2. Exact balance_microusd
    /// 3. Legacy balance_cents
    final double resolvedBalanceUsd;

    if (balanceUsdDirect != null && balanceUsdDirect.isFinite) {
      resolvedBalanceUsd = balanceUsdDirect;
    } else if (balanceMicroUsd != null) {
      resolvedBalanceUsd = balanceMicroUsd / 1000000.0;
    } else {
      resolvedBalanceUsd = balanceCents / 100.0;
    }

    final rateUsdPerMinute =
        double.tryParse(
          estimatedRate["sell_rate_usd_per_min"]?.toString() ?? "0",
        ) ??
        0.0;

    return WalletOverview(
      balanceUsd: resolvedBalanceUsd,
      estimatedRateUsdPerMinute: rateUsdPerMinute > 0 ? rateUsdPerMinute : 0.0,
    );
  } catch (e) {
    print("WALLET OVERVIEW ERROR: $e");

    return const WalletOverview(
      balanceUsd: 0.0,
      estimatedRateUsdPerMinute: 0.0,
    );
  }
}

/// ===============================
/// FETCH BALANCE
/// ===============================
Future<double> fetchWalletBalance() async {
  final overview = await fetchWalletOverview();

  return overview.balanceUsd;
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
