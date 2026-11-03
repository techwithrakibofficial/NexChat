String? validateEmail(String? value) {
  final email = value?.trim() ?? '';
  if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
    return 'Enter a valid email address';
  }
  return null;
}

String? validateNewPassword(String? value) {
  if ((value ?? '').length < 12) return 'Use at least 12 characters';
  return null;
}
