import 'package:flutter_test/flutter_test.dart';
import 'package:restaurix/domain/models/order.dart';
import 'package:restaurix/domain/models/order_enums.dart';
import 'package:restaurix/core/sync/sync_action.dart';
import 'package:restaurix/domain/services/tablet_order_detection.dart';

Order _order({
  required String orderNumber,
  required String deviceId,
}) {
  final now = DateTime(2024, 6, 21, 12);
  return Order(
    id: 'o1',
    orderNumber: orderNumber,
    orderType: OrderType.dineIn,
    subtotal: 10,
    itemDiscountTotal: 0,
    orderDiscountTotal: 0,
    total: 10,
    paymentStatus: OrderPaymentStatus.unpaid,
    status: OrderStatus.received,
    isPrepaid: false,
    createdByUserId: 'u1',
    createdAt: now,
    updatedAt: now,
    isSynced: true,
    syncAction: SyncAction.create,
    deviceId: deviceId,
    version: 1,
  );
}

void main() {
  group('tablet order detection', () {
    test('detects ODR order numbers as waiter tablet', () {
      final order = _order(orderNumber: 'ODR-0001', deviceId: 'tab-1');
      expect(isTabletOrder(order, 'desktop-1'), isTrue);
      expect(isWaiterTabletOrder(order, 'desktop-1'), isTrue);
      expect(isCustomerAppOrder(order), isFalse);
    });

    test('detects ODRM order numbers as customer app only', () {
      final order = _order(orderNumber: 'ODRM-0001', deviceId: 'phone-1');
      expect(isTabletOrder(order, 'desktop-1'), isTrue);
      expect(isWaiterTabletOrder(order, 'desktop-1'), isFalse);
      expect(isCustomerAppOrder(order), isTrue);
    });

    test('keeps legacy ORDM / ORDC detection', () {
      expect(
        isWaiterTabletOrder(
          _order(orderNumber: 'ORDM-20260630-001', deviceId: 'tab-1'),
          'desktop-1',
        ),
        isTrue,
      );
      expect(
        isCustomerAppOrder(
          _order(orderNumber: 'ORDC-20260630-001', deviceId: 'phone-1'),
        ),
        isTrue,
      );
    });

    test('detects orders from another device even without tablet prefix', () {
      expect(
        isTabletOrder(
          _order(orderNumber: 'ORD-20260630-001', deviceId: 'tab-1'),
          'desktop-1',
        ),
        isTrue,
      );
    });

    test('ignores orders created on this desktop device', () {
      expect(
        isTabletOrder(
          _order(orderNumber: 'ORD-20260630-001', deviceId: 'desktop-1'),
          'desktop-1',
        ),
        isFalse,
      );
    });

    test('realtime payload detects ODRM and foreign device', () {
      expect(
        isTabletOrderPayload(
          record: const {
            'order_number': 'ODRM-0002',
            'device_id': 'customer-phone',
          },
          localDeviceId: 'desktop-device',
        ),
        isTrue,
      );
      expect(
        isTabletOrderPayload(
          record: const {
            'order_number': 'ODR-0002',
            'device_id': 'tablet-device',
          },
          localDeviceId: 'desktop-device',
        ),
        isTrue,
      );
    });
  });
}
