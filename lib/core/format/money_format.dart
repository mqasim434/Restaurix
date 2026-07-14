import 'package:intl/intl.dart';

import '../../domain/models/app_currency.dart';

typedef MoneyFormatter = String Function(double amount);

abstract final class MoneyFormat {
  static NumberFormat numberFormat(
    String currencyCode, {
    int? decimalDigits,
  }) {
    final option = AppCurrency.optionFor(currencyCode);
    return NumberFormat.currency(
      locale: option.locale,
      name: option.code,
      symbol: option.symbol,
      decimalDigits: decimalDigits ?? option.decimalDigits,
    );
  }

  static String format(
    double amount,
    String currencyCode, {
    int? decimalDigits,
  }) {
    return numberFormat(currencyCode, decimalDigits: decimalDigits).format(amount);
  }

  static MoneyFormatter formatter(String currencyCode, {int? decimalDigits}) {
    final format = numberFormat(currencyCode, decimalDigits: decimalDigits);
    return (amount) => format.format(amount);
  }

  static String formatCompact(double amount, String currencyCode) {
    final option = AppCurrency.optionFor(currencyCode);
    try {
      return NumberFormat.compactCurrency(
        locale: option.locale,
        name: option.code,
        symbol: option.symbol,
      ).format(amount);
    } catch (_) {
      return format(amount, currencyCode);
    }
  }
}
