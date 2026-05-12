import 'dart:math' as math;

import 'package:equatable/equatable.dart';

import 'package:flutter_pos/features/pos/domain/entities/cart_entity.dart';

enum DiscountType { fixed, percentage }

extension DiscountTypeX on DiscountType {
  String get displayName {
    return switch (this) {
      DiscountType.fixed => 'Fixed',
      DiscountType.percentage => 'Percentage',
    };
  }
}

class CartDiscount extends Equatable {
  const CartDiscount({required this.type, required this.value});

  const CartDiscount.none() : this(type: DiscountType.fixed, value: 0);

  final DiscountType type;
  final double value;

  double amountFor(double subtotal) {
    final normalizedSubtotal = math.max(0, subtotal);
    final normalizedValue = math.max(0, value);

    switch (type) {
      case DiscountType.fixed:
        return math.min(normalizedSubtotal, normalizedValue).toDouble();
      case DiscountType.percentage:
        return math
            .min(
              normalizedSubtotal,
              normalizedSubtotal * (normalizedValue / 100),
            )
            .toDouble();
    }
  }

  String get label {
    return type.displayName;
  }

  @override
  List<Object?> get props => [type, value];
}

class CartTotals extends Equatable {
  const CartTotals({
    required this.subtotal,
    required this.discountAmount,
    required this.total,
  });

  final double subtotal;
  final double discountAmount;
  final double total;

  @override
  List<Object?> get props => [subtotal, discountAmount, total];
}

class CalculateTotal {
  const CalculateTotal();

  CartTotals call(
    CartEntity cart, {
    CartDiscount discount = const CartDiscount.none(),
  }) {
    final subtotal = cart.subtotal;
    final discountAmount = discount.amountFor(subtotal);
    final total = math.max(0.0, subtotal - discountAmount).toDouble();

    return CartTotals(
      subtotal: subtotal,
      discountAmount: discountAmount,
      total: total,
    );
  }
}
