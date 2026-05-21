import 'package:equatable/equatable.dart';

import 'package:flutter_pos/features/pos/domain/entities/cart_entity.dart';
import 'package:flutter_pos/features/pos/domain/usecases/calculate_total.dart';

class CartPersistenceState extends Equatable {
  const CartPersistenceState({required this.cart, required this.discount});

  final CartEntity cart;
  final CartDiscount discount;

  @override
  List<Object?> get props => [cart, discount];
}