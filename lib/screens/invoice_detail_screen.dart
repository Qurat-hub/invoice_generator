import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../models/app_settings.dart';
import '../models/invoice.dart';
import '../pdf/invoice_pdf_generator.dart';
import '../services/invoice_service.dart';
import '../services/settings_service.dart';
import '../utils/constants.dart';
import '../utils/currency_formatter.dart';
import '../widgets/status_badge.dart';
import 'invoice_form_screen.dart';

class InvoiceDetailScreen extends StatefulWidget {
  final String invoiceId;
  const InvoiceDetailScreen({super.key, required this.invoiceId});

  @override
  State<InvoiceDetailScreen> createState() => _InvoiceDetailScreenState();
}

class _InvoiceDetailScreenState extends State<InvoiceDetailScreen> {
  final _invoiceService = InvoiceService.instance;
  final _settingsService = SettingsService.instance;

  Invoice? _invoice;
  AppSettings _settings = AppSettings();
  bool _loading = true;
  bool _exporting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final invoice = await _invoiceService.getInvoiceById(widget.invoiceId);
    final settings = await _settingsService.loadSettings();
    if (!mounted) return;
    setState(() {
      _invoice = invoice;
      _settings = settings;
      _loading = false;
    });
  }

  Future<void> _changeStatus(InvoiceStatus status) async {
    if (_invoice == null) return;
    await _invoiceService.updateStatus(_invoice!, status);
    _load();
  }

  /// Uses the `printing` package for everything PDF-related. Unlike
  /// dart:io File + share_plus, `printing` has first-class Web support:
  /// - `Printing.sharePdf` triggers a browser download on Web and the
  ///   native OS share sheet (WhatsApp, Email, etc.) on Android/iOS.
  /// - `Printing.layoutPdf` opens the browser's print dialog on Web and
  ///   the native print flow on mobile/desktop.
  /// No file system access is required on any platform.
  Future<void> _exportPdf({required String action}) async {
    if (_invoice == null) return;
    setState(() => _exporting = true);
    try {
      final bytes =
          await InvoicePdfGenerator.generateBytes(_invoice!, _settings.currencySymbol);
      final fileName = '${_invoice!.invoiceNumber}.pdf';

      if (action == 'print') {
        await Printing.layoutPdf(onLayout: (format) async => bytes);
      } else {
        // Covers both "share" and "download": on Web this downloads the
        // file, on mobile it opens the native share sheet.
        await Printing.sharePdf(bytes: bytes, filename: fileName);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Export failed: $e')));
      }
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Invoice?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && _invoice != null) {
      await _invoiceService.deleteInvoice(_invoice!.id);
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_invoice == null) {
      return const Scaffold(body: Center(child: Text('Invoice not found')));
    }
    final invoice = _invoice!;
    final symbol = _settings.currencySymbol;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(invoice.invoiceNumber),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => InvoiceFormScreen(existingInvoice: invoice)),
              );
              if (result == true) _load();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(invoice.invoiceNumber,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    StatusBadge(status: invoice.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Invoice Date: ${DateFormatter.short(invoice.invoiceDate)}'),
                Text('Due Date: ${DateFormatter.short(invoice.dueDate)}'),
                const SizedBox(height: 12),
                DropdownButtonFormField<InvoiceStatus>(
                  value: invoice.status,
                  decoration: const InputDecoration(labelText: 'Update Status'),
                  items: InvoiceStatus.values
                      .map((s) => DropdownMenuItem(value: s, child: Text(s.label)))
                      .toList(),
                  onChanged: (s) {
                    if (s != null) _changeStatus(s);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _infoCard('From', invoice.business.companyName, invoice.business.address,
              invoice.business.email, invoice.business.phone),
          const SizedBox(height: AppSpacing.md),
          _infoCard('Bill To', invoice.customer.name, invoice.customer.address,
              invoice.customer.email, invoice.customer.phone),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Items',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 8),
                ...invoice.items.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(item.name),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text('x${item.quantity.toStringAsFixed(
                                item.quantity.truncateToDouble() == item.quantity ? 0 : 2)}'),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              CurrencyFormatter.format(item.lineTotal, symbol),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    )),
                const Divider(),
                _summaryRow('Subtotal', invoice.subtotal, symbol),
                _summaryRow(
                    'Tax (${invoice.taxPercent.toStringAsFixed(1)}%)', invoice.taxAmount, symbol),
                _summaryRow('Grand Total', invoice.grandTotal, symbol, bold: true),
              ],
            ),
          ),
          if (invoice.notes.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Notes',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 6),
                  Text(invoice.notes),
                ],
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _exporting ? null : () => _exportPdf(action: 'download'),
                  icon: const Icon(Icons.download),
                  label: const Text('Download PDF'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _exporting ? null : () => _exportPdf(action: 'print'),
                  icon: const Icon(Icons.print_outlined),
                  label: const Text('Print'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _exporting ? null : () => _exportPdf(action: 'share'),
              icon: _exporting
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.share),
              label: const Text('Share Invoice'),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(
      String title, String name, String address, String email, String phone) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          const SizedBox(height: 4),
          Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          if (address.isNotEmpty) Text(address),
          if (email.isNotEmpty) Text(email),
          if (phone.isNotEmpty) Text(phone),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, double value, String symbol, {bool bold = false}) {
    final style = TextStyle(
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        fontSize: bold ? 16 : 14);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(CurrencyFormatter.format(value, symbol), style: style),
        ],
      ),
    );
  }
}
