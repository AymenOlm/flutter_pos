import 'package:equatable/equatable.dart';

class Product extends Equatable {
  const Product({
    required this.id,
    required this.name,
    required this.price,
    this.category = defaultCategory,
  });

  static const String defaultCategory = 'General';

  final String id;
  final String name;
  final double price;
  final String category;

  @override
  List<Object?> get props => [id, name, price, category];
}
