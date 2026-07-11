class RateModel {
  final String countryName;
  final String countryCode;
  final String prefix;
  final double sellRateUsdPerMin;
  final int pricePerMinCents;

  RateModel({
    required this.countryName,
    required this.countryCode,
    required this.prefix,
    required this.sellRateUsdPerMin,
    required this.pricePerMinCents,
  });

  factory RateModel.fromJson(Map<String, dynamic> json) {
    return RateModel(
      countryName: json['country_name'] ?? 'Unknown',
      countryCode: json['country_code'] ?? '',
      prefix: json['prefix'] ?? '',
      sellRateUsdPerMin:
          double.tryParse(json['sell_rate_usd_per_min'].toString()) ?? 0.0,
      pricePerMinCents: json['price_per_min_cents'] ?? 0,
    );
  }
}
