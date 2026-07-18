import 'package:flutter_test/flutter_test.dart';
import 'package:restaurix/core/sync/sync_action.dart';
import 'package:restaurix/domain/models/order.dart';
import 'package:restaurix/domain/models/order_enums.dart';
import 'package:restaurix/domain/models/user_role.dart';
import 'package:restaurix/domain/services/order_lifecycle.dart';

Order _creditOrder({
  OrderType type = OrderType.dineIn,
  OrderStatus status = OrderStatus.received,
}) {
  return Order(
    id: 'o1',
    orderNumber: 'TEST-001',
    orderType: type,
    subtotal: 100,
    itemDiscountTotal: 0,
    orderDiscountTotal: 0,
    total: 100,
    paymentType: PaymentType.credit,
    paymentStatus: OrderPaymentStatus.unpaid,
    status: status,
    isPrepaid: false,
    createdByUserId: 'u1',
    createdAt: DateTime(2024, 6, 21),
    updatedAt: DateTime(2024, 6, 21),
    isSynced: false,
    syncAction: SyncAction.create,
    deviceId: 'd1',
    version: 1,
  );
}

void main() {
  group('OrderLifecycle credit orders', () {
    test('credit orders skip mark paid and can complete on account', () {
      final order = _creditOrder(
        type: OrderType.takeaway,
        status: OrderStatus.received,
      );

      expect(OrderLifecycle.canMarkPaid(order, UserRole.admin), isFalse);
      expect(
        OrderLifecycle.canCompleteCreditOrder(order, UserRole.admin),
        isTrue,
      );
      expect(OrderLifecycle.nextStatus(order), OrderStatus.completed);
    });

    test('dine-in credit order completes after served', () {
      final order = _creditOrder(
        type: OrderType.dineIn,
        status: OrderStatus.served,
      );

      expect(OrderLifecycle.nextStatus(order), OrderStatus.completed);
      expect(
        OrderLifecycle.canCompleteCreditOrder(order, UserRole.admin),
        isTrue,
      );
    });

    test('closed credit orders cannot be completed again', () {
      final order = _creditOrder(status: OrderStatus.completed);
      expect(
        OrderLifecycle.canCompleteCreditOrder(order, UserRole.admin),
        isFalse,
      );
    });
  });
}
