import 'package:flutter_pos/features/pos/domain/entities/cart_entity.dart';
import 'package:flutter_pos/features/pos/domain/entities/cart_persistence_state.dart';
import 'package:flutter_pos/features/pos/domain/usecases/calculate_total.dart';

abstract class CartRepository {
  Future<void> saveCartState({
    required CartEntity cart,
    required CartDiscount discount,
  });

  Future<CartPersistenceState?> loadCartState();

  Future<void> clearCartState();
}