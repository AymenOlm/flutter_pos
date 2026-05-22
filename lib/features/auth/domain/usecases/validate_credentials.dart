import 'package:dartz/dartz.dart';

import 'package:flutter_pos/core/errors/failures.dart';
import 'package:flutter_pos/features/auth/domain/errors/auth_failures.dart';

class ValidateCredentials {
  const ValidateCredentials();

  Either<Failure, Unit> call({
    required String username,
    required String password,
  }) {
    final normalizedUsername = username.trim();

    if (normalizedUsername.isEmpty) {
      return left(const InvalidCredentialInputFailure('Username is required.'));
    }

    if (password.isEmpty) {
      return left(const InvalidCredentialInputFailure('Password is required.'));
    }

    return right(unit);
  }
}
