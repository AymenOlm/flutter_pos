import 'package:equatable/equatable.dart';

import 'package:flutter_pos/features/pos/domain/entities/cart_entity.dart';
import 'package:flutter_pos/features/pos/domain/entities/transaction_record.dart';
import 'package:flutter_pos/features/pos/domain/repositories/sales_repository.dart';
import 'package:flutter_pos/features/pos/domain/usecases/calculate_total.dart';

class SaveTransactionParams extends Equatable {
  const SaveTransactionParams({
    required this.cart,
    required this.totals,
    required this.discount,
    required this.paymentMethod,
  });

  final CartEntity cart;
  final CartTotals totals;
  final CartDiscount discount;
  final String paymentMethod;

  @override
  List<Object?> get props => [cart, totals, discount, paymentMethod];
}

class SaveTransaction {
  const SaveTransaction(this.salesRepository);

  final SalesRepository salesRepository;

  Future<TransactionRecord> call(SaveTransactionParams params) async {
    final record = TransactionRecord(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      paymentMethod: params.paymentMethod,
      cart: params.cart,
      subtotal: params.totals.subtotal,
      discountType: params.discount.type,
      discountValue: params.discount.value,
      discountAmount: params.totals.discountAmount,
      total: params.totals.total,
    );

    await salesRepository.saveTransaction(record);
    return record;
  }
}
