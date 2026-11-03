import 'package:flutter_test/flutter_test.dart';
import 'package:nexchat/features/auth/auth_validation.dart';

void main() {
  test('Email rejects missing address parts and embedded whitespace', () {
    for (final value in ['', 'name', '@example.com', 'a b@example.com']) {
      expect(validateEmail(value), isNotNull);
    }
    expect(validateEmail(' person@example.com '), isNull);
  });
  test('New password requires 12 characters; spaces are not trimmed', () {
    expect(validateNewPassword('short'), isNotNull);
    expect(validateNewPassword('twelveChars!'), isNull);
    expect(validateNewPassword(' a long passphrase '), isNull);
  });
}
