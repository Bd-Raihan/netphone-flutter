import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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
      case 'fax_charge':
        return 'Fax Charge';
      case 'fax_refund':
        return 'Fax Refund';
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
    return type == 'fax_refund' ||
        type == 'admin_credit' ||
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

  String formatUsdAmount(double usdAmount, {bool exact = false}) {
    if (!usdAmount.isFinite) {
      return r'$0.00';
    }

    if (exact) {
      return '\$${usdAmount.abs().toStringAsFixed(4)}';
    }

    return CurrencyFormatter.formatUsd(usdAmount.abs());
  }

  String? _readMetaText(Map<String, dynamic>? meta, List<String> keys) {
    if (meta == null) {
      return null;
    }

    for (final key in keys) {
      final value = meta[key]?.toString().trim();

      if (value != null && value.isNotEmpty) {
        return value;
      }
    }

    return null;
  }

  String? getTransactionPhone(WalletTransaction tx) {
    final meta = tx.meta;

    switch (tx.type) {
      case 'fax_charge':
      case 'fax_refund':
        return _readMetaText(meta, const ['to_phone_e164', 'from_phone_e164']);

      case 'call_charge':
        return _readMetaText(meta, const [
          'to_phone_e164',
          'phone_e164',
          'destination_phone_e164',
          'destination_phone',
          'called_number',
          'to_phone',
          'recipient_phone',
        ]);

      case 'transfer_sent':
        return _readMetaText(meta, const [
          'receiver_phone',
          'to_phone_e164',
          'recipient_phone',
        ]);

      case 'transfer_received':
        return _readMetaText(meta, const ['sender_phone', 'from_phone_e164']);

      default:
        return _readMetaText(meta, const [
          'phone_e164',
          'to_phone_e164',
          'sender_phone',
          'receiver_phone',
        ]);
    }
  }

  String formatTransactionDate(String rawValue) {
    final raw = rawValue.trim();

    if (raw.isEmpty) {
      return 'Date unavailable';
    }

    try {
      final parsed = DateTime.parse(raw).toLocal();

      return DateFormat('dd MMM yyyy • hh:mm a').format(parsed);
    } catch (_) {
      return raw;
    }
  }

  String _formatDuration(dynamic rawSeconds) {
    final totalSeconds = int.tryParse(rawSeconds?.toString() ?? '') ?? 0;

    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
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
                final isFax = tx.type == 'fax_charge' || tx.type == 'fax_refund';
                final amountDisplay = isFax && displayCurrencyCode == 'USD'
                    ? '\$${tx.amount.abs().toStringAsFixed(6)}'
                    : formatDisplayFromUsd(tx.amount);
                final amountUsd = formatUsdAmount(
                  tx.amount,
                  exact: tx.type == 'call_charge' || isFax,
                );

                final balanceDisplay = formatDisplayFromUsd(tx.balanceAfter);
                final balanceUsd = formatUsdAmount(tx.balanceAfter);
                final transactionPhone = getTransactionPhone(tx);
                final formattedDate = formatTransactionDate(tx.createdAt);

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

                        if (transactionPhone != null) ...[
                          _infoText(
                            tx.type == 'call_charge'
                                ? 'Called number: $transactionPhone'
                                : tx.type == 'transfer_received'
                                ? 'From: $transactionPhone'
                                : tx.type == 'transfer_sent'
                                ? 'To: $transactionPhone'
                                : 'Phone: $transactionPhone',
                          ),
                        ],

                        if (isFax && tx.meta?['pages'] != null)
                          _infoText('Fax: ${tx.meta?['pages']} pages · ${tx.meta?['direction'] ?? ''}'),

                        if (tx.meta?['duration_sec'] != null)
                          _infoText(
                            'Duration: '
                            '${_formatDuration(tx.meta!['duration_sec'])}',
                          ),

                        if (tx.meta?['billable_seconds'] != null)
                          _infoText(
                            'Billable time: '
                            '${_formatDuration(tx.meta!['billable_seconds'])}',
                          ),

                        if (tx.meta?['tx_hash'] != null)
                          _infoText('TXID: ${tx.meta!['tx_hash']}'),

                        const SizedBox(height: 8),

                        Text(
                          'Balance: $balanceDisplay  ≈ $balanceUsd',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.35,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Row(
                          children: [
                            const Icon(
                              Icons.schedule,
                              color: Colors.white38,
                              size: 15,
                            ),

                            const SizedBox(width: 6),

                            Expanded(
                              child: Text(
                                formattedDate,
                                style: const TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
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
