import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_pos/features/auth/domain/entities/app_user.dart';
import 'package:flutter_pos/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_pos/features/auth/domain/usecases/get_current_user.dart';

class _FakeAuthRepository implements AuthRepository {
  AppUser? currentUser;
  int getCurrentUserCalls = 0;
  int loginCalls = 0;
  int logoutCalls = 0;

  @override
  Future<AppUser?> getCurrentUser() async {
    getCurrentUserCalls += 1;
    return currentUser;
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
  group('GetCurrentUser', () {
    test('returns repository user when session exists', () async {
      final repository = _FakeAuthRepository();
      const expectedUser = AppUser(
        id: 'u-seller-1',
        username: 'seller',
        role: UserRole.seller,
      );
      repository.currentUser = expectedUser;

      final useCase = GetCurrentUser(repository);
      final result = await useCase();

      expect(result, expectedUser);
      expect(repository.getCurrentUserCalls, 1);
      expect(repository.loginCalls, 0);
      expect(repository.logoutCalls, 0);
    });

    test('returns null when no active session exists', () async {
      final repository = _FakeAuthRepository();
      repository.currentUser = null;

      final useCase = GetCurrentUser(repository);
      final result = await useCase();

      expect(result, isNull);
      expect(repository.getCurrentUserCalls, 1);
    });
  });
}
