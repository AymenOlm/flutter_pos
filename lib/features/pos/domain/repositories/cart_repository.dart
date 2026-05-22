import 'package:dartz/dartz.dart';

import 'package:flutter_pos/core/errors/failures.dart';
import 'package:flutter_pos/features/pos/domain/entities/cart_entity.dart';
import 'package:flutter_pos/features/pos/domain/entities/cart_persistence_state.dart';
import 'package:flutter_pos/features/pos/domain/usecases/calculate_total.dart';

abstract class CartRepository {
  Future<Either<Failure, Unit>> saveCartState({
    required CartEntity cart,
    required CartDiscount discount,
  });

  Future<Either<Failure, CartPersistenceState?>> loadCartState();

  Future<Either<Failure, Unit>> clearCartState();
}
