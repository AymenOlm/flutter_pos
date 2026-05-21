import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthSession {
  const AuthSession({required this.userId, required this.token});

  final String userId;
  final String token;
}

abstract class AuthSessionLocalDataSource {
  Future<AuthSession?> readSession();
  Future<void> saveSession(AuthSession session);
  Future<void> clearSession();
}

class SecureStorageAuthSessionLocalDataSource
    implements AuthSessionLocalDataSource {
  SecureStorageAuthSessionLocalDataSource(this.secureStorage);

  final FlutterSecureStorage secureStorage;

  static const _keyUserId = 'auth_user_id';
  static const _keyToken = 'auth_session_token';

  @override
  Future<AuthSession?> readSession() async {
    final userId = await secureStorage.read(key: _keyUserId);
    final token = await secureStorage.read(key: _keyToken);

    if (userId == null || token == null) {
      return null;
    }

    return AuthSession(userId: userId, token: token);
  }

  @override
  Future<void> saveSession(AuthSession session) async {
    await secureStorage.write(key: _keyUserId, value: session.userId);
    await secureStorage.write(key: _keyToken, value: session.token);
  }

  @override
  Future<void> clearSession() async {
    await secureStorage.delete(key: _keyUserId);
    await secureStorage.delete(key: _keyToken);
  }
}
