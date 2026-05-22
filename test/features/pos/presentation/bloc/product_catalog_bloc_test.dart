import 'package:flutter_test/flutter_test.dart';

import 'package:dartz/dartz.dart';

import 'package:flutter_pos/core/errors/failures.dart';
import 'package:flutter_pos/core/logging/app_logger.dart';
import 'package:flutter_pos/features/pos/data/models/product_model.dart';
import 'package:flutter_pos/features/pos/domain/entities/product.dart';
import 'package:flutter_pos/features/pos/domain/repositories/product_repository.dart';
import 'package:flutter_pos/features/pos/presentation/bloc/product_catalog/product_catalog_bloc.dart';
import 'package:flutter_pos/features/pos/presentation/bloc/product_catalog/product_catalog_event.dart';
import 'package:flutter_pos/features/pos/presentation/bloc/product_catalog/product_catalog_state.dart';

class _FakeProductRepository implements ProductRepository {
  _FakeProductRepository(this.products);

  final List<Product> products;

  @override
  Future<Either<Failure, List<Product>>> getProducts() async => right(products);

  @override
  Future<Either<Failure, Unit>> deleteProduct(String productId) async =>
      right(unit);

  @override
  Future<Either<Failure, Unit>> upsertProduct(Product product) async =>
      right(unit);
}

void main() {
  test('filters products by query and category', () async {
    final repository = _FakeProductRepository(const [
      ProductModel(
        id: 'p-1',
        name: 'Coffee',
        price: 3.50,
        category: 'Beverages',
      ),
      ProductModel(id: 'p-2', name: 'Tea', price: 2.50, category: 'Beverages'),
      ProductModel(id: 'p-3', name: 'Sandwich', price: 7.25, category: 'Food'),
    ]);
    final bloc = ProductCatalogBloc(
      repository: repository,
      logger: AppLogger(sinks: const []),
    );

    final expectation = expectLater(
      bloc.stream,
      emitsInOrder([
        isA<ProductCatalogState>().having(
          (state) => state.status,
          'status',
          ProductCatalogStatus.loading,
        ),
        isA<ProductCatalogState>().having(
          (state) =>
              state.filteredProducts.map((product) => product.id).toList(),
          'filteredProducts',
          ['p-1', 'p-2', 'p-3'],
        ),
        isA<ProductCatalogState>().having(
          (state) =>
              state.filteredProducts.map((product) => product.id).toList(),
          'filteredProducts',
          ['p-1'],
        ),
        isA<ProductCatalogState>().having(
          (state) =>
              state.filteredProducts.map((product) => product.id).toList(),
          'filteredProducts',
          <String>[],
        ),
      ]),
    );

    bloc.add(const LoadProducts());
    bloc.add(const SearchProducts('cof'));
    bloc.add(const SelectProductCategory('Food'));

    await expectation;
    await bloc.close();
  });
}
