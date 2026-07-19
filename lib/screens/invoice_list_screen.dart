import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../models/invoice.dart';
import '../services/invoice_service.dart';
import '../services/settings_service.dart';
import '../utils/constants.dart';
import '../widgets/invoice_card.dart';
import '../widgets/empty_state.dart';
import 'invoice_detail_screen.dart';
import 'invoice_form_screen.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  final _invoiceService = InvoiceService.instance;
  final _settingsService = SettingsService.instance;

  List<Invoice> _invoices = [];
  AppSettings _settings = AppSettings();
  bool _loading = true;
  String _query = '';
  InvoiceStatus? _filterStatus;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final settings = await _settingsService.loadSettings();
    final all = await _invoiceService.searchInvoices(_query);
    await _invoiceService.refreshOverdueStatuses(all);
    final filtered = _filterStatus == null
        ? all
        : all.where((i) => i.status == _filterStatus).toList();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _invoices = filtered;
      _loading = false;
    });
  }

  Future<void> _confirmDelete(Invoice invoice) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Invoice?'),
        content: Text(
            'Are you sure you want to delete ${invoice.invoiceNumber}? This action cannot be undone.'),
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
    if (confirmed == true) {
      await _invoiceService.deleteInvoice(invoice.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${invoice.invoiceNumber} deleted')),
        );
      }
      _load();
    }
  }

  Future<void> _duplicate(Invoice invoice) async {
    final settings = await _settingsService.loadSettings();
    final newNumber = await _settingsService.generateNextInvoiceNumber(settings);
    await _invoiceService.duplicateInvoice(invoice, newNumber);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Duplicated as $newNumber')),
      );
    }
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: const Text('All Invoices')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, 0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search by invoice # or customer name',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Theme.of(context).cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) {
                _query = v;
                _load();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _filterChip('All', null),
                  _filterChip('Paid', InvoiceStatus.paid),
                  _filterChip('Unpaid', InvoiceStatus.unpaid),
                  _filterChip('Overdue', InvoiceStatus.overdue),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _invoices.isEmpty
                    ? EmptyState(
                        title: 'No invoices found',
                        message: _query.isEmpty
                            ? 'Create your first invoice to get started.'
                            : 'Try a different search term.',
                        actionLabel: _query.isEmpty ? 'Create Invoice' : null,
                        onAction: _query.isEmpty
                            ? () async {
                                await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const InvoiceFormScreen()));
                                _load();
                              }
                            : null,
                      )
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView.builder(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          itemCount: _invoices.length,
                          itemBuilder: (context, index) {
                            final inv = _invoices[index];
                            return InvoiceCard(
                              invoice: inv,
                              currencySymbol: _settings.currencySymbol,
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        InvoiceDetailScreen(invoiceId: inv.id),
                                  ),
                                );
                                _load();
                              },
                              onDelete: () => _confirmDelete(inv),
                              onDuplicate: () => _duplicate(inv),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(context,
              MaterialPageRoute(builder: (_) => const InvoiceFormScreen()));
          _load();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _filterChip(String label, InvoiceStatus? status) {
    final selected = _filterStatus == status;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) {
          setState(() => _filterStatus = status);
          _load();
        },
      ),
    );
  }
}
