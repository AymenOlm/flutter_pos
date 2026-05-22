import 'package:dartz/dartz.dart';

import 'package:flutter_pos/core/errors/failures.dart';
import 'package:flutter_pos/features/pos/domain/entities/transaction_record.dart';

abstract class SalesRepository {
  Future<Either<Failure, Unit>> saveTransaction(TransactionRecord record);

  Future<Either<Failure, List<TransactionRecord>>> getTransactions();
}
