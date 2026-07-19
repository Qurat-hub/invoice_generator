import 'package:intl/intl.dart';

class CurrencyFormatter {
  static String format(double value, String symbol) {
    final formatter = NumberFormat('#,##0.00');
    return '$symbol${formatter.format(value)}';
  }
}

class DateFormatter {
  static String short(DateTime date) => DateFormat('dd MMM yyyy').format(date);
  static String withTime(DateTime date) =>
      DateFormat('dd MMM yyyy, hh:mm a').format(date);
}
