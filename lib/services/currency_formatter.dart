import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _ugxFormat = NumberFormat.currency(
    locale: 'en_UG',
    symbol: 'UGX ',
    decimalDigits: 0,
  );

  static final NumberFormat _compactFormat = NumberFormat.compact(
    locale: 'en_UG',
  );

  // Format amount to UGX string
  static String formatUGX(double amount) {
    return _ugxFormat.format(amount);
  }

  // Format to compact (e.g., 1.5M)
  static String formatCompact(double amount) {
    return 'UGX ${_compactFormat.format(amount)}';
  }

  // Format with custom symbol position
  static String format(double amount, {bool symbolAfter = false}) {
    String formatted = amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
    
    return symbolAfter ? '$formatted UGX' : 'UGX $formatted';
  }

  // Parse UGX string back to double
  static double parse(String ugxString) {
    String cleaned = ugxString
        .replaceAll('UGX', '')
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .trim();
    return double.tryParse(cleaned) ?? 0.0;
  }

  // Format for input field (no symbol)
  static String formatForInput(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }
}
