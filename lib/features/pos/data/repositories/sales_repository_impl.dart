import 'package:flutter_pos/features/pos/data/datasources/sales_local_data_source.dart';
import 'package:flutter_pos/features/pos/domain/entities/transaction_record.dart';
import 'package:flutter_pos/features/pos/domain/repositories/sales_repository.dart';

class SalesRepositoryImpl implements SalesRepository {
  SalesRepositoryImpl(this.localDataSource);

  final SalesLocalDataSource localDataSource;

  @override
  Future<void> saveTransaction(TransactionRecord record) {
    return localDataSource.saveTransaction(record);
  }

  @override
  Future<List<TransactionRecord>> getTransactions() {
    return localDataSource.getTransactions();
  }
}
