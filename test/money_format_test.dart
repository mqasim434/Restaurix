import 'package:flutter_test/flutter_test.dart';
import 'package:restaurix/core/format/money_format.dart';
import 'package:restaurix/domain/models/app_currency.dart';

void main() {
  group('MoneyFormat', () {
    test('formats USD with dollar symbol', () {
      expect(MoneyFormat.format(12.5, 'USD'), r'$12.50');
    });

    test('formats PKR with rupee prefix', () {
      final formatted = MoneyFormat.format(1500, 'PKR');
      expect(formatted, contains('Rs'));
      expect(formatted, contains('1,500'));
    });

    test('falls back to default for unknown code', () {
      expect(
        MoneyFormat.format(10, 'XYZ'),
        MoneyFormat.format(10, AppCurrency.defaultCode),
      );
    });
  });

  group('AppCurrency', () {
    test('normalizeCode returns known codes', () {
      expect(AppCurrency.normalizeCode('pkr'), 'PKR');
      expect(AppCurrency.normalizeCode('qar'), 'QAR');
      expect(AppCurrency.normalizeCode(null), AppCurrency.defaultCode);
    });
  });
}
