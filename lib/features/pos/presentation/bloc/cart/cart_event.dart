import 'package:equatable/equatable.dart';

import 'package:flutter_pos/features/pos/domain/entities/product.dart';

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
