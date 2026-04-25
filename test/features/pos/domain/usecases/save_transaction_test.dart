import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_pos/features/pos/domain/entities/cart_entity.dart';
import 'package:flutter_pos/features/pos/domain/entities/product.dart';
import 'package:flutter_pos/features/pos/domain/entities/transaction_record.dart';
import 'package:flutter_pos/features/pos/domain/repositories/sales_repository.dart';
import 'package:flutter_pos/features/pos/domain/usecases/calculate_total.dart';
import 'package:flutter_pos/features/pos/domain/usecases/save_transaction.dart';

class _FakeSalesRepository implements SalesRepository {
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
  group('SaveTransaction', () {
    test('builds a record from params, persists it, and returns it', () async {
      final repository = _FakeSalesRepository();
      final useCase = SaveTransaction(repository);
      final cart = CartEntity(
        items: const [
          CartItemEntity(
            product: Product(id: 'p-1', name: 'Coffee', price: 3.50),
            quantity: 2,
          ),
          CartItemEntity(
            product: Product(id: 'p-2', name: 'Bagel', price: 2.75),
            quantity: 1,
          ),
        ],
      );
      const totals = CartTotals(subtotal: 9.75, tax: 0.98, total: 10.73);

      final result = await useCase(
        SaveTransactionParams(
          cart: cart,
          totals: totals,
          paymentMethod: 'cash',
        ),
      );

      expect(repository.savedRecords.length, 1);
      expect(repository.savedRecords.single, result);
      expect(result.cart, cart);
      expect(result.paymentMethod, 'cash');
      expect(result.subtotal, 9.75);
      expect(result.tax, 0.98);
      expect(result.total, 10.73);
      expect(result.id, isNotEmpty);
    });
  });
}
