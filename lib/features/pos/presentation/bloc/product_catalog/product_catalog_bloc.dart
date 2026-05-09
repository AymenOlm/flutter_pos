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
    on<SelectProductCategory>(_onSelectProductCategory);
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
          filteredProducts: _applyFilters(
            products: products,
            query: state.query,
            selectedCategory: state.selectedCategory,
          ),
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
    emit(
      state.copyWith(
        query: event.query,
        filteredProducts: _applyFilters(
          products: state.products,
          query: event.query,
          selectedCategory: state.selectedCategory,
        ),
      ),
    );
  }

  void _onSelectProductCategory(
    SelectProductCategory event,
    Emitter<ProductCatalogState> emit,
  ) {
    emit(
      state.copyWith(
        selectedCategory: event.category,
        filteredProducts: _applyFilters(
          products: state.products,
          query: state.query,
          selectedCategory: event.category,
        ),
      ),
    );
  }

  List<Product> _applyFilters({
    required List<Product> products,
    required String query,
    required String selectedCategory,
  }) {
    final normalizedQuery = query.trim().toLowerCase();
    final normalizedCategory = selectedCategory.trim().toLowerCase();

    return products
        .where((product) {
          final matchesQuery =
              normalizedQuery.isEmpty ||
              product.name.toLowerCase().contains(normalizedQuery);
          final matchesCategory =
              normalizedCategory == 'all' ||
              product.category.toLowerCase() == normalizedCategory;
          return matchesQuery && matchesCategory;
        })
        .toList(growable: false);
  }
}
