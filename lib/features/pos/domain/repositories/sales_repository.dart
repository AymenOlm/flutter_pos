import 'package:flutter_pos/features/pos/domain/entities/transaction_record.dart';

abstract class SalesRepository {
  Future<void> saveTransaction(TransactionRecord record);
  Future<List<TransactionRecord>> getTransactions();
}
