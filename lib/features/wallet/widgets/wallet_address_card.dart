import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class WalletAddressCard extends StatelessWidget {
  final String walletAddress;

  const WalletAddressCard({super.key, required this.walletAddress});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "USDT TRC20 Wallet Address",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SelectableText(walletAddress),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: walletAddress));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Wallet address copied")),
              );
            },
            icon: const Icon(Icons.copy),
            label: const Text("Copy Address"),
          ),
        ],
      ),
    );
  }
}
