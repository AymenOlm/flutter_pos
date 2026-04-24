import 'package:equatable/equatable.dart';

import 'package:flutter_pos/features/pos/domain/entities/cart_entity.dart';

class CartTotals extends Equatable {
  const CartTotals({
    required this.subtotal,
    required this.tax,
    required this.total,
  });

  final double subtotal;
  final double tax;
  final double total;

  @override
  List<Object?> get props => [subtotal, tax, total];
}

class CalculateTotal {
  const CalculateTotal({this.taxRate = 0.10});

  final double taxRate;

  CartTotals call(CartEntity cart) {
    final subtotal = cart.subtotal;
    final tax = subtotal * taxRate;

    return CartTotals(subtotal: subtotal, tax: tax, total: subtotal + tax);
  }
}
