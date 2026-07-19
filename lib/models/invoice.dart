import 'package:uuid/uuid.dart';
import 'business_info.dart';
import 'customer.dart';
import 'invoice_item.dart';

enum InvoiceStatus { paid, unpaid, overdue }

extension InvoiceStatusX on InvoiceStatus {
  String get label {
    switch (this) {
      case InvoiceStatus.paid:
        return 'Paid';
      case InvoiceStatus.unpaid:
        return 'Unpaid';
      case InvoiceStatus.overdue:
        return 'Overdue';
    }
  }

  static InvoiceStatus fromString(String value) {
    return InvoiceStatus.values.firstWhere(
      (e) => e.name == value,
      orElse: () => InvoiceStatus.unpaid,
    );
  }
}

/// Core Invoice model. Holds business + customer snapshots, line items,
/// tax rate, notes, and status. All monetary totals are derived from
/// [items] and [taxPercent] so they never fall out of sync.
///
/// Serializes to a single nested JSON map (stored as a JSON string in
/// Hive) rather than a flat relational row, since there's no longer a
/// SQL schema to fit into.
class Invoice {
  final String id;
  final String invoiceNumber;
  DateTime invoiceDate;
  DateTime dueDate;
  BusinessInfo business;
  Customer customer;
  List<InvoiceItem> items;
  double taxPercent;
  String notes;
  InvoiceStatus status;
  final DateTime createdAt;

  Invoice({
    String? id,
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.dueDate,
    required this.business,
    required this.customer,
    List<InvoiceItem>? items,
    this.taxPercent = 0,
    this.notes = '',
    this.status = InvoiceStatus.unpaid,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        items = items ?? [],
        createdAt = createdAt ?? DateTime.now();

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.lineTotal);

  double get taxAmount => subtotal * (taxPercent / 100);

  double get grandTotal => subtotal + taxAmount;

  bool get isOverdueByDate =>
      status != InvoiceStatus.paid && dueDate.isBefore(DateTime.now());

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoiceNumber': invoiceNumber,
      'invoiceDate': invoiceDate.toIso8601String(),
      'dueDate': dueDate.toIso8601String(),
      'taxPercent': taxPercent,
      'notes': notes,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'business': business.toJson(),
      'customer': customer.toJson(),
      'items': items.map((i) => i.toJson()).toList(),
    };
  }

  factory Invoice.fromJson(Map<String, dynamic> json) {
    final itemsJson = (json['items'] as List<dynamic>? ?? []);
    return Invoice(
      id: json['id'] as String,
      invoiceNumber: json['invoiceNumber'] as String,
      invoiceDate: DateTime.parse(json['invoiceDate'] as String),
      dueDate: DateTime.parse(json['dueDate'] as String),
      business: BusinessInfo.fromJson(
          Map<String, dynamic>.from(json['business'] as Map)),
      customer: Customer.fromJson(
          Map<String, dynamic>.from(json['customer'] as Map)),
      items: itemsJson
          .map((e) => InvoiceItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList(),
      taxPercent: (json['taxPercent'] as num?)?.toDouble() ?? 0,
      notes: json['notes'] as String? ?? '',
      status: InvoiceStatusX.fromString(json['status'] as String? ?? 'unpaid'),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Invoice copyWith({
    String? invoiceNumber,
    DateTime? invoiceDate,
    DateTime? dueDate,
    BusinessInfo? business,
    Customer? customer,
    List<InvoiceItem>? items,
    double? taxPercent,
    String? notes,
    InvoiceStatus? status,
    bool newId = false,
  }) {
    return Invoice(
      id: newId ? null : id,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      dueDate: dueDate ?? this.dueDate,
      business: business ?? this.business,
      customer: customer ?? this.customer,
      items: items ??
          this.items.map((i) => i.copyWith(name: i.name)).toList(),
      taxPercent: taxPercent ?? this.taxPercent,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      createdAt: newId ? DateTime.now() : createdAt,
    );
  }
}
