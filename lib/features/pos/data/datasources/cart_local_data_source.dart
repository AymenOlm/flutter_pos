import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:flutter_pos/features/pos/domain/entities/cart_entity.dart';
import 'package:flutter_pos/features/pos/domain/entities/product.dart';
import 'package:flutter_pos/features/pos/domain/usecases/calculate_total.dart';

class PersistedCartState {
  const PersistedCartState({required this.cart, required this.discount});

  final CartEntity cart;
  final CartDiscount discount;
}

abstract class CartLocalDataSource {
  Future<void> saveCartState({
    required CartEntity cart,
    required CartDiscount discount,
  });
  Future<PersistedCartState?> loadCartState();
  Future<void> clearCartState();
}

class SharedPrefsCartLocalDataSource implements CartLocalDataSource {
  static const _keyCartState = 'pos_cart_state_v1';

  @override
  Future<void> saveCartState({
    required CartEntity cart,
    required CartDiscount discount,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final payload = jsonEncode({
      'items': cart.items
          .map(
            (item) => {
              'productId': item.product.id,
              'name': item.product.name,
              'price': item.product.price,
              'category': item.product.category,
              'quantity': item.quantity,
            },
          )
          .toList(growable: false),
      'discount': {'type': discount.type.name, 'value': discount.value},
    });
    await prefs.setString(_keyCartState, payload);
  }

  @override
  Future<PersistedCartState?> loadCartState() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyCartState);
    if (raw == null || raw.isEmpty) {
      return null;
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final items = (decoded['items'] as List<dynamic>? ?? const <dynamic>[])
          .map((itemRaw) {
            final item = itemRaw as Map<String, dynamic>;
            return CartItemEntity(
              product: Product(
                id: item['productId'] as String,
                name: item['name'] as String,
                price: (item['price'] as num).toDouble(),
                category:
                    (item['category'] as String?) ?? Product.defaultCategory,
              ),
              quantity: (item['quantity'] as num).toInt(),
            );
          })
          .where((item) => item.quantity > 0)
          .toList(growable: false);

      final discountRaw = decoded['discount'] as Map<String, dynamic>?;
      final discountTypeName = discountRaw?['type'] as String?;
      final discountType = DiscountType.values.firstWhere(
        (value) => value.name == discountTypeName,
        orElse: () => DiscountType.fixed,
      );
      final discountValue = ((discountRaw?['value'] as num?) ?? 0).toDouble();

      return PersistedCartState(
        cart: CartEntity(items: items),
        discount: CartDiscount(type: discountType, value: discountValue),
      );
    } catch (_) {
      await clearCartState();
      return null;
    }
  }

  @override
  Future<void> clearCartState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCartState);
  }
}
