import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_pos/features/pos/data/datasources/product_local_data_source.dart';
import 'package:flutter_pos/features/pos/data/datasources/product_remote_data_source.dart';
import 'package:flutter_pos/features/pos/data/models/product_model.dart';
import 'package:flutter_pos/features/pos/data/repositories/product_repository_impl.dart';
import 'package:flutter_pos/features/pos/domain/entities/product.dart';

class _FakeProductRemoteDataSource implements ProductRemoteDataSource {
  List<ProductModel> products = <ProductModel>[];
  Exception? error;
  int fetchCalls = 0;

  @override
  Future<List<ProductModel>> fetchProducts() async {
    fetchCalls += 1;
    if (error != null) {
      throw error!;
    }
    return products;
  }
}

class _FakeProductLocalDataSource implements ProductLocalDataSource {
  final List<List<ProductModel>> cacheInvocations = <List<ProductModel>>[];
  List<ProductModel> cachedProducts = <ProductModel>[];
  ProductModel? upsertedProduct;
  String? deletedProductId;
  int getCachedProductsCalls = 0;

  @override
  Future<void> cacheProducts(List<ProductModel> products) async {
    cacheInvocations.add(products);
  }

  @override
  Future<void> deleteProduct(String productId) async {
    deletedProductId = productId;
  }

  @override
  Future<List<ProductModel>> getCachedProducts() async {
    getCachedProductsCalls += 1;
    return cachedProducts;
  }

  @override
  Future<void> upsertProduct(ProductModel product) async {
    upsertedProduct = product;
  }
}

void main() {
  group('ProductRepositoryImpl', () {
    test(
      'returns cached products after remote sync when cache is available',
      () async {
        final remoteDataSource = _FakeProductRemoteDataSource();
        final localDataSource = _FakeProductLocalDataSource();
        remoteDataSource.products = const [
          ProductModel(id: 'p-1', name: 'Coffee', price: 3.50),
        ];
        localDataSource.cachedProducts = const [
          ProductModel(id: 'p-1', name: 'Coffee', price: 3.50),
          ProductModel(id: 'p-admin-1', name: 'Admin Item', price: 9.99),
        ];
        final repository = ProductRepositoryImpl(
          remoteDataSource: remoteDataSource,
          localDataSource: localDataSource,
        );

        final result = await repository.getProducts();

        expect(result, localDataSource.cachedProducts);
        expect(remoteDataSource.fetchCalls, 1);
        expect(localDataSource.cacheInvocations, [remoteDataSource.products]);
        expect(localDataSource.getCachedProductsCalls, 1);
      },
    );

    test(
      'returns remote products when cache is empty after remote sync',
      () async {
        final remoteDataSource = _FakeProductRemoteDataSource();
        final localDataSource = _FakeProductLocalDataSource();
        remoteDataSource.products = const [
          ProductModel(id: 'p-1', name: 'Coffee', price: 3.50),
        ];
        localDataSource.cachedProducts = const [];
        final repository = ProductRepositoryImpl(
          remoteDataSource: remoteDataSource,
          localDataSource: localDataSource,
        );

        final result = await repository.getProducts();

        expect(result, remoteDataSource.products);
        expect(localDataSource.getCachedProductsCalls, 1);
      },
    );

    test(
      'returns cached products when remote fetch fails and cache is not empty',
      () async {
        final remoteDataSource = _FakeProductRemoteDataSource();
        final localDataSource = _FakeProductLocalDataSource();
        remoteDataSource.error = Exception('network error');
        localDataSource.cachedProducts = const [
          ProductModel(id: 'p-2', name: 'Bagel', price: 2.75),
        ];
        final repository = ProductRepositoryImpl(
          remoteDataSource: remoteDataSource,
          localDataSource: localDataSource,
        );

        final result = await repository.getProducts();

        expect(result, localDataSource.cachedProducts);
        expect(remoteDataSource.fetchCalls, 1);
        expect(localDataSource.getCachedProductsCalls, 1);
      },
    );

    test(
      'rethrows remote error when remote fails and cache is empty',
      () async {
        final remoteDataSource = _FakeProductRemoteDataSource();
        final localDataSource = _FakeProductLocalDataSource();
        remoteDataSource.error = Exception('network error');
        localDataSource.cachedProducts = const [];
        final repository = ProductRepositoryImpl(
          remoteDataSource: remoteDataSource,
          localDataSource: localDataSource,
        );

        await expectLater(repository.getProducts, throwsA(isA<Exception>()));
        expect(localDataSource.getCachedProductsCalls, 1);
      },
    );

    test('upsertProduct maps domain product to ProductModel', () async {
      final remoteDataSource = _FakeProductRemoteDataSource();
      final localDataSource = _FakeProductLocalDataSource();
      final repository = ProductRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
      );
      const product = Product(id: 'p-3', name: 'Tea', price: 2.50);

      await repository.upsertProduct(product);

      expect(
        localDataSource.upsertedProduct,
        const ProductModel(id: 'p-3', name: 'Tea', price: 2.50),
      );
    });

    test('deleteProduct delegates to local data source', () async {
      final remoteDataSource = _FakeProductRemoteDataSource();
      final localDataSource = _FakeProductLocalDataSource();
      final repository = ProductRepositoryImpl(
        remoteDataSource: remoteDataSource,
        localDataSource: localDataSource,
      );

      await repository.deleteProduct('p-9');

      expect(localDataSource.deletedProductId, 'p-9');
    });
  });
}
