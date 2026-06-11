import 'package:flutter/material.dart';
import '../data/wallet_data.dart';
import '../data/wallet_api_service.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  List<WalletTransaction> transactions = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    transactions = await fetchWalletTransactions();

    if (mounted) {
      setState(() {
        loading = false;
      });
    }
  }

  /// =======================================
  /// Transaction title show করবে
  /// =======================================
  String getTitle(String type) {
    switch (type) {
      /// ===========================
      /// Admin recharge
      /// ===========================
      case "admin_credit":
        return "Recharge";

      /// ===========================
      /// Call charge
      /// ===========================
      case "call_charge":
        return "Call Charge";

      /// ===========================
      /// Debit
      /// ===========================
      case "admin_debit":
        return "Debit";

      /// ===========================
      /// Transfer sent
      /// ===========================
      case "transfer_sent":
        return "Transfer";

      /// ===========================
      /// Transfer received
      /// ===========================
      case "transfer_received":
        return "Received";

      default:
        return type;
    }
  }

  /// =======================================
  /// কোন transaction positive
  /// কোনটা negative
  /// =======================================
  bool isPositive(String type) {
    /// টাকা যোগ হয়েছে
    return type == "admin_credit" || type == "transfer_received";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text("Transaction History"),
        backgroundColor: const Color(0xFF1145F5),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final tx = transactions[index];

                return Card(
                  color: Colors.grey[900],
                  margin: const EdgeInsets.all(10),
                  child: ListTile(
                    title: Text(
                      getTitle(tx.type),
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,

                      children: [
                        /// =====================================
                        /// Transaction extra info
                        /// =====================================
                        if (tx.meta != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 4, bottom: 4),

                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,

                              children: [
                                /// ===============================
                                /// Recharge phone
                                /// ===============================
                                if (tx.meta!["phone_e164"] != null)
                                  Text(
                                    "Phone: ${tx.meta!["phone_e164"]}",

                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),

                                /// ===============================
                                /// Transfer sender
                                /// ===============================
                                if (tx.meta!["sender_phone"] != null)
                                  Text(
                                    "From: ${tx.meta!["sender_phone"]}",

                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),

                                /// ===============================
                                /// Transfer receiver
                                /// ===============================
                                if (tx.meta!["receiver_phone"] != null)
                                  Text(
                                    "To: ${tx.meta!["receiver_phone"]}",

                                    style: const TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ),

                        /// =====================================
                        /// Balance + date
                        /// =====================================
                        Text(
                          "Balance: \$${tx.balanceAfter.toStringAsFixed(2)} USD\n${tx.createdAt}",

                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                    trailing: Text(
                      "${isPositive(tx.type) ? "+" : "-"}\$${tx.amount.toStringAsFixed(2)} USD",
                      style: TextStyle(
                        color: isPositive(tx.type) ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
