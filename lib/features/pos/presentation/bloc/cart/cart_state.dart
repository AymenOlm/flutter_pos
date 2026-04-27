import 'package:equatable/equatable.dart';

import 'package:flutter_pos/features/pos/domain/entities/cart_entity.dart';
import 'package:flutter_pos/features/pos/domain/entities/transaction_record.dart';
import 'package:flutter_pos/features/pos/domain/usecases/calculate_total.dart';

enum CheckoutStatus { idle, submitting, success, failure }

class CartState extends Equatable {
  const CartState({
    required this.cart,
    required this.totals,
    required this.discount,
    required this.checkoutStatus,
    this.errorMessage,
    this.lastTransaction,
  });

  factory CartState.initial() {
    const cart = CartEntity();
    const discount = CartDiscount.none();
    const totals = CartTotals(
      subtotal: 0,
      discountAmount: 0,
      taxableSubtotal: 0,
      tax: 0,
      total: 0,
    );
    return const CartState(
      cart: cart,
      totals: totals,
      discount: discount,
      checkoutStatus: CheckoutStatus.idle,
    );
  }

  final CartEntity cart;
  final CartTotals totals;
  final CartDiscount discount;
  final CheckoutStatus checkoutStatus;
  final String? errorMessage;
  final TransactionRecord? lastTransaction;

  CartState copyWith({
    CartEntity? cart,
    CartTotals? totals,
    CartDiscount? discount,
    CheckoutStatus? checkoutStatus,
    String? errorMessage,
    TransactionRecord? lastTransaction,
    bool clearErrorMessage = false,
    bool clearLastTransaction = false,
  }) {
    return CartState(
      cart: cart ?? this.cart,
      totals: totals ?? this.totals,
      discount: discount ?? this.discount,
      checkoutStatus: checkoutStatus ?? this.checkoutStatus,
      errorMessage: clearErrorMessage
          ? null
          : (errorMessage ?? this.errorMessage),
      lastTransaction: clearLastTransaction
          ? null
          : (lastTransaction ?? this.lastTransaction),
    );
  }

  @override
  List<Object?> get props => [
    cart,
    totals,
    discount,
    checkoutStatus,
    errorMessage,
    lastTransaction,
  ];
}
