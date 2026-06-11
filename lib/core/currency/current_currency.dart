class CurrencyInfo {
  final String currency;
  final double exchangeRate;

  const CurrencyInfo({required this.currency, required this.exchangeRate});
}

/// Kuwait
const CurrencyInfo currentCurrency = CurrencyInfo(
  currency: "KWD",
  exchangeRate: 0.31,
);
