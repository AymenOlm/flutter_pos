import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_pos/features/auth/domain/entities/app_user.dart';
import 'package:flutter_pos/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_pos/features/auth/domain/usecases/logout.dart';

class _FakeAuthRepository implements AuthRepository {
  int getCurrentUserCalls = 0;
  int loginCalls = 0;
  int logoutCalls = 0;

  @override
  Future<AppUser?> getCurrentUser() async {
    getCurrentUserCalls += 1;
    return null;
  }

  @override
  Future<AppUser> login({
    required String username,
    required String password,
  }) async {
    loginCalls += 1;
    return AppUser(id: 'unused', username: username, role: UserRole.seller);
  }

  @override
  Future<void> logout() async {
    logoutCalls += 1;
  }
}

void main() {
  group('Logout', () {
    test('delegates logout to repository', () async {
      final repository = _FakeAuthRepository();
      final useCase = Logout(repository);

      await useCase();

      expect(repository.logoutCalls, 1);
      expect(repository.getCurrentUserCalls, 0);
      expect(repository.loginCalls, 0);
    });
  });
}
