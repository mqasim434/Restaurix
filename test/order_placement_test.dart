import 'package:restaurix/domain/models/order_enums.dart';
import 'package:restaurix/domain/services/order_placement.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('order placement helpers', () {
    test('generateOrderNumber includes device prefix and date', () {
      final number = generateOrderNumber(
        deviceId: 'abcdef12-3456-7890-abcd-ef1234567890',
        now: DateTime(2024, 6, 21),
      );

      expect(number.startsWith('ABCDEF-20240621-'), isTrue);
      expect(number.split('-').length, 3);
    });

    test('resolvePaymentStatus marks prepaid orders paid', () {
      expect(
        resolvePaymentStatus(isPrepaid: true),
        OrderPaymentStatus.paid,
      );
      expect(
        resolvePaymentStatus(isPrepaid: false),
        OrderPaymentStatus.unpaid,
      );
    });

    test('resolveIsPrepaid uses order-type defaults', () {
      expect(
        resolveIsPrepaid(orderType: OrderType.dineIn),
        isFalse,
      );
      expect(
        resolveIsPrepaid(orderType: OrderType.takeaway),
        isTrue,
      );
      expect(
        resolveIsPrepaid(
          orderType: OrderType.dineIn,
          override: true,
        ),
        isTrue,
      );
    });
  });
}
