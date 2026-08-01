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
/// TRANSACTION MODEL
class WalletTransaction {
  final String type;

  /// Legacy compatibility fields.
  final int amountCents;
  final int balanceAfterCents;

  /// Final exact USD values.
  final double amountUsd;
  final double balanceAfterUsd;

  final String createdAt;
  final Map<String, dynamic>? meta;

  const WalletTransaction({
    required this.type,
    required this.amountCents,
    required this.balanceAfterCents,
    required this.amountUsd,
    required this.balanceAfterUsd,
    required this.createdAt,
    this.meta,
  });

  static int _parseInt(dynamic value) {
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  static double? _parseDouble(dynamic value) {
    final parsed = double.tryParse(value?.toString() ?? '');

    if (parsed == null || !parsed.isFinite) {
      return null;
    }

    return parsed;
  }

  static double _resolveUsd({
    required Map<String, dynamic> json,
    required String usdKey,
    required String microUsdKey,
    required String centsKey,
  }) {
    /// 1. Backend direct decimal USD.
    final directUsd = _parseDouble(json[usdKey]);

    if (directUsd != null) {
      return directUsd;
    }

    /// 2. Exact micro-USD.
    final microUsd = int.tryParse(json[microUsdKey]?.toString() ?? '');

    if (microUsd != null) {
      return microUsd / 1000000.0;
    }

    /// 3. Legacy cents fallback.
    final cents = _parseInt(json[centsKey]);

    return cents / 100.0;
  }

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
    final rawMeta = json['meta'];

    return WalletTransaction(
      type: json['type']?.toString() ?? '',

      amountCents: _parseInt(json['amount_cents']),

      balanceAfterCents: _parseInt(json['balance_after_cents']),

      amountUsd: _resolveUsd(
        json: json,
        usdKey: 'amount_usd',
        microUsdKey: 'amount_microusd',
        centsKey: 'amount_cents',
      ),

      balanceAfterUsd: _resolveUsd(
        json: json,
        usdKey: 'balance_after_usd',
        microUsdKey: 'balance_after_microusd',
        centsKey: 'balance_after_cents',
      ),

      createdAt: json['created_at']?.toString() ?? '',

      meta: rawMeta is Map ? Map<String, dynamic>.from(rawMeta) : null,
    );
  }

  /// Existing Flutter screens যেন না ভাঙে।
  double get amount => amountUsd;

  double get balanceAfter => balanceAfterUsd;
}
