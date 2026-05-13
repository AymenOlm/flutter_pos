import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_pos/core/utils/receipt_service.dart';
import 'package:flutter_pos/features/pos/domain/entities/cart_entity.dart';
import 'package:flutter_pos/features/pos/domain/entities/product.dart';
import 'package:flutter_pos/features/pos/domain/entities/transaction_record.dart';
import 'package:flutter_pos/features/pos/domain/usecases/calculate_total.dart';
import 'package:flutter_pos/features/pos/presentation/di/service_locator.dart';
import 'package:flutter_pos/features/pos/presentation/views/checkout_success_view.dart';

class _FakeReceiptService extends ReceiptService {
  int printCalls = 0;
  int exportCalls = 0;

  @override
  Future<void> printReceipt(
    TransactionRecord record, {
    ReceiptPaperSize paperSize = ReceiptPaperSize.mm80,
  }) async {
    printCalls += 1;
  }

  @override
  Future<void> exportReceiptPdf(
    TransactionRecord record, {
    ReceiptPaperSize paperSize = ReceiptPaperSize.mm80,
  }) async {
    exportCalls += 1;
  }
}

TransactionRecord _buildRecord() {
  const coffee = Product(
    id: 'p-1',
    name: 'Coffee',
    price: 3.50,
    category: 'Beverages',
  );
  const sandwich = Product(
    id: 'p-2',
    name: 'Sandwich',
    price: 7.25,
    category: 'Food',
  );
  final cart = CartEntity(
    items: const [
      CartItemEntity(product: coffee, quantity: 2),
      CartItemEntity(product: sandwich, quantity: 1),
    ],
  );
  const totals = CalculateTotal();
  final summary = totals(
    cart,
    discount: const CartDiscount(type: DiscountType.percentage, value: 10),
  );

  return TransactionRecord(
    id: 'txn-1',
    createdAt: DateTime(2026, 5, 13, 14, 30),
    paymentMethod: 'Cash',
    cart: cart,
    subtotal: summary.subtotal,
    discountType: DiscountType.percentage,
    discountValue: 10,
    discountAmount: summary.discountAmount,
    total: summary.total,
  );
}

void main() {
  setUp(() async {
    await sl.reset();
    sl.registerSingleton<ReceiptService>(_FakeReceiptService());
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('shows a receipt summary after checkout', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(home: CheckoutSuccessView(record: _buildRecord())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Receipt summary'), findsOneWidget);
    expect(find.text('Transaction ID: txn-1'), findsOneWidget);
    expect(find.text('Coffee'), findsOneWidget);
    expect(find.text('Sandwich'), findsOneWidget);
    expect(find.text('Subtotal'), findsOneWidget);
    expect(find.text('Discount (Percentage 10%)'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('Print Receipt'), findsOneWidget);
    expect(find.text('Export PDF'), findsOneWidget);
    expect(find.text('Back to POS'), findsOneWidget);
  });

  testWidgets('calls print and export actions from the summary screen', (
    WidgetTester tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1280, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final fakeReceiptService = _FakeReceiptService();
    await sl.reset();
    sl.registerSingleton<ReceiptService>(fakeReceiptService);

    await tester.pumpWidget(
      MaterialApp(home: CheckoutSuccessView(record: _buildRecord())),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Print Receipt'));
    await tester.tap(find.text('Print Receipt'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Export PDF'));
    await tester.tap(find.text('Export PDF'));
    await tester.pumpAndSettle();

    expect(fakeReceiptService.printCalls, 1);
    expect(fakeReceiptService.exportCalls, 1);
  });
}
