import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class PosLocalDatabase {
  PosLocalDatabase({this.dbFileName = 'flutter_pos.sqlite'});

  final String dbFileName;
  GeneratedDatabase? _database;

  Future<GeneratedDatabase> get database async {
    if (_database != null) {
      return _database!;
    }

    final documents = await getApplicationDocumentsDirectory();
    final dbFile = File(p.join(documents.path, dbFileName));
    final executor = NativeDatabase.createInBackground(dbFile);
    final db = _PosGeneratedDatabase(executor);

    await _createSchema(db);
    _database = db;
    return db;
  }

  Future<void> _createSchema(GeneratedDatabase db) async {
    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS products (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        price REAL NOT NULL
      )
    ''');

    await db.customStatement('''
      CREATE TABLE IF NOT EXISTS sales (
        id TEXT PRIMARY KEY,
        created_at TEXT NOT NULL,
        payment_method TEXT NOT NULL,
        subtotal REAL NOT NULL,
        tax REAL NOT NULL,
        total REAL NOT NULL,
        items_json TEXT NOT NULL
      )
    ''');
  }
}

class _PosGeneratedDatabase extends GeneratedDatabase {
  _PosGeneratedDatabase(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  Iterable<TableInfo> get allTables => const [];
}
