import 'package:flutter_pos/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:flutter_pos/features/auth/domain/entities/app_user.dart';
import 'package:flutter_pos/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this.localDataSource);

  final AuthLocalDataSource localDataSource;

  static const _users = <String, ({String password, UserRole role, String id})>{
    'admin': (password: 'admin123', role: UserRole.admin, id: 'u-admin-1'),
    'seller': (password: 'seller123', role: UserRole.seller, id: 'u-seller-1'),
  };

  @override
  Future<AppUser?> getCurrentUser() {
    return localDataSource.getSession();
  }

  @override
  Future<AppUser> login({
    required String username,
    required String password,
  }) async {
    final normalized = username.trim().toLowerCase();
    final user = _users[normalized];

    if (user == null || user.password != password) {
      throw Exception('Invalid credentials');
    }

    final appUser = AppUser(id: user.id, username: normalized, role: user.role);
    await localDataSource.saveSession(appUser);
    return appUser;
  }

  @override
  Future<void> logout() {
    return localDataSource.clearSession();
  }
}
