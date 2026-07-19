import 'package:flutter/material.dart';
import '../models/invoice_item.dart';
import '../utils/currency_formatter.dart';
import '../utils/validators.dart';

/// Editable row for a single invoice line item, used inside the
/// invoice creation/edit form.
class InvoiceItemFormRow extends StatefulWidget {
  final InvoiceItem item;
  final String currencySymbol;
  final VoidCallback onRemove;
  final ValueChanged<InvoiceItem> onChanged;

  const InvoiceItemFormRow({
    super.key,
    required this.item,
    required this.currencySymbol,
    required this.onRemove,
    required this.onChanged,
  });

  @override
  State<InvoiceItemFormRow> createState() => _InvoiceItemFormRowState();
}

class _InvoiceItemFormRowState extends State<InvoiceItemFormRow> {
  late TextEditingController _nameCtrl;
  late TextEditingController _qtyCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _discountCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.item.name);
    _qtyCtrl = TextEditingController(
        text: widget.item.quantity == widget.item.quantity.roundToDouble()
            ? widget.item.quantity.toInt().toString()
            : widget.item.quantity.toString());
    _priceCtrl = TextEditingController(text: widget.item.unitPrice.toString());
    _discountCtrl =
        TextEditingController(text: widget.item.discountPercent.toString());
  }

  void _notify() {
    final updated = widget.item.copyWith(
      name: _nameCtrl.text,
      quantity: double.tryParse(_qtyCtrl.text) ?? 0,
      unitPrice: double.tryParse(_priceCtrl.text) ?? 0,
      discountPercent: double.tryParse(_discountCtrl.text) ?? 0,
    );
    widget.onChanged(updated);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _qtyCtrl.dispose();
    _priceCtrl.dispose();
    _discountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Product / Service Name',
                    isDense: true,
                  ),
                  validator: (v) => Validators.required(v, field: 'Item name'),
                  onChanged: (_) => _notify(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: widget.onRemove,
                tooltip: 'Remove item',
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _qtyCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Qty', isDense: true),
                  keyboardType: TextInputType.number,
                  validator: (v) => Validators.positiveNumber(v, field: 'Quantity'),
                  onChanged: (_) => _notify(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _priceCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Unit Price', isDense: true),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => Validators.positiveNumber(v, field: 'Price'),
                  onChanged: (_) => _notify(),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextFormField(
                  controller: _discountCtrl,
                  decoration: const InputDecoration(
                      labelText: 'Discount %', isDense: true),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (v) => Validators.nonNegativeNumber(v, field: 'Discount'),
                  onChanged: (_) => _notify(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Line total: ${CurrencyFormatter.format(widget.item.lineTotal, widget.currencySymbol)}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
