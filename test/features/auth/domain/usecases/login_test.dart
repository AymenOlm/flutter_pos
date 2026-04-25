import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_pos/features/auth/domain/entities/app_user.dart';
import 'package:flutter_pos/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_pos/features/auth/domain/usecases/login.dart';

class _FakeAuthRepository implements AuthRepository {
  AppUser? currentUser;
  AppUser? loginResult;
  Exception? loginError;
  String? lastUsername;
  String? lastPassword;
  int loginCalls = 0;
  int logoutCalls = 0;

  @override
  Future<AppUser?> getCurrentUser() async => currentUser;

  @override
  Future<AppUser> login({
    required String username,
    required String password,
  }) async {
    loginCalls += 1;
    lastUsername = username;
    lastPassword = password;

    if (loginError != null) {
      throw loginError!;
    }

    return loginResult!;
  }

  @override
  Future<void> logout() async {
    logoutCalls += 1;
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

        final useCase = Login(repository);
        final result = await useCase(username: 'admin', password: 'admin123');

        expect(result, expectedUser);
        expect(repository.loginCalls, 1);
        expect(repository.lastUsername, 'admin');
        expect(repository.lastPassword, 'admin123');
      },
    );

    test('rethrows repository login failures', () async {
      final repository = _FakeAuthRepository();
      repository.loginError = Exception('Invalid credentials');

      final useCase = Login(repository);

      await expectLater(
        () => useCase(username: 'admin', password: 'wrong'),
        throwsA(isA<Exception>()),
      );
      expect(repository.loginCalls, 1);
    });
  });
}
