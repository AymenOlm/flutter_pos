import 'package:equatable/equatable.dart';

import 'package:flutter_pos/features/pos/domain/entities/product.dart';

enum ProductCatalogStatus { initial, loading, loaded, error }

class ProductCatalogState extends Equatable {
  const ProductCatalogState({
    required this.status,
    required this.products,
    required this.filteredProducts,
    required this.query,
    required this.selectedCategory,
    this.message,
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
  final String? message;

  ProductCatalogState copyWith({
    ProductCatalogStatus? status,
    List<Product>? products,
    List<Product>? filteredProducts,
    String? query,
    String? selectedCategory,
    String? message,
  }) {
    return ProductCatalogState(
      status: status ?? this.status,
      products: products ?? this.products,
      filteredProducts: filteredProducts ?? this.filteredProducts,
      query: query ?? this.query,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      message: message,
    );
  }

  @override
  List<Object?> get props => [
    status,
    products,
    filteredProducts,
    query,
    selectedCategory,
    message,
  ];
}
