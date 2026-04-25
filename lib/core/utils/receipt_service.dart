import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import 'package:flutter_pos/features/pos/domain/entities/transaction_record.dart';

enum ReceiptPaperSize { mm58, mm80 }

class ReceiptService {
  Future<Uint8List> buildReceipt(
    TransactionRecord record, {
    ReceiptPaperSize paperSize = ReceiptPaperSize.mm80,
  }) async {
    final pdf = pw.Document();
    final pageFormat = _pageFormat(paperSize);

    pdf.addPage(
      pw.Page(
        pageFormat: pageFormat,
        margin: const pw.EdgeInsets.all(8),
        build: (_) => _buildReceiptContent(record),
      ),
    );

    return pdf.save();
  }

  Future<void> printReceipt(
    TransactionRecord record, {
    ReceiptPaperSize paperSize = ReceiptPaperSize.mm80,
  }) async {
    await Printing.layoutPdf(
      onLayout: (_) => buildReceipt(record, paperSize: paperSize),
      name: 'receipt_${record.id}.pdf',
    );
  }

  PdfPageFormat _pageFormat(ReceiptPaperSize paperSize) {
    const mmToPoint = 72 / 25.4;
    final width = (paperSize == ReceiptPaperSize.mm58 ? 58 : 80) * mmToPoint;

    return PdfPageFormat(width, double.infinity, marginAll: 8);
  }

  pw.Widget _buildReceiptContent(TransactionRecord record) {
    final textStyle = pw.TextStyle(fontSize: 9);
    final headerStyle = pw.TextStyle(
      fontSize: 12,
      fontWeight: pw.FontWeight.bold,
    );

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Center(child: pw.Text('Flutter POS', style: headerStyle)),
        pw.SizedBox(height: 4),
        pw.Text('Transaction: ${record.id}', style: textStyle),
        pw.Text('Date: ${record.createdAt}', style: textStyle),
        pw.Text('Payment: ${record.paymentMethod}', style: textStyle),
        pw.SizedBox(height: 6),
        pw.Divider(),
        ...record.cart.items.map(
          (item) => pw.Padding(
            padding: const pw.EdgeInsets.symmetric(vertical: 2),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Text(
                    '${item.product.name} x${item.quantity}',
                    style: textStyle,
                  ),
                ),
                pw.Text(item.lineTotal.toStringAsFixed(2), style: textStyle),
              ],
            ),
          ),
        ),
        pw.Divider(),
        _amountRow('Subtotal', record.subtotal, textStyle),
        _amountRow('Tax', record.tax, textStyle),
        _amountRow(
          'Total',
          record.total,
          pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
        pw.SizedBox(height: 6),
        pw.Center(
          child: pw.Text('Thank you for your purchase', style: textStyle),
        ),
      ],
    );
  }

  pw.Widget _amountRow(String label, double amount, pw.TextStyle style) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: style),
        pw.Text(amount.toStringAsFixed(2), style: style),
      ],
    );
  }
}
