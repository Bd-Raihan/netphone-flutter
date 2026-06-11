bool isValidPhoneNumber(String phoneNumber) {
  /// Remove spaces
  phoneNumber = phoneNumber.replaceAll(" ", "");

  /// Bangladesh
  if (phoneNumber.startsWith("+880")) {
    return phoneNumber.length == 14;
  }

  /// Kuwait
  if (phoneNumber.startsWith("+965")) {
    return phoneNumber.length == 12;
  }

  /// India
  if (phoneNumber.startsWith("+91")) {
    return phoneNumber.length == 13;
  }

  /// USA
  if (phoneNumber.startsWith("+1")) {
    return phoneNumber.length == 12;
  }

  /// Invalid
  return false;
}
