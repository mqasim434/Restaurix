import 'package:flutter_test/flutter_test.dart';
import 'package:restaurix/core/printing/esc_pos_money_format.dart';
import 'package:restaurix/core/printing/esc_pos_text_sanitizer.dart';

void main() {
  group('EscPosMoneyFormat', () {
    test('formats USD without unicode symbols', () {
      expect(EscPosMoneyFormat.format(12.5, 'USD'), r'$12.50');
    });

    test('formats PKR with ASCII prefix', () {
      expect(EscPosMoneyFormat.format(1500, 'PKR'), 'Rs 1,500.00');
    });

    test('formats EUR with ASCII code instead of euro sign', () {
      expect(EscPosMoneyFormat.format(99.9, 'EUR'), 'EUR 99.90');
    });

    test('formats discounts with leading minus', () {
      expect(
        EscPosMoneyFormat.formatDiscount(25, 'USD'),
        r'-$25.00',
      );
    });
  });

  group('EscPosTextSanitizer', () {
    test('maps unicode punctuation to ASCII', () {
      expect(
        EscPosTextSanitizer.sanitize('Take Away · Table 5'),
        'Take Away * Table 5',
      );
    });

    test('strips unsupported characters instead of question marks', () {
      expect(
        EscPosTextSanitizer.sanitize('Burger 🍔'),
        'Burger',
      );
    });

    test('normalizes accented latin characters', () {
      expect(
        EscPosTextSanitizer.sanitize('Cafe au lait'),
        'Cafe au lait',
      );
      expect(
        EscPosTextSanitizer.sanitize('Crème Brûlée'),
        'Creme Brulee',
      );
    });
  });
}
