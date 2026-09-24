import 'package:flutter_test/flutter_test.dart';
import 'package:food_guruji/features/auth/domain/password_hash.dart';

void main() {
  group('PasswordHash', () {
    test('verifies the same secret it hashed', () {
      final encoded = PasswordHash.hash('sup3r-secret');
      expect(PasswordHash.verify('sup3r-secret', encoded), isTrue);
    });

    test('rejects a wrong secret', () {
      final encoded = PasswordHash.hash('sup3r-secret');
      expect(PasswordHash.verify('nope', encoded), isFalse);
    });

    test('uses a fresh salt so equal passwords hash differently', () {
      final a = PasswordHash.hash('same');
      final b = PasswordHash.hash('same');
      expect(a, isNot(equals(b)));
      expect(PasswordHash.verify('same', a), isTrue);
      expect(PasswordHash.verify('same', b), isTrue);
    });

    test('encodes the algorithm, iterations, salt and hash', () {
      final parts = PasswordHash.hash('x').split(r'$');
      expect(parts, hasLength(4));
      expect(parts[0], 'pbkdf2');
      expect(int.parse(parts[1]), greaterThan(0));
      expect(parts[2], isNotEmpty);
      expect(parts[3], isNotEmpty);
    });

    test('rejects a malformed encoding without throwing', () {
      expect(PasswordHash.verify('x', 'garbage'), isFalse);
      expect(PasswordHash.verify('x', r'pbkdf2$120000$only-three'), isFalse);
    });
  });
}
