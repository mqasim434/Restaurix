import 'package:flutter_test/flutter_test.dart';
import 'package:restaurix/domain/models/table_status.dart';

void main() {
  group('TableStatusX.fromWire', () {
    test('keeps available and occupied', () {
      expect(TableStatusX.fromWire('available'), TableStatus.available);
      expect(TableStatusX.fromWire('occupied'), TableStatus.occupied);
    });

    test('maps legacy reserved without order to available', () {
      expect(TableStatusX.fromWire('reserved'), TableStatus.available);
      expect(
        TableStatusX.fromWire('reserved', currentOrderId: ''),
        TableStatus.available,
      );
    });

    test('maps legacy reserved with order to occupied', () {
      expect(
        TableStatusX.fromWire('reserved', currentOrderId: 'order-1'),
        TableStatus.occupied,
      );
    });
  });
}
