import 'package:uuid/uuid.dart';

/// Represents a single product/service line item on an invoice.
class InvoiceItem {
  final String id;
  String name;
  double quantity;
  double unitPrice;
  double discountPercent; // Optional discount, stored as a percentage (0-100)

  InvoiceItem({
    String? id,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    this.discountPercent = 0,
  }) : id = id ?? const Uuid().v4();

  /// Line total after applying the discount, before tax.
  double get lineTotal {
    final gross = quantity * unitPrice;
    final discountAmount = gross * (discountPercent / 100);
    return gross - discountAmount;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'discountPercent': discountPercent,
    };
  }

  factory InvoiceItem.fromJson(Map<String, dynamic> json) {
    return InvoiceItem(
      id: json['id'] as String,
      name: json['name'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unitPrice: (json['unitPrice'] as num).toDouble(),
      discountPercent: (json['discountPercent'] as num?)?.toDouble() ?? 0,
    );
  }

  InvoiceItem copyWith({
    String? name,
    double? quantity,
    double? unitPrice,
    double? discountPercent,
  }) {
    return InvoiceItem(
      id: id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
      discountPercent: discountPercent ?? this.discountPercent,
    );
  }
}
