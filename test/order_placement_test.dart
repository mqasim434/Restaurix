import 'package:flutter_test/flutter_test.dart';
import 'package:restaurix/domain/models/order_enums.dart';
import 'package:restaurix/domain/services/order_placement.dart';

void main() {
  group('order placement helpers', () {
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
