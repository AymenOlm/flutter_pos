import 'package:flutter_pos/features/auth/domain/entities/app_user.dart';

abstract class AuthRepository {
  Future<AppUser?> getCurrentUser();
  Future<AppUser> login({required String username, required String password});
  Future<void> logout();
}
