import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/format/money_format.dart';
import '../../../domain/models/app_currency.dart';
import 'settings_providers.dart';

final currencyCodeProvider = Provider<String>((ref) {
  final settings = ref.watch(appSettingsProvider).valueOrNull;
  return AppCurrency.normalizeCode(settings?.currencyCode);
});

final formatMoneyProvider = Provider<MoneyFormatter>((ref) {
  final code = ref.watch(currencyCodeProvider);
  return MoneyFormat.formatter(code);
});

final moneyNumberFormatProvider = Provider<NumberFormat>((ref) {
  return MoneyFormat.numberFormat(ref.watch(currencyCodeProvider));
});

final compactMoneyFormatProvider = Provider<MoneyFormatter>((ref) {
  final code = ref.watch(currencyCodeProvider);
  return (amount) => MoneyFormat.formatCompact(amount, code);
});

final dashboardMoneyFormatProvider = Provider<NumberFormat>((ref) {
  return MoneyFormat.numberFormat(
    ref.watch(currencyCodeProvider),
    decimalDigits: 0,
  );
});
