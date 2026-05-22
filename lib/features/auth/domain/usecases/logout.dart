import 'package:dartz/dartz.dart';

import 'package:flutter_pos/core/errors/failures.dart';
import 'package:flutter_pos/features/auth/domain/repositories/auth_repository.dart';

class Logout {
  const Logout(this.repository);

  final AuthRepository repository;

  Future<Either<Failure, Unit>> call() {
    return repository.logout();
  }
}
