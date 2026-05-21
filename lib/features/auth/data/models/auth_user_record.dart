import 'package:flutter_pos/features/auth/domain/entities/app_user.dart';

class AuthUserRecord {
  const AuthUserRecord({
    required this.id,
    required this.username,
    required this.passwordHash,
    required this.role,
    required this.failedLoginAttempts,
    required this.lockoutUntilEpochMs,
  });

  final String id;
  final String username;
  final String passwordHash;
  final UserRole role;
  final int failedLoginAttempts;
  final int? lockoutUntilEpochMs;

  AppUser toAppUser() {
    return AppUser(id: id, username: username, role: role);
  }
}
