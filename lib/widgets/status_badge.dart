import 'package:flutter/material.dart';
import '../models/invoice.dart';
import '../utils/constants.dart';

class StatusBadge extends StatelessWidget {
  final InvoiceStatus status;
  const StatusBadge({super.key, required this.status});

  Color get _color {
    switch (status) {
      case InvoiceStatus.paid:
        return AppColors.success;
      case InvoiceStatus.unpaid:
        return AppColors.warning;
      case InvoiceStatus.overdue:
        return AppColors.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: _color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
