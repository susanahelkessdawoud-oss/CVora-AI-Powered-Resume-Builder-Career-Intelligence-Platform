import 'package:cvora/utils/validators.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Validators.email', () {
    test('accepts a well-formed address', () {
      expect(Validators.email('user@example.com'), isNull);
    });
    test('rejects an empty value', () {
      expect(Validators.email(''), isNotNull);
    });
    test('rejects a malformed address', () {
      expect(Validators.email('not-an-email'), isNotNull);
    });
  });

  group('Validators.password', () {
    test('rejects short passwords', () {
      expect(Validators.password('123'), isNotNull);
    });
    test('accepts 6+ characters', () {
      expect(Validators.password('secret1'), isNull);
    });
  });

  group('Validators.required', () {
    test('rejects blank input', () {
      expect(Validators.required('   ', 'Name'), isNotNull);
    });
    test('accepts non-blank input', () {
      expect(Validators.required('Ada', 'Name'), isNull);
    });
  });
}
