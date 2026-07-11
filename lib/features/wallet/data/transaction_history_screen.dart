import 'package:flutter/material.dart';

import '../data/wallet_data.dart';
import '../data/wallet_api_service.dart';
import '../../../shared/services/storage_service.dart';
import '../services/exchange_rate_service.dart';
import '../services/country_currency_service.dart';
import '../services/currency_formatter.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() =>
      _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  List<WalletTransaction> transactions = [];
  bool loading = true;
  String displayCurrencyCode = 'USD';
  String userPhoneE164 = '';

  @override
  void initState() {
    super.initState();
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    final phone = await StorageService.getPhone();
    await ExchangeRateService.instance.loadRates();
    final items = await fetchWalletTransactions();

    if (mounted) {
      setState(() {
        userPhoneE164 = phone ?? '';
        displayCurrencyCode = CountryCurrencyService.currencyFromPhone(phone);
        transactions = items;
        loading = false;
      });
    }
  }

  String getTitle(String type) {
    switch (type) {
      case 'admin_credit':
        return 'Recharge';
      case 'call_charge':
        return 'Call Charge';
      case 'admin_debit':
        return 'Debit';
      case 'transfer_sent':
        return 'Transfer';
      case 'transfer_received':
        return 'Received';
      case 'recharge':
        return 'Recharge';
      default:
        return type.replaceAll('_', ' ');
    }
  }

  bool isPositive(String type) {
    return type == 'admin_credit' ||
        type == 'transfer_received' ||
        type == 'recharge';
  }

  String formatDisplayFromUsd(double usdAmount) {
    final displayAmount = ExchangeRateService.instance.convertUsdTo(
      usdAmount,
      displayCurrencyCode,
    );

    return CurrencyFormatter.formatDisplayAmount(
      displayAmount,
      displayCurrencyCode,
    );
  }

  String formatUsd(double usdAmount) {
    return CurrencyFormatter.formatUsd(usdAmount);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text('Transaction History'),
        backgroundColor: const Color(0xFF1145F5),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : transactions.isEmpty
          ? const Center(
              child: Text(
                'No transactions found',
                style: TextStyle(color: Colors.white70),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final tx = transactions[index];
                final positive = isPositive(tx.type);
                final amountDisplay = formatDisplayFromUsd(tx.amount);
                final amountUsd = formatUsd(tx.amount);
                final balanceDisplay = formatDisplayFromUsd(tx.balanceAfter);
                final balanceUsd = formatUsd(tx.balanceAfter);

                return Card(
                  color: Colors.grey[900],
                  margin: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                getTitle(tx.type),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '${positive ? '+' : '-'}$amountDisplay',
                              style: TextStyle(
                                color: positive ? Colors.green : Colors.red,
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        if (tx.meta != null) ...[
                          if (tx.meta!['phone_e164'] != null)
                            _infoText('Phone: ${tx.meta!['phone_e164']}'),
                          if (tx.meta!['sender_phone'] != null)
                            _infoText('From: ${tx.meta!['sender_phone']}'),
                          if (tx.meta!['receiver_phone'] != null)
                            _infoText('To: ${tx.meta!['receiver_phone']}'),
                          if (tx.meta!['tx_hash'] != null)
                            _infoText('TXID: ${tx.meta!['tx_hash']}'),
                        ],

                        const SizedBox(height: 8),

                        Text(
                          'Balance: $balanceDisplay  ≈ $balanceUsd\n${tx.createdAt}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.35,
                          ),
                        ),

                        if (displayCurrencyCode != 'USD')
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              'Amount USD: $amountUsd',
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _infoText(String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Text(
        value,
        style: const TextStyle(color: Colors.white54, fontSize: 12),
      ),
    );
  }
}
