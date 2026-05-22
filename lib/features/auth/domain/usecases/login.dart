import 'package:dartz/dartz.dart';

import 'package:flutter_pos/core/errors/failures.dart';
import 'package:flutter_pos/features/auth/domain/entities/app_user.dart';
import 'package:flutter_pos/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_pos/features/auth/domain/usecases/validate_credentials.dart';

class Login {
  const Login(this.repository, this.validateCredentials);

  final AuthRepository repository;
  final ValidateCredentials validateCredentials;

  Future<Either<Failure, AppUser>> call({
    required String username,
    required String password,
  }) async {
    final validationResult = validateCredentials(
      username: username,
      password: password,
    );

    return validationResult.fold(
      (failure) => Future.value(left(failure)),
      (_) => repository.login(username: username, password: password),
    );
  }
}
