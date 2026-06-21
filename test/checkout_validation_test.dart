import 'package:flutter_test/flutter_test.dart';

import 'package:restaurix/domain/models/order_enums.dart';
import 'package:restaurix/domain/models/pos_checkout_draft.dart';
import 'package:restaurix/features/pos/services/checkout_validation.dart';

void main() {
  group('CheckoutValidation', () {
    test('requires order type', () {
      expect(
        CheckoutValidation.validate(const PosCheckoutDraft()),
        contains('order type'),
      );
    });

    test('requires table for dine in', () {
      expect(
        CheckoutValidation.validate(
          const PosCheckoutDraft(orderType: OrderType.dineIn),
        ),
        contains('table'),
      );
    });

    test('passes for takeaway', () {
      expect(
        CheckoutValidation.validate(
          const PosCheckoutDraft(orderType: OrderType.takeaway),
        ),
        isNull,
      );
    });

    test('blocks delivery without rider or company', () {
      expect(
        CheckoutValidation.validate(
          const PosCheckoutDraft(
            orderType: OrderType.delivery,
            deliveryMode: DeliveryMode.ownRider,
          ),
        ),
        contains('rider'),
      );

      expect(
        CheckoutValidation.validate(
          const PosCheckoutDraft(
            orderType: OrderType.delivery,
            deliveryMode: DeliveryMode.pickupCompany,
          ),
        ),
        contains('pickup company'),
      );
    });

    test('passes for delivery with rider selected', () {
      expect(
        CheckoutValidation.validate(
          const PosCheckoutDraft(
            orderType: OrderType.delivery,
            deliveryMode: DeliveryMode.ownRider,
            riderId: 'r1',
            riderName: 'Ali',
          ),
        ),
        isNull,
      );
    });
  });
}
