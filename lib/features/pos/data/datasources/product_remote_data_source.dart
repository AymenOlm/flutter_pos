import 'package:flutter_pos/features/pos/data/models/product_model.dart';

abstract class ProductRemoteDataSource {
  Future<List<ProductModel>> fetchProducts();
}

class MockProductRemoteDataSource implements ProductRemoteDataSource {
  @override
  Future<List<ProductModel>> fetchProducts() async {
    await Future<void>.delayed(const Duration(milliseconds: 250));

    return const [
      ProductModel(
        id: 'p-1',
        name: 'Coffee',
        price: 3.50,
        category: 'Beverages',
      ),
      ProductModel(id: 'p-2', name: 'Sandwich', price: 7.25, category: 'Food'),
      ProductModel(
        id: 'p-3',
        name: 'Cake Slice',
        price: 4.00,
        category: 'Bakery',
      ),
      ProductModel(
        id: 'p-4',
        name: 'Orange Juice',
        price: 5.00,
        category: 'Beverages',
      ),
      ProductModel(id: 'p-5', name: 'Bagel', price: 2.75, category: 'Bakery'),
      ProductModel(id: 'p-6', name: 'Salad', price: 8.50, category: 'Food'),
      ProductModel(id: 'p-7', name: 'Tea', price: 2.50, category: 'Beverages'),
      ProductModel(id: 'p-8', name: 'Muffin', price: 3.25, category: 'Bakery'),
    ];
  }
}
