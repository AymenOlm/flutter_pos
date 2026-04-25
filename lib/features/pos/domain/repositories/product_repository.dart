import 'package:flutter_pos/features/pos/domain/entities/product.dart';

abstract class ProductRepository {
  Future<List<Product>> getProducts();
  Future<void> upsertProduct(Product product);
  Future<void> deleteProduct(String productId);
}
