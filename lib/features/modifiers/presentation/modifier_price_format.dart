import 'package:intl/intl.dart';

/// Formats a modifier price delta, including negative values (e.g. "−$0.50").
String formatModifierPriceDelta(double priceDelta) {
  final formatter = NumberFormat.simpleCurrency();
  if (priceDelta == 0) return formatter.format(0);
  if (priceDelta > 0) return '+${formatter.format(priceDelta)}';
  return formatter.format(priceDelta);
}
