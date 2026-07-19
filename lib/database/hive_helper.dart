import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/invoice.dart';

/// Local persistence layer backed by Hive.
///
/// Hive works identically on Web (IndexedDB), Android, iOS, and Desktop,
/// unlike sqflite which requires extra FFI/web shims. Each invoice is
/// stored as a single JSON string keyed by its id, inside the
/// 'invoices' box. Storing JSON strings (rather than raw nested maps)
/// avoids the Map<dynamic,dynamic> casting issues Hive can produce when
/// reading nested structures back on web.
class HiveHelper {
  HiveHelper._internal();
  static final HiveHelper instance = HiveHelper._internal();

  static const String invoicesBoxName = 'invoices';
  Box<String>? _box;

  /// Must be called once (after Hive.initFlutter()) before any other
  /// method is used. Safe to call multiple times.
  Future<void> init() async {
    if (_box != null && _box!.isOpen) return;
    _box = await Hive.openBox<String>(invoicesBoxName);
  }

  Box<String> get _requireBox {
    final box = _box;
    if (box == null || !box.isOpen) {
      throw StateError('HiveHelper.init() must be called before use.');
    }
    return box;
  }

  Future<void> insertInvoice(Invoice invoice) async {
    await _requireBox.put(invoice.id, jsonEncode(invoice.toJson()));
  }

  Future<void> updateInvoice(Invoice invoice) async {
    await _requireBox.put(invoice.id, jsonEncode(invoice.toJson()));
  }

  Future<void> deleteInvoice(String id) async {
    await _requireBox.delete(id);
  }

  Future<List<Invoice>> getAllInvoices() async {
    final box = _requireBox;
    final invoices = box.values
        .map((raw) => Invoice.fromJson(jsonDecode(raw) as Map<String, dynamic>))
        .toList();
    invoices.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return invoices;
  }

  Future<Invoice?> getInvoiceById(String id) async {
    final raw = _requireBox.get(id);
    if (raw == null) return null;
    return Invoice.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }
}
