import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../services/crypto_service.dart';
import '../widgets/amount_field.dart';
import '../widgets/tx_hash_field.dart';
import '../widgets/wallet_address_card.dart';
import '../widgets/qr_card.dart';

class RechargeCryptoScreen extends StatefulWidget {
  const RechargeCryptoScreen({super.key});

  @override
  State<RechargeCryptoScreen> createState() => _RechargeCryptoScreenState();
}

class _RechargeCryptoScreenState extends State<RechargeCryptoScreen> {
  final amountController = TextEditingController();
  final txHashController = TextEditingController();

  bool isLoading = false;

  final String walletAddress = "TDZm6J9kfDaNQrvg17c7FeoSjuacB2LfmX";

  @override
  void dispose() {
    amountController.dispose();
    txHashController.dispose();
    super.dispose();
  }

  Future<void> submitRecharge() async {
    final amountText = amountController.text.trim();
    final txHash = txHashController.text.trim();

    if (amountText.isEmpty || txHash.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Amount and TXID are required")),
      );
      return;
    }

    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter valid amount")));
      return;
    }

    try {
      setState(() => isLoading = true);

      await CryptoService.submitRechargeRequest(
        amountUsd: amount,
        txHash: txHash,
        cryptoCurrency: "USDT",
        network: "TRC20",
        walletAddress: walletAddress,
      );

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text("Request Submitted"),
          content: const Text(
            "Your USDT TRC20 recharge request has been submitted. Admin will verify and approve it.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed: $e")));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text("USDT TRC20 Recharge")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              "Send USDT only on TRC20 network. Wrong network or coin may result in permanent loss.",
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),

            QrCard(walletAddress: walletAddress),
            const SizedBox(height: 20),

            WalletAddressCard(walletAddress: walletAddress),
            const SizedBox(height: 20),

            AmountField(controller: amountController),
            const SizedBox(height: 16),

            TxHashField(controller: txHashController),
            const SizedBox(height: 30),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : submitRecharge,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Submit Recharge Request"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
