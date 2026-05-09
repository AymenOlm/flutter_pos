import 'package:flutter_pos/features/pos/data/datasources/pos_local_database.dart';
import 'package:flutter_pos/features/pos/data/models/product_model.dart';

abstract class ProductLocalDataSource {
  Future<void> cacheProducts(List<ProductModel> products);
  Future<List<ProductModel>> getCachedProducts();
  Future<void> upsertProduct(ProductModel product);
  Future<void> deleteProduct(String productId);
}

class DriftProductLocalDataSource implements ProductLocalDataSource {
  DriftProductLocalDataSource(this.localDatabase);

  final PosLocalDatabase localDatabase;

  @override
  Future<void> cacheProducts(List<ProductModel> products) async {
    final db = await localDatabase.database;

    await db.transaction(() async {
      for (final product in products) {
        await db.customStatement(
          'INSERT OR REPLACE INTO products (id, name, price, category) VALUES (?, ?, ?, ?)',
          [product.id, product.name, product.price, product.category],
        );
      }
    });
  }

  @override
  Future<List<ProductModel>> getCachedProducts() async {
    final db = await localDatabase.database;
    final rows = await db
        .customSelect(
          'SELECT id, name, price, category FROM products ORDER BY name ASC',
        )
        .get();

    return rows
        .map(
          (row) => ProductModel(
            id: row.read<String>('id'),
            name: row.read<String>('name'),
            price: row.read<double>('price'),
            category: row.read<String>('category'),
          ),
        )
        .toList(growable: false);
  }

  @override
  Future<void> upsertProduct(ProductModel product) async {
    final db = await localDatabase.database;
    await db.customStatement(
      'INSERT OR REPLACE INTO products (id, name, price, category) VALUES (?, ?, ?, ?)',
      [product.id, product.name, product.price, product.category],
    );
  }

  @override
  Future<void> deleteProduct(String productId) async {
    final db = await localDatabase.database;
    await db.customStatement('DELETE FROM products WHERE id = ?', [productId]);
  }
}
