import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_pos/features/pos/data/datasources/pos_local_database.dart';
import 'package:flutter_pos/features/pos/data/datasources/sales_local_data_source.dart';
import 'package:flutter_pos/features/pos/domain/entities/cart_entity.dart';
import 'package:flutter_pos/features/pos/domain/entities/product.dart';
import 'package:flutter_pos/features/pos/domain/entities/transaction_record.dart';
import 'package:flutter_pos/features/pos/domain/usecases/calculate_total.dart';

class _MemorySalesDatabase extends GeneratedDatabase {
  _MemorySalesDatabase() : super(NativeDatabase.memory());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (migrator) => _createSchema(migrator.database),
      onUpgrade: (migrator, from, to) => _createSchema(migrator.database),
    );
  }

  @override
  Iterable<TableInfo> get allTables => const [];

  static Future<void> _createSchema(GeneratedDatabase db) async {
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
  }
}

class _MemoryPosLocalDatabase extends PosLocalDatabase {
  _MemoryPosLocalDatabase() : super(dbFileName: 'ignored.sqlite');

  final _database = _MemorySalesDatabase();

  @override
  Future<GeneratedDatabase> get database async => _database;

  Future<void> dispose() async {
    await _database.close();
  }
}

void main() {
  test(
    'persists and reads sales records through an in-memory Drift database',
    () async {
      final localDatabase = _MemoryPosLocalDatabase();
      addTearDown(localDatabase.dispose);

      final dataSource = DriftSalesLocalDataSource(localDatabase);
      const cart = CartEntity(
        items: [
          CartItemEntity(
            product: Product(
              id: 'p-1',
              name: 'Coffee',
              price: 3.50,
              category: 'Beverages',
            ),
            quantity: 2,
          ),
        ],
      );
      const totals = CartTotals(subtotal: 7.0, discountAmount: 0.5, total: 6.5);
      const discount = CartDiscount(type: DiscountType.fixed, value: 0.5);
      final record = TransactionRecord(
        id: 'txn-1',
        createdAt: DateTime.utc(2026, 5, 21, 10, 30),
        paymentMethod: 'Card',
        cart: cart,
        subtotal: totals.subtotal,
        discountType: discount.type,
        discountValue: discount.value,
        discountAmount: totals.discountAmount,
        total: totals.total,
      );

      await dataSource.saveTransaction(record);

      final transactions = await dataSource.getTransactions();
      expect(transactions, [record]);
    },
  );
}
