import 'dart:convert';

import 'package:http/http.dart' as http;

/// Wallet Engine V2
/// Base currency is always USD.
/// UI converts USD -> user's display currency.
class ExchangeRateService {
  ExchangeRateService._();

  static final ExchangeRateService instance = ExchangeRateService._();

  static const String baseCurrency = 'USD';

  /// Safe fallback rates. These keep the app running even if live API fails.
  /// 1 USD = rate
  final Map<String, double> _fallbackRates = const {
    'USD': 1.000000,
    'KWD': 0.307000,
    'BDT': 122.000000,
    'INR': 83.000000,
    'SAR': 3.750000,
    'AED': 3.672500,
    'QAR': 3.640000,
    'OMR': 0.385000,
    'BHD': 0.376000,
    'EUR': 0.920000,
    'GBP': 0.780000,
    'PHP': 58.000000,
    'PKR': 278.000000,
    'TRY': 32.000000,
    'EGP': 48.000000,
    'CNY': 7.250000,
  };

  Map<String, double> _rates = {};
  DateTime? _lastUpdated;

  Map<String, double> get rates => _rates.isEmpty ? _fallbackRates : _rates;
  DateTime? get lastUpdated => _lastUpdated;

  /// Call this once after login or before wallet screen load.
  /// Uses public API. If it fails, fallback rates remain active.
  Future<void> loadRates() async {
    try {
      final uri = Uri.parse('https://open.er-api.com/v6/latest/USD');
      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final rawRates = data['rates'];
      if (rawRates is! Map) return;

      final nextRates = <String, double>{};
      for (final entry in rawRates.entries) {
        final key = entry.key.toString().toUpperCase();
        final value = entry.value;
        if (value is num) nextRates[key] = value.toDouble();
      }

      if (nextRates.isNotEmpty) {
        _rates = {..._fallbackRates, ...nextRates, 'USD': 1.0};
        _lastUpdated = DateTime.now();
      }
    } catch (_) {
      // Silent fallback: app must not break because exchange API failed.
      _rates = _fallbackRates;
    }
  }

  double rateFor(String currencyCode) {
    final code = currencyCode.toUpperCase();
    return rates[code] ?? rates['USD'] ?? 1.0;
  }

  double convertUsdTo(double usdAmount, String currencyCode) {
    return usdAmount * rateFor(currencyCode);
  }
}
