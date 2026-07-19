import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../models/business_info.dart';
import '../models/customer.dart';
import '../models/invoice.dart';
import '../models/invoice_item.dart';
import '../services/invoice_service.dart';
import '../services/settings_service.dart';
import '../utils/constants.dart';
import '../utils/currency_formatter.dart';
import '../utils/validators.dart';
import '../widgets/invoice_item_form_row.dart';

/// Handles BOTH creating a new invoice and editing an existing one.
/// Pass [existingInvoice] to edit; leave null to create.
class InvoiceFormScreen extends StatefulWidget {
  final Invoice? existingInvoice;
  const InvoiceFormScreen({super.key, this.existingInvoice});

  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _invoiceService = InvoiceService.instance;
  final _settingsService = SettingsService.instance;

  late TextEditingController _companyNameCtrl;
  late TextEditingController _companyAddressCtrl;
  late TextEditingController _companyEmailCtrl;
  late TextEditingController _companyPhoneCtrl;

  late TextEditingController _customerNameCtrl;
  late TextEditingController _customerAddressCtrl;
  late TextEditingController _customerEmailCtrl;
  late TextEditingController _customerPhoneCtrl;

  late TextEditingController _taxCtrl;
  late TextEditingController _notesCtrl;

  late DateTime _invoiceDate;
  late DateTime _dueDate;
  late List<InvoiceItem> _items;
  String _invoiceNumber = '';
  String _currencySymbol = '\$';
  AppSettings _settings = AppSettings();
  bool _loading = true;
  bool _saving = false;

  bool get _isEditing => widget.existingInvoice != null;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final settings = await _settingsService.loadSettings();
    final existing = widget.existingInvoice;

    _companyNameCtrl = TextEditingController(
        text: existing?.business.companyName ?? settings.business.companyName);
    _companyAddressCtrl = TextEditingController(
        text: existing?.business.address ?? settings.business.address);
    _companyEmailCtrl = TextEditingController(
        text: existing?.business.email ?? settings.business.email);
    _companyPhoneCtrl = TextEditingController(
        text: existing?.business.phone ?? settings.business.phone);

    _customerNameCtrl = TextEditingController(text: existing?.customer.name ?? '');
    _customerAddressCtrl =
        TextEditingController(text: existing?.customer.address ?? '');
    _customerEmailCtrl = TextEditingController(text: existing?.customer.email ?? '');
    _customerPhoneCtrl = TextEditingController(text: existing?.customer.phone ?? '');

    _taxCtrl = TextEditingController(
        text: (existing?.taxPercent ?? settings.defaultTaxPercent).toString());
    _notesCtrl = TextEditingController(text: existing?.notes ?? '');

    _invoiceDate = existing?.invoiceDate ?? DateTime.now();
    _dueDate = existing?.dueDate ?? DateTime.now().add(const Duration(days: 14));
    _items = existing?.items.map((i) => i.copyWith(name: i.name)).toList() ?? [];

    if (existing != null) {
      _invoiceNumber = existing.invoiceNumber;
    } else {
      _invoiceNumber = settings.nextInvoiceNumber;
    }

