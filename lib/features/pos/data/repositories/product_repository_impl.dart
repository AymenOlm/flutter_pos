import 'package:dartz/dartz.dart';

import 'package:flutter_pos/core/errors/failures.dart';
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
  Future<Either<Failure, List<Product>>> getProducts() async {
    try {
      final remoteProducts = await remoteDataSource.fetchProducts();
      await localDataSource.cacheProducts(remoteProducts);
      final cachedProducts = await localDataSource.getCachedProducts();
      if (cachedProducts.isNotEmpty) {
        return right(cachedProducts);
      }

      return right(remoteProducts);
    } catch (_) {
      final cachedProducts = await localDataSource.getCachedProducts();
      if (cachedProducts.isNotEmpty) {
        return right(cachedProducts);
      }

      return left(const NetworkFailure('Unable to load products.'));
    }
  }

  @override
  Future<Either<Failure, Unit>> upsertProduct(Product product) async {
    try {
      await localDataSource.upsertProduct(
        ProductModel(
          id: product.id,
          name: product.name,
          price: product.price,
          category: product.category,
        ),
      );
      return right(unit);
    } catch (_) {
      return left(const DatabaseFailure('Unable to save the product.'));
    }
  }

  @override
  Future<Either<Failure, Unit>> deleteProduct(String productId) async {
    try {
      await localDataSource.deleteProduct(productId);
      return right(unit);
    } catch (_) {
      return left(const DatabaseFailure('Unable to delete the product.'));
    }
  }
}
