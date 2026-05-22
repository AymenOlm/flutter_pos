import 'package:flutter_pos/features/pos/domain/entities/cart_entity.dart';
import 'package:flutter_pos/features/pos/domain/entities/cart_persistence_state.dart';
import 'package:flutter_pos/features/pos/domain/entities/product.dart';
import 'package:flutter_pos/features/pos/domain/usecases/calculate_total.dart';
import 'package:flutter_pos/features/pos/data/datasources/pos_local_database.dart';

abstract class CartLocalDataSource {
  Future<void> saveCartState({
    required CartEntity cart,
    required CartDiscount discount,
  });
  Future<CartPersistenceState?> loadCartState();
  Future<void> clearCartState();
}

class DriftCartLocalDataSource implements CartLocalDataSource {
  DriftCartLocalDataSource(this.localDatabase);

  final PosLocalDatabase localDatabase;

  @override
  Future<void> saveCartState({
    required CartEntity cart,
    required CartDiscount discount,
  }) async {
    final db = await localDatabase.database;

    await db.transaction(() async {
      await db.customStatement('DELETE FROM cart_state WHERE id = 1');
      await db.customStatement(
        '''
        INSERT OR REPLACE INTO cart_state (
          id,
          discount_type,
          discount_value
        ) VALUES (?, ?, ?)
        ''',
        [1, discount.type.name, discount.value],
      );

      await db.customStatement('DELETE FROM cart_items');

      for (final item in cart.items) {
        await db.customStatement(
          '''
          INSERT OR REPLACE INTO cart_items (
            product_id,
            name,
            price,
            category,
            quantity
          ) VALUES (?, ?, ?, ?, ?)
          ''',
          [
            item.product.id,
            item.product.name,
            item.product.price,
            item.product.category,
            item.quantity,
          ],
        );
      }
    });
  }

  @override
  Future<CartPersistenceState?> loadCartState() async {
    final db = await localDatabase.database;

    final stateRows = await db.customSelect('''
      SELECT discount_type, discount_value
      FROM cart_state
      WHERE id = 1
      LIMIT 1
      ''').get();
    final itemRows = await db.customSelect('''
      SELECT product_id, name, price, category, quantity
      FROM cart_items
      ORDER BY name ASC
      ''').get();

    if (stateRows.isEmpty && itemRows.isEmpty) {
      return null;
    }

    final items = itemRows
        .map((row) {
          return CartItemEntity(
            product: Product(
              id: row.read<String>('product_id'),
              name: row.read<String>('name'),
              price: row.read<double>('price'),
              category: row.read<String>('category'),
            ),
            quantity: row.read<int>('quantity'),
          );
        })
        .where((item) => item.quantity > 0)
        .toList(growable: false);

    final stateRow = stateRows.isEmpty ? null : stateRows.first;
    final discountTypeName = stateRow?.read<String>('discount_type');
    final discountType = DiscountType.values.firstWhere(
      (value) => value.name == discountTypeName,
      orElse: () => DiscountType.fixed,
    );
    final discountValue = stateRow?.read<double>('discount_value') ?? 0;

    return CartPersistenceState(
      cart: CartEntity(items: items),
      discount: CartDiscount(type: discountType, value: discountValue),
    );
  }

  @override
  Future<void> clearCartState() async {
    final db = await localDatabase.database;
    await db.transaction(() async {
      await db.customStatement('DELETE FROM cart_items');
      await db.customStatement('DELETE FROM cart_state WHERE id = 1');
    });
  }
}
