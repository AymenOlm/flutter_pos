import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_pos/core/errors/failures.dart';
import 'package:flutter_pos/features/auth/domain/entities/app_user.dart';
import 'package:flutter_pos/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_pos/features/auth/domain/usecases/logout.dart';

class _FakeAuthRepository implements AuthRepository {
  int getCurrentUserCalls = 0;
  int loginCalls = 0;
  int logoutCalls = 0;

  @override
  Future<Either<Failure, AppUser?>> getCurrentUser() async {
    getCurrentUserCalls += 1;
    return right(null);
  }

  @override
  Future<Either<Failure, AppUser>> login({
    required String username,
    required String password,
  }) async {
    loginCalls += 1;
    return right(
      AppUser(id: 'unused', username: username, role: UserRole.seller),
    );
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    logoutCalls += 1;
    return right(unit);
  }
}

void main() {
  group('Logout', () {
    test('delegates logout to repository', () async {
      final repository = _FakeAuthRepository();
      final useCase = Logout(repository);

      final result = await useCase();

      expect(result.isRight(), true);

      expect(repository.logoutCalls, 1);
      expect(repository.getCurrentUserCalls, 0);
      expect(repository.loginCalls, 0);
    });
  });
}
