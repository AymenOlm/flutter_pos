import 'package:dartz/dartz.dart';

import 'package:flutter_pos/core/errors/failures.dart';
import 'package:flutter_pos/features/auth/domain/entities/app_user.dart';

abstract class AuthRepository {
  Future<Either<Failure, AppUser?>> getCurrentUser();

  Future<Either<Failure, AppUser>> login({
    required String username,
    required String password,
  });

  Future<Either<Failure, Unit>> logout();
}
