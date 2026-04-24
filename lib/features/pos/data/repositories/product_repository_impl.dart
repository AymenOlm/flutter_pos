import 'package:flutter_pos/features/pos/data/datasources/product_remote_data_source.dart';
import 'package:flutter_pos/features/pos/domain/entities/product.dart';
import 'package:flutter_pos/features/pos/domain/repositories/product_repository.dart';

class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl(this.remoteDataSource);

  final ProductRemoteDataSource remoteDataSource;

  @override
  Future<List<Product>> getProducts() async {
    final products = await remoteDataSource.fetchProducts();
    return products;
  }
}
