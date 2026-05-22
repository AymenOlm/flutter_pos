import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_pos/core/errors/failures.dart';
import 'package:flutter_pos/features/auth/domain/entities/app_user.dart';
import 'package:flutter_pos/features/auth/domain/errors/auth_failures.dart';
import 'package:flutter_pos/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_pos/features/auth/domain/usecases/login.dart';
import 'package:flutter_pos/features/auth/domain/usecases/validate_credentials.dart';

class _FakeAuthRepository implements AuthRepository {
  AppUser? currentUser;
  AppUser? loginResult;
  Failure? loginFailure;
  String? lastUsername;
  String? lastPassword;
  int loginCalls = 0;
  int logoutCalls = 0;

  @override
  Future<Either<Failure, AppUser?>> getCurrentUser() async =>
      right(currentUser);

  @override
  Future<Either<Failure, AppUser>> login({
    required String username,
    required String password,
  }) async {
    loginCalls += 1;
    lastUsername = username;
    lastPassword = password;

    if (loginFailure != null) {
      return left(loginFailure!);
    }

    return right(loginResult!);
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    logoutCalls += 1;
    return right(unit);
  }
}

void main() {
  group('Login', () {
    test(
      'delegates credentials to repository and returns authenticated user',
      () async {
        final repository = _FakeAuthRepository();
        const expectedUser = AppUser(
          id: 'u-admin-1',
          username: 'admin',
          role: UserRole.admin,
        );
        repository.loginResult = expectedUser;

        const validator = ValidateCredentials();
        final useCase = Login(repository, validator);
        final result = await useCase(username: 'admin', password: 'admin123');

        expect(result.fold((_) => null, (user) => user), expectedUser);
        expect(repository.loginCalls, 1);
        expect(repository.lastUsername, 'admin');
        expect(repository.lastPassword, 'admin123');
      },
    );

    test('returns repository login failures', () async {
      final repository = _FakeAuthRepository();
      repository.loginFailure = const InvalidCredentialsFailure();
      const validator = ValidateCredentials();

      final useCase = Login(repository, validator);

      final result = await useCase(username: 'admin', password: 'wrong');

      expect(result.isLeft(), true);
      expect(repository.loginCalls, 1);
    });

    test('fails fast when username is empty and skips repository', () async {
      final repository = _FakeAuthRepository();
      const validator = ValidateCredentials();
      final useCase = Login(repository, validator);

      final result = await useCase(username: '   ', password: 'admin123');

      expect(result.isLeft(), true);
      expect(
        result.fold((failure) => failure, (_) => null),
        isA<InvalidCredentialInputFailure>(),
      );

      expect(repository.loginCalls, 0);
    });
  });
}
