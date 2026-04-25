import 'package:equatable/equatable.dart';

import 'package:flutter_pos/features/pos/domain/entities/cart_entity.dart';

class TransactionRecord extends Equatable {
  const TransactionRecord({
    required this.id,
    required this.createdAt,
    required this.paymentMethod,
    required this.cart,
    required this.subtotal,
    required this.tax,
    required this.total,
  });

  final String id;
  final DateTime createdAt;
  final String paymentMethod;
  final CartEntity cart;
  final double subtotal;
  final double tax;
  final double total;

  @override
  List<Object?> get props => [
    id,
    createdAt,
    paymentMethod,
    cart,
    subtotal,
    tax,
    total,
  ];
}
