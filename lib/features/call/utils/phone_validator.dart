String normalizePhoneNumber(String input) {
  return input.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');
}

bool isValidPhoneNumber(String phoneNumber) {
  final cleaned = normalizePhoneNumber(phoneNumber);
  return RegExp(r'^\+[1-9]\d{7,14}$').hasMatch(cleaned);
}
