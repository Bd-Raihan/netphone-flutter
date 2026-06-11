import '../data/wallet_api_service.dart';

/// =======================================
/// SINGLE REAL BALANCE SOURCE
double currentBalance = 0.000;

/// =======================================
/// USD Conversion Rate
const double usdRate = 3.25;

/// Minutes Calculation
int getRemainingMinutes() {
  const double perMinuteRate = 0.004;
  return (currentBalance / perMinuteRate).floor();
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

  double get amount => amountCents / 1000;
  double get balanceAfter => balanceAfterCents / 1000;
}