    setState(() {
      _settings = settings;
      _currencySymbol = settings.currencySymbol;
      _loading = false;
    });
  }

  @override
  void dispose() {
    _companyNameCtrl.dispose();
    _companyAddressCtrl.dispose();
    _companyEmailCtrl.dispose();
    _companyPhoneCtrl.dispose();
    _customerNameCtrl.dispose();
    _customerAddressCtrl.dispose();
    _customerEmailCtrl.dispose();
    _customerPhoneCtrl.dispose();
    _taxCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double get _subtotal => _items.fold(0.0, (sum, i) => sum + i.lineTotal);
  double get _taxPercent => double.tryParse(_taxCtrl.text) ?? 0;
  double get _taxAmount => _subtotal * (_taxPercent / 100);
  double get _grandTotal => _subtotal + _taxAmount;

  Future<void> _pickDate({required bool isInvoiceDate}) async {
    final initial = isInvoiceDate ? _invoiceDate : _dueDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        if (isInvoiceDate) {
          _invoiceDate = picked;
        } else {
          _dueDate = picked;
        }
      });
    }
  }

  void _addItem() {
    setState(() {
      _items.add(InvoiceItem(name: '', quantity: 1, unitPrice: 0));
    });
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fix the errors above')),
      );
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one product or service')),
      );
      return;
    }
    if (_items.any((i) => i.name.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All items need a name')),
      );
      return;
    }

    setState(() => _saving = true);

    final business = BusinessInfo(
      companyName: _companyNameCtrl.text.trim(),
      address: _companyAddressCtrl.text.trim(),
      email: _companyEmailCtrl.text.trim(),
      phone: _companyPhoneCtrl.text.trim(),
      logoBase64: _settings.business.logoBase64,
    );
    final customer = Customer(
      name: _customerNameCtrl.text.trim(),
      address: _customerAddressCtrl.text.trim(),
      email: _customerEmailCtrl.text.trim(),
      phone: _customerPhoneCtrl.text.trim(),
    );

    if (_isEditing) {
      final updated = widget.existingInvoice!.copyWith(
        invoiceDate: _invoiceDate,
        dueDate: _dueDate,
        business: business,
        customer: customer,
        items: _items,
        taxPercent: _taxPercent,
        notes: _notesCtrl.text.trim(),
      );
      await _invoiceService.updateInvoice(updated);
    } else {
      final newNumber =
          await _settingsService.generateNextInvoiceNumber(_settings);
      final invoice = Invoice(
        invoiceNumber: newNumber,
        invoiceDate: _invoiceDate,
        dueDate: _dueDate,
        business: business,
        customer: customer,
        items: _items,
        taxPercent: _taxPercent,
        notes: _notesCtrl.text.trim(),
      );
      await _invoiceService.createInvoice(invoice);
    }

    if (!mounted) return;
    setState(() => _saving = false);
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Invoice' : 'New Invoice'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            _sectionCard(
              title: 'Invoice Details',
              children: [
                _readOnlyField('Invoice Number', _invoiceNumber),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _dateField('Invoice Date', _invoiceDate,
                          () => _pickDate(isInvoiceDate: true)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _dateField('Due Date', _dueDate,
                          () => _pickDate(isInvoiceDate: false)),
                    ),
                  ],
                ),
              ],
            ),
            _sectionCard(
              title: 'Business Information',
              children: [
                _textField(_companyNameCtrl, 'Company Name',
                    validator: (v) => Validators.required(v, field: 'Company name')),
                _textField(_companyAddressCtrl, 'Address',
                    validator: (v) => Validators.required(v, field: 'Address')),
                _textField(_companyEmailCtrl, 'Email', validator: Validators.email),
                _textField(_companyPhoneCtrl, 'Phone Number',
                    validator: Validators.phone),
              ],
            ),
            _sectionCard(
              title: 'Customer Information',
              children: [
                _textField(_customerNameCtrl, 'Customer Name',
                    validator: (v) => Validators.required(v, field: 'Customer name')),
                _textField(_customerAddressCtrl, 'Address',
                    validator: (v) => Validators.required(v, field: 'Address')),
                _textField(_customerEmailCtrl, 'Email', validator: Validators.email),
                _textField(_customerPhoneCtrl, 'Phone Number',
                    validator: Validators.phone),
              ],
            ),
            _sectionCard(
              title: 'Products / Services',
              children: [
                ..._items.asMap().entries.map((entry) {
                  final index = entry.key;
                  return InvoiceItemFormRow(
                    key: ValueKey(entry.value.id),
                    item: entry.value,
                    currencySymbol: _currencySymbol,
                    onRemove: () => setState(() => _items.removeAt(index)),
                    onChanged: (updated) =>
                        setState(() => _items[index] = updated),
                  );
                }),
                OutlinedButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                ),
              ],
            ),
            _sectionCard(
              title: 'Tax & Notes',
              children: [
                TextFormField(
                  controller: _taxCtrl,
                  decoration: const InputDecoration(labelText: 'Tax Percentage (%)'),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => Validators.nonNegativeNumber(v, field: 'Tax'),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notesCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Notes / Payment Instructions',
                    alignLabelWithHint: true,
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            _sectionCard(
              title: 'Summary',
              children: [
                _summaryRow('Subtotal', _subtotal),
                _summaryRow('Tax (${_taxPercent.toStringAsFixed(1)}%)', _taxAmount),
                const Divider(),
                _summaryRow('Grand Total', _grandTotal, bold: true),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16)),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(_isEditing ? 'Update Invoice' : 'Save Invoice'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({required String title, required List<Widget> children}) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _textField(TextEditingController controller, String label,
      {String? Function(String?)? validator}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(labelText: label),
        validator: validator,
      ),
    );
  }

  Widget _readOnlyField(String label, String value) {
    return TextFormField(
      initialValue: value,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.lock_outline, size: 18),
      ),
    );
  }

  Widget _dateField(String label, DateTime date, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(DateFormatter.short(date)),
      ),
    );
  }

  Widget _summaryRow(String label, double value, {bool bold = false}) {
    final style = TextStyle(
        fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        fontSize: bold ? 16 : 14);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text(CurrencyFormatter.format(value, _currencySymbol), style: style),
        ],
      ),
    );
  }
}
