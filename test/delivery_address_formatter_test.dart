import 'package:flutter_test/flutter_test.dart';
import 'package:restaurix/domain/services/delivery_address_formatter.dart';

void main() {
  group('DeliveryAddressFormatter', () {
    test('extracts coordinate pairs and hides them from textual lines', () {
      final coords = DeliveryAddressFormatter.extractCoordinates([
        '25.285412, 51.531045',
        'Near Ibn Omran',
      ]);
      expect(coords, isNotNull);
      expect(coords!.latitude, closeTo(25.285412, 0.000001));
      expect(coords.longitude, closeTo(51.531045, 0.000001));

      final lines = DeliveryAddressFormatter.textualLines(
        line1: '25.285412, 51.531045',
        line2: 'St 850, Zone 37',
        city: 'Doha',
      );
      expect(lines, isNot(contains(contains('25.285'))));
      expect(lines.any((line) => line.contains('St 850')), isTrue);
      expect(lines.any((line) => line.contains('Doha')), isTrue);
    });

    test('drops coordinate-only address lines', () {
      final lines = DeliveryAddressFormatter.textualLines(
        line1: '25.28, 51.53',
      );
      expect(lines, isEmpty);
    });
  });
}