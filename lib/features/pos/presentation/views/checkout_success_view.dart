import 'package:flutter/material.dart';

import 'package:flutter_pos/core/utils/receipt_service.dart';
import 'package:flutter_pos/features/pos/domain/entities/cart_entity.dart';
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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Transaction completed',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            'Review the receipt summary below before printing or exporting.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Receipt summary',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 4),
                            Text('Transaction ID: ${record.id}'),
                            Text('Payment Method: ${record.paymentMethod}'),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Chip(label: Text('${record.cart.items.length} items')),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  for (final item in record.cart.items) ...[
                    _ReceiptLineItem(item: item),
                    const SizedBox(height: 10),
                  ],
                  const Divider(height: 24),
                  _ReceiptAmountRow(label: 'Subtotal', value: record.subtotal),
                  if (record.discountAmount > 0) ...[
                    const SizedBox(height: 4),
                    _ReceiptAmountRow(
                      label: 'Discount (${_discountSummary(record)})',
                      value: record.discountAmount,
                      isNegative: true,
                    ),
                  ],
                  const SizedBox(height: 4),
                  _ReceiptAmountRow(
                    label: 'Total',
                    value: record.total,
                    isEmphasis: true,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Actions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => _printReceipt(context),
                    icon: const Icon(Icons.print_outlined),
                    label: const Text('Print Receipt'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => _exportReceiptPdf(context),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Export PDF'),
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
          ),
        ],
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

  Future<void> _exportReceiptPdf(BuildContext context) async {
    try {
      await sl<ReceiptService>().exportReceiptPdf(record);
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to export receipt PDF.')),
      );
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

class _ReceiptLineItem extends StatelessWidget {
  const _ReceiptLineItem({required this.item});

  final CartItemEntity item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.product.name,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${item.quantity} × \$${item.product.price.toStringAsFixed(2)}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          '\$${item.lineTotal.toStringAsFixed(2)}',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _ReceiptAmountRow extends StatelessWidget {
  const _ReceiptAmountRow({
    required this.label,
    required this.value,
    this.isNegative = false,
    this.isEmphasis = false,
  });

  final String label;
  final double value;
  final bool isNegative;
  final bool isEmphasis;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = isEmphasis
        ? theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)
        : theme.textTheme.bodyMedium;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: style),
        Text(
          '${isNegative ? '-' : ''}\$${value.toStringAsFixed(2)}',
          style: style,
        ),
      ],
    );
  }
}
