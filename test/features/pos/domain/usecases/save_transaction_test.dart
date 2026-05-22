import 'package:flutter_test/flutter_test.dart';

import 'package:dartz/dartz.dart';

import 'package:flutter_pos/core/errors/failures.dart';
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
  Future<Either<Failure, List<TransactionRecord>>> getTransactions() async =>
      right(transactions);

  @override
  Future<Either<Failure, Unit>> saveTransaction(
    TransactionRecord record,
  ) async {
    savedRecords.add(record);
    return right(unit);
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
      const discount = CartDiscount(type: DiscountType.fixed, value: 2.00);
      final totals = CalculateTotal()(cart, discount: discount);

      final result = await useCase(
        SaveTransactionParams(
          cart: cart,
          totals: totals,
          discount: discount,
          paymentMethod: 'cash',
        ),
      );

      expect(repository.savedRecords.length, 1);
      expect(
        result.fold((_) => null, (record) => record),
        repository.savedRecords.single,
      );
      final record = result.fold((_) => null, (record) => record)!;
      expect(record.cart, cart);
      expect(record.paymentMethod, 'cash');
      expect(record.subtotal, 9.75);
      expect(record.discountType, DiscountType.fixed);
      expect(record.discountValue, 2.00);
      expect(record.discountAmount, 2.00);
      expect(record.total, closeTo(7.75, 0.0001));
      expect(record.id, isNotEmpty);
    });
  });
}
