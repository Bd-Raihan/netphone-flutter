import '../data/wallet_api_service.dart';
import '../../../shared/services/storage_service.dart';

/// =======================================
/// SINGLE REAL BALANCE SOURCE
/// Database balance_cents = USD cents
/// 100 cents = 1.00 USD
double currentBalance = 0.00;

/// =======================================
/// Display currency model
class DisplayCurrency {
  final String code;
  final String symbol;
  final double rateFromUsd;

  const DisplayCurrency({
    required this.code,
    required this.symbol,
    required this.rateFromUsd,
  });
}

/// =======================================
/// Country/phone based currency
DisplayCurrency getDisplayCurrencyByPhone(String? phone) {
  final p = phone ?? '';

  if (p.startsWith('+880')) {
    return const DisplayCurrency(code: 'BDT', symbol: '৳', rateFromUsd: 122.00);
  }

  if (p.startsWith('+965')) {
    return const DisplayCurrency(
      code: 'KWD',
      symbol: 'KWD',
      rateFromUsd: 0.307,
    );
  }

  if (p.startsWith('+91')) {
    return const DisplayCurrency(code: 'INR', symbol: '₹', rateFromUsd: 83.00);
  }

  if (p.startsWith('+966')) {
    return const DisplayCurrency(code: 'SAR', symbol: 'SAR', rateFromUsd: 3.75);
  }

  if (p.startsWith('+971')) {
    return const DisplayCurrency(code: 'AED', symbol: 'AED', rateFromUsd: 3.67);
  }

  return const DisplayCurrency(code: 'USD', symbol: r'$', rateFromUsd: 1.00);
}

/// =======================================
/// Minutes Calculation
/// For now: 1 USD = 25 minutes
int getRemainingMinutes() {
  const double perMinuteRateUsd = 0.08; // 1 USD = 12.5 minutes
  return (currentBalance / perMinuteRateUsd).floor();
}

/// =======================================
/// TRANSACTION MODEL
class WalletTransaction {
  final String type;
  final int amountCents;
  final int balanceAfterCents;
  final String createdAt;
  final Map<String, dynamic>? meta;

  WalletTransaction({
    required this.type,
    required this.amountCents,
    required this.balanceAfterCents,
    required this.createdAt,
    this.meta,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    return WalletTransaction(
      type: json['type'] ?? '',
      amountCents: int.parse(json['amount_cents'].toString()),
      balanceAfterCents: int.parse(json['balance_after_cents'].toString()),
      createdAt: json['created_at'] ?? '',
      meta: json['meta'],
    );
  }

  double get amount => amountCents / 100;
  double get balanceAfter => balanceAfterCents / 100;
}
