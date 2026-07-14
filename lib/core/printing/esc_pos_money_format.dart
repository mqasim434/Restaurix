import 'package:intl/intl.dart';

import '../../domain/models/app_currency.dart';

/// ASCII-only currency formatting for thermal ESC/POS printers.
abstract final class EscPosMoneyFormat {
  static final NumberFormat _amount = NumberFormat('#,##0.00', 'en_US');

  static String format(double amount, String currencyCode) {
    final code = AppCurrency.normalizeCode(currencyCode);
    return '${_prefix(code)}${_amount.format(amount)}';
  }

  static String formatDiscount(double amount, String currencyCode) {
    return '-${format(amount, currencyCode)}';
  }

  static String _prefix(String code) {
    return switch (code) {
      'USD' => r'$',
      'PKR' => 'Rs ',
      'INR' => 'Rs ',
      'EUR' => 'EUR ',
      'GBP' => 'GBP ',
      'CAD' => 'CAD ',
      'AUD' => 'AUD ',
      'AED' => 'AED ',
      'SAR' => 'SAR ',
      'QAR' => 'QAR ',
      _ => '$code ',
    };
  }
}
