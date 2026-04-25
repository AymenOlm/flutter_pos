import 'package:flutter_pos/features/pos/data/datasources/product_remote_data_source.dart';
import 'package:flutter_pos/features/pos/data/datasources/product_local_data_source.dart';
import 'package:flutter_pos/features/pos/data/models/product_model.dart';
import 'package:flutter_pos/features/pos/domain/entities/product.dart';
import 'package:flutter_pos/features/pos/domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
  });

  final ProductRemoteDataSource remoteDataSource;
  final ProductLocalDataSource localDataSource;

  @override
  Future<List<Product>> getProducts() async {
    try {
      final remoteProducts = await remoteDataSource.fetchProducts();
      await localDataSource.cacheProducts(remoteProducts);
      final cachedProducts = await localDataSource.getCachedProducts();
      if (cachedProducts.isNotEmpty) {
        return cachedProducts;
      }

      return remoteProducts;
    } catch (_) {
      final cachedProducts = await localDataSource.getCachedProducts();
      if (cachedProducts.isNotEmpty) {
        return cachedProducts;
      }

      rethrow;
    }
  }

  @override
  Future<void> upsertProduct(Product product) {
    return localDataSource.upsertProduct(
      ProductModel(id: product.id, name: product.name, price: product.price),
    );
  }

  @override
  Future<void> deleteProduct(String productId) {
    return localDataSource.deleteProduct(productId);
  }
}
