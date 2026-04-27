import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_pos/features/pos/domain/entities/cart_entity.dart';
import 'package:flutter_pos/features/pos/domain/entities/product.dart';
import 'package:flutter_pos/features/pos/domain/usecases/calculate_total.dart';

void main() {
  group('CalculateTotal', () {
    test('applies no discount when discount is absent', () {
      const cart = CartEntity(
        items: [
          CartItemEntity(
            product: Product(id: 'p-1', name: 'Coffee', price: 10),
            quantity: 1,
          ),
        ],
      );

      const calculator = CalculateTotal();

      final result = calculator(cart);

      expect(result.subtotal, 10);
      expect(result.discountAmount, 0);
      expect(result.taxableSubtotal, 10);
      expect(result.tax, closeTo(1, 0.0001));
      expect(result.total, closeTo(11, 0.0001));
    });

    test('applies a fixed discount before tax', () {
      const cart = CartEntity(
        items: [
          CartItemEntity(
            product: Product(id: 'p-1', name: 'Coffee', price: 10),
            quantity: 2,
          ),
        ],
      );

      const calculator = CalculateTotal();
      const discount = CartDiscount(type: DiscountType.fixed, value: 5);

      final result = calculator(cart, discount: discount);

      expect(result.subtotal, 20);
      expect(result.discountAmount, 5);
      expect(result.taxableSubtotal, 15);
      expect(result.tax, closeTo(1.5, 0.0001));
      expect(result.total, closeTo(16.5, 0.0001));
    });

    test('applies a percentage discount before tax', () {
      const cart = CartEntity(
        items: [
          CartItemEntity(
            product: Product(id: 'p-1', name: 'Coffee', price: 20),
            quantity: 1,
          ),
        ],
      );

      const calculator = CalculateTotal();
      const discount = CartDiscount(type: DiscountType.percentage, value: 10);

      final result = calculator(cart, discount: discount);

      expect(result.subtotal, 20);
      expect(result.discountAmount, 2);
      expect(result.taxableSubtotal, 18);
      expect(result.tax, closeTo(1.8, 0.0001));
      expect(result.total, closeTo(19.8, 0.0001));
    });
  });
}
