class CountryRate {
  final String countryName;
  final String countryCode;
  final double usdRatePerMinute;

  CountryRate({
    required this.countryName,
    required this.countryCode,
    required this.usdRatePerMinute,
  });
}

final List<CountryRate> countryRates = [
  CountryRate(
    countryName: "Bangladesh",
    countryCode: "+880",
    usdRatePerMinute: 0.013,
  ),
  CountryRate(
    countryName: "India",
    countryCode: "+91",
    usdRatePerMinute: 0.018,
  ),
  CountryRate(
    countryName: "Pakistan",
    countryCode: "+92",
    usdRatePerMinute: 0.016,
  ),
  CountryRate(countryName: "USA", countryCode: "+1", usdRatePerMinute: 0.010),
  CountryRate(
    countryName: "Kuwait",
    countryCode: "+965",
    usdRatePerMinute: 0.040,
  ),
  CountryRate(
    countryName: "Saudi Arabia",
    countryCode: "+966",
    usdRatePerMinute: 0.030,
  ),
  CountryRate(
    countryName: "United Arab Emirates",
    countryCode: "+971",
    usdRatePerMinute: 0.025,
  ),
  CountryRate(
    countryName: "Qatar",
    countryCode: "+974",
    usdRatePerMinute: 0.035,
  ),

  CountryRate(
    countryName: "Oman",
    countryCode: "+968",
    usdRatePerMinute: 0.028,
  ),

  CountryRate(
    countryName: "Bahrain",
    countryCode: "+973",
    usdRatePerMinute: 0.032,
  ),

  CountryRate(
    countryName: "Egypt",
    countryCode: "+20",
    usdRatePerMinute: 0.015,
  ),

  CountryRate(
    countryName: "Jordan",
    countryCode: "+962",
    usdRatePerMinute: 0.022,
  ),

  CountryRate(
    countryName: "Lebanon",
    countryCode: "+961",
    usdRatePerMinute: 0.027,
  ),

  CountryRate(
    countryName: "Morocco",
    countryCode: "+212",
    usdRatePerMinute: 0.018,
  ),

  CountryRate(
    countryName: "Tunisia",
    countryCode: "+216",
    usdRatePerMinute: 0.020,
  ),

  CountryRate(
    countryName: "Algeria",
    countryCode: "+213",
    usdRatePerMinute: 0.017,
  ),

  CountryRate(
    countryName: "Libya",
    countryCode: "+218",
    usdRatePerMinute: 0.019,
  ),

  CountryRate(
    countryName: "Sudan",
    countryCode: "+249",
    usdRatePerMinute: 0.014,
  ),

  CountryRate(
    countryName: "Iraq",
    countryCode: "+964",
    usdRatePerMinute: 0.021,
  ),

  CountryRate(
    countryName: "Syria",
    countryCode: "+963",
    usdRatePerMinute: 0.023,
  ),

  CountryRate(
    countryName: "Yemen",
    countryCode: "+967",
    usdRatePerMinute: 0.026,
  ),

  CountryRate(
    countryName: "Afghanistan",
    countryCode: "+93",
    usdRatePerMinute: 0.012,
  ),

  CountryRate(
    countryName: "Sri Lanka",
    countryCode: "+94",
    usdRatePerMinute: 0.014,
  ),

  CountryRate(
    countryName: "Nepal",
    countryCode: "+977",
    usdRatePerMinute: 0.016,
  ),

  CountryRate(
    countryName: "Myanmar",
    countryCode: "+95",
    usdRatePerMinute: 0.018,
  ),

  CountryRate(
    countryName: "Thailand",
    countryCode: "+66",
    usdRatePerMinute: 0.020,
  ),

  CountryRate(
    countryName: "Vietnam",
    countryCode: "+84",
    usdRatePerMinute: 0.022,
  ),

  CountryRate(
    countryName: "Indonesia",
    countryCode: "+62",
    usdRatePerMinute: 0.019,
  ),

  CountryRate(
    countryName: "Philippines",
    countryCode: "+63",
    usdRatePerMinute: 0.021,
  ),

  CountryRate(
    countryName: "Malaysia",
    countryCode: "+60",
    usdRatePerMinute: 0.017,
  ),

  CountryRate(
    countryName: "Singapore",
    countryCode: "+65",
    usdRatePerMinute: 0.015,
  ),

  CountryRate(
    countryName: "Brunei",
    countryCode: "+673",
    usdRatePerMinute: 0.018,
  ),

  CountryRate(
    countryName: "Cambodia",
    countryCode: "+855",
    usdRatePerMinute: 0.020,
  ),

  CountryRate(
    countryName: "Laos",
    countryCode: "+856",
    usdRatePerMinute: 0.022,
  ),

  CountryRate(
    countryName: "Myanmar",
    countryCode: "+95",
    usdRatePerMinute: 0.018,
  ),

  CountryRate(
    countryName: "Timor-Leste",
    countryCode: "+670",
    usdRatePerMinute: 0.025,
  ),

  CountryRate(
    countryName: "Bhutan",
    countryCode: "+975",
    usdRatePerMinute: 0.019,
  ),

  CountryRate(
    countryName: "Maldives",
    countryCode: "+960",
    usdRatePerMinute: 0.021,
  ),

  CountryRate(
    countryName: "Mongolia",
    countryCode: "+976",
    usdRatePerMinute: 0.023,
  ),

  CountryRate(
    countryName: "North Korea",
    countryCode: "+850",
    usdRatePerMinute: 0.030,
  ),

  CountryRate(
    countryName: "South Korea",
    countryCode: "+82",
    usdRatePerMinute: 0.015,
  ),

  CountryRate(
    countryName: "Japan",
    countryCode: "+81",
    usdRatePerMinute: 0.012,
  ),

  CountryRate(
    countryName: "China",
    countryCode: "+86",
    usdRatePerMinute: 0.018,
  ),

  CountryRate(
    countryName: "Hong Kong",
    countryCode: "+852",
    usdRatePerMinute: 0.020,
  ),

  CountryRate(
    countryName: "Macau",
    countryCode: "+853",
    usdRatePerMinute: 0.022,
  ),

  CountryRate(
    countryName: "Taiwan",
    countryCode: "+886",
    usdRatePerMinute: 0.019,
  ),
];

CountryRate getCountryRate(String phoneNumber) {
  for (var country in countryRates) {
    if (phoneNumber.startsWith(country.countryCode)) {
      return country;
    }
  }

  return CountryRate(
    countryName: "Unknown",
    countryCode: "",
    usdRatePerMinute: 0.020,
  );
}
