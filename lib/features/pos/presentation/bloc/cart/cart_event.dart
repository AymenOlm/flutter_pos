import 'package:equatable/equatable.dart';

import 'package:flutter_pos/features/pos/domain/entities/product.dart';
import 'package:flutter_pos/features/pos/domain/usecases/calculate_total.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class AddItem extends CartEvent {
  const AddItem(this.product);

  final Product product;

  @override
  List<Object?> get props => [product];
}

class RemoveItem extends CartEvent {
  const RemoveItem(this.product);

  final Product product;

  @override
  List<Object?> get props => [product];
}

class ClearCart extends CartEvent {
  const ClearCart();
}

class DiscountChanged extends CartEvent {
  const DiscountChanged({required this.discount});

  final CartDiscount discount;

  @override
  List<Object?> get props => [discount];
}

class CheckoutSubmitted extends CartEvent {
  const CheckoutSubmitted({required this.paymentMethod});

  final String paymentMethod;

  @override
  List<Object?> get props => [paymentMethod];
}

class CheckoutStatusReset extends CartEvent {
  const CheckoutStatusReset();
}

class RestoreCartRequested extends CartEvent {
  const RestoreCartRequested();
}
