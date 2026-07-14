import 'package:flutter_test/flutter_test.dart';
import 'package:restaurix/domain/models/app_settings.dart';

void main() {
  group('AppSettings', () {
    test('copyWith updates currency code', () {
      const settings = AppSettings(businessName: 'Test Cafe');

      final updated = settings.copyWith(currencyCode: 'PKR');

      expect(updated.currencyCode, 'PKR');
    });

    test('copyWith clears optional receipt fields', () {
      const settings = AppSettings(
        businessName: 'Test Cafe',
        businessAddress: '123 Main',
        receiptHeaderText: 'Welcome',
        receiptFooterText: 'Thanks',
      );

      final cleared = settings.copyWith(
        clearBusinessAddress: true,
        clearReceiptHeaderText: true,
        clearReceiptFooterText: true,
      );

      expect(cleared.businessAddress, isNull);
      expect(cleared.receiptHeaderText, isNull);
      expect(cleared.receiptFooterText, isNull);
    });
  });

  group('settings encoding helpers', () {
    test('parseSalaryGenerationDay clamps to valid range', () {
      expect(parseSalaryGenerationDay(null), 1);
      expect(parseSalaryGenerationDay('15'), 15);
      expect(parseSalaryGenerationDay('31'), 28);
      expect(parseSalaryGenerationDay('abc'), 1);
    });
  });
}
