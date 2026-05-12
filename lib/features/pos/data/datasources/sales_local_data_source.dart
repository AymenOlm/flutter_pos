import 'dart:convert';

import 'package:drift/drift.dart';

import 'package:flutter_pos/features/pos/data/datasources/pos_local_database.dart';
import 'package:flutter_pos/features/pos/domain/entities/cart_entity.dart';
import 'package:flutter_pos/features/pos/domain/entities/product.dart';
import 'package:flutter_pos/features/pos/domain/entities/transaction_record.dart';
import 'package:flutter_pos/features/pos/domain/usecases/calculate_total.dart';

abstract class SalesLocalDataSource {
  Future<void> saveTransaction(TransactionRecord record);
  Future<List<TransactionRecord>> getTransactions();
}

class DriftSalesLocalDataSource implements SalesLocalDataSource {
  DriftSalesLocalDataSource(this.localDatabase);

  final PosLocalDatabase localDatabase;

  @override
  Future<void> saveTransaction(TransactionRecord record) async {
    final db = await localDatabase.database;
    final itemsJson = jsonEncode(
      record.cart.items
          .map(
            (item) => {
              'productId': item.product.id,
              'name': item.product.name,
              'price': item.product.price,
              'category': item.product.category,
              'quantity': item.quantity,
            },
          )
          .toList(growable: false),
    );

    await db.customStatement(
      '''
      INSERT INTO sales (
        id,
        created_at,
        payment_method,
        subtotal,
        discount_type,
        discount_value,
        discount_amount,
        tax,
        total,
        items_json
      ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        record.id,
        record.createdAt.toIso8601String(),
        record.paymentMethod,
        record.subtotal,
        record.discountType.name,
        record.discountValue,
        record.discountAmount,
        0.0,
        record.total,
        itemsJson,
      ],
    );
  }

  @override
  Future<List<TransactionRecord>> getTransactions() async {
    final db = await localDatabase.database;
    final rows = await db.customSelect('''
      SELECT
        id,
        created_at,
        payment_method,
        subtotal,
        discount_type,
        discount_value,
        discount_amount,
        total,
        items_json
      FROM sales
      ORDER BY created_at DESC
      ''').get();

    return rows.map(_mapRowToRecord).toList(growable: false);
  }

  TransactionRecord _mapRowToRecord(QueryRow row) {
    final itemsRaw =
        jsonDecode(row.read<String>('items_json')) as List<dynamic>;
    final cartItems = itemsRaw
        .map((item) {
          final json = item as Map<String, dynamic>;
          final product = Product(
            id: json['productId'] as String,
            name: json['name'] as String,
            price: (json['price'] as num).toDouble(),
            category: (json['category'] as String?) ?? Product.defaultCategory,
          );
          return CartItemEntity(
            product: product,
            quantity: (json['quantity'] as num).toInt(),
          );
        })
        .toList(growable: false);

    return TransactionRecord(
      id: row.read<String>('id'),
      createdAt: DateTime.parse(row.read<String>('created_at')),
      paymentMethod: row.read<String>('payment_method'),
      cart: CartEntity(items: cartItems),
      subtotal: row.read<double>('subtotal'),
      discountType: _discountTypeFromName(row.read<String>('discount_type')),
      discountValue: row.read<double>('discount_value'),
      discountAmount: row.read<double>('discount_amount'),
      total: row.read<double>('total'),
    );
  }

  DiscountType _discountTypeFromName(String name) {
    return DiscountType.values.firstWhere(
      (value) => value.name == name,
      orElse: () => DiscountType.fixed,
    );
  }
}
