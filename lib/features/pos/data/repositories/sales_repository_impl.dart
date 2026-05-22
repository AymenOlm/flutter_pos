import 'package:dartz/dartz.dart';

import 'package:flutter_pos/core/errors/failures.dart';
import 'package:flutter_pos/features/pos/data/datasources/sales_local_data_source.dart';
import 'package:flutter_pos/features/pos/domain/entities/transaction_record.dart';
import 'package:flutter_pos/features/pos/domain/repositories/sales_repository.dart';

class SalesRepositoryImpl implements SalesRepository {
  SalesRepositoryImpl(this.localDataSource);

  final SalesLocalDataSource localDataSource;

  @override
  Future<Either<Failure, Unit>> saveTransaction(
    TransactionRecord record,
  ) async {
    try {
      await localDataSource.saveTransaction(record);
      return right(unit);
    } catch (_) {
      return left(const DatabaseFailure('Unable to save transaction.'));
    }
  }

  @override
  Future<Either<Failure, List<TransactionRecord>>> getTransactions() async {
    try {
      return right(await localDataSource.getTransactions());
    } catch (_) {
      return left(const DatabaseFailure('Unable to load transactions.'));
    }
  }
}
