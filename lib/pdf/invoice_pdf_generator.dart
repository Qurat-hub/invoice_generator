import 'dart:convert';
import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/invoice.dart';
import '../utils/currency_formatter.dart';

/// Builds a professional, single-page invoice PDF and returns it as raw
/// bytes (Uint8List). Deliberately has no dependency on dart:io or
/// path_provider — that's what makes it work identically on Web,
/// Android, iOS, and Desktop. Callers (the `printing` package) take the
/// bytes and handle platform-appropriate printing/sharing/downloading.
class InvoicePdfGenerator {
  static Future<Uint8List> generateBytes(
      Invoice invoice, String currencySymbol) async {
    final doc = pw.Document();
    final primary = PdfColor.fromHex('#3457D5');
    final grey = PdfColor.fromHex('#6B7280');
    final light = PdfColor.fromHex('#F4F6FB');

    pw.ImageProvider? logoImage;
    if (invoice.business.logoBase64.isNotEmpty) {
      try {
        final bytes = base64Decode(invoice.business.logoBase64);
        logoImage = pw.MemoryImage(bytes);
      } catch (_) {
        logoImage = null;
      }
    }

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header: logo + business info | invoice title + number
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      if (logoImage != null)
                        pw.Container(
                          height: 50,
                          margin: const pw.EdgeInsets.only(bottom: 8),
                          child: pw.Image(logoImage),
                        ),
                      pw.Text(
                        invoice.business.companyName.isEmpty
                            ? 'Your Company'
                            : invoice.business.companyName,
                        style: pw.TextStyle(
                            fontSize: 18, fontWeight: pw.FontWeight.bold),
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text(invoice.business.address,
                          style: pw.TextStyle(fontSize: 9, color: grey)),
                      pw.Text(invoice.business.email,
                          style: pw.TextStyle(fontSize: 9, color: grey)),
                      pw.Text(invoice.business.phone,
                          style: pw.TextStyle(fontSize: 9, color: grey)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('INVOICE',
                          style: pw.TextStyle(
                              fontSize: 24,
                              fontWeight: pw.FontWeight.bold,
                              color: primary)),
                      pw.SizedBox(height: 6),
                      pw.Text('# ${invoice.invoiceNumber}',
                          style: pw.TextStyle(fontSize: 11)),
                      pw.Text(
                          'Date: ${DateFormatter.short(invoice.invoiceDate)}',
                          style: pw.TextStyle(fontSize: 9, color: grey)),
                      pw.Text('Due: ${DateFormatter.short(invoice.dueDate)}',
                          style: pw.TextStyle(fontSize: 9, color: grey)),
                      pw.SizedBox(height: 6),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: pw.BoxDecoration(
                          color: light,
                          borderRadius: pw.BorderRadius.circular(4),
                        ),
                        child: pw.Text(
                          invoice.status.label.toUpperCase(),
                          style: pw.TextStyle(
                              fontSize: 9,
                              color: primary,
                              fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 24),
              pw.Divider(color: grey),
              pw.SizedBox(height: 12),

              // Bill To
              pw.Text('BILL TO',
                  style: pw.TextStyle(
                      fontSize: 10,
                      color: grey,
                      fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 4),
              pw.Text(invoice.customer.name,
                  style: pw.TextStyle(
                      fontSize: 12, fontWeight: pw.FontWeight.bold)),
              pw.Text(invoice.customer.address,
                  style: pw.TextStyle(fontSize: 9, color: grey)),
              pw.Text(invoice.customer.email,
                  style: pw.TextStyle(fontSize: 9, color: grey)),
              pw.Text(invoice.customer.phone,
                  style: pw.TextStyle(fontSize: 9, color: grey)),
              pw.SizedBox(height: 20),

              // Items table
              pw.Table(
                border: pw.TableBorder(
                  horizontalInside: pw.BorderSide(color: light, width: 1),
                ),
                columnWidths: const {
                  0: pw.FlexColumnWidth(3.2),
                  1: pw.FlexColumnWidth(1),
                  2: pw.FlexColumnWidth(1.3),
                  3: pw.FlexColumnWidth(1),
                  4: pw.FlexColumnWidth(1.3),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: primary),
                    children: [
                      _headerCell('Item'),
                      _headerCell('Qty'),
                      _headerCell('Unit Price'),
                      _headerCell('Disc %'),
                      _headerCell('Total'),
                    ],
                  ),
                  ...invoice.items.map((item) => pw.TableRow(
                        children: [
                          _bodyCell(item.name),
                          _bodyCell(item.quantity.toStringAsFixed(
                              item.quantity.truncateToDouble() ==
                                      item.quantity
                                  ? 0
                                  : 2)),
                          _bodyCell(CurrencyFormatter.format(
                              item.unitPrice, currencySymbol)),
                          _bodyCell('${item.discountPercent.toStringAsFixed(0)}%'),
                          _bodyCell(CurrencyFormatter.format(
                              item.lineTotal, currencySymbol)),
                        ],
                      )),
                ],
              ),
              pw.SizedBox(height: 16),

              // Totals
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.SizedBox(
                    width: 220,
                    child: pw.Column(
                      children: [
                        _totalRow('Subtotal',
                            CurrencyFormatter.format(invoice.subtotal, currencySymbol)),
                        _totalRow(
                            'Tax (${invoice.taxPercent.toStringAsFixed(1)}%)',
                            CurrencyFormatter.format(invoice.taxAmount, currencySymbol)),
                        pw.Divider(color: grey),
                        _totalRow(
                          'Grand Total',
                          CurrencyFormatter.format(invoice.grandTotal, currencySymbol),
                          bold: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              if (invoice.notes.trim().isNotEmpty) ...[
                pw.SizedBox(height: 24),
                pw.Text('NOTES / PAYMENT INSTRUCTIONS',
                    style: pw.TextStyle(
                        fontSize: 10,
                        color: grey,
                        fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text(invoice.notes, style: const pw.TextStyle(fontSize: 9)),
              ],

              pw.Spacer(),
              pw.Divider(color: light),
              pw.Center(
                child: pw.Text('Thank you for your business!',
                    style: pw.TextStyle(fontSize: 9, color: grey)),
              ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _headerCell(String text) => pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(text,
            style: pw.TextStyle(
                fontSize: 9,
                color: PdfColors.white,
                fontWeight: pw.FontWeight.bold)),
      );

  static pw.Widget _bodyCell(String text) => pw.Padding(
        padding: const pw.EdgeInsets.all(8),
        child: pw.Text(text, style: const pw.TextStyle(fontSize: 9)),
      );

  static pw.Widget _totalRow(String label, String value, {bool bold = false}) {
    final style = pw.TextStyle(
        fontSize: bold ? 12 : 10,
        fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal);
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 3),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(value, style: style),
        ],
      ),
    );
  }
}
