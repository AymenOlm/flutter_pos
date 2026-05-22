import 'package:dartz/dartz.dart';

import 'package:flutter_pos/core/errors/failures.dart';
import 'package:flutter_pos/features/pos/data/datasources/cart_local_data_source.dart';
import 'package:flutter_pos/features/pos/domain/entities/cart_entity.dart';
import 'package:flutter_pos/features/pos/domain/entities/cart_persistence_state.dart';
import 'package:flutter_pos/features/pos/domain/repositories/cart_repository.dart';
import 'package:flutter_pos/features/pos/domain/usecases/calculate_total.dart';

class CartRepositoryImpl implements CartRepository {
  CartRepositoryImpl(this.localDataSource);

  final CartLocalDataSource localDataSource;

  @override
  Future<Either<Failure, Unit>> clearCartState() async {
    try {
      await localDataSource.clearCartState();
      return right(unit);
    } catch (_) {
      return left(const DatabaseFailure('Unable to clear cart state.'));
    }
  }

  @override
  Future<Either<Failure, CartPersistenceState?>> loadCartState() async {
    try {
      return right(await localDataSource.loadCartState());
    } catch (_) {
      return left(const DatabaseFailure('Unable to restore cart state.'));
    }
  }

  @override
  Future<Either<Failure, Unit>> saveCartState({
    required CartEntity cart,
    required CartDiscount discount,
  }) async {
    try {
      await localDataSource.saveCartState(cart: cart, discount: discount);
      return right(unit);
    } catch (_) {
      return left(const DatabaseFailure('Unable to persist cart state.'));
    }
  }
}
