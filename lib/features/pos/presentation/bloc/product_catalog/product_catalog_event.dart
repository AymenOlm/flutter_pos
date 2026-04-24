import 'package:equatable/equatable.dart';

abstract class ProductCatalogEvent extends Equatable {
  const ProductCatalogEvent();

  @override
  List<Object?> get props => [];
}

class LoadProducts extends ProductCatalogEvent {
  const LoadProducts();
}

class SearchProducts extends ProductCatalogEvent {
  const SearchProducts(this.query);

  final String query;

  @override
  List<Object?> get props => [query];
}
