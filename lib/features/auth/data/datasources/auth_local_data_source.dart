import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_pos/features/auth/domain/entities/app_user.dart';

abstract class AuthLocalDataSource {
  Future<AppUser?> getSession();
  Future<void> saveSession(AppUser user);
  Future<void> clearSession();
}

class SharedPrefsAuthLocalDataSource implements AuthLocalDataSource {
  static const _keyUserId = 'auth_user_id';
  static const _keyUsername = 'auth_username';
  static const _keyRole = 'auth_role';

  @override
  Future<AppUser?> getSession() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_keyUserId);
    final username = prefs.getString(_keyUsername);
    final roleRaw = prefs.getString(_keyRole);

    if (id == null || username == null || roleRaw == null) {
      return null;
    }

    UserRole? role;
    for (final value in UserRole.values) {
      if (value.name == roleRaw) {
        role = value;
        break;
      }
    }
    if (role == null) {
      return null;
    }

    return AppUser(id: id, username: username, role: role);
  }

  @override
  Future<void> saveSession(AppUser user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, user.id);
    await prefs.setString(_keyUsername, user.username);
    await prefs.setString(_keyRole, user.role.name);
  }

  @override
  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUsername);
    await prefs.remove(_keyRole);
  }
}
