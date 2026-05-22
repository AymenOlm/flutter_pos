import 'package:equatable/equatable.dart';

import 'package:flutter_pos/core/errors/failures.dart';
import 'package:flutter_pos/features/pos/domain/entities/product.dart';

enum ProductCatalogStatus { initial, loading, loaded, error }

class ProductCatalogState extends Equatable {
  const ProductCatalogState({
    required this.status,
    required this.products,
    required this.filteredProducts,
    required this.query,
    required this.selectedCategory,
    this.failure,
  });

  factory ProductCatalogState.initial() {
    return const ProductCatalogState(
      status: ProductCatalogStatus.initial,
      products: <Product>[],
      filteredProducts: <Product>[],
      query: '',
      selectedCategory: 'All',
    );
  }

  final ProductCatalogStatus status;
  final List<Product> products;
  final List<Product> filteredProducts;
  final String query;
  final String selectedCategory;
  final Failure? failure;

  ProductCatalogState copyWith({
    ProductCatalogStatus? status,
    List<Product>? products,
    List<Product>? filteredProducts,
    String? query,
    String? selectedCategory,
    Failure? failure,
    bool clearFailure = false,
  }) {
    return ProductCatalogState(
      status: status ?? this.status,
      products: products ?? this.products,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      query: query ?? this.query,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      failure: clearFailure ? null : (failure ?? this.failure),
    );
  }

  @override
  List<Object?> get props => [
    status,
    products,
    filteredProducts,
    query,
    selectedCategory,
    failure,
  ];
}
