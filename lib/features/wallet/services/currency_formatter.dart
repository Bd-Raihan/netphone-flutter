import 'package:intl/intl.dart';

class CurrencyFormatter {
  CurrencyFormatter._();

  static String symbolFor(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'USD':
        return r'$';
      case 'BDT':
        return '৳';
      case 'INR':
        return '₹';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'KWD':
        return 'KWD';
      case 'SAR':
        return 'SAR';
      case 'AED':
        return 'AED';
      case 'QAR':
        return 'QAR';
      case 'OMR':
        return 'OMR';
      case 'BHD':
        return 'BHD';
      case 'PHP':
        return '₱';
      case 'PKR':
        return 'Rs';
      case 'TRY':
        return '₺';
      case 'EGP':
        return 'E£';
      case 'CNY':
        return '¥';
      default:
        return currencyCode.toUpperCase();
    }
  }

  static int decimalsFor(String currencyCode) {
    switch (currencyCode.toUpperCase()) {
      case 'KWD':
      case 'BHD':
      case 'OMR':
        return 3;
      case 'JPY':
      case 'KRW':
        return 0;
      default:
        return 2;
    }
  }

  static String formatDisplayAmount(double amount, String currencyCode) {
    final code = currencyCode.toUpperCase();
    final decimals = decimalsFor(code);
    final formatted = NumberFormat('#,##0.${'0' * decimals}').format(amount);
    final symbol = symbolFor(code);

    if (code == 'USD' ||
        code == 'BDT' ||
        code == 'INR' ||
        code == 'EUR' ||
        code == 'GBP') {
      return '$symbol$formatted';
    }

    return '$formatted $symbol';
  }

  static String formatUsd(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }
}
