import 'dart:convert';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

abstract class PasswordHasher {
  Future<String> hash(String password);
  Future<bool> verify({required String password, required String encodedHash});
}

class Argon2PasswordHasher implements PasswordHasher {
  Argon2PasswordHasher({Argon2id? algorithm})
    : _algorithm =
          algorithm ??
          Argon2id(
            memory: 19456,
            parallelism: 1,
            iterations: 2,
            hashLength: 32,
          );

  final Argon2id _algorithm;

  static const _separator = r'$';
  static const _prefix = 'argon2id';

  @override
  Future<String> hash(String password) async {
    final random = Random.secure();
    final salt = List<int>.generate(16, (_) => random.nextInt(256));
    final secretKey = await _algorithm.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
    final hashBytes = await secretKey.extractBytes();

    final encodedSalt = base64Encode(salt);
    final encodedHash = base64Encode(hashBytes);
    return '$_prefix$_separator$encodedSalt$_separator$encodedHash';
  }

  @override
  Future<bool> verify({
    required String password,
    required String encodedHash,
  }) async {
    final parts = encodedHash.split(_separator);
    if (parts.length != 3 || parts[0] != _prefix) {
      return false;
    }

    final salt = base64Decode(parts[1]);
    final expectedHash = base64Decode(parts[2]);
    final secretKey = await _algorithm.deriveKey(
      secretKey: SecretKey(utf8.encode(password)),
      nonce: salt,
    );
    final actualHash = await secretKey.extractBytes();

    return _constantTimeEquals(actualHash, expectedHash);
  }

  bool _constantTimeEquals(List<int> left, List<int> right) {
    if (left.length != right.length) {
      return false;
    }

    var mismatch = 0;
    for (var i = 0; i < left.length; i += 1) {
      mismatch |= left[i] ^ right[i];
    }
    return mismatch == 0;
  }
}
