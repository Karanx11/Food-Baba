import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Salted PBKDF2-HMAC-SHA256 password hashing, so a stored secret can never
/// be read back as plain text. The encoded form is
/// `pbkdf2$<iterations>$<saltB64>$<hashB64>`, which carries everything needed
/// to verify a later guess.
abstract final class PasswordHash {
  static const int _iterations = 120000;
  static const int _saltBytes = 16;
  static const int _keyBytes = 32;

  static final Random _random = Random.secure();

  /// Hashes [secret] with a fresh random salt. Use for passwords and for the
  /// security answer.
  static String hash(String secret) {
    final salt = Uint8List.fromList(
      List.generate(_saltBytes, (_) => _random.nextInt(256)),
    );
    final key = _pbkdf2(utf8.encode(secret), salt, _iterations, _keyBytes);
    return 'pbkdf2\$$_iterations\$${base64.encode(salt)}\$${base64.encode(key)}';
  }

  /// True when [secret] matches the [encoded] hash. Comparison is
  /// constant-time so it does not leak how much of the hash matched.
  static bool verify(String secret, String encoded) {
    final parts = encoded.split(r'$');
    if (parts.length != 4 || parts[0] != 'pbkdf2') return false;
    final iterations = int.tryParse(parts[1]);
    if (iterations == null) return false;
    final Uint8List salt;
    final Uint8List expected;
    try {
      salt = base64.decode(parts[2]);
      expected = base64.decode(parts[3]);
    } on Object {
      return false;
    }
    final actual = _pbkdf2(
      utf8.encode(secret),
      salt,
      iterations,
      expected.length,
    );
    return _constantTimeEquals(actual, expected);
  }

  static Uint8List _pbkdf2(
    List<int> secret,
    List<int> salt,
    int iterations,
    int dkLen,
  ) {
    final hmac = Hmac(sha256, secret);
    final blocks = (dkLen / 32).ceil();
    final out = BytesBuilder();
    for (var block = 1; block <= blocks; block++) {
      final indexed = <int>[
        ...salt,
        (block >> 24) & 0xff,
        (block >> 16) & 0xff,
        (block >> 8) & 0xff,
        block & 0xff,
      ];
      var u = hmac.convert(indexed).bytes;
      final t = Uint8List.fromList(u);
      for (var i = 1; i < iterations; i++) {
        u = hmac.convert(u).bytes;
        for (var j = 0; j < t.length; j++) {
          t[j] ^= u[j];
        }
      }
      out.add(t);
    }
    return out.toBytes().sublist(0, dkLen);
  }

  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    var diff = 0;
    for (var i = 0; i < a.length; i++) {
      diff |= a[i] ^ b[i];
    }
    return diff == 0;
  }
}
