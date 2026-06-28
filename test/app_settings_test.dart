import 'package:flutter_test/flutter_test.dart';
import 'package:restaurix/domain/models/app_settings.dart';

void main() {
  group('AppSettings', () {
    test('resolvePrinterTarget maps config id to target', () {
      const settings = AppSettings(
        businessName: 'Test Cafe',
        printers: [
          PrinterConfig(
            id: 'kitchen-main',
            name: 'Kitchen',
            target: '192.168.1.10',
          ),
        ],
        receiptPrinterTarget: 'kitchen-main',
      );

      expect(settings.resolvedReceiptPrinterTarget(), '192.168.1.10');
      expect(settings.resolvePrinterTarget('kitchen-main'), '192.168.1.10');
      expect(settings.resolvePrinterTarget('10.0.0.5'), '10.0.0.5');
    });

    test('resolveKitchenCategoryPrinter uses category map', () {
      const settings = AppSettings(
        businessName: 'Test Cafe',
        printers: [
          PrinterConfig(
            id: 'bar-printer',
            name: 'Bar',
            target: 'Bar-Printer',
          ),
        ],
        kitchenCategoryPrinters: {'Bar': 'bar-printer'},
      );

      expect(settings.resolveKitchenCategoryPrinter('Bar'), 'Bar-Printer');
      expect(settings.resolveKitchenCategoryPrinter('Grill'), isNull);
    });
  });

  group('settings encoding helpers', () {
    test('encode and decode printer configs', () {
      const printers = [
        PrinterConfig(id: 'p1', name: 'Receipt', target: 'Receipt-58'),
      ];

      final decoded = decodePrinterConfigs(encodePrinterConfigs(printers));
      expect(decoded, hasLength(1));
      expect(decoded.first.id, 'p1');
      expect(decoded.first.name, 'Receipt');
      expect(decoded.first.target, 'Receipt-58');
    });

    test('encode and decode category printer map', () {
      const map = {'Grill': 'kitchen-main', 'Bar': 'bar-printer'};

      final decoded = decodeCategoryPrinterMap(encodeCategoryPrinterMap(map));
      expect(decoded, map);
    });

    test('parseSalaryGenerationDay clamps to valid range', () {
      expect(parseSalaryGenerationDay(null), 1);
      expect(parseSalaryGenerationDay('15'), 15);
      expect(parseSalaryGenerationDay('31'), 28);
      expect(parseSalaryGenerationDay('abc'), 1);
    });
  });
}
