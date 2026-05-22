import 'package:dartz/dartz.dart';

import 'package:flutter_pos/core/errors/failures.dart';
import 'package:flutter_pos/features/auth/domain/entities/app_user.dart';
import 'package:flutter_pos/features/auth/domain/repositories/auth_repository.dart';

class GetCurrentUser {
  const GetCurrentUser(this.repository);

  final AuthRepository repository;

  Future<Either<Failure, AppUser?>> call() {
    return repository.getCurrentUser();
  }
}
