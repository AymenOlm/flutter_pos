import 'package:flutter_pos/features/auth/domain/errors/auth_failures.dart';

class ValidateCredentials {
  const ValidateCredentials();

  void call({required String username, required String password}) {
    final normalizedUsername = username.trim();

    if (normalizedUsername.isEmpty) {
      throw const InvalidCredentialInputFailure('Username is required.');
    }

    if (password.isEmpty) {
      throw const InvalidCredentialInputFailure('Password is required.');
    }
  }
}
