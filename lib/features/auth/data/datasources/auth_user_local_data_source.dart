import 'package:drift/drift.dart';
import 'package:flutter_pos/features/auth/data/models/auth_user_record.dart';
import 'package:flutter_pos/features/auth/domain/entities/app_user.dart';
import 'package:flutter_pos/features/pos/data/datasources/pos_local_database.dart';

abstract class AuthUserLocalDataSource {
  Future<AuthUserRecord?> findByUsername(String username);
  Future<AuthUserRecord?> findById(String id);
  Future<void> updateFailedAttemptState({
    required String userId,
    required int failedAttempts,
    int? lockoutUntilEpochMs,
  });
  Future<void> resetFailedAttemptState(String userId);
  Future<void> ensureSeedUsers({
    required String adminPasswordHash,
    required String sellerPasswordHash,
  });
}

class DriftAuthUserLocalDataSource implements AuthUserLocalDataSource {
  DriftAuthUserLocalDataSource(this.localDatabase);

  final PosLocalDatabase localDatabase;

  @override
  Future<AuthUserRecord?> findByUsername(String username) async {
    final db = await localDatabase.database;
    final rows = await db
        .customSelect(
          '''
          SELECT id, username, password_hash, role, failed_login_attempts, lockout_until_epoch_ms
          FROM users
          WHERE username = ?
          LIMIT 1
          ''',
          variables: [Variable<String>(username)],
        )
        .get();

    if (rows.isEmpty) {
      return null;
    }

    return _mapRow(rows.first.data);
  }

  @override
  Future<AuthUserRecord?> findById(String id) async {
    final db = await localDatabase.database;
    final rows = await db
        .customSelect(
          '''
          SELECT id, username, password_hash, role, failed_login_attempts, lockout_until_epoch_ms
          FROM users
          WHERE id = ?
          LIMIT 1
          ''',
          variables: [Variable<String>(id)],
        )
        .get();

    if (rows.isEmpty) {
      return null;
    }

    return _mapRow(rows.first.data);
  }

  @override
  Future<void> updateFailedAttemptState({
    required String userId,
    required int failedAttempts,
    int? lockoutUntilEpochMs,
  }) async {
    final db = await localDatabase.database;
    await db.customStatement(
      '''
      UPDATE users
      SET failed_login_attempts = ?,
          lockout_until_epoch_ms = ?,
          updated_at_epoch_ms = ?
      WHERE id = ?
      ''',
      [
        failedAttempts,
        lockoutUntilEpochMs,
        DateTime.now().millisecondsSinceEpoch,
        userId,
      ],
    );
  }

  @override
  Future<void> resetFailedAttemptState(String userId) async {
    final db = await localDatabase.database;
    await db.customStatement(
      '''
      UPDATE users
      SET failed_login_attempts = 0,
          lockout_until_epoch_ms = NULL,
          updated_at_epoch_ms = ?
      WHERE id = ?
      ''',
      [DateTime.now().millisecondsSinceEpoch, userId],
    );
  }

  @override
  Future<void> ensureSeedUsers({
    required String adminPasswordHash,
    required String sellerPasswordHash,
  }) async {
    final db = await localDatabase.database;
    final rows = await db
        .customSelect('SELECT COUNT(*) AS total FROM users')
        .getSingle();

    final total = rows.read<int>('total');
    if (total > 0) {
      return;
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    await db.transaction(() async {
      await db.customStatement(
        '''
        INSERT OR IGNORE INTO users (
          id,
          username,
          password_hash,
          role,
          failed_login_attempts,
          lockout_until_epoch_ms,
          created_at_epoch_ms,
          updated_at_epoch_ms
        ) VALUES (?, ?, ?, ?, 0, NULL, ?, ?)
        ''',
        [
          'u-admin-1',
          'admin',
          adminPasswordHash,
          UserRole.admin.name,
          now,
          now,
        ],
      );

      await db.customStatement(
        '''
        INSERT OR IGNORE INTO users (
          id,
          username,
          password_hash,
          role,
          failed_login_attempts,
          lockout_until_epoch_ms,
          created_at_epoch_ms,
          updated_at_epoch_ms
        ) VALUES (?, ?, ?, ?, 0, NULL, ?, ?)
        ''',
        [
          'u-seller-1',
          'seller',
          sellerPasswordHash,
          UserRole.seller.name,
          now,
          now,
        ],
      );
    });
  }

  AuthUserRecord _mapRow(Map<String, dynamic> row) {
    final roleRaw = row['role'] as String;
    final role = UserRole.values.firstWhere(
      (value) => value.name == roleRaw,
      orElse: () => UserRole.seller,
    );

    return AuthUserRecord(
      id: row['id'] as String,
      username: row['username'] as String,
      passwordHash: row['password_hash'] as String,
      role: role,
      failedLoginAttempts: row['failed_login_attempts'] as int,
      lockoutUntilEpochMs: row['lockout_until_epoch_ms'] as int?,
    );
  }
}
