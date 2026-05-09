import 'package:flutter_pos/features/pos/domain/entities/product.dart';

class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.name,
    required super.price,
    super.category,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      category: (json['category'] as String?) ?? Product.defaultCategory,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'price': price, 'category': category};
  }
}
