import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_pos/features/pos/data/datasources/sales_local_data_source.dart';
import 'package:flutter_pos/features/pos/data/repositories/sales_repository_impl.dart';
import 'package:flutter_pos/features/pos/domain/entities/cart_entity.dart';
import 'package:flutter_pos/features/pos/domain/entities/product.dart';
import 'package:flutter_pos/features/pos/domain/entities/transaction_record.dart';

class _FakeSalesLocalDataSource implements SalesLocalDataSource {
  final List<TransactionRecord> savedRecords = <TransactionRecord>[];
  List<TransactionRecord> transactions = <TransactionRecord>[];

  @override
  Future<List<TransactionRecord>> getTransactions() async => transactions;

  @override
  Future<void> saveTransaction(TransactionRecord record) async {
    savedRecords.add(record);
  }
}

void main() {
  group('SalesRepositoryImpl', () {
    test('saveTransaction delegates to local data source', () async {
      final localDataSource = _FakeSalesLocalDataSource();
      final repository = SalesRepositoryImpl(localDataSource);
      final record = TransactionRecord(
        id: 'trx-1',
        createdAt: DateTime(2026, 4, 25),
        paymentMethod: 'card',
        cart: CartEntity(
          items: const [
            CartItemEntity(
              product: Product(id: 'p-1', name: 'Coffee', price: 3.50),
              quantity: 1,
            ),
          ],
        ),
        subtotal: 3.50,
        tax: 0.35,
        total: 3.85,
      );

      await repository.saveTransaction(record);

      expect(localDataSource.savedRecords, [record]);
    });

    test('getTransactions delegates to local data source', () async {
      final localDataSource = _FakeSalesLocalDataSource();
      final expected = [
        TransactionRecord(
          id: 'trx-1',
          createdAt: DateTime(2026, 4, 25),
          paymentMethod: 'cash',
          cart: const CartEntity(),
          subtotal: 0,
          tax: 0,
          total: 0,
        ),
      ];
      localDataSource.transactions = expected;
      final repository = SalesRepositoryImpl(localDataSource);

      final result = await repository.getTransactions();

      expect(result, expected);
    });
  });
}
