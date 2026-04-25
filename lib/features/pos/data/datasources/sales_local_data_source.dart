import 'dart:convert';

import 'package:drift/drift.dart';

import 'package:flutter_pos/features/pos/data/datasources/pos_local_database.dart';
import 'package:flutter_pos/features/pos/domain/entities/cart_entity.dart';
import 'package:flutter_pos/features/pos/domain/entities/product.dart';
import 'package:flutter_pos/features/pos/domain/entities/transaction_record.dart';

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
        tax,
        total,
        items_json
      ) VALUES (?, ?, ?, ?, ?, ?, ?)
      ''',
      [
        record.id,
        record.createdAt.toIso8601String(),
        record.paymentMethod,
        record.subtotal,
        record.tax,
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
        tax,
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
      tax: row.read<double>('tax'),
      total: row.read<double>('total'),
    );
  }
}
