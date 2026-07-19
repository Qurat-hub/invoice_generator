import 'package:flutter/material.dart';
import '../models/invoice.dart';
import '../utils/constants.dart';
import '../utils/currency_formatter.dart';
import 'status_badge.dart';

class InvoiceCard extends StatelessWidget {
  final Invoice invoice;
  final String currencySymbol;
  final VoidCallback onTap;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;

  const InvoiceCard({
    super.key,
    required this.invoice,
    required this.currencySymbol,
    required this.onTap,
    required this.onDelete,
    required this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          invoice.invoiceNumber,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(width: 8),
                        StatusBadge(status: invoice.status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      invoice.customer.name.isEmpty
                          ? 'No customer name'
                          : invoice.customer.name,
                      style: TextStyle(color: Colors.grey.shade700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Due ${DateFormatter.short(invoice.dueDate)}',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyFormatter.format(invoice.grandTotal, currencySymbol),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert, size: 20),
                    onSelected: (value) {
                      if (value == 'delete') onDelete();
                      if (value == 'duplicate') onDuplicate();
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'duplicate',
                        child: Row(children: [
                          Icon(Icons.copy, size: 18),
                          SizedBox(width: 8),
                          Text('Duplicate'),
                        ]),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Row(children: [
                          Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ]),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
