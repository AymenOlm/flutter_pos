import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_pos/core/logging/app_logger.dart';
import 'package:flutter_pos/features/pos/domain/entities/product.dart';
import 'package:flutter_pos/features/pos/domain/repositories/product_repository.dart';
import 'package:flutter_pos/features/pos/presentation/bloc/product_catalog/product_catalog_event.dart';
import 'package:flutter_pos/features/pos/presentation/bloc/product_catalog/product_catalog_state.dart';

class ProductCatalogBloc
    extends Bloc<ProductCatalogEvent, ProductCatalogState> {
  ProductCatalogBloc({
    required ProductRepository repository,
    required AppLogger logger,
  }) : _repository = repository,
       _logger = logger,
       super(ProductCatalogState.initial()) {
    on<LoadProducts>(_onLoadProducts);
    on<SearchProducts>(_onSearchProducts);
  }

  final ProductRepository _repository;
  final AppLogger _logger;

  Future<void> _onLoadProducts(
    LoadProducts event,
    Emitter<ProductCatalogState> emit,
  ) async {
    emit(state.copyWith(status: ProductCatalogStatus.loading));

    try {
      final products = await _repository.getProducts();
      emit(
        state.copyWith(
          status: ProductCatalogStatus.loaded,
          products: products,
          filteredProducts: products,
        ),
      );
    } catch (error, stackTrace) {
      _logger.error(
        feature: 'catalog',
        action: 'load_products',
        outcome: 'failed',
        errorCode: 'CATALOG_LOAD_FAILED',
        context: <String, Object?>{
          'existingProductCount': state.products.length,
        },
        error: error,
        stackTrace: stackTrace,
      );
      emit(
        state.copyWith(
          status: ProductCatalogStatus.error,
          message: 'Unable to load products.',
        ),
      );
    }
  }

  void _onSearchProducts(
    SearchProducts event,
    Emitter<ProductCatalogState> emit,
  ) {
    final query = event.query.trim().toLowerCase();
    final filtered = _filterProducts(state.products, query);

    emit(state.copyWith(query: event.query, filteredProducts: filtered));
  }

  List<Product> _filterProducts(List<Product> products, String query) {
    if (query.isEmpty) {
      return products;
    }

    return products
        .where((product) => product.name.toLowerCase().contains(query))
        .toList(growable: false);
  }
}
