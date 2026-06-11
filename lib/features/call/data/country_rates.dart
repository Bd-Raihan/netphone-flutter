class CountryRate {
  final String countryName;

  final String countryCode;

  final double ratePerMinute;

  CountryRate({
    required this.countryName,
    required this.countryCode,
    required this.ratePerMinute,
  });
}

/// ======================================
/// Country Rates List
/// ======================================

final List<CountryRate> countryRates = [
  CountryRate(
    countryName: "Bangladesh",
    countryCode: "+880",
    ratePerMinute: 0.004,
  ),

  CountryRate(countryName: "India", countryCode: "+91", ratePerMinute: 0.006),

  CountryRate(
    countryName: "Pakistan",
    countryCode: "+92",
    ratePerMinute: 0.005,
  ),

  CountryRate(countryName: "USA", countryCode: "+1", ratePerMinute: 0.010),

  CountryRate(countryName: "Kuwait", countryCode: "+965", ratePerMinute: 0.013),
];

/// ======================================
/// Detect Country From Number
/// ======================================

CountryRate getCountryRate(String phoneNumber) {
  for (var country in countryRates) {
    if (phoneNumber.startsWith(country.countryCode)) {
      return country;
    }
  }

  /// Default
  return CountryRate(
    countryName: "Unknown",
    countryCode: "",
    ratePerMinute: 0.008,
  );
}
