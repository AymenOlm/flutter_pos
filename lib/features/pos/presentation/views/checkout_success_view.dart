import 'package:flutter/material.dart';

import 'package:flutter_pos/core/utils/receipt_service.dart';
import 'package:flutter_pos/features/pos/domain/entities/transaction_record.dart';
import 'package:flutter_pos/features/pos/domain/usecases/calculate_total.dart';
import 'package:flutter_pos/features/pos/presentation/di/service_locator.dart';

class CheckoutSuccessView extends StatelessWidget {
  const CheckoutSuccessView({super.key, required this.record});

  final TransactionRecord record;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout Success')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Transaction completed',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            Text('Transaction ID: ${record.id}'),
            Text('Payment Method: ${record.paymentMethod}'),
            if (record.discountAmount > 0)
              Text('Discount: ${_discountSummary(record)}'),
            Text('Total: \$${record.total.toStringAsFixed(2)}'),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => _printReceipt(context),
              icon: const Icon(Icons.print_outlined),
              label: const Text('Print Receipt'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Back to POS'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _printReceipt(BuildContext context) async {
    try {
      await sl<ReceiptService>().printReceipt(record);
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Unable to print receipt.')));
    }
  }

  String _discountSummary(TransactionRecord record) {
    switch (record.discountType) {
      case DiscountType.fixed:
        return '${record.discountType.displayName} \$${record.discountValue.toStringAsFixed(2)}';
      case DiscountType.percentage:
        return '${record.discountType.displayName} ${record.discountValue.toStringAsFixed(0)}%';
    }
  }
}
