import 'package:flutter_pos/features/pos/data/datasources/cart_local_data_source.dart';
import 'package:flutter_pos/features/pos/domain/entities/cart_entity.dart';
import 'package:flutter_pos/features/pos/domain/entities/cart_persistence_state.dart';
import 'package:flutter_pos/features/pos/domain/repositories/cart_repository.dart';
import 'package:flutter_pos/features/pos/domain/usecases/calculate_total.dart';

class CartRepositoryImpl implements CartRepository {
  CartRepositoryImpl(this.localDataSource);

  final CartLocalDataSource localDataSource;

  @override
  Future<void> clearCartState() {
    return localDataSource.clearCartState();
  }

  @override
  Future<CartPersistenceState?> loadCartState() {
    return localDataSource.loadCartState();
  }

  @override
  Future<void> saveCartState({
    required CartEntity cart,
    required CartDiscount discount,
  }) {
    return localDataSource.saveCartState(cart: cart, discount: discount);
  }
}