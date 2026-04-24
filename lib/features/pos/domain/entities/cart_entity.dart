import 'package:equatable/equatable.dart';

import 'package:flutter_pos/features/pos/domain/entities/product.dart';

class CartItemEntity extends Equatable {
  const CartItemEntity({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  double get lineTotal => product.price * quantity;

  CartItemEntity copyWith({Product? product, int? quantity}) {
    return CartItemEntity(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  List<Object?> get props => [product, quantity];
}

class CartEntity extends Equatable {
  const CartEntity({this.items = const <CartItemEntity>[]});

  final List<CartItemEntity> items;

  double get subtotal =>
      items.fold<double>(0, (sum, item) => sum + item.lineTotal);

  CartEntity addItem(Product product) {
    final updatedItems = List<CartItemEntity>.from(items);
    final index = updatedItems.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (index == -1) {
      updatedItems.add(CartItemEntity(product: product, quantity: 1));
    } else {
      final existing = updatedItems[index];
      updatedItems[index] = existing.copyWith(quantity: existing.quantity + 1);
    }

    return CartEntity(items: updatedItems);
  }

  CartEntity removeItem(Product product) {
    final updatedItems = List<CartItemEntity>.from(items);
    final index = updatedItems.indexWhere(
      (item) => item.product.id == product.id,
    );

    if (index == -1) {
      return this;
    }

    final existing = updatedItems[index];
    if (existing.quantity <= 1) {
      updatedItems.removeAt(index);
    } else {
      updatedItems[index] = existing.copyWith(quantity: existing.quantity - 1);
    }

    return CartEntity(items: updatedItems);
  }

  CartEntity clear() => const CartEntity();

  @override
  List<Object?> get props => [items];
}
