import 'package:flutter_pos/features/pos/data/models/product_model.dart';

abstract class ProductRemoteDataSource {
  Future<List<ProductModel>> fetchProducts();
}

class MockProductRemoteDataSource implements ProductRemoteDataSource {
  @override
  Future<List<ProductModel>> fetchProducts() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    return const [
      ProductModel(id: 'p-1', name: 'Coffee', price: 3.50),
      ProductModel(id: 'p-2', name: 'Sandwich', price: 7.25),
      ProductModel(id: 'p-3', name: 'Cake Slice', price: 4.00),
      ProductModel(id: 'p-4', name: 'Orange Juice', price: 5.00),
      ProductModel(id: 'p-5', name: 'Bagel', price: 2.75),
      ProductModel(id: 'p-6', name: 'Salad', price: 8.50),
      ProductModel(id: 'p-7', name: 'Tea', price: 2.50),
      ProductModel(id: 'p-8', name: 'Muffin', price: 3.25),
    ];
  }
}
