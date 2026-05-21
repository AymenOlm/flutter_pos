import 'dart:async';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class PosLocalDatabase {
  PosLocalDatabase({this.dbFileName = 'flutter_pos.sqlite'});

  final String dbFileName;
  GeneratedDatabase? _database;
  Completer<GeneratedDatabase>? _databaseCompleter;

  Future<GeneratedDatabase> get database async {
    if (_database != null) {
      return _database!;
    }

    // Ensure only one initialization happens even with concurrent access
    if (_databaseCompleter != null) {
      return _databaseCompleter!.future;
    }

    _databaseCompleter = Completer<GeneratedDatabase>();

    try {
      final documents = await getApplicationDocumentsDirectory();
      final dbFile = File(p.join(documents.path, dbFileName));
      final executor = NativeDatabase.createInBackground(dbFile);
      final db = _PosGeneratedDatabase(executor, _createSchema);

      await _createSchema(db);
      _database = db;
      _databaseCompleter!.complete(db);
      return db;
    } catch (e) {
      _databaseCompleter!.completeError(e);
      _databaseCompleter = null;
      rethrow;
    }
  }

  Future<void> _createSchema(GeneratedDatabase db) async {
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        category TEXT NOT NULL DEFAULT 'General'
      )
    ''');

    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS sales (
        id TEXT PRIMARY KEY,
        created_at TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        subtotal REAL NOT NULL,
        discount_type TEXT NOT NULL DEFAULT 'fixed',
        discount_value REAL NOT NULL DEFAULT 0,
        discount_amount REAL NOT NULL DEFAULT 0,
        tax REAL NOT NULL,
        total REAL NOT NULL,
        items_json TEXT NOT NULL
      )
    ''');

    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS cart_state (
        id INTEGER PRIMARY KEY,
        discount_type TEXT NOT NULL DEFAULT 'fixed',
        discount_value REAL NOT NULL DEFAULT 0
      )
    ''');

    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS cart_items (
        product_id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        price REAL NOT NULL,
        category TEXT NOT NULL DEFAULT 'General',
        quantity INTEGER NOT NULL
      )
    ''');

    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        username TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        role TEXT NOT NULL,
        failed_login_attempts INTEGER NOT NULL DEFAULT 0,
        lockout_until_epoch_ms INTEGER,
        created_at_epoch_ms INTEGER NOT NULL,
        updated_at_epoch_ms INTEGER NOT NULL
      )
    ''');

    await _ensureColumn(
      db,
      tableName: 'sales',
      columnName: 'discount_type',
      columnDefinition: "TEXT NOT NULL DEFAULT 'fixed'",
    );
    await _ensureColumn(
      db,
      tableName: 'sales',
      columnName: 'discount_value',
      columnDefinition: 'REAL NOT NULL DEFAULT 0',
    );
    await _ensureColumn(
      db,
      tableName: 'sales',
      columnName: 'discount_amount',
      columnDefinition: 'REAL NOT NULL DEFAULT 0',
    );
    await _ensureColumn(
      db,
      tableName: 'products',
      columnName: 'category',
      columnDefinition: "TEXT NOT NULL DEFAULT 'General'",
    );
    await _ensureColumn(
      db,
      tableName: 'users',
      columnName: 'failed_login_attempts',
      columnDefinition: 'INTEGER NOT NULL DEFAULT 0',
    );
    await _ensureColumn(
      db,
      tableName: 'users',
      columnName: 'lockout_until_epoch_ms',
      columnDefinition: 'INTEGER',
    );
    await _ensureColumn(
      db,
      tableName: 'users',
      columnName: 'created_at_epoch_ms',
      columnDefinition: 'INTEGER NOT NULL DEFAULT 0',
    );
    await _ensureColumn(
      db,
      tableName: 'users',
      columnName: 'updated_at_epoch_ms',
      columnDefinition: 'INTEGER NOT NULL DEFAULT 0',
    );
  }

  Future<void> _ensureColumn(
    GeneratedDatabase db, {
    required String tableName,
    required String columnName,
    required String columnDefinition,
  }) async {
    final rows = await db.customSelect('PRAGMA table_info($tableName)').get();
    final hasColumn = rows.any((row) => row.read<String>('name') == columnName);

    if (!hasColumn) {
      await db.customStatement(
        'ALTER TABLE $tableName ADD COLUMN $columnName $columnDefinition',
      );
    }
  }
}

class _PosGeneratedDatabase extends GeneratedDatabase {
  _PosGeneratedDatabase(super.executor, this._createSchema);

  final Future<void> Function(GeneratedDatabase db) _createSchema;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (migrator) => _createSchema(migrator.database),
      onUpgrade: (migrator, from, to) => _createSchema(migrator.database),
    );
  }

  @override
  int get schemaVersion => 5;

  @override
  Iterable<TableInfo> get allTables => const [];
}
