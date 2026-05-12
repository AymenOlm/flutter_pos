import 'package:equatable/equatable.dart';

import 'package:flutter_pos/features/pos/domain/entities/cart_entity.dart';
import 'package:flutter_pos/features/pos/domain/usecases/calculate_total.dart';

class TransactionRecord extends Equatable {
  const TransactionRecord({
    required this.id,
    required this.createdAt,
    required this.paymentMethod,
    required this.cart,
    required this.subtotal,
    required this.discountType,
    required this.discountValue,
    required this.discountAmount,
    required this.total,
  });

  final String id;
  final DateTime createdAt;
  final String paymentMethod;
  final CartEntity cart;
  final double subtotal;
  final DiscountType discountType;
  final double discountValue;
  final double discountAmount;
  final double total;

  @override
  List<Object?> get props => [
    id,
    createdAt,
    paymentMethod,
    cart,
    subtotal,
    discountType,
    discountValue,
    discountAmount,
    total,
  ];
}
