import '../database/hive_helper.dart';
import '../models/invoice.dart';

/// Business-logic layer sitting on top of [HiveHelper].
/// Screens should talk to this, never to the database directly.
class InvoiceService {
  InvoiceService._internal();
  static final InvoiceService instance = InvoiceService._internal();

  final HiveHelper _db = HiveHelper.instance;

  Future<List<Invoice>> getAllInvoices() => _db.getAllInvoices();

  Future<Invoice?> getInvoiceById(String id) => _db.getInvoiceById(id);

  Future<void> createInvoice(Invoice invoice) => _db.insertInvoice(invoice);

  Future<void> updateInvoice(Invoice invoice) => _db.updateInvoice(invoice);

  Future<void> deleteInvoice(String id) => _db.deleteInvoice(id);

  Future<void> updateStatus(Invoice invoice, InvoiceStatus status) async {
    invoice.status = status;
    await _db.updateInvoice(invoice);
  }

  /// Creates a copy of an existing invoice with a new id, new invoice
  /// number, today's date, and status reset to unpaid.
  Future<Invoice> duplicateInvoice(Invoice source, String newNumber) async {
    final copy = source.copyWith(
      newId: true,
      invoiceNumber: newNumber,
      invoiceDate: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(days: 14)),
      status: InvoiceStatus.unpaid,
      items: source.items
          .map((i) => i.copyWith(name: i.name))
          .toList(growable: true),
    );
    await _db.insertInvoice(copy);
    return copy;
  }

  Future<List<Invoice>> searchInvoices(String query) async {
    final all = await _db.getAllInvoices();
    if (query.trim().isEmpty) return all;
    final lower = query.toLowerCase();
    return all
        .where((inv) =>
            inv.invoiceNumber.toLowerCase().contains(lower) ||
            inv.customer.name.toLowerCase().contains(lower))
        .toList();
  }

  /// Recomputes overdue status for invoices whose due date has passed
  /// and are still unpaid. Call on app start / dashboard load.
  Future<List<Invoice>> refreshOverdueStatuses(List<Invoice> invoices) async {
    for (final inv in invoices) {
      if (inv.status == InvoiceStatus.unpaid &&
          inv.dueDate.isBefore(DateTime.now())) {
        inv.status = InvoiceStatus.overdue;
        await _db.updateInvoice(inv);
      }
    }
    return invoices;
  }

  // ---------------- Dashboard aggregates ----------------

  Future<DashboardStats> getDashboardStats() async {
    final invoices = await getAllInvoices();
    final paid = invoices.where((i) => i.status == InvoiceStatus.paid);
    final unpaid = invoices.where((i) => i.status == InvoiceStatus.unpaid);
    final overdue = invoices.where((i) => i.status == InvoiceStatus.overdue);
    final revenue = paid.fold(0.0, (sum, i) => sum + i.grandTotal);

    return DashboardStats(
      totalInvoices: invoices.length,
      paidCount: paid.length,
      unpaidCount: unpaid.length,
      overdueCount: overdue.length,
      totalRevenue: revenue,
      recentInvoices: invoices.take(5).toList(),
    );
  }
}

class DashboardStats {
  final int totalInvoices;
  final int paidCount;
  final int unpaidCount;
  final int overdueCount;
  final double totalRevenue;
  final List<Invoice> recentInvoices;

  DashboardStats({
    required this.totalInvoices,
    required this.paidCount,
    required this.unpaidCount,
    required this.overdueCount,
    required this.totalRevenue,
    required this.recentInvoices,
  });
}
