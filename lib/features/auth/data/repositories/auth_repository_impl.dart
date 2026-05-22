import 'dart:convert';
import 'dart:math';

import 'package:dartz/dartz.dart';

import 'package:flutter_pos/core/errors/failures.dart';
import 'package:flutter_pos/features/auth/data/datasources/auth_session_local_data_source.dart';
import 'package:flutter_pos/features/auth/data/datasources/auth_user_local_data_source.dart';
import 'package:flutter_pos/features/auth/data/security/password_hasher.dart';
import 'package:flutter_pos/features/auth/domain/entities/app_user.dart';
import 'package:flutter_pos/features/auth/domain/errors/auth_failures.dart';
import 'package:flutter_pos/features/auth/domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({
    required this.userLocalDataSource,
    required this.sessionLocalDataSource,
    required this.passwordHasher,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final AuthUserLocalDataSource userLocalDataSource;
  final AuthSessionLocalDataSource sessionLocalDataSource;
  final PasswordHasher passwordHasher;
  final DateTime Function() _now;

  static const _maxFailedAttempts = 5;
  static const _lockoutDuration = Duration(seconds: 30);

  Future<void>? _seedFuture;

  Future<void> _ensureSeedUsers() {
    return _seedFuture ??= _seedUsers();
  }

  Future<void> _seedUsers() async {
    final adminHash = await passwordHasher.hash('admin123');
    final sellerHash = await passwordHasher.hash('seller123');
    await userLocalDataSource.ensureSeedUsers(
      adminPasswordHash: adminHash,
      sellerPasswordHash: sellerHash,
    );
  }

  @override
  Future<Either<Failure, AppUser?>> getCurrentUser() async {
    try {
      await _ensureSeedUsers();
      final session = await sessionLocalDataSource.readSession();
      if (session == null || session.token.isEmpty) {
        return right(null);
      }

      final record = await userLocalDataSource.findById(session.userId);
      if (record == null) {
        await sessionLocalDataSource.clearSession();
        return right(null);
      }

      return right(record.toAppUser());
    } catch (_) {
      return left(const DatabaseFailure('Unable to load the current session.'));
    }
  }

  @override
  Future<Either<Failure, AppUser>> login({
    required String username,
    required String password,
  }) async {
    try {
      await _ensureSeedUsers();
      final normalized = username.trim().toLowerCase();
      final user = await userLocalDataSource.findByUsername(normalized);

      if (user == null) {
        return left(const InvalidCredentialsFailure());
      }

      final nowEpochMs = _now().millisecondsSinceEpoch;
      final lockoutUntil = user.lockoutUntilEpochMs;
      if (lockoutUntil != null && lockoutUntil > nowEpochMs) {
        final remainingSeconds = ((lockoutUntil - nowEpochMs) / 1000).ceil();
        return left(AuthLockoutFailure(remainingSeconds: remainingSeconds));
      }

      final isValid = await passwordHasher.verify(
        password: password,
        encodedHash: user.passwordHash,
      );

      if (!isValid) {
        final nextFailedAttempts = user.failedLoginAttempts + 1;

        if (nextFailedAttempts >= _maxFailedAttempts) {
          final lockedUntilEpochMs = _now()
              .add(_lockoutDuration)
              .millisecondsSinceEpoch;
          await userLocalDataSource.updateFailedAttemptState(
            userId: user.id,
            failedAttempts: nextFailedAttempts,
            lockoutUntilEpochMs: lockedUntilEpochMs,
          );
          return left(const AuthLockoutFailure(remainingSeconds: 30));
        }

        await userLocalDataSource.updateFailedAttemptState(
          userId: user.id,
          failedAttempts: nextFailedAttempts,
        );
        return left(const InvalidCredentialsFailure());
      }

      await userLocalDataSource.resetFailedAttemptState(user.id);

      final appUser = user.toAppUser();
      final sessionToken = _generateSessionToken();
      await sessionLocalDataSource.saveSession(
        AuthSession(userId: appUser.id, token: sessionToken),
      );

      return right(appUser);
    } catch (_) {
      return left(const DatabaseFailure('Unable to complete login.'));
    }
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    try {
      await sessionLocalDataSource.clearSession();
      return right(unit);
    } catch (_) {
      return left(const DatabaseFailure('Unable to sign out.'));
    }
  }

  String _generateSessionToken() {
    final random = Random.secure();
    final values = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(values);
  }
}
