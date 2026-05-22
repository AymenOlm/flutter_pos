import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_pos/features/pos/domain/entities/cart_entity.dart';
import 'package:flutter_pos/features/pos/domain/entities/product.dart';
import 'package:flutter_pos/features/pos/domain/usecases/calculate_total.dart';

void main() {
  group('CalculateTotal', () {
    test('treats zero-quantity cart items as no charge', () {
      const cart = CartEntity(
        items: [
          CartItemEntity(
            product: Product(id: 'p-1', name: 'Coffee', price: 10),
            quantity: 0,
          ),
        ],
      );

      const calculator = CalculateTotal();

      final result = calculator(cart);

      expect(result.subtotal, 0);
      expect(result.discountAmount, 0);
      expect(result.total, 0);
    });

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
      expect(result.total, closeTo(10, 0.0001));
    });

    test('applies a fixed discount before the final total', () {
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
      expect(result.total, closeTo(15, 0.0001));
    });

    test('applies a percentage discount before the final total', () {
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
      expect(result.total, closeTo(18, 0.0001));
    });

    test('clamps fixed discounts that exceed the subtotal', () {
      const cart = CartEntity(
        items: [
          CartItemEntity(
            product: Product(id: 'p-1', name: 'Coffee', price: 9.99),
            quantity: 1,
          ),
        ],
      );

      const calculator = CalculateTotal();
      const discount = CartDiscount(type: DiscountType.fixed, value: 25);

      final result = calculator(cart, discount: discount);

      expect(result.subtotal, closeTo(9.99, 0.0001));
      expect(result.discountAmount, closeTo(9.99, 0.0001));
      expect(result.total, 0);
    });

    test('keeps fractional totals stable for rounding-sensitive prices', () {
      const cart = CartEntity(
        items: [
          CartItemEntity(
            product: Product(id: 'p-1', name: 'Coffee', price: 0.1),
            quantity: 3,
          ),
        ],
      );

      const calculator = CalculateTotal();
      const discount = CartDiscount(type: DiscountType.percentage, value: 12.5);

      final result = calculator(cart, discount: discount);

      expect(result.subtotal, closeTo(0.3, 0.0001));
      expect(result.discountAmount, closeTo(0.0375, 0.0001));
      expect(result.total, closeTo(0.2625, 0.0001));
    });
  });
}
