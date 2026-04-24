import 'package:equatable/equatable.dart';

import 'package:flutter_pos/features/pos/domain/entities/cart_entity.dart';
import 'package:flutter_pos/features/pos/domain/usecases/calculate_total.dart';

class CartState extends Equatable {
  const CartState({required this.cart, required this.totals});

  factory CartState.initial() {
    const cart = CartEntity();
    const totals = CartTotals(subtotal: 0, tax: 0, total: 0);
    return const CartState(cart: cart, totals: totals);
  }

  final CartEntity cart;
  final CartTotals totals;

  CartState copyWith({CartEntity? cart, CartTotals? totals}) {
    return CartState(cart: cart ?? this.cart, totals: totals ?? this.totals);
  }

  @override
  List<Object?> get props => [cart, totals];
}
