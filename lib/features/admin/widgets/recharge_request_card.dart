import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/recharge_request_model.dart';

class RechargeRequestCard extends StatelessWidget {
  final RechargeRequestModel item;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const RechargeRequestCard({
    super.key,
    required this.item,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900],
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.phone,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "${item.amountUsd} USD • ${item.currency} ${item.network}",
              style: const TextStyle(color: Colors.green),
            ),
            const SizedBox(height: 8),
            SelectableText(
              "TXID: ${item.txHash}",
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Text(
              item.createdAt,
              style: const TextStyle(color: Colors.white38, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: onApprove,
                  icon: const Icon(Icons.check),
                  label: const Text("Approve"),
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: onReject,
                  icon: const Icon(Icons.close),
                  label: const Text("Reject"),
                ),
                IconButton(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: item.txHash));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("TXID copied")),
                    );
                  },
                  icon: const Icon(Icons.copy, color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
