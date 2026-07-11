class CountryCurrencyService {
  CountryCurrencyService._();

  /// Detect display currency from E.164 phone number.
  /// Example: +880... => BDT, +965... => KWD
  static String currencyFromPhone(String? phoneE164) {
    final phone = (phoneE164 ?? '').replaceAll(RegExp(r'\s+'), '');

    if (phone.startsWith('+880')) return 'BDT'; // Bangladesh
    if (phone.startsWith('+965')) return 'KWD'; // Kuwait
    if (phone.startsWith('+966')) return 'SAR'; // Saudi Arabia
    if (phone.startsWith('+971')) return 'AED'; // UAE
    if (phone.startsWith('+974')) return 'QAR'; // Qatar
    if (phone.startsWith('+968')) return 'OMR'; // Oman
    if (phone.startsWith('+973')) return 'BHD'; // Bahrain
    if (phone.startsWith('+91')) return 'INR'; // India
    if (phone.startsWith('+63')) return 'PHP'; // Philippines
    if (phone.startsWith('+92')) return 'PKR'; // Pakistan
    if (phone.startsWith('+20')) return 'EGP'; // Egypt
    if (phone.startsWith('+86')) return 'CNY'; // China
    if (phone.startsWith('+39')) return 'EUR'; // Italy
    if (phone.startsWith('+44')) return 'GBP'; // UK
    if (phone.startsWith('+1')) return 'USD'; // USA/Canada

    return 'USD';
  }

  static String countryNameFromPhone(String? phoneE164) {
    final phone = (phoneE164 ?? '').replaceAll(RegExp(r'\s+'), '');

    if (phone.startsWith('+880')) return 'Bangladesh';
    if (phone.startsWith('+965')) return 'Kuwait';
    if (phone.startsWith('+966')) return 'Saudi Arabia';
    if (phone.startsWith('+971')) return 'United Arab Emirates';
    if (phone.startsWith('+974')) return 'Qatar';
    if (phone.startsWith('+968')) return 'Oman';
    if (phone.startsWith('+973')) return 'Bahrain';
    if (phone.startsWith('+91')) return 'India';
    if (phone.startsWith('+63')) return 'Philippines';
    if (phone.startsWith('+92')) return 'Pakistan';
    if (phone.startsWith('+20')) return 'Egypt';
    if (phone.startsWith('+86')) return 'China';
    if (phone.startsWith('+39')) return 'Italy';
    if (phone.startsWith('+44')) return 'United Kingdom';
    if (phone.startsWith('+1')) return 'United States';

    return 'International';
  }
}
