import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../../core/config/app_config.dart';
import '../../../shared/services/storage_service.dart';
import '../services/country_currency_service.dart';
import '../services/exchange_rate_service.dart';
import '../services/currency_formatter.dart';

class RechargeHistoryScreen extends StatefulWidget {
  const RechargeHistoryScreen({super.key});

  @override
  State<RechargeHistoryScreen> createState() => _RechargeHistoryScreenState();
}

class _RechargeHistoryScreenState extends State<RechargeHistoryScreen> {
  bool isLoading = true;
  String? error;
  List<dynamic> items = [];

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    try {
      setState(() {
        isLoading = true;
        error = null;
      });

      final token = await StorageService.getToken();

      final res = await http.get(
        Uri.parse("${AppConfig.baseUrl}/api/crypto/recharge-history"),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token",
        },
      );

      final data = jsonDecode(res.body);

      if (res.statusCode != 200 || data["ok"] != true) {
        throw Exception(data["message"] ?? "Failed to load recharge history");
      }

      setState(() {
        items = data["requests"] ?? data["items"] ?? [];
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Color statusColor(String status) {
    switch (status.toLowerCase()) {
      case "approved":
        return Colors.green;
      case "rejected":
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  // Convert USD amount to local currency based on phone number
  String formatLocalAmount(dynamic amountUsd, String phone) {
    final usd = double.tryParse(amountUsd.toString()) ?? 0.0;

    final currencyCode = CountryCurrencyService.currencyFromPhone(phone);

    final rate = ExchangeRateService.instance.rateFor(currencyCode);

    final localAmount = usd * rate;

    return CurrencyFormatter.formatDisplayAmount(localAmount, currencyCode);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: const Color(0xFF1145F5),
        title: const Text("Recharge History"),
      ),
      body: RefreshIndicator(
        onRefresh: loadHistory,
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : error != null
            ? ListView(
                children: [
                  const SizedBox(height: 120),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Text(
                        error!,
                        style: const TextStyle(color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ],
              )
            : items.isEmpty
            ? ListView(
                children: const [
                  SizedBox(height: 220),
                  Center(
                    child: Text(
                      "No recharge history found",
                      style: TextStyle(color: Colors.white70),
                    ),
                  ),
                ],
              )
            : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];

                  final phone = item["phone_e164"]?.toString() ?? "";
                  final usd =
                      double.tryParse(item["amount_usd"].toString()) ?? 0.0;

                  final status = item["status"]?.toString() ?? "pending";

                  return Card(
                    color: const Color(0xFF1E1E1E),
                    margin: const EdgeInsets.only(bottom: 14),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${item["crypto_currency"] ?? "USDT"} ${item["network"] ?? ""}",
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                status.toUpperCase(),
                                style: TextStyle(
                                  color: statusColor(status),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "${formatLocalAmount(usd, phone)} ≈ \$${usd.toStringAsFixed(2)}",
                            style: const TextStyle(
                              color: Colors.greenAccent,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "TXID: ${item["tx_hash"] ?? "-"}",
                            style: const TextStyle(color: Colors.white70),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            "Date: ${item["created_at"] ?? "-"}",
                            style: const TextStyle(color: Colors.white54),
                          ),
                          if (item["admin_note"] != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: Text(
                                "Note: ${item["admin_note"]}",
                                style: const TextStyle(color: Colors.white54),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
